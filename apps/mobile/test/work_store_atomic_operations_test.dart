import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_downloads.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';

// Automated invoice fixture only; never supplies OPPO runtime acceptance records.
class _PurchaseInvoicePickerFixture implements WorkProofPicker {
  _PurchaseInvoicePickerFixture(this.value);
  WorkPickedProof? value;
  void Function()? afterPick;
  @override
  Future<WorkPickedProof?> pick(WorkProofSource source) async {
    afterPick?.call();
    return value;
  }
}

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
  int saveAttempts = 0;
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
    saveAttempts++;
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
  String? failWriteKey;
  String? failReadKey;
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
    if (failRead || key == failReadKey) throw StateError('test read failure');
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
    if (failWrite || key == failWriteKey) throw StateError('test write failure');
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
  Future<StoreReviewSeed?> archiveLegacySelectionForEntry(
    String account,
  ) async {
    final previous = await read(account);
    if (previous == null || previous.orderCount == 0) return previous;
    return seed = StoreReviewSeed(
      accountScope: previous.accountScope,
      orderCount: 0,
      now: previous.now,
    );
  }

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
      contactDraftStore: account,
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
  // Local automated fixture evidence only; no runtime supplier/bill injection.
  WorkspacePurchaseEntryBook entryFixture({int revision = 1, String reference = 'EVAL-P-001'}) {
    final at = DateTime.utc(2026, 9, 30);
    return WorkspacePurchaseEntryBook(account: 'account-A', store: 'store-A', qa: true,
      revision: revision, profiles: [WorkspaceSupplierProfile(id: 'private-supplier-A',
        name: 'Evaluation supply house', createdAt: at, updatedAt: at)],
      draft: WorkspacePurchaseEntryDraft(id: 'manual-draft-A', supplierId: 'private-supplier-A',
        invoiceReference: reference, invoiceDate: '2026-09-30', createdAt: at, updatedAt: at,
        goods: [const {'productId': 'saved-product-A', 'name': 'Evaluation rice', 'pack': '1 kg',
          'quantity': '12', 'cost': '45.50'}]));
  }
  test('P02 purchase entry secure restart and scope isolation', () async {
    final storage = _OrderJournalStorage();
    String account = 'account-A';
    SecureWorkPurchaseEntryStore owner() => SecureWorkPurchaseEntryStore(
      accountScope: () => account, storage: storage);
    await owner().save(entryFixture(), expectedRevision: null);
    final restored = await owner().read('account-A', 'store-A', qa: true);
    expect(restored!.toJson(), entryFixture().toJson());
    expect(await owner().read('account-A', 'other-store', qa: true), isNull);
    expect(await owner().read('account-A', 'store-A', qa: false), isNull);
    account = 'other-account';
    await expectLater(owner().read('account-A', 'store-A', qa: true), throwsA(isA<WorkGatewayException>()));
    expect(await owner().read('other-account', 'store-A', qa: true), isNull);
  });
  // R12 fixtures are automated evidence only, never runtime acceptance records.
  WorkspacePurchaseSavedCopy copyFixture({String id = 'reviewed-copy-A', int revision = 2}) {
    final book = entryFixture();
    return WorkspacePurchaseSavedCopy(id: id, storeName: 'Evaluation Store',
      revision: revision, savedAt: book.draft!.updatedAt,
      supplier: book.profiles.single, draft: book.draft!, labels: {'invoiceTotal': 'Invoice total ₹'});
  }
  WorkspacePurchaseEntryBook copyBook({int revision = 2, String reference = 'EVAL-P-001',
      List<WorkspacePurchaseSavedCopy>? copies}) {
    final book = entryFixture(revision: revision, reference: reference);
    return WorkspacePurchaseEntryBook(account: book.account, store: book.store, qa: book.qa,
      revision: revision, profiles: book.profiles, draft: book.draft,
      copies: copies ?? [copyFixture()]);
  }
  // P04 labelled host fixtures only; no runtime records or financial posting.
  WorkspaceSupplierOpeningRecord openingFixture({int revision = 3, int? amount,
      bool credit = false, List<WorkspaceOpeningBillLink>? bills}) =>
    WorkspaceSupplierOpeningRecord(id: 'opening-A-r$revision', basisId: 'opening-A',
      account: 'account-A', store: 'store-A', qa: true, supplierId: 'private-supplier-A',
      revision: revision, asOfDate: '2026-10-01', savedAt: DateTime.utc(2026, 10, 2),
      amountMinor: amount, supplierCredit: credit, sourceNote: 'Supplier opening statement reviewed',
      bills: bills ?? [const WorkspaceOpeningBillLink(copyId: 'reviewed-copy-A',
        copyRevision: 2, draftId: 'manual-draft-A', inclusion: WorkspaceOpeningBillInclusion.included)]);
  WorkspacePurchaseEntryBook openingBook({int revision = 3,
      List<WorkspaceSupplierOpeningRecord>? records, List<WorkspacePurchaseSavedCopy>? copies}) {
    final base = copyBook();
    return WorkspacePurchaseEntryBook(account: base.account, store: base.store, qa: base.qa,
      revision: revision, profiles: base.profiles, draft: base.draft,
      copies: copies ?? base.copies, openingRecords: records ?? [openingFixture()]);
  }
  test('P04 unknown is not zero and correction history keeps one supplier basis', () {
    expect(WorkspacePurchaseEntryBook.fromJson(entryFixture().toJson()).openingRecords, isEmpty);
    final unknown = openingFixture();
    final zero = openingFixture(revision: 4, amount: 0, credit: true);
    final restored = WorkspacePurchaseEntryBook.fromJson(openingBook(revision: 4,
      records: [unknown, zero]).toJson());
    expect(restored.openingRecords.first.amountMinor, isNull);
    expect(restored.openingRecordFor(unknown.supplierId)!.amountMinor, 0);
    expect(restored.openingRecordFor(unknown.supplierId)!.supplierCredit, isTrue);
    expect(restored.openingRecords.map((r) => r.basisId).toSet(), {'opening-A'});
    expect(() => restored.openingRecords.clear(), throwsUnsupportedError);
    expect(() => restored.openingRecords.first.bills.clear(), throwsUnsupportedError);
  });
  for (final invalid in <(String, Object?)>[
    ('currency', 'USD'), ('amountMinor', -1), ('amountMinor', 1.5),
    ('amountMinor', 1000000000000), ('asOfDate', '2026-02-30'),
    ('sourceNote', ''), ('supplierCredit', 'true'), ('qa', false),
    ('store', 'foreign-store'), ('account', 'foreign-account'),
    ('supplierId', 'missing-supplier'), ('revision', 2), ('posted', true),
  ]) {
    test('P04 strict record rejects ${invalid.$1} ${invalid.$2}', () {
      final raw = jsonDecode(jsonEncode(openingBook().toJson())) as Map<String, dynamic>;
      ((raw['openingRecords'] as List).single as Map)[invalid.$1] = invalid.$2;
      expect(() => WorkspacePurchaseEntryBook.fromJson(raw), throwsFormatException);
    });
  }
  test('P04 bill assertions bind exact reviewed revisions not corrected latest copies', () {
    final corrected = copyFixture(id: 'reviewed-copy-B', revision: 4);
    final book = WorkspacePurchaseEntryBook.fromJson(openingBook(revision: 4,
      copies: [copyFixture(), corrected]).toJson());
    expect(book.latestReviewedCopies.single.id, corrected.id);
    expect(book.openingRecords.single.bills.single.copyId, 'reviewed-copy-A');
    expect(book.openingRecords.single.bills.single.copyRevision, 2);
    for (final change in <Map<String, Object?>>[
      {'copyId': 'missing'}, {'copyRevision': 4}, {'draftId': 'foreign-draft'},
      {'inclusion': 'allocation'},
    ]) {
      final raw = jsonDecode(jsonEncode(openingBook().toJson())) as Map<String, dynamic>;
      final link = (((raw['openingRecords'] as List).single as Map)['bills'] as List).single as Map;
      link.addAll(change);
      expect(() => WorkspacePurchaseEntryBook.fromJson(raw), throwsFormatException);
    }
    final replacement = WorkspaceSupplierOpeningRecord.fromJson({...openingFixture(revision: 4).toJson(),
      'basisId': 'replacement-basis'});
    expect(() => WorkspacePurchaseEntryBook.fromJson(openingBook(revision: 4,
      records: [openingFixture(), replacement]).toJson()), throwsFormatException);
  });
  test('P04 secure restart preserves records and rejects old-writer drop or mutation', () async {
    final device = _OrderJournalStorage();
    SecureWorkPurchaseEntryStore owner() => SecureWorkPurchaseEntryStore(
      accountScope: () => 'account-A', storage: device);
    await owner().save(entryFixture(), expectedRevision: null);
    await owner().save(copyBook(), expectedRevision: 1);
    await owner().save(openingBook(), expectedRevision: 2);
    final before = Map.of(device.values);
    await expectLater(owner().save(copyBook(revision: 4), expectedRevision: 3),
      throwsA(isA<WorkGatewayException>()));
    await expectLater(owner().save(openingBook(revision: 4,
      records: [openingFixture(amount: 900)]), expectedRevision: 3),
      throwsA(isA<WorkGatewayException>()));
    expect(device.values, before);
    final correction = openingFixture(revision: 4, amount: 900, credit: true);
    await owner().save(openingBook(revision: 4,
      records: [openingFixture(), correction]), expectedRevision: 3);
    final saved = await owner().read('account-A', 'store-A', qa: true);
    expect(saved!.openingRecords, hasLength(2));
    expect(saved.openingRecordFor(correction.supplierId)!.toJson(), correction.toJson());
    expect(saved.draft!.toJson(), copyBook().draft!.toJson());
    expect(saved.copies.single.toJson(), copyFixture().toJson());
    expect(await owner().read('account-A', 'other-store', qa: true), isNull);
    expect(await owner().read('account-A', 'store-A', qa: false), isNull);
  });
  test('P04 failed write read and lost response retain one stable record', () async {
    final device = _OrderJournalStorage();
    final owner = SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: device);
    await owner.save(entryFixture(), expectedRevision: null);
    await owner.save(copyBook(), expectedRevision: 1);
    final before = Map.of(device.values);
    device.failWrite = true;
    await expectLater(owner.save(openingBook(), expectedRevision: 2), throwsA(isA<Object>()));
    expect(device.values, before);
    device.failWrite = false;
    device.failRead = true;
    await expectLater(owner.save(openingBook(), expectedRevision: 2), throwsA(isA<Object>()));
    expect(device.values, before);
    device.failRead = false;
    device.loseWriteResponseOnce = true;
    await owner.save(openingBook(), expectedRevision: 2);
    final writes = device.writes.length;
    await owner.save(openingBook(), expectedRevision: 2);
    expect(device.writes.length, writes, reason: 'Lost-response retry must not append a second record.');
    await expectLater(owner.save(openingBook(revision: 4,
      records: [openingFixture(), openingFixture(revision: 4, amount: 1)]), expectedRevision: 2),
      throwsA(isA<WorkGatewayException>()));
    expect((await owner.read('account-A', 'store-A', qa: true))!.openingRecords, hasLength(1));
  });
  test('P04 session serializes saves preserves working bill and scopes restart', () async {
    final device = _OrderJournalStorage();
    final account = _CommandAccountStore();
    WorkSession fresh() => WorkSession(gateway: ReviewWorkGateway(), contactDraftStore: account,
      purchaseEntryStore: SecureWorkPurchaseEntryStore(accountScope: () => account.accountScope,
        storage: device))..activeWorkspace = _commandStore;
    final work = fresh();
    addTearDown(work.dispose);
    expect(await work.loadWorkspaceSuppliers(), isTrue);
    final base = entryFixture();
    final supplier = base.profiles.single;
    final scope = work.workspaceSupplierScope!;
    expect(await work.saveWorkspacePurchaseEntry(supplier, scope: scope,
      draft: base.draft!, expectedRevision: null), isTrue);
    WorkspaceSupplierOpeningRecord record(int rev, {int? amount}) =>
      WorkspaceSupplierOpeningRecord(id: 'session-opening-r$rev', basisId: 'session-opening',
        account: scope.$1, store: scope.$2, qa: scope.$3, supplierId: supplier.id,
        revision: rev, asOfDate: '2026-10-01', savedAt: DateTime.utc(2026, 10, 2),
        amountMinor: amount, supplierCredit: false, sourceNote: 'Evaluation statement', bills: const []);
    final stock = work.workspaceCatalogueItems.map((p) => (p.id, p.stock)).toList();
    final finance = work.workspaceFinance;
    device.holdWrite = Completer<void>();
    final pending = work.saveWorkspaceSupplierOpeningRecord(record(2), scope: scope, expectedRevision: 1);
    await Future<void>.delayed(Duration.zero);
    expect(work.workspaceSupplierSaving, isTrue);
    expect(await work.saveWorkspacePurchaseEntry(supplier, scope: scope,
      draft: base.draft!, expectedRevision: 1), isFalse);
    expect(await work.saveWorkspaceSupplierOpeningRecord(record(2), scope: scope,
      expectedRevision: 1), isFalse);
    device.holdWrite!.complete();
    expect(await pending, isTrue);
    device.holdWrite = null;
    final writes = device.writes.length;
    expect(await work.saveWorkspaceSupplierOpeningRecord(record(2), scope: scope,
      expectedRevision: 1), isTrue);
    expect(device.writes.length, writes);
    expect(await work.saveWorkspaceSupplierOpeningRecord(record(3, amount: 200),
      scope: (scope.$1, 'foreign-store', scope.$3), expectedRevision: 2), isFalse);
    expect(await work.saveWorkspaceSupplierOpeningRecord(record(3, amount: 200),
      scope: scope, expectedRevision: 1), isFalse);
    expect(await work.saveWorkspacePurchaseEntry(supplier, scope: scope,
      draft: base.draft!, expectedRevision: 2), isTrue);
    expect(work.workspaceSupplierOpeningRecords.single.amountMinor, isNull);
    expect(await work.saveWorkspaceSupplierOpeningRecord(record(4, amount: 0),
      scope: scope, expectedRevision: 3), isTrue);
    expect(work.workspaceCatalogueItems.map((p) => (p.id, p.stock)), stock);
    expect(work.workspaceFinance, same(finance));
    expect(work.workspacePurchases, isEmpty);
    final restarted = fresh();
    addTearDown(restarted.dispose);
    expect(await restarted.loadWorkspaceSuppliers(), isTrue);
    expect(restarted.workspaceSupplierOpeningRecords, hasLength(2));
    expect(restarted.workspaceSupplierOpeningRecord(supplier.id)!.amountMinor, 0);
    expect(restarted.workspacePurchaseEntryDraft!.id, base.draft!.id);
    expect(restarted.workspacePurchaseEntryRevision, 4);
    expect(restarted.workspaceFinance, isNull);
  });
  test('P05-R12 legacy history empty and saved copies defensively immutable', () {
    expect(WorkspacePurchaseEntryBook.fromJson(entryFixture().toJson()).copies, isEmpty);
    final book = WorkspacePurchaseEntryBook.fromJson(copyBook().toJson());
    expect(book.copies.single.draft.invoiceReference, 'EVAL-P-001');
    expect(() => book.copies.clear(), throwsUnsupportedError);
    expect(() => book.copies.single.labels['invoiceTotal'] = 'Changed', throwsUnsupportedError);
    expect(() => book.copies.single.draft.goods.single['cost'] = '0', throwsUnsupportedError);
    expect(book.toJson(), copyBook().toJson());
  });
  for (final pair in <(String, int?)>[
    ('31/03/2026', 2025), ('01/04/2026', 2026), ('2026-04-01', 2026),
    ('29/02/2024', 2023), ('29/02/2026', null), ('31/04/2026', null),
    ('01/13/2026', null), ('2026/09/30', null), ('', null),
  ]) {
    test('P05-NEXT invoice financial year validates ${pair.$1}', () {
      final draft = WorkspacePurchaseEntryDraft.fromJson({...entryFixture().draft!.toJson(),
        'invoiceDate': pair.$1});
      expect(draft.invoiceFinancialYear, pair.$2);
      expect(draft.invoiceDate, pair.$1); // Preserve printed/raw content.
    });
  }
  test('P05-NEXT duplicate key preserves supplier year punctuation and revisions', () {
    final book = copyBook();
    WorkspacePurchaseEntryDraft candidate({String id = 'new-draft', String? supplier,
        String reference = 'EVAL-P-001', String date = '30/09/2026'}) =>
      WorkspacePurchaseEntryDraft.fromJson({...book.draft!.toJson(), 'id': id,
        'supplierId': supplier ?? book.draft!.supplierId, 'invoiceReference': reference, 'invoiceDate': date});
    expect(book.draftHasReviewedCopy, isTrue);
    expect(book.duplicateInvoice(candidate(reference: ' eval-p-001 ', date: '31/03/2027')), isNotNull);
    expect(book.duplicateInvoice(candidate(date: '01/04/2027')), isNull);
    expect(book.duplicateInvoice(candidate(supplier: 'other-supplier')), isNull);
    expect(book.duplicateInvoice(candidate(reference: 'EVAL/P/001')), isNull);
    expect(book.duplicateInvoice(candidate(reference: 'EVAL-P-01')), isNull);
    expect(book.duplicateInvoice(candidate(reference: 'EVAL- P-001')), isNull);
    expect(book.duplicateInvoice(candidate(id: book.draft!.id)), isNull);
    expect(book.duplicateInvoice(candidate(date: '31/02/2026')), isNull);
    final correctedDraft = candidate(id: book.draft!.id, reference: 'CORRECTED-P-001');
    final correctedCopy = WorkspacePurchaseSavedCopy(id: 'corrected-copy', storeName: book.copies.single.storeName,
      revision: 3, savedAt: correctedDraft.updatedAt, supplier: book.profiles.single,
      draft: correctedDraft, labels: const {});
    final correctedBook = WorkspacePurchaseEntryBook(account: book.account, store: book.store, qa: book.qa,
      revision: 3, profiles: book.profiles, draft: correctedDraft, copies: [...book.copies, correctedCopy]);
    expect(correctedBook.duplicateInvoice(candidate()), isNull);
    expect(correctedBook.duplicateInvoice(candidate(reference: 'CORRECTED-P-001')), isNotNull);
    final edited = WorkspacePurchaseEntryDraft.fromJson({...correctedDraft.toJson(),
      'goods': [const {'productId': '', 'name': 'Changed unsaved working goods',
        'pack': '', 'quantity': '', 'cost': ''}]});
    final unfinished = WorkspacePurchaseEntryBook(account: book.account, store: book.store, qa: book.qa,
      revision: 4, profiles: book.profiles, draft: edited, copies: correctedBook.copies);
    expect(unfinished.draftHasReviewedCopy, isFalse);
    expect(WorkspacePurchaseEntryBook.fromJson(correctedBook.toJson()).copies, hasLength(2));
    final conflicting = WorkspacePurchaseSavedCopy(id: 'conflicting-copy',
      storeName: correctedCopy.storeName, revision: 3, savedAt: correctedCopy.savedAt,
      supplier: correctedCopy.supplier, draft: book.draft!, labels: const {});
    final ambiguous = WorkspacePurchaseEntryBook(account: book.account, store: book.store, qa: book.qa,
      revision: 3, profiles: book.profiles, draft: correctedDraft,
      copies: [...correctedBook.copies, conflicting]);
    expect(ambiguous.draftHasReviewedCopy, isFalse);
    expect(ambiguous.duplicateInvoice(candidate()), isNotNull);
    expect(ambiguous.duplicateInvoice(candidate(reference: 'CORRECTED-P-001')), isNotNull);
  });
  test('P05-R12 strict copy validation scope duplicate identity and posted data', () {
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (r) => (r['copies'] as List).add((r['copies'] as List).single),
      (r) => ((r['copies'] as List).single as Map)['revision'] = 3,
      (r) => (((r['copies'] as List).single as Map)['draft'] as Map)['stage'] = 'posted',
      (r) => (((r['copies'] as List).single as Map)['supplier'] as Map)['id'] = 'wrong-supplier',
      (r) => r['copies'] = null,
    ]) {
      final raw = jsonDecode(jsonEncode(copyBook().toJson())) as Map<String, dynamic>;
      mutate(raw);
      expect(() => WorkspacePurchaseEntryBook.fromJson(raw), throwsFormatException);
    }
  });
  test('P05-R12 restart later draft changes preserve historical supplier and data', () async {
    final storage = _OrderJournalStorage();
    SecureWorkPurchaseEntryStore owner() => SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage);
    await owner().save(entryFixture(), expectedRevision: null);
    await owner().save(copyBook(), expectedRevision: 1);
    final later = jsonDecode(jsonEncode(copyBook(revision: 3, reference: 'LATER-DRAFT').toJson())) as Map;
    ((later['profiles'] as List).single as Map)['name'] = 'Later supplier name';
    await owner().save(WorkspacePurchaseEntryBook.fromJson(later), expectedRevision: 2);
    final restored = (await owner().read('account-A', 'store-A', qa: true))!;
    expect(restored.draft!.invoiceReference, 'LATER-DRAFT');
    expect(restored.profiles.single.name, 'Later supplier name');
    expect(restored.copies.single.toJson(), copyFixture().toJson());
    expect(await owner().read('account-A', 'other-store', qa: true), isNull);
    expect(await owner().read('account-A', 'store-A', qa: false), isNull);
  });
  test('P05-R12 append-only storage rejects deletion mutation stale and retries lost reply', () async {
    final storage = _OrderJournalStorage();
    final owner = SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage);
    await owner.save(entryFixture(), expectedRevision: null);
    storage.loseWriteResponseOnce = true;
    await owner.save(copyBook(), expectedRevision: 1);
    await owner.save(copyBook(), expectedRevision: 1);
    expect((await owner.read('account-A', 'store-A', qa: true))!.copies, hasLength(1));
    await expectLater(owner.save(copyBook(revision: 3, copies: []), expectedRevision: 2),
      throwsA(isA<WorkGatewayException>()));
    final altered = WorkspacePurchaseSavedCopy(id: 'reviewed-copy-A', storeName: 'Changed',
      revision: 2, savedAt: copyFixture().savedAt, supplier: copyFixture().supplier,
      draft: copyFixture().draft, labels: copyFixture().labels);
    await expectLater(owner.save(copyBook(revision: 3, copies: [altered]), expectedRevision: 2),
      throwsA(isA<WorkGatewayException>()));
    await expectLater(owner.save(copyBook(revision: 3), expectedRevision: 1),
      throwsA(isA<WorkGatewayException>()));
    storage.failWrite = true;
    await expectLater(owner.save(copyBook(revision: 3), expectedRevision: 2), throwsStateError);
    expect((await owner.read('account-A', 'store-A', qa: true))!.toJson(), copyBook().toJson());
  });
  test('P05-R12 capacity rejects safely and still permits draft-only saves at copy count limit', () async {
    final storage = _OrderJournalStorage();
    final owner = SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage);
    await owner.save(entryFixture(), expectedRevision: null);
    final copies = [for (var i = 0; i < 1000; i++) copyFixture(id: 'copy-$i')];
    final full = copyBook(copies: copies);
    await owner.save(full, expectedRevision: 1);
    await owner.save(copyBook(revision: 3, reference: 'DRAFT-STILL-EDITABLE', copies: copies), expectedRevision: 2);
    expect((await owner.read('account-A', 'store-A', qa: true))!.copies, hasLength(1000));
    expect(() => WorkspacePurchaseEntryBook.fromJson(copyBook(revision: 4,
      copies: [...copies, copyFixture(id: 'overflow')]).toJson()), throwsFormatException);
    final sizeStorage = _OrderJournalStorage();
    final sizeOwner = SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: sizeStorage);
    await sizeOwner.save(entryFixture(), expectedRevision: null);
    final before = (await sizeOwner.read('account-A', 'store-A', qa: true))!.toJson();
    final base = entryFixture();
    final big = WorkspacePurchaseEntryDraft(id: base.draft!.id, supplierId: base.draft!.supplierId,
      invoiceReference: 'BIG-FIXTURE', invoiceDate: base.draft!.invoiceDate,
      createdAt: base.draft!.createdAt, updatedAt: base.draft!.updatedAt,
      goods: List.generate(200, (i) => {'productId': 'sku-$i', 'name': 'Evaluation item $i',
        'specifications': 'x' * 1000, 'pack': 'pcs', 'quantity': '1', 'cost': '1'}));
    final overBytes = WorkspacePurchaseEntryBook(account: base.account, store: base.store, qa: base.qa,
      revision: 2, profiles: base.profiles, draft: big, copies: [
        for (var i = 0; i < 100; i++) WorkspacePurchaseSavedCopy(id: 'big-$i',
          storeName: 'Store', revision: 2, savedAt: big.updatedAt,
          supplier: base.profiles.single, draft: big, labels: const {})]);
    expect(big.valid, isTrue);
    expect(overBytes.copies.every((copy) => copy.valid), isTrue);
    expect(WorkspacePurchaseEntryBook.fromJson(overBytes.toJson()).copies, hasLength(100));
    expect(utf8.encode(jsonEncode(overBytes.toJson())).length, greaterThan(10 * 1024 * 1024));
    await expectLater(sizeOwner.save(overBytes, expectedRevision: 1),
      throwsA(isA<WorkGatewayException>().having((e) => e.message, 'capacity explanation', contains('storage is full'))));
    expect((await sizeOwner.read('account-A', 'store-A', qa: true))!.toJson(), before);
  });
  test('P02 purchase entry stale revision and corrupt record preserve prior data', () async {
    final storage = _OrderJournalStorage();
    final owner = SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage);
    await owner.save(entryFixture(), expectedRevision: null);
    await expectLater(owner.save(entryFixture(revision: 2, reference: 'changed'), expectedRevision: null),
      throwsA(isA<WorkGatewayException>()));
    expect((await owner.read('account-A', 'store-A', qa: true))!.draft!.invoiceReference, 'EVAL-P-001');
    final key = storage.values.keys.single;
    storage.values[key] = '{broken';
    await expectLater(owner.read('account-A', 'store-A', qa: true), throwsA(isA<WorkGatewayException>()));
    await expectLater(owner.save(entryFixture(), expectedRevision: null), throwsA(isA<WorkGatewayException>()));
    expect(storage.values[key], '{broken');
  });
  test('P02 purchase entry lost response and failed write recovery', () async {
    final storage = _OrderJournalStorage()..loseWriteResponseOnce = true;
    final owner = SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage);
    await owner.save(entryFixture(), expectedRevision: null);
    expect((await owner.read('account-A', 'store-A', qa: true))!.revision, 1);
    storage.failWrite = true;
    await expectLater(owner.save(entryFixture(revision: 2, reference: 'changed'), expectedRevision: 1),
      throwsStateError);
    expect((await owner.read('account-A', 'store-A', qa: true))!.draft!.invoiceReference, 'EVAL-P-001');
  });
  test('P02 purchase entry rejects dangling supplier and posted or oversized drafts', () {
    final raw = entryFixture().toJson();
    raw['profiles'] = [];
    expect(() => WorkspacePurchaseEntryBook.fromJson(raw), throwsFormatException);
    final posted = entryFixture().toJson();
    (posted['draft'] as Map)['stage'] = 'posted';
    expect(() => WorkspacePurchaseEntryBook.fromJson(posted), throwsFormatException);
    final oversized = entryFixture().toJson();
    (oversized['draft'] as Map)['goods'] = List.filled(201, entryFixture().draft!.goods.single);
    expect(() => WorkspacePurchaseEntryBook.fromJson(oversized), throwsFormatException);
  });
  test('P05 detailed draft legacy compatibility scope and secure restart', () async {
    final legacy = entryFixture();
    expect(WorkspacePurchaseEntryBook.fromJson(legacy.toJson()).toJson(), legacy.toJson());
    final raw = jsonDecode(jsonEncode(legacy.toJson())) as Map<String, dynamic>;
    final draft = raw['draft'] as Map<String, dynamic>;
    draft['details'] = {'invoiceTotal': '600.60', 'paymentStatus': 'On credit',
      'dueDate': '15/10/2026', 'cgst': '30.30', 'sgst': '30.30'};
    (draft['goods'] as List).single['hsn'] = '1006';
    draft['attachments'] = [WorkspacePurchaseInvoiceAttachment(
      owner: jsonEncode(['account-A', 'store-A', true, 'manual-draft-A']),
      digest: List.filled(64, 'a').join(), fileName: 'Invoice.png', contentType: 'image/png',
      byteLength: 12, source: 'camera', detectedText: 'Invoice no: EVAL-P-001').toJson()];
    final detailed = WorkspacePurchaseEntryBook.fromJson(raw);
    final storage = _OrderJournalStorage();
    await SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage)
      .save(detailed, expectedRevision: null);
    final restored = await SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage)
      .read('account-A', 'store-A', qa: true);
    expect(restored!.toJson(), detailed.toJson());
    expect(restored.draft!.id, legacy.draft!.id);
    expect(restored.draft!.goods.single['productId'], 'saved-product-A');
    for (final changed in ['account', 'store', 'qa']) {
      final wrong = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
      wrong[changed] = changed == 'qa' ? false : 'other';
      expect(() => WorkspacePurchaseEntryBook.fromJson(wrong), throwsFormatException);
    }
    for (final changed in ['unknown', 'duplicates', 'oversized-text']) {
      final wrong = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
      final d = wrong['draft'] as Map<String, dynamic>;
      if (changed == 'unknown') (d['details'] as Map)['postedPayment'] = 'true';
      if (changed == 'duplicates') (d['attachments'] as List).add((d['attachments'] as List).single);
      if (changed == 'oversized-text') (d['attachments'] as List).single['detectedText'] = List.filled(60001, 'a').join();
      expect(() => WorkspacePurchaseEntryBook.fromJson(wrong), throwsFormatException);
    }
  });
  test('P05-GST domestic particulars retain legacy fields and secure restart', () async {
    final raw = jsonDecode(jsonEncode(entryFixture().toJson())) as Map<String, dynamic>;
    final draft = raw['draft'] as Map<String, dynamic>;
    draft['details'] = {'placeOfSupplyCode':'27', 'buyerUin':'UIN-AS-PRINTED',
      'buyerState':'Maharashtra', 'buyerStateCode':'27', 'deliveryAddress':'Evaluation delivery address',
      'deliveryState':'Maharashtra', 'deliveryStateCode':'27', 'supplyValue':'546',
      'sgst':'24.57', 'sgstAmount':'', 'utgst':'', 'eInvoiceStatus':'IRN / QR shown',
      'irn':List.filled(64, 'a').join(), 'ackNumber':'123456789012345',
      'ackDate':'30/09/2026', 'qrStatus':'Shown on invoice',
      'signatureStatus':'Electronic document', 'eInvoiceDeclaration':'As printed'};
    (draft['goods'] as List).single.addAll({'unitCode':'KGS', 'taxableValue':'546',
      'cgstRate':'4.5', 'cgst':'24.57', 'sgstRate':'4.5', 'sgst':'24.57',
      'utgstRate':'', 'utgst':'', 'igstRate':'', 'igst':'', 'cessRate':''});
    final book = WorkspacePurchaseEntryBook.fromJson(raw);
    final storage = _OrderJournalStorage();
    await SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage)
      .save(book, expectedRevision: null);
    final restored = await SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage)
      .read('account-A', 'store-A', qa: true);
    expect(restored!.toJson(), book.toJson());
    expect(restored.draft!.details['sgst'], '24.57', reason: 'Legacy combined tax is not silently migrated.');
    expect(restored.draft!.details['sgstAmount'], isEmpty);
    expect(restored.draft!.goods.single['productId'], 'saved-product-A');
    for (final unknown in ['unknownDetail', 'unknownGoods']) {
      final bad = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
      if (unknown == 'unknownDetail') {
        (bad['draft']['details'] as Map)['issuedByApp'] = 'true';
      } else {
        (bad['draft']['goods'] as List).single['taxVerified'] = 'true';
      }
      expect(() => WorkspacePurchaseEntryBook.fromJson(bad), throwsFormatException);
    }
  });

  test('P05-R02-R08 differential fields retain private identities through secure restart', () async {
    final raw = jsonDecode(jsonEncode(entryFixture().toJson())) as Map<String, dynamic>;
    final draft = raw['draft'] as Map<String, dynamic>;
    const additions = {'supplierEmail':'supplier@example.test', 'buyerPhone':'9999999999',
      'buyerEmail':'buyer@example.test', 'poReference':'EXISTING-PO-01', 'documentCopy':'Original for recipient',
      'totalTax':'18.25', 'amountPayable':'2840.00', 'amountInWords':'As printed, not regenerated',
      'bankName':'Evaluation bank', 'bankAccount':'001234500', 'bankIfsc':'ASPRINTED01',
      'bankBranch':'Evaluation branch', 'upiType':'As printed', 'upiId':'evaluation@upi',
      'paymentQrStatus':'Shown on invoice', 'terms':'Only terms printed on this bill',
      'signatory':'Printed name, not authenticated', 'expectedDeliveryDate':'03/10/2026',
      'shippingTerms':'Delivered at Store', 'paymentTerms':'Pay within fifteen days'};
    draft['details'] = additions;
    (draft['goods'] as List).single.addAll({'specifications':'Model A, 1 kg pack', 'taxAmount':'18.25'});
    final book = WorkspacePurchaseEntryBook.fromJson(raw);
    final storage = _OrderJournalStorage();
    await SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage)
      .save(book, expectedRevision: null);
    final restored = await SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage)
      .read('account-A', 'store-A', qa: true);
    expect(restored!.toJson(), book.toJson());
    expect(restored.draft!.id, 'manual-draft-A');
    expect(restored.draft!.supplierId, 'private-supplier-A');
    expect(restored.draft!.goods.single['productId'], 'saved-product-A');
    expect(restored.draft!.details.containsKey('paymentStatus'), isFalse);
    expect(restored.draft!.details.containsKey('signatureStatus'), isFalse);
    expect(await SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage)
      .read('account-A', 'store-A', qa: false), isNull);
    final bad = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
    bad['draft']['details']['postedPayable'] = '2840';
    expect(() => WorkspacePurchaseEntryBook.fromJson(bad), throwsFormatException);
  });
  test('P05-R10 printed reference differential retains observations not receipts', () {
    final raw = entryFixture().toJson();
    (raw['draft'] as Map)['details'] = {'documentTitle': 'Consulting Invoice',
      'printedTotalItems': '3', 'printedTotalQuantity': '3 pcs', 'printedTaxRate': '0.25%',
      'printedPaymentMark': 'Amount Paid', 'printedFooter': 'Thank you'};
    final draft = WorkspacePurchaseEntryBook.fromJson(raw).draft!;
    expect(draft.details['documentTitle'], 'Consulting Invoice');
    expect(draft.details.containsKey('paidAmount'), false);
    expect(draft.details.containsKey('paymentStatus'), false);
  });
  test('P05-R15 additional fields and printed tax rows survive secure restart', () async {
    final raw = jsonDecode(jsonEncode(entryFixture().toJson())) as Map<String, dynamic>;
    final draft = raw['draft'] as Map<String, dynamic>;
    draft['printedTaxRows'] = [{'label':'TOTAL', 'taxableValue':'8,07,117.80',
      'igstRate':'18%', 'igst':'1,45,281.20', 'totalTax':'1,45,281.20'}];
    draft['additionalFields'] = [
      const WorkspacePurchaseAdditionalField(id:'field-A', label:'Warranty period',
        value:'  2 years\nSupplier terms apply  ', section:'invoice', reviewed:true).toJson(),
      const WorkspacePurchaseAdditionalField(id:'field-B', label:'Serial / IMEI',
        value:'001234500', section:'items', itemIndex:0).toJson(),
      const WorkspacePurchaseAdditionalField(id:'field-C', label:'Special levy',
        value:'₹ 125.00 as printed', section:'tax', summaryIndex:0).toJson()];
    final book = WorkspacePurchaseEntryBook.fromJson(raw);
    final storage = _OrderJournalStorage();
    await SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage)
      .save(book, expectedRevision: null);
    final restored = await SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage)
      .read('account-A', 'store-A', qa:true);
    expect(restored!.toJson(), book.toJson());
    expect(restored.draft!.additionalFields.first.value, '  2 years\nSupplier terms apply  ');
    expect(restored.draft!.printedTaxRows.single['igstRate'], '18%');
    expect(restored.draft!.additionalFields[1].itemIndex, 0);
    expect(restored.draft!.additionalFields[2].summaryIndex, 0);
    expect(restored.draft!.id, entryFixture().draft!.id);
    expect(restored.draft!.details.containsKey('paidAmount'), isFalse);
    expect(() => restored.draft!.printedTaxRows.single['igst'] = '0', throwsUnsupportedError);
  });
  for (final invalid in ['duplicate', 'item', 'summary', 'scope', 'version', 'value', 'label', 'rule']) {
    test('P05-R15 rejects unsafe additional field $invalid without dropping saved data', () {
      final raw = jsonDecode(jsonEncode(entryFixture().draft!.toJson())) as Map<String, dynamic>;
      final extra = const WorkspacePurchaseAdditionalField(id:'field-A', label:'Raw field',
        value:'Original', section:'invoice').toJson();
      raw['additionalFields'] = [extra];
      switch (invalid) {
        case 'duplicate': (raw['additionalFields'] as List).add(extra);
        case 'item': extra['section']='items'; extra['itemIndex']=1;
        case 'summary': extra['section']='tax'; extra['summaryIndex']=0;
        case 'scope': extra['sourceDigest']='a'*64;
        case 'version': extra['version']=2;
        case 'value': extra['value']='a'*4001;
        case 'label': extra['label']='';
        case 'rule': extra['postPayment']=true;
      }
      expect(() => WorkspacePurchaseEntryDraft.fromJson(raw), throwsFormatException);
      expect(WorkspacePurchaseEntryDraft.fromJson(entryFixture().draft!.toJson()).toJson(),
        entryFixture().draft!.toJson());
    });
  }
  test('P05-R15-C01 scanned row identity is distinct from matched item identity', () {
    final field=WorkspacePurchaseAdditionalField(id:'scanned-extra',label:'Supplier code',
      value:'00123',section:'items',sourceDigest:'a'*64,sourceItemIndex:2);
    final restored=WorkspacePurchaseAdditionalField.fromJson(field.toJson());
    expect(restored.sourceItemIndex,2);
    expect(restored.itemIndex,isNull,reason:'Detected item position does not identify an entered item.');
    for (final invalid in ['noSource','negative','large','wrongSection']) {
      final raw=field.toJson();
      switch(invalid) {
        case 'noSource': raw.remove('sourceDigest');
        case 'negative': raw['sourceItemIndex']=-1;
        case 'large': raw['sourceItemIndex']=200;
        case 'wrongSection': raw['section']='invoice';
      }
      expect(()=>WorkspacePurchaseAdditionalField.fromJson(raw),throwsFormatException);
    }
  });
  test('P05-R15 candidate extras preserve unknown item columns and invalid known values', () {
    final parsed = WorkPurchaseInvoiceSuggestions.parse('Warranty: Two years\n'
      'Invoice date: 17 Jun 2023\nInvoice total: ₹ 9,52,399.00\n'
      'Item | Qty | Rate | Serial / IMEI | Tax amount\nPhone | 1 | 40 | 00123 | 7.20 (18%)');
    expect(parsed.fields['invoiceDate'], '17/06/2023');
    expect(parsed.fields['originalInvoiceDate'], '17 Jun 2023');
    expect(parsed.fields['invoiceTotal'], '952399.00');
    expect(parsed.additionalFields.map((f) => (f.label, f.value, f.itemIndex)), containsAll([
      ('Warranty', 'Two years', null), ('Serial / IMEI', '00123', 0),
      ('Tax amount', '7.20 (18%)', 0)]));
    expect(parsed.additionalFields.every((f) => !f.reviewed), true);
    expect(parsed.goods.single['productId'], isEmpty);
    expect(parsed.goods.single.containsKey('taxAmount'), false);
    expect(WorkPurchaseInvoiceSuggestions.parse('Extra: ${'a'*4001}').additionalOverflow, true);
  });
  test('P05-R05-C01 longer supplier terms and specifications retain bounded originals', () {
    final terms = 'Evaluation supplier terms. ' * 120;
    final specs = 'Evaluation model. ' * 40;
    final raw = jsonDecode(jsonEncode(entryFixture().draft!.toJson())) as Map<String, dynamic>;
    raw['details'] = {'terms':terms};
    (raw['goods'] as List).single['specifications'] = specs;
    final restored = WorkspacePurchaseEntryDraft.fromJson(raw);
    expect(restored.details['terms'], terms);
    expect(restored.goods.single['specifications'], specs);
    final parsed = WorkPurchaseInvoiceSuggestions.parse('Supplier terms: $terms\n'
      'Item | Qty | Rate | Specifications\nEvaluation item | 2 | 40 | $specs');
    expect(parsed.fields['terms'], terms.trim());
    expect(parsed.goods.single['specifications'], specs.trim());
    raw['details']['terms'] = 'a' * 4001;
    expect(() => WorkspacePurchaseEntryDraft.fromJson(raw), throwsFormatException);
    raw['details']['terms'] = terms;
    (raw['goods'] as List).single['specifications'] = 'a' * 1001;
    expect(() => WorkspacePurchaseEntryDraft.fromJson(raw), throwsFormatException);
  });
  test('P05-R04-R08 printed paise and incomplete tax never invent zeroes', () {
    expect(WorkspacePurchaseEntryDraft.printedPaise('807117.80'), 80711780);
    expect(WorkspacePurchaseEntryDraft.printedPaise('-0.50'), -50);
    for (final value in ['', 'NaN', 'Infinity', '1.234', '1e4', '1,23']) {
      expect(WorkspacePurchaseEntryDraft.printedPaise(value), isNull);
    }
    expect(WorkspacePurchaseEntryDraft.reviewAmounts({'taxTreatment':'IGST', 'totalTax':'18.25', 'igst':'18.25'}), isEmpty);
    expect(WorkspacePurchaseEntryDraft.reviewAmounts({'taxTreatment':'IGST', 'totalTax':'18.25', 'igst':'18.25', 'cess':'0'}), isEmpty);
    expect(WorkspacePurchaseEntryDraft.reviewAmounts({'taxTreatment':'IGST', 'totalTax':'18.25', 'igst':'18.24', 'cess':'0'}), hasLength(1));
    expect(WorkspacePurchaseEntryDraft.reviewAmounts({'roundOff':'-0.50'}), isEmpty);
    expect(WorkspacePurchaseEntryDraft.reviewAmounts({'paidAmount':'not known'}), hasLength(1));
  });
  test('P05-R04 HSN summary needs all explicit line facts and keeps rates separate', () {
    final rows = [
      {'hsn':'1006', 'gstRate':'5', 'taxableValue':'1.01', 'taxAmount':'0.05', 'quantity':'2', 'pack':'kg'},
      {'hsn':'1006', 'gstRate':'5', 'taxableValue':'2.02', 'taxAmount':'0.10', 'quantity':'3', 'pack':'bags'},
      {'hsn':'1006', 'gstRate':'12', 'taxableValue':'3', 'taxAmount':'0.36'},
    ];
    final summary = WorkspacePurchaseEntryDraft.printedHsnSummary(rows);
    expect(summary, hasLength(2));
    expect(summary.first.taxable, 303);
    expect(summary.first.tax, 15);
    expect(summary.last.rate, '12');
    expect(WorkspacePurchaseEntryDraft.printedHsnSummary([...rows, {'hsn':'1006', 'taxableValue':'5'}]), isEmpty);
  });
  test('P05-R07 explicit differential OCR suggestions do not invent payment identity', () {
    final result = WorkPurchaseInvoiceSuggestions.parse('Supplier email: supplier@example.test\n'
      'Buyer phone: 9999999999\nBuyer email: buyer@example.test\nPO number: EXISTING-1\n'
      'Copy label: Original for recipient\nTotal tax: 18.25\nAmount payable: 2840\n'
      'Amount in words: As printed\nBank name: Evaluation bank\nBank account: 0012345\n'
      'IFSC: ASPRINTED\nUPI ID: evaluation@upi\nSupplier terms: As printed\n'
      'Expected delivery date: 03/10/2026\nPayment terms: Fifteen days\nPaid: Yes\n'
      'Item | Qty | Rate/Item | Units | HSN/SAC | Model | Tax amount | Amount\n'
      'Evaluation item | 2 | 40 | pcs | 1006 | Model A | 4 | 84');
    expect(result.fields['supplierEmail'], 'supplier@example.test');
    expect(result.fields['bankAccount'], '0012345');
    expect(result.fields['poReference'], 'EXISTING-1');
    expect(result.fields.containsKey('paymentStatus'), isFalse);
    expect(result.goods.single['productId'], isEmpty);
    expect(result.goods.single['specifications'], 'Model A');
    expect(result.goods.single['taxAmount'], '4');
    expect(WorkPurchaseInvoiceSuggestions.parse('Buyer phone: A\nBuyer phone: B\n'
      'Total tax: NaN\nExpected delivery date: 31/02/2026').fields, isEmpty);
    expect(WorkPurchaseInvoiceSuggestions.parse('').fields, isEmpty);
    expect(WorkPurchaseInvoiceSuggestions.parse('unclear words').goods, isEmpty);
  });
  test('P05-GST invoice format review keeps nonconforming supplier originals', () {
    final raw = entryFixture(reference: 'EXTERNAL-NUMBER-TOO-LONG').draft!.toJson();
    raw['invoiceDate'] = '31/02/2026';
    raw['details'] = {'documentType':'GST invoice'};
    final draft = WorkspacePurchaseEntryDraft.fromJson(raw);
    expect(draft.valid, isTrue, reason: 'A partial external document can still be saved as a draft.');
    expect(draft.invoiceFormatWarnings, hasLength(2));
    expect(draft.toJson()['invoiceReference'], 'EXTERNAL-NUMBER-TOO-LONG');
    expect(draft.toJson()['invoiceDate'], '31/02/2026');
    expect(WorkspacePurchaseEntryDraft.reviewInvoiceFormat('AB-123/2026', '29/02/2024', 'GST invoice'), isEmpty);
    expect(WorkspacePurchaseEntryDraft.reviewInvoiceFormat('A B', '29/02/2026', 'GST invoice'), hasLength(2));
    expect(WorkspacePurchaseEntryDraft.reviewInvoiceFormat('A'*16, '30/09/2026', 'GST invoice'), isEmpty);
    expect(WorkspacePurchaseEntryDraft.reviewInvoiceFormat('A'*17, '30/09/2026', 'GST invoice'), hasLength(1));
    expect(WorkspacePurchaseEntryDraft.reviewInvoiceFormat('', '', 'Other bill'), isEmpty);
  });

  test('P05-GST OCR maps explicit identities and tax columns without verification', () {
    final irn = List.filled(64, 'a').join();
    final result = WorkPurchaseInvoiceSuggestions.parse('Supplier address: Source address\n'
      'Buyer name: Buyer only\nBuyer UIN: AS-PRINTED\nBuyer State: Maharashtra\n'
      'Buyer State code: 27\nDelivery address: Another address\n'
      'Place of supply code: 27\nSGST: 24.57\nUTGST: 0\nIRN: $irn\n'
      'Acknowledgement date: 30/09/2026\n'
      'Item | Qty | Rate | UQC | Taxable value | CGST % | CGST | SGST % | SGST | Amount\n'
      'Rice | 12 | 45.50 | KGS | 546 | 4.5 | 24.57 | 4.5 | 24.57 | 595.14');
    expect(result.fields['supplierAddress'], 'Source address');
    expect(result.fields['buyerName'], 'Buyer only');
    expect(result.fields['buyerUin'], 'AS-PRINTED');
    expect(result.fields.containsKey('buyerGstin'), isFalse);
    expect(result.fields['sgstAmount'], '24.57');
    expect(result.fields.containsKey('sgst'), isFalse, reason: 'Explicit SGST is not legacy combined tax.');
    expect(result.fields['irn'], irn);
    expect(result.fields.containsKey('qrStatus'), isFalse);
    expect(result.fields.containsKey('eInvoiceStatus'), isFalse);
    expect(result.goods.single['productId'], isEmpty);
    expect(result.goods.single['unitCode'], 'KGS');
    expect(result.goods.single['taxableValue'], '546');
    expect(result.goods.single['sgstRate'], '4.5');
    expect(result.goods.single['sgst'], '24.57');
    expect(WorkPurchaseInvoiceSuggestions.parse('IRN: invalid\nAck date: 31/02/2026').fields, isEmpty);
    expect(WorkPurchaseInvoiceSuggestions.parse('Buyer name: A\nBuyer name: B').fields, isEmpty);
    expect(WorkPurchaseInvoiceSuggestions.parse('SGST: NaN\nCGST: -2\nUTGST: Infinity').fields, isEmpty);
    final address = 'Evaluation address '*15;
    expect(WorkPurchaseInvoiceSuggestions.parse('Delivery address: $address').fields['deliveryAddress'], address.trim());
    final uncertain = WorkPurchaseInvoiceSuggestions.parse(
      'Item | Qty | Rate | SGST % | SGST | Amount\nRice | 2 | 40 | unknown | NaN | 80');
    expect(uncertain.goods.single.containsKey('sgstRate'), isFalse);
    expect(uncertain.goods.single.containsKey('sgst'), isFalse);
    expect(uncertain.goods.single['lineTotal'], '80');
  });

  test('P05-R07-C02 host-only invoice labels Indian amounts and printed dates', () {
    final parsed = WorkPurchaseInvoiceSuggestions.parse('TAX INVOICE\n'
      'Billed by: Evaluation supplier\nMobile: 9999999999\nEmail: supplier@example.test\n'
      'GSTIN: 27AAAAA0000A1Z5\nInvoice #: EVAL-123\nInvoice Date: 17 Jun 2023\n'
      'Due Date: 17 July 2023\nCustomer Details: Evaluation buyer\nPh: 8888888888\n'
      'Billing address: Printed billing address\nShipping address: Printed shipping address\n'
      'Taxable Amount: ₹8,07,117.80\nIGST @ 18.0%: INR 1,45,281.20\n'
      'Total: ₹9,52,399.00\nRound Off: -0.50\nBank: Evaluation bank\n'
      'Account #: 0012345\nUPI Number: evaluation@upi\nAmount Paid: Yes');
    expect(parsed.fields['supplierName'], 'Evaluation supplier');
    expect(parsed.fields['supplierPhone'], '9999999999');
    expect(parsed.fields['supplierEmail'], 'supplier@example.test');
    expect(parsed.fields['supplierGstin'], '27AAAAA0000A1Z5');
    expect(parsed.fields['invoiceReference'], 'EVAL-123');
    expect(parsed.fields['invoiceDate'], '17/06/2023');
    expect(parsed.fields['originalInvoiceDate'], '17 Jun 2023');
    expect(parsed.fields['dueDate'], '17/07/2023');
    expect(parsed.fields['buyerName'], 'Evaluation buyer');
    expect(parsed.fields['buyerPhone'], '8888888888');
    expect(parsed.fields['buyerAddress'], 'Printed billing address');
    expect(parsed.fields['deliveryAddress'], 'Printed shipping address');
    expect(parsed.fields['taxableValue'], '807117.80');
    expect(parsed.fields['igst'], '145281.20');
    expect(parsed.fields['printedIgstRate'], '18.0');
    expect(parsed.fields['invoiceTotal'], '952399.00');
    expect(parsed.fields['roundOff'], '-0.50');
    expect(parsed.fields['bankAccount'], '0012345');
    expect(parsed.fields['upiId'], 'evaluation@upi');
    expect(parsed.fields['printedPaymentMark'], 'Yes');
    for (final key in ['paidAmount','paymentStatus','paymentMethod','receiptStatus']) {
      expect(parsed.fields.containsKey(key), false, reason: 'Printed bill is not a POS confirmation.');
    }
  });
  test('P05-R07-C02 host-only row amounts rate percentages and exact identity', () {
    final parsed = WorkPurchaseInvoiceSuggestions.parse('Billed To: Evaluation buyer\n'
      'CGST @ 0.125 %: Rs. 81.25\nSGST @ 0.125%: 81.25\nGST @ 0.25%: 162.50\n'
      'Invoice date: 2026-05-13\n'
      'S No. | Item / description | Qty | Rate / Item ₹ | Units | HSN / SAC | GST % | Taxable Value ₹ | Amount ₹\n'
      '001 | Evaluation item | 2.5 | ₹1,250.00 | kg | 001143 | 0.25% | Rs. 3,125.00 | INR 3,132.81');
    expect(parsed.fields['printedCgstRate'], '0.125');
    expect(parsed.fields['printedSgstRate'], '0.125');
    expect(parsed.fields['printedTaxRate'], '0.25');
    expect(parsed.fields['totalTax'], '162.50');
    expect(parsed.fields['invoiceDate'], '13/05/2026');
    expect(parsed.goods.single, containsPair('printedSerial', '001'));
    expect(parsed.goods.single, containsPair('hsn', '001143'));
    expect(parsed.goods.single, containsPair('cost', '1250.00'));
    expect(parsed.goods.single, containsPair('quantity', '2.5'));
    expect(parsed.goods.single, containsPair('gstRate', '0.25'));
    expect(parsed.goods.single, containsPair('lineTotal', '3132.81'));
    expect(parsed.goods.single['productId'], isEmpty);
  });
  test('P05-R07-C02 host-only malformed numbers and unlabelled geometry stay uncertain', () {
    for (final value in ['1,2,3.00','₹NaN','INR 1e4','1.234','-12','100 + 18%','12%','Infinity']) {
      final parsed = WorkPurchaseInvoiceSuggestions.parse('Invoice total: $value');
      expect(parsed.fields.containsKey('invoiceTotal'), false, reason: value);
      expect(parsed.additionalFields.map((field) => field.value), contains(value));
    }
    for (final value in ['31 Feb 2026','2026-02-29','17 Unknown 2026']) {
      final parsed = WorkPurchaseInvoiceSuggestions.parse('Invoice date: $value');
      expect(parsed.fields.containsKey('invoiceDate'), false, reason: value);
      expect(parsed.additionalFields.map((field) => field.value), contains(value));
    }
    expect(WorkPurchaseInvoiceSuggestions.parse('Invoice date: 29 February 2024').fields['invoiceDate'], '29/02/2024');
    final parsed = WorkPurchaseInvoiceSuggestions.parse('Warranty: Two years\n'
      'Invoice total: 100\nTotal: 200\nItem Qty Rate\nRice 2 40');
    expect(parsed.fields.containsKey('invoiceTotal'), false);
    expect(parsed.goods, isEmpty, reason: 'No invented column assignments from flattened words.');
    expect(parsed.additionalFields.map((field) => (field.label, field.value)), containsAll([
      ('Warranty','Two years'),('Invoice total','100'),('Total','200')]));
  });
  test('P05-R07-C03 host-only fractional commas never change amounts', () {
    for (final value in ['1,234.5,6', '1,234.56,', '1,234.,56']) {
      final parsed=WorkPurchaseInvoiceSuggestions.parse('Total: $value');
      expect(parsed.fields.containsKey('invoiceTotal'),false,reason:value);
      expect(parsed.additionalFields.single.value,value);
      final goods=WorkPurchaseInvoiceSuggestions.parse('Item | Qty | Rate\nRice | $value | 40');
      expect(goods.goods,isEmpty,reason:'Malformed quantity is not a candidate item.');
    }
    expect(WorkPurchaseInvoiceSuggestions.parse('Total: 1,234.56').fields['invoiceTotal'],'1234.56');
    expect(WorkPurchaseInvoiceSuggestions.parse('Total: 1,23,456.78').fields['invoiceTotal'],'123456.78');
  });
  test('P05-R07-C04 host-only party context ends at unrelated or invalid details', () {
    for(final text in ['Supplier: Acme\nBank details\nAddress: 10 Bank Road\nEmail: bank@example.test',
        'Billed to: Buyer\nShipping address: Delivery road\nPhone: 9999999999',
        'Supplier GSTIN: invalid\nMobile: 8888888888']) {
      final parsed=WorkPurchaseInvoiceSuggestions.parse(text);
      for(final key in ['supplierAddress','supplierEmail','buyerPhone','supplierPhone']) {
        expect(parsed.fields.containsKey(key),false,reason:text);
      }
      expect(parsed.additionalFields,isNotEmpty,reason:'Ambiguous contacts remain source extras.');
    }
    final accepted=WorkPurchaseInvoiceSuggestions.parse('Supplier details\nAddress: Warehouse road\n\nPhone: 8888888888\n'
      'Customer details\nPhone: 9999999999');
    expect(accepted.fields['supplierAddress'],'Warehouse road');
    expect(accepted.fields['supplierPhone'],'8888888888');
    expect(accepted.fields['buyerPhone'],'9999999999');
  });

  test('P05 OCR labelled suggestions reject ambiguity invalid dates and unsafe rows', () {
    final parsed = WorkPurchaseInvoiceSuggestions.parse('Supplier: A\nSold by: B\n'
      'GSTIN: 27AAAAA0000A1Z5\nSupplier GSTIN: 27AAAAA0000A1Z5\n'
      'Invoice no: EVAL-123\nInvoice date: 31/02/2026\n'
      'Item | Qty | Rate | Unit | HSN\nRice | 2.5 | 40 | kg | 1006\n'
      'Unsafe | NaN | 40 | kg | 1006\nUnsafe | 1 | -40 | kg | 1006\n'
      'Unsafe | -1 | 40 | kg | 1006\nUnsafe | 1 | Infinity | kg | 1006\n'
      'Item | Qty | Quantity | Rate\nUnsafe | 1 | 5 | 40');
    expect(parsed.fields.containsKey('supplierName'), isFalse);
    expect(parsed.fields.containsKey('buyerGstin'), isFalse);
    expect(parsed.fields.containsKey('invoiceDate'), isFalse);
    expect(parsed.fields['supplierGstin'], '27AAAAA0000A1Z5');
    expect(parsed.fields['invoiceReference'], 'EVAL-123');
    expect(parsed.goods, hasLength(1));
    expect(parsed.goods.single['productId'], isEmpty);
    expect(parsed.goods.single['quantity'], '2.5');
    expect(WorkPurchaseInvoiceSuggestions.parse('Invoice date: 29/02/2024').fields['invoiceDate'], '29/02/2024');
  });
  test('P05 private image original roundtrip cancellation scope and native fallback', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final directory = await Directory.systemTemp.createTemp('mool-purchase-fixture-');
    addTearDown(() => directory.delete(recursive: true));
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawPaint(ui.Paint()..color = const ui.Color(0xffffffff));
    final picture = recorder.endRecording();
    final image = await picture.toImage(2, 2);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    image.dispose(); picture.dispose();
    final picker = _PurchaseInvoicePickerFixture(WorkPickedProof(fileName: '../invoice.png',
      contentType: 'wrong/extension', bytes: bytes));
    (String, String, bool) scope = ('account-A', 'store-A', true);
    final capture = WorkPurchaseInvoiceCapture(currentScope: () => scope, picker: picker,
      supportDirectory: () async => directory,
      recognize: (_) async => throw MissingPluginException('old APK fixture'));
    final a = (await capture.capture(scope, 'draft-A', WorkProofSource.camera))!;
    expect(a.contentType, 'image/png');
    expect(a.fileName.contains('/'), isFalse);
    expect(await capture.read(scope, 'draft-A', a), orderedEquals(bytes));
    final reopened = WorkPurchaseInvoiceCapture(currentScope: () => scope,
      supportDirectory: () async => directory);
    expect(await reopened.read(scope, 'draft-A', a), orderedEquals(bytes));
    expect((await directory.list(recursive: true).toList()).whereType<File>()
      .any((f) => f.path.endsWith('.pending')), isFalse);
    await expectLater(capture.read(scope, 'other-draft', a), throwsA(isA<WorkGatewayException>()));
    await expectLater(capture.read(('account-A', 'store-A', false), 'draft-A', a), throwsA(isA<WorkGatewayException>()));
    await expectLater(capture.scan(scope, 'draft-A', a), throwsA(isA<WorkGatewayException>()
      .having((e) => e.message, 'manual fallback', contains('next app update'))));
    picker.value = null;
    expect(await capture.capture(scope, 'draft-A', WorkProofSource.camera), isNull);
    picker.value = WorkPickedProof(fileName: 'invoice.png', contentType: 'image/png', bytes: bytes);
    picker.afterPick = () => scope = ('account-A', 'other-store', true);
    await expectLater(capture.capture(('account-A', 'store-A', true), 'draft-A', WorkProofSource.camera),
      throwsA(isA<WorkGatewayException>()));
    scope = ('account-A', 'store-A', true);
    final file = (await directory.list(recursive: true).toList()).whereType<File>().single;
    await file.writeAsBytes(List.filled(bytes.length, 0));
    await expectLater(capture.read(scope, 'draft-A', a), throwsA(isA<WorkGatewayException>()));
  });
  test('P05 PDF manual fallback unsupported media and size limits', () async {
    final directory = await Directory.systemTemp.createTemp('mool-purchase-pdf-fixture-');
    addTearDown(() => directory.delete(recursive: true));
    const scope = ('account-A', 'store-A', true);
    final picker = _PurchaseInvoicePickerFixture(WorkPickedProof(fileName: 'invoice.pdf',
      contentType: 'application/pdf', bytes: Uint8List.fromList(utf8.encode('%PDF-fixture-only'))));
    final capture = WorkPurchaseInvoiceCapture(currentScope: () => scope, picker: picker,
      supportDirectory: () async => directory);
    final a = (await capture.capture(scope, 'draft-A', WorkProofSource.upload))!;
    await expectLater(capture.scan(scope, 'draft-A', a), throwsA(isA<WorkGatewayException>()
      .having((e) => e.message, 'PDF fallback', contains('manually'))));
    for (final bytes in [Uint8List(0), Uint8List(10 * 1024 * 1024 + 1), Uint8List.fromList([1,2,3])]) {
      picker.value = WorkPickedProof(fileName: 'bad.jpg', contentType: 'image/jpeg', bytes: bytes);
      await expectLater(capture.capture(scope, 'draft-A', WorkProofSource.upload), throwsA(isA<WorkGatewayException>()));
    }
  });
  WorkspaceCustomerLedger creditLedger() => WorkspaceCustomerLedger(
    accountScope: 'account-A', workspaceId: 'credit-store', customerId: '9000091941',
    customerName: 'Credit QA · 9000091941', revision: 1, asOf: DateTime.utc(2026, 9, 20),
    openingBalanceMinor: 0, historyComplete: true, entries: [
      for (var i = 0; i < 4; i++) WorkspaceCustomerLedgerEntry(id: 'entry-$i',
        operationId: 'entry-$i', invoiceId: i < 3 ? 'source' : 'target',
        orderId: i < 3 ? 'source-order' : 'target-order', sequence: i + 1,
        occurredAt: DateTime.utc(2026, 9, 19, i),
        kind: [WorkspaceLedgerEntryKind.invoice, WorkspaceLedgerEntryKind.collection,
          WorkspaceLedgerEntryKind.creditNote, WorkspaceLedgerEntryKind.invoice][i],
        state: WorkspaceLedgerPostingState.posted, amountMinor: i < 3 ? 50000 : 80000,
        channel: WorkspacePaymentChannel.cash),
    ]);
  WorkspaceFinanceSnapshot creditFinance() => WorkspaceFinanceSnapshot(
    accountScope: 'account-A', workspaceId: 'credit-store', revision: 1,
    asOf: DateTime.utc(2026, 9, 20), salesTodayMinor: 0, duesMinor: 80000,
    availableMinor: 0, heldMinor: 0, requestedMinor: 0, paidOutMinor: 0,
    feesMinor: 0, deliveryAdjustmentsMinor: 0, refundsMinor: 0, taxWithheldMinor: 0,
    customerLedgers: [creditLedger()], payouts: [], historyComplete: true,
    payments: [for (final source in [true, false]) WorkspacePaymentRecord(
      orderId: source ? 'source-order' : 'target-order', customerId: '9000091941',
      customerName: 'Credit QA · 9000091941', revision: 1, updatedAt: DateTime.utc(2026, 9, 20),
      amountMinor: source ? 50000 : 80000, paidMinor: source ? 50000 : 0,
      dueMinor: source ? 0 : 80000, refundedMinor: 0,
      state: source ? WorkspacePaymentState.returnAdjusted : WorkspacePaymentState.unpaid,
      channel: WorkspacePaymentChannel.cash, invoiceId: source ? 'source' : 'target')]);

  test('CREDITUSE partial full replay and changed request limits', () {
    final before = creditLedger();
    final after = before.allocateCredit(sourceInvoiceId: 'source', targetInvoiceId: 'target',
      amountMinor: 30000, expectedRevision: 1, operationId: 'use-1', at: DateTime.utc(2026, 9, 21));
    expect(after.valid, isTrue);
    expect(after.canFollow(before), isTrue);
    expect(after.closingBalanceMinor, before.closingBalanceMinor);
    expect(after.invoiceBalance('source')!.availableCreditMinor, 20000);
    expect(after.invoiceBalance('target')!.dueMinor, 50000);
    expect(after.invoiceBalance('target')!.collectedMinor, 0);
    expect(identical(after.allocateCredit(sourceInvoiceId: 'source', targetInvoiceId: 'target',
      amountMinor: 30000, expectedRevision: 1, operationId: 'use-1', at: DateTime.utc(2026, 9, 22)), after), isTrue);
    for (final args in [(20001, 2, 'new'), (20000, 1, 'stale'), (1, 2, 'use-1')]) {
      expect(() => after.allocateCredit(sourceInvoiceId: 'source', targetInvoiceId: 'target',
        amountMinor: args.$1, expectedRevision: args.$2, operationId: args.$3, at: DateTime.utc(2026, 9, 22)), throwsFormatException);
    }
    final full = after.allocateCredit(sourceInvoiceId: 'source', targetInvoiceId: 'target',
      amountMinor: 20000, expectedRevision: 2, operationId: 'use-2', at: DateTime.utc(2026, 9, 22));
    expect(full.invoiceBalance('source')!.availableCreditMinor, 0);
    expect(full.invoiceBalance('source')!.refundableMinor, 0);
  });

  test('CREDITUSE statement separates paired allocation from cash and return credit', () {
    final gateway = StoreReviewCustomerCollectionGateway(creditFinance());
    final after = gateway.previewCreditAllocation(customerId: '9000091941', sourceInvoiceId: 'source',
      targetInvoiceId: 'target', amountMinor: 30000, expectedRevision: 1,
      operationId: 'report-credit');
    final statement = StoreSalesStatement(accountId: 'account-A', storeId: 'credit-store',
      storeName: 'Evaluation credit Store', from: DateTime.utc(2026, 9),
      until: after.asOf.add(const Duration(days: 1)),
      generatedAt: after.asOf.add(const Duration(minutes: 1)), finance: after, reviewOnly: true,
      invoices: [for (final source in [true, false]) WorkspaceCustomerInvoice(
        id: source ? 'source' : 'target', orderId: source ? 'source-order' : 'target-order',
        customer: '9000091941', items: 'Evaluation goods', amount: source ? 500 : 800,
        payment: 'Cash', issuedAt: DateTime.utc(2026, 9, 19))]);
    expect(statement.recorded(WorkspaceLedgerEntryKind.collection), 50000);
    expect(statement.recorded(WorkspaceLedgerEntryKind.creditNote), 50000);
    expect(statement.recorded(WorkspaceLedgerEntryKind.refund), 0);
    expect(statement.recorded(WorkspaceLedgerEntryKind.creditReceived), 30000);
    // A later adjustment must not leak into an earlier invoice/report period.
    final beforeAllocation = StoreSalesStatement(accountId: statement.accountId,
      storeId: statement.storeId, storeName: statement.storeName, from: statement.from,
      until: after.asOf, generatedAt: statement.generatedAt, finance: after,
      reviewOnly: true, invoices: statement.invoices);
    expect(beforeAllocation.recorded(WorkspaceLedgerEntryKind.creditReceived), 0);
    final allocations = statement.report.rows.where((r) => r[12] is num).toList();
    expect(allocations, hasLength(2));
    expect(allocations.map((r) => r[1]), ['source', 'target']);
    expect(allocations.map((r) => r[12]), [300, 300]);
    expect(allocations.every((r) => r[9] == '' && r[10] == ''), isTrue);
    expect(statement.report.summary.any((r) => r[0] == 'Customer credit applied (non-cash)' && r[1] == 'INR 300.00'), isTrue);
  });
  test('CREDITUSE credit-funded returns cannot invent cash refunds', () {
    final used = creditLedger().allocateCredit(sourceInvoiceId: 'source', targetInvoiceId: 'target',
      amountMinor: 50000, expectedRevision: 1, operationId: 'use', at: DateTime.utc(2026, 9, 21));
    final returned = WorkspaceCustomerLedger(accountScope: used.accountScope, workspaceId: used.workspaceId,
      customerId: used.customerId, customerName: used.customerName, revision: 3,
      asOf: DateTime.utc(2026, 9, 22), openingBalanceMinor: 0, historyComplete: true,
      entries: [...used.entries, WorkspaceCustomerLedgerEntry(id: 'return-target', operationId: 'return-target',
        invoiceId: 'target', orderId: 'target-order', sequence: 7, occurredAt: DateTime.utc(2026, 9, 22),
        kind: WorkspaceLedgerEntryKind.creditNote, state: WorkspaceLedgerPostingState.posted, amountMinor: 80000)]);
    expect(returned.invoiceBalance('target')!.availableCreditMinor, 50000);
    expect(returned.invoiceBalance('target')!.refundableMinor, 0);
  });
  for (final failure in ['none', 'before-write', 'lost-response']) {
    test('CREDITUSE atomic save restart and stale retry $failure', () async {
      final storage = _OrderJournalStorage();
      final original = creditFinance();
      WorkSession open() {
        final work = WorkSession(gateway: ReviewWorkGateway(), contactDraftStore: _CommandAccountStore(),
          pendingProofStore: _CommandAccountStore())..activeWorkspace = const WorkWorkspace(id: 'credit-store',
            name: 'Credit evaluation', profileId: 'retailer-grocery', profileLabel: 'Grocery', area: 'QA', verified: true);
        expect(work.applyWorkspaceFinance(original), isTrue);
        expect(work.bindCustomerCollectionGateway(accountScope: 'account-A', storeId: 'credit-store',
          adapter: StoreReviewCustomerCollectionGateway(original), checkpointStore: SecureWorkLedgerCheckpointStore(
            accountScope: () => 'account-A', storage: storage)), isTrue);
        addTearDown(work.dispose);
        return work;
      }
      final work = open();
      expect(await work.recoverCustomerLedger(), isTrue);
      storage.failWrite = failure == 'before-write';
      storage.loseWriteResponseOnce = failure == 'lost-response';
      final result = await work.applyCustomerCredit(customerId: '9000091941', sourceInvoiceId: 'source',
        targetInvoiceId: 'target', amountMinor: 30000, expectedRevision: 1);
      expect(result, failure == 'none');
      storage.failWrite = false;
      final restarted = open();
      expect(await restarted.recoverCustomerLedger(), isTrue);
      final f = restarted.workspaceFinance!;
      final saved = failure != 'before-write';
      expect(f.payments.last.dueMinor, saved ? 50000 : 80000);
      expect(f.payments.last.paidMinor, 0);
      expect(f.refundsMinor, 0);
      expect(f.salesTodayMinor, original.salesTodayMinor);
      if (saved) {
        expect(await restarted.applyCustomerCredit(customerId: '9000091941', sourceInvoiceId: 'source',
          targetInvoiceId: 'target', amountMinor: 30000, expectedRevision: 1), isFalse);
        expect(f.customerLedgers.single.entries.where((e) => e.kind == WorkspaceLedgerEntryKind.creditUsed), hasLength(1));
      }
      expect(await restarted.applyCustomerCredit(customerId: 'different-customer', sourceInvoiceId: 'source',
        targetInvoiceId: 'target', amountMinor: 1, expectedRevision: 1), isFalse);
    });
  }
  test('REFUNDSOURCE mixed receipts keep original identity and remaining limits', () {
    final now = DateTime.utc(2026, 9, 27);
    WorkspaceCustomerRefund request({String source = 'receipt-cash', int amount = 2000,
      WorkspacePaymentChannel channel = WorkspacePaymentChannel.cash}) => WorkspaceCustomerRefund(
        accountScope: 'qa-account', workspaceId: 'qa-store', customerId: 'qa-customer',
        invoiceId: 'qa-invoice', orderId: 'qa-order', operationId: 'qa-refund',
        expectedRevision: 1, amountMinor: amount, channel: channel,
        reference: channel == WorkspacePaymentChannel.cash ? null : 'NEW-REFUND',
        sourceCollectionId: source);
    WorkspaceCustomerLedgerEntry entry(String id, int sequence, WorkspaceLedgerEntryKind kind,
      int amount, {WorkspacePaymentChannel channel = WorkspacePaymentChannel.cash,
      WorkspaceCustomerRefund? refund}) => WorkspaceCustomerLedgerEntry(
        id: id, operationId: refund?.operationId ?? id, invoiceId: 'qa-invoice', orderId: 'qa-order',
        sequence: sequence, occurredAt: now, kind: kind, state: WorkspaceLedgerPostingState.posted,
        amountMinor: amount, channel: channel, customerRefund: refund, paymentReference: refund?.reference);
    final base = [
      entry('invoice', 1, WorkspaceLedgerEntryKind.invoice, 10000),
      entry('receipt-cash', 2, WorkspaceLedgerEntryKind.collection, 4000),
      entry('receipt-bank', 3, WorkspaceLedgerEntryKind.collection, 6000, channel: WorkspacePaymentChannel.bankTransfer),
      entry('credit', 4, WorkspaceLedgerEntryKind.creditNote, 10000),
    ];
    WorkspaceCustomerLedger ledger(List<WorkspaceCustomerLedgerEntry> entries) => WorkspaceCustomerLedger(
      accountScope: 'qa-account', workspaceId: 'qa-store', customerId: 'qa-customer', customerName: 'QA',
      revision: 1, asOf: now, entries: entries, historyComplete: true, openingBalanceMinor: 0);
    final before = ledger(base);
    expect(before.valid, isTrue);
    expect(before.recordedReceiptChannels('qa-invoice', 'qa-order'), {
      WorkspacePaymentChannel.cash, WorkspacePaymentChannel.bankTransfer,
    });
    expect(before.recordedReceiptChannels('other-invoice', 'qa-order'), isEmpty);
    expect(before.recordedReceiptChannels('qa-invoice', 'other-order'), isEmpty);
    expect(ledger(base.take(2).toList()).recordedReceiptChannels('qa-invoice', 'qa-order'), {
      WorkspacePaymentChannel.cash,
    });
    expect(before.receiptRemainingMinor('qa-invoice', 'receipt-cash'), 4000);
    expect(before.receiptRemainingMinor('qa-invoice', 'receipt-bank'), 6000);
    expect(before.permitsReceiptRefund(request(amount: 4001)), isFalse);
    expect(before.permitsReceiptRefund(request(source: 'missing')), isFalse);
    expect(before.permitsReceiptRefund(request(channel: WorkspacePaymentChannel.bankTransfer)), isFalse);
    final bank = request(source: 'receipt-bank', channel: WorkspacePaymentChannel.bankTransfer);
    expect(bank.valid, isTrue);
    expect(before.permitsReceiptRefund(bank), isTrue);
    expect(WorkspaceCustomerRefund.fromJson(bank.toJson()).identityData, bank.identityData);
    final after = ledger([...base, entry('refund', 5, WorkspaceLedgerEntryKind.refund, 2000, refund: request())]);
    expect(after.receiptRemainingMinor('qa-invoice', 'receipt-cash'), 2000);
    expect(after.recordedReceiptChannels('qa-invoice', 'qa-order'),
        before.recordedReceiptChannels('qa-invoice', 'qa-order'));
    expect(after.receiptRemainingMinor('qa-invoice', 'receipt-bank'), 6000);
    expect(after.permitsReceiptRefund(request(amount: 2001)), isFalse);
    final legacy = ledger([...base, entry('legacy', 5, WorkspaceLedgerEntryKind.refund, 2000)]);
    expect(legacy.receiptRemainingMinor('qa-invoice', 'receipt-bank'), isNull);
    expect(before.receiptRemainingMinor('other-invoice', 'receipt-cash'), isNull);
  });
  test(
    'HOME latest invoice follows issue time not restored insertion order',
    () {
      final work = WorkSession()..seedVerifiedWorkspace();
      addTearDown(work.dispose);
      WorkspaceCustomerInvoice invoice(String id, DateTime issuedAt) =>
          WorkspaceCustomerInvoice(
            id: id,
            orderId: id,
            customer: 'Customer',
            items: 'Goods',
            amount: 250,
            payment: 'Cash',
            issuedAt: issuedAt,
          );
      final older = invoice('INV-OLDER', DateTime.utc(2026, 9, 24));
      final newer = invoice('INV-NEWER', DateTime.utc(2026, 9, 26));
      work.workspaceInvoices.addAll([older, newer]);
      expect(work.latestWorkspaceInvoice?.id, 'INV-NEWER');
      expect(work.workspaceInvoices.map((record) => record.id), [
        'INV-OLDER',
        'INV-NEWER',
      ]);
      work.workspaceInvoices.clear();
      expect(work.latestWorkspaceInvoice, isNull);
    },
  );

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
  // Host fixtures only. Each physical entry path still needs OPPO acceptance.
  group('P03 host-only opening-stock provenance', () {
    final base = workspaceMasterCatalogue.last.copyWith(
      stock: 6, purchasePrice: 25, sellingPrice: 30, publicListing: false);
    final at = DateTime.utc(2026, 10, 2);
    WorkspaceStockEntry entry() => WorkspaceStockEntry(
      method: WorkspaceStockEntryMethod.manual, productId: base.id,
      sku: base.sku, pack: base.pack, stockMode: base.stockMode, quantity: 6,
      purchasePriceRupees: 25, recordedAt: at, stockAsOf: at);
    WorkspaceSavedInventory checkpoint(List<WorkspaceCatalogueItem> products,
        {int revision = 1, bool qa = true}) => WorkspaceSavedInventory(
      account: 'account-A', store: _commandStore.id, qa: qa,
      revision: revision, savedAt: at, products: products, movements: const []);

    test('legacy unknown and strict new schema roundtrip', () {
      expect(WorkspaceCatalogueItem.fromInventoryJson(base.toInventoryJson()).stockEntry, isNull);
      final product = base.copyWith(stockEntry: entry());
      final saved = checkpoint([product]);
      expect(saved.toJson()['version'], 2);
      expect(WorkspaceSavedInventory.fromJson(jsonDecode(jsonEncode(saved.toJson())))
        .products.single.stockEntry!.contentIdentity, entry().contentIdentity);
      for (final patch in <Map<String, Object?>>[
        {'version': 1}, {'stockEntry': null}, {'version': 3},
        {'stockEntry': {...entry().toJson(), 'quantity': -1}},
        {'stockEntry': {...entry().toJson(), 'method': 'guessed'}},
        {'stockEntry': {...entry().toJson(), 'productId': 'different'}},
        {'stockEntry': {...entry().toJson(), 'stockAsOf': '2026-10-03'}},
        {'stockEntry': {...entry().toJson(), 'purchasePriceRupees': 0}},
      ]) {
        expect(() => WorkspaceCatalogueItem.fromInventoryJson({
          ...product.toInventoryJson(), ...patch}), throwsFormatException);
      }
      expect(() => WorkspaceSavedInventory.fromJson({...saved.toJson(), 'version': 1}),
        throwsFormatException);
    });

    for (final method in WorkspaceStockEntryMethod.values) {
      test('${method.name} freezes original facts through restart and later edits', () async {
        final device = _OrderJournalStorage();
        final owner = _CommandAccountStore();
        WorkSession fresh() => WorkSession(gateway: ReviewWorkGateway(),
          contactDraftStore: owner, inventoryStore: SecureWorkInventoryStore(
            accountScope: () => owner.accountScope, storage: device))
          ..activeWorkspace = _commandStore;
        final first = fresh();
        expect(await first.loadWorkspaceInventory(), isTrue);
        if (method == WorkspaceStockEntryMethod.csv) {
          first.importWorkspaceProducts([base], addOnly: true, stockEntryMethod: method);
        } else {
          first.addOrUpdateWorkspaceProduct(base, stockEntryMethod: method);
        }
        expect(await first.workspaceInventorySaved, isTrue);
        final original = first.workspaceCatalogueItems.single.stockEntry!;
        expect(original.method, method);
        expect(original.quantity, 6);
        expect(original.purchasePriceRupees, 25);
        expect(original.sku, base.sku);
        expect(original.stockAsOf, original.recordedAt);
        first.dispose();
        final restarted = fresh();
        addTearDown(restarted.dispose);
        expect(await restarted.loadWorkspaceInventory(), isTrue);
        expect(restarted.workspaceCatalogueItems.single.stockEntry!.contentIdentity,
          original.contentIdentity);
        restarted.addOrUpdateWorkspaceProduct(restarted.workspaceCatalogueItems.single
          .copyWith(stock: 4, purchasePrice: 26, sku: 'EDITED-SKU', pack: 'Edited pack'),
          stockEntryMethod: WorkspaceStockEntryMethod.manual);
        expect(await restarted.workspaceInventorySaved, isTrue);
        final edited = restarted.workspaceCatalogueItems.single;
        expect(edited.stockEntry!.contentIdentity, original.contentIdentity);
        expect(edited.stock, 4);
        expect(edited.purchasePrice, 26);
        expect(edited.stockEntry!.pack, base.pack);
        expect(restarted.workspaceInvoices, isEmpty);
        expect(restarted.workspaceFinance, isNull);
        expect(restarted.workspacePurchaseCopies, isEmpty);
      });
    }

    for (final mode in WorkspaceStockMode.values) {
      test('zero/count-unknown ${mode.name} does not invent a movement', () {
        final work = WorkSession(gateway: ReviewWorkGateway())..activeWorkspace = _commandStore;
        addTearDown(work.dispose);
        work.addOrUpdateWorkspaceProduct(base.copyWith(stock: 0, stockMode: mode),
          stockEntryMethod: WorkspaceStockEntryMethod.manual);
        final saved = work.workspaceCatalogueItems.single;
        expect(saved.stockEntry!.quantity,
          mode == WorkspaceStockMode.exactQuantity ? 0 : null);
        expect(saved.stockEntry!.purchasePriceRupees, 25);
        expect(work.workspaceStockMovements, isEmpty);
      });
    }

    test('generic and legacy edits never infer an origin', () {
      final work = WorkSession(gateway: ReviewWorkGateway())..activeWorkspace = _commandStore;
      addTearDown(work.dispose);
      work.importWorkspaceProducts([base], addOnly: true);
      work.addOrUpdateWorkspaceProduct(base.copyWith(stock: 4),
        stockEntryMethod: WorkspaceStockEntryMethod.manual);
      expect(work.workspaceCatalogueItems.single.stockEntry, isNull);
    });

    test('storage rejects dropped rewritten and retroactive origin; scope remains isolated', () async {
      final device = _OrderJournalStorage();
      final storage = SecureWorkInventoryStore(accountScope: () => 'account-A', storage: device);
      final product = base.copyWith(stockEntry: entry());
      await storage.save(checkpoint([product]), expectedRevision: null);
      final altered = WorkspaceStockEntry.fromJson({...entry().toJson(), 'quantity': 5})!;
      for (final products in [<WorkspaceCatalogueItem>[], [base],
          [base.copyWith(stockEntry: altered)]]) {
        await expectLater(storage.save(checkpoint(products, revision: 2), expectedRevision: 1),
          throwsA(isA<WorkGatewayException>()));
      }
      expect((await storage.read('account-A', _commandStore.id, qa: true))!.revision, 1);
      expect(await storage.read('account-A', _commandStore.id, qa: false), isNull);
      expect(await storage.read('account-A', 'other-store', qa: true), isNull);
      await storage.save(checkpoint([base], qa: false), expectedRevision: null);
      await expectLater(storage.save(checkpoint([product], revision: 2, qa: false), expectedRevision: 1),
        throwsA(isA<WorkGatewayException>()));
    });

    test('failed-save retry and lost native reply keep the same snapshot', () async {
      final device = _OrderJournalStorage()..failWrite = true;
      final owner = _CommandAccountStore();
      final work = WorkSession(gateway: ReviewWorkGateway(), contactDraftStore: owner,
        inventoryStore: SecureWorkInventoryStore(accountScope: () => owner.accountScope,
          storage: device))..activeWorkspace = _commandStore;
      addTearDown(work.dispose);
      expect(await work.loadWorkspaceInventory(), isTrue);
      work.addOrUpdateWorkspaceProduct(base, stockEntryMethod: WorkspaceStockEntryMethod.manual);
      expect(await work.workspaceInventorySaved, isFalse);
      final original = work.workspaceCatalogueItems.single.stockEntry!.contentIdentity;
      final movementIds = work.workspaceStockMovements.map((m) => m.id).toList();
      device.failWrite = false;
      device.loseWriteResponseOnce = true;
      expect(await work.retryWorkspaceInventorySave(), isTrue);
      final saved = await SecureWorkInventoryStore(accountScope: () => owner.accountScope,
        storage: device).read('account-A', _commandStore.id, qa: true);
      expect(saved!.products.single.stockEntry!.contentIdentity, original);
      expect(saved.movements.map((m) => m.id), movementIds);
      expect(saved.products.single.stock, 6);
    });

    test('later already-stocked bill copy keeps original quantity without stocking again', () async {
      final device = _OrderJournalStorage();
      final owner = _CommandAccountStore();
      WorkSession fresh() => WorkSession(gateway: ReviewWorkGateway(),
        contactDraftStore: owner, inventoryStore: SecureWorkInventoryStore(
          accountScope: () => owner.accountScope, storage: device),
        purchaseEntryStore: SecureWorkPurchaseEntryStore(
          accountScope: () => owner.accountScope, storage: device))
        ..activeWorkspace = _commandStore;
      final work = fresh();
      expect(await work.loadWorkspaceInventory(), isTrue);
      work.addOrUpdateWorkspaceProduct(base, stockEntryMethod: WorkspaceStockEntryMethod.manual);
      expect(await work.workspaceInventorySaved, isTrue);
      final original = work.workspaceCatalogueItems.single.stockEntry!.contentIdentity;
      work.addOrUpdateWorkspaceProduct(work.workspaceCatalogueItems.single.copyWith(stock: 4));
      expect(await work.workspaceInventorySaved, isTrue);
      final movements = work.workspaceStockMovements.map((m) => m.id).toList();
      expect(await work.loadWorkspaceSuppliers(), isTrue);
      final now = DateTime.now().toUtc();
      final supplier = WorkspaceSupplierProfile(id: 'p03-host-supplier',
        name: 'P03 evaluation supplier', createdAt: now, updatedAt: now);
      final draft = WorkspacePurchaseEntryDraft(id: 'p03-host-bill',
        supplierId: supplier.id, invoiceReference: 'P03-HOST-BILL',
        invoiceDate: '2026-10-02', createdAt: now, updatedAt: now,
        goods: [{'productId': base.id, 'name': base.title, 'pack': base.pack,
          'quantity': '6', 'cost': '25'}],
        details: const {'receiptStatus': 'Already added to Stock'});
      final copy = WorkspacePurchaseSavedCopy(id: 'p03-host-copy',
        storeName: _commandStore.name, revision: 1, savedAt: now,
        supplier: supplier, draft: draft, labels: const {});
      expect(await work.saveWorkspacePurchaseEntry(supplier,
        scope: work.workspaceSupplierScope!, draft: draft,
        expectedRevision: null, reviewedCopy: copy), isTrue);
      expect(work.workspaceCatalogueItems.single.stock, 4);
      expect(work.workspaceStockMovements.map((m) => m.id), movements);
      expect(work.workspaceCatalogueItems.single.stockEntry!.contentIdentity, original);
      expect(work.workspaceFinance, isNull);
      work.dispose();
      final restarted = fresh();
      addTearDown(restarted.dispose);
      expect(await restarted.loadWorkspaceInventory(), isTrue);
      expect(await restarted.loadWorkspaceSuppliers(), isTrue);
      expect(restarted.workspaceCatalogueItems.single.stock, 4);
      expect(restarted.workspacePurchaseCopies.single.draft.goods.single['productId'], base.id);
      expect(restarted.workspacePurchaseCopies.single.draft.goods.single['quantity'], '6');
      expect(restarted.workspacePurchaseCopies.single.draft.details['receiptStatus'],
        'Already added to Stock');
      expect(restarted.workspaceFinance, isNull);
      expect(restarted.workspaceCatalogueItems.single.stockEntry!.contentIdentity, original);
    });
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
    test('STOCK-AUDIT-09 hiding survives restart without changing stock', () async {
      final device = _OrderJournalStorage();
      final owner = _CommandAccountStore();
      WorkSession fresh() => WorkSession(
        gateway: ReviewWorkGateway(),
        contactDraftStore: owner,
        inventoryStore: SecureWorkInventoryStore(
          accountScope: () => owner.accountScope, storage: device,
        ),
      )..activeWorkspace = _commandStore;
      final first = fresh();
      expect(await first.loadWorkspaceInventory(), isTrue);
      final product = record().products.single;
      first.addOrUpdateWorkspaceProduct(product);
      expect(await first.workspaceInventorySaved, isTrue);
      final movementIds = first.workspaceStockMovements.map((m) => m.id).toList();
      first.retireWorkspaceProduct(product.id);
      expect(await first.workspaceInventorySaved, isTrue);
      first.dispose();
      final reopened = fresh();
      addTearDown(reopened.dispose);
      expect(await reopened.loadWorkspaceInventory(), isTrue);
      final saved = reopened.workspaceCatalogueItems.single;
      expect(saved.stock, product.stock);
      expect(saved.id, product.id);
      expect(saved.sku, product.sku);
      expect(saved.available, product.available);
      expect(saved.counterSaleAllowed, isFalse);
      expect(saved.publicListing, product.publicListing);
      expect(saved.canSellAtCounter, isFalse);
      expect(reopened.workspaceStockMovements.map((m) => m.id), movementIds);
      expect(reopened.workspaceInvoices, isEmpty);
      expect(reopened.workspaceOrders, isEmpty);
      reopened.restoreWorkspaceProduct(product.id);
      expect(await reopened.workspaceInventorySaved, isTrue);
      final restored = fresh();
      addTearDown(restored.dispose);
      expect(await restored.loadWorkspaceInventory(), isTrue);
      expect(restored.workspaceCatalogueItems.single.available, isTrue);
      expect(restored.workspaceCatalogueItems.single.publicListing, product.publicListing);
      expect(restored.workspaceCatalogueItems.single.published, product.published);
      expect(restored.workspaceCatalogueItems.single.counterSaleAllowed, isTrue);
      expect(restored.workspaceCatalogueItems.single.stock, product.stock);
      expect(restored.workspaceStockMovements.map((m) => m.id), movementIds);
    });

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
    test(
      'EVALUATION eight reference products never create stock or photo approval',
      () {
        expect(storeEntryEvaluationCatalogue, hasLength(8));
        expect(
          storeEntryEvaluationCatalogue.map((p) => p.id).toSet(),
          hasLength(8),
        );
        for (final product in storeEntryEvaluationCatalogue) {
          expect(product.stock, 0);
          expect(product.purchasePrice, 0);
          expect(product.sellingPrice, 0);
          expect(product.publicListing, isFalse);
          expect(
            product.cataloguePhoto!.status,
            WorkspaceCataloguePhotoStatus.testOnly,
          );
          expect(
            storeEntryEvaluationPhotoAsset(product),
            SecureWorkReviewStoreSelectionStore.enabled ? isNotNull : isNull,
          );
          expect(
            storeEntryEvaluationPhotoAsset(
              product.copyWith(pack: 'wrong pack'),
            ),
            isNull,
          );
          expect(
            storeEntryEvaluationPhotoAsset(
              product.copyWith(brand: 'wrong brand'),
            ),
            isNull,
          );
          final wrongPhoto = WorkspaceCataloguePhoto.fromJson({
            ...product.cataloguePhoto!.toJson(),
            'source': 'https://wrong.invalid/photo.png',
          });
          expect(
            storeEntryEvaluationPhotoAsset(
              product.copyWith(cataloguePhoto: wrongPhoto),
            ),
            isNull,
          );
        }
      },
    );
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
        'ENTRYEMPTY actual startup migrates legacy Store and stays empty after relaunch',
        () async {
          final native = _OrderJournalStorage();
          final account = _CommandAccountStore();
          final selection = SecureWorkReviewStoreSelectionStore(
            accountScope: () => account.accountScope,
            storage: native,
          );
          await selection.save(
            StoreReviewSeed(
              accountScope: 'account-A',
              orderCount: 1000,
              now: DateTime.utc(2026, 9, 19),
            ),
          );
          WorkSession open() => WorkSession(
            gateway: ReviewWorkGateway(),
            contactDraftStore: account,
            reviewStoreSelectionStore: selection,
            inventoryStore: SecureWorkInventoryStore(
              accountScope: () => account.accountScope,
              storage: native,
            ),
          );
          String? storeId;
          for (var launch = 0; launch < 2; launch++) {
            final session = open();
            await session.loadInitialWorkspaceState();
            expect(session.initialWorkspaceStateLoaded, isTrue);
            expect(session.activeWorkspace?.id, startsWith('QA-STORE-V1-0-'));
            storeId ??= session.activeWorkspace!.id;
            expect(session.activeWorkspace!.id, storeId);
            expect(session.workspaceCatalogueItems, isEmpty);
            expect(session.referenceCatalogue, storeEntryEvaluationCatalogue);
            expect(session.workspaceOrders, isEmpty);
            expect(session.workspaceInvoices, isEmpty);
            expect(session.customerLedgerRecoveryError, isNull);
            session.dispose();
          }
          expect(
            native.values.keys.where((key) => key.contains('.archive.')),
            hasLength(1),
          );
        },
      );

      test(
        'ENTRYEMPTY archives legacy selection without deleting linked data',
        () async {
          final native = _OrderJournalStorage();
          final store = SecureWorkReviewStoreSelectionStore(
            accountScope: () => 'account-A',
            storage: native,
          );
          final legacy = StoreReviewSeed(
            accountScope: 'account-A',
            orderCount: 1000,
            now: DateTime.utc(2026, 9, 19),
          );
          await store.save(legacy);
          final selectionKey = native.values.keys.single;
          final original = native.values[selectionKey];
          final linkedKey = 'inventory/${legacy.storeId}';
          native.values[linkedKey] = 'preserve legacy history exactly';
          final empty = (await store.archiveLegacySelectionForEntry(
            'account-A',
          ))!;
          expect(empty.orderCount, 0);
          expect(empty.storeId, isNot(legacy.storeId));
          expect(empty.products, isEmpty);
          expect(empty.orders, isEmpty);
          expect(empty.purchases, isEmpty);
          expect(empty.offers, isEmpty);
          expect(empty.supplierLedgers, isEmpty);
          expect(empty.finance.customerLedgers, isEmpty);
          expect(empty.finance.payments, isEmpty);
          expect(empty.finance.availableMinor, 0);
          expect(native.values[linkedKey], 'preserve legacy history exactly');
          expect(
            native.values['$selectionKey.archive.${legacy.storeId}'],
            original,
          );
          final before = Map<String, String>.from(native.values);
          expect(
            (await store.archiveLegacySelectionForEntry('account-A'))!.storeId,
            empty.storeId,
          );
          expect(native.values, before);
        },
      );

      for (final failure in ['write', 'lost-reply', 'archive-conflict']) {
        test(
          'ENTRYEMPTY $failure preserves legacy selection and supports safe retry',
          () async {
            final native = _OrderJournalStorage();
            final store = SecureWorkReviewStoreSelectionStore(
              accountScope: () => 'account-A',
              storage: native,
            );
            final legacy = StoreReviewSeed(
              accountScope: 'account-A',
              orderCount: 12,
              now: DateTime.utc(2026, 9, 19),
            );
            await store.save(legacy);
            final key = native.values.keys.single;
            final original = native.values[key];
            native.failWrite = failure == 'write';
            native.loseWriteResponseOnce = failure == 'lost-reply';
            if (failure == 'archive-conflict') {
              native.values['$key.archive.${legacy.storeId}'] =
                  'conflicting history';
            }
            await expectLater(
              store.archiveLegacySelectionForEntry('account-A'),
              throwsA(isA<Object>()),
            );
            expect(native.values[key], original);
            native.failWrite = false;
            if (failure == 'archive-conflict') {
              expect(
                native.values['$key.archive.${legacy.storeId}'],
                'conflicting history',
              );
            } else {
              expect(
                (await store.archiveLegacySelectionForEntry(
                  'account-A',
                ))!.orderCount,
                0,
              );
            }
          },
        );
      }

      test(
        'ledger recovery retains invoice then product-entry history across restarts',
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
          Future<void> invoice(WorkSession session, String productId) async {
            expect(session.startNewWorkspaceOrder(), isTrue);
            await session.loadWorkspaceCounterDraft();
            session.adjustWorkspaceOrderQuantity(productId, 1);
            session.updateWorkspaceCounterDetails(
              customer: '9000091934',
              payment: 'Cash',
            );
            expect(
              (await session.submitWorkspaceCounterBill())?.invoice,
              isNotNull,
            );
          }

          final first = open()..activeWorkspace = _commandStore;
          expect(
            first.loadStoreReviewSeed(0, now: DateTime.utc(2026, 9, 19)),
            isTrue,
          );
          expect(await first.storeReviewSelectionSaved, isTrue);
          expect(await first.recoverCustomerLedger(), isTrue);
          expect(await first.loadWorkspaceInventory(), isTrue);
          final oil = workspaceMasterCatalogue.first.copyWith(stock: 6);
          first.addOrUpdateWorkspaceProduct(oil);
          expect(await first.workspaceInventorySaved, isTrue);
          await invoice(first, oil.id);
          first.dispose();

          final second = open();
          await second.loadInitialWorkspaceState();
          expect(second.customerLedgerRecoveryError, isNull);
          expect(
            second.workspaceStockMovements.map((m) => m.quantityDelta),
            [-1, 6],
            reason: 'Recovered history stays newest-first.',
          );
          // Emulate the old APK hydration order before another product save.
          // This legacy snapshot must recover too, not only newly fixed saves.
          final legacyOrder = second.workspaceStockMovements.reversed.toList();
          second.workspaceStockMovements
            ..clear()
            ..addAll(legacyOrder);
          final rice = WorkspaceProductImport.parse(
            'title,brand,pack,purchasePrice,sellingPrice,stock,sku\n'
            'QA Rice,QA,1 kg,80,101,100,QA-RESTART-RICE',
            catalogue: const [],
            owned: const [],
          ).rows.single.product!;
          second.importWorkspaceProducts([rice], addOnly: true);
          expect(await second.workspaceInventorySaved, isTrue);
          await invoice(second, rice.id);
          final expectedProducts = second.workspaceCatalogueItems
              .map((p) => p.toInventoryJson())
              .toList();
          final expectedInvoices = {
            for (final i in second.workspaceInvoices) i.id: i.toLedgerJson(),
          };
          second.dispose();

          final third = open();
          addTearDown(third.dispose);
          await third.loadInitialWorkspaceState();
          expect(third.customerLedgerRecoveryError, isNull);
          expect(
            third.workspaceCatalogueItems
                .map((p) => p.toInventoryJson())
                .toList(),
            expectedProducts,
          );
          expect({
            for (final i in third.workspaceInvoices) i.id: i.toLedgerJson(),
          }, expectedInvoices);
          expect(await third.recoverCustomerLedger(), isTrue);
          expect(third.workspaceInvoices.length, 2);
          expect(third.workspaceStockMovements.map((m) => m.quantityDelta), [
            -1,
            100,
            -1,
            6,
          ]);

          final inventoryKey = native.values.keys.singleWhere(
            (key) => key.contains('workspace.inventory.'),
          );
          final preserved = native.values[inventoryKey]!;
          // A product can be added while another product's older ledger is
          // unrecovered. Its receipt is later in the checkpoint, but each SKU's
          // retained movements and quantity still prove its own complete prefix.
          final interleaved = jsonDecode(preserved) as Map<String, dynamic>;
          (interleaved['movements'] as List).removeWhere(
            (m) => m['productId'] == oil.id && m['quantityDelta'] == -1,
          );
          ((interleaved['products'] as List).singleWhere(
                    (p) => p['id'] == oil.id,
                  )
                  as Map)['stock'] =
              6;
          native.values[inventoryKey] = jsonEncode(interleaved);
          final interleavedRecovery = open();
          await interleavedRecovery.loadInitialWorkspaceState();
          expect(interleavedRecovery.customerLedgerRecoveryError, isNull);
          expect(
            {
              for (final p in interleavedRecovery.workspaceCatalogueItems)
                p.id: p.stock,
            },
            {oil.id: 5, rice.id: 99},
          );
          expect(interleavedRecovery.workspaceInvoices.length, 2);
          interleavedRecovery.dispose();
          native.values[inventoryKey] = preserved;
          for (final damage in ['gap', 'changed', 'duplicate', 'quantity']) {
            final altered = jsonDecode(preserved) as Map<String, dynamic>;
            final movements = altered['movements'] as List;
            switch (damage) {
              case 'gap':
                movements.removeAt(1);
              case 'changed':
                (movements.first as Map)['reason'] = 'Conflicting content';
              case 'duplicate':
                movements.add(
                  Map<String, dynamic>.from(movements.first as Map),
                );
              case 'quantity':
                ((altered['products'] as List).first as Map)['stock'] = 4;
            }
            final damaged = jsonEncode(altered);
            native.values[inventoryKey] = damaged;
            final rejected = open();
            await rejected.loadInitialWorkspaceState();
            expect(
              rejected.customerLedgerRecoveryError,
              isNotNull,
              reason: damage,
            );
            expect(
              native.values[inventoryKey],
              damaged,
              reason: 'Do not rewrite conflicting evidence: $damage',
            );
            rejected.dispose();
            native.values[inventoryKey] = preserved;
          }
        },
      );

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
            first.loadStoreReviewSeed(0, now: DateTime.utc(2026, 9, 19)),
            isTrue,
          );
          expect(await first.storeReviewSelectionSaved, isTrue);
          expect(await first.recoverCustomerLedger(), isTrue);
          expect(await first.loadWorkspaceInventory(), isTrue);
          expect(first.workspaceCatalogueItems, isEmpty);
          final original = workspaceMasterCatalogue.first.copyWith(stock: 10);
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
            first.loadStoreReviewSeed(0, now: DateTime.utc(2026, 9, 19)),
            isTrue,
          );
          expect(await first.storeReviewSelectionSaved, isTrue);
          expect(await first.recoverCustomerLedger(), isTrue);
          final storeId = first.activeWorkspace!.id;
          expect(first.workspaceCatalogueItems, isEmpty);
          first.addOrUpdateWorkspaceProduct(
            workspaceMasterCatalogue.first.copyWith(stock: 10),
          );
          expect(await first.workspaceInventorySaved, isTrue);
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
        contactDraftStore: _CommandAccountStore(),
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

  // Automated contract evidence only. No evaluation records are injected into
  // the phone, and these cases do not qualify the actual purchase-entry flow.
  WorkspaceSupplierLedger? confirmedOpeningFixture(
    WorkspaceSupplierOpeningRecord record, {
    String account = 'account-A',
    String store = 'store-A',
    String supplier = 'private-supplier-A',
    bool qa = true,
    DateTime? at,
  }) => WorkspaceSupplierLedger.confirmedOpening(
    record,
    accountScope: account,
    workspaceId: store,
    supplierId: supplier,
    supplierName: 'Automated supplier fixture',
    qa: qa,
    confirmedAt: at ?? DateTime.utc(2026, 10, 3),
  );

  WorkspaceSupplierGoodsReceipt goodsReceiptFixture({String id = 'receipt-A',
    String group = 'expected-delivery-A', String lineId = 'line-A',
    String product = 'saved-product-A', int delivered = 6000, int accepted = 6000,
    int damaged = 0, int short = 0, int? expected = 12000, int factor = 1,
    Map<String, int> prior = const {},
  }) => WorkspaceSupplierGoodsReceipt(id: id, expectedDeliveryId: group,
    reference: 'DEL-$id', deliveredOn: '2026-10-02', recordedAt: DateTime.utc(2026, 10, 3),
    lines: [WorkspaceSupplierGoodsReceiptLine(sourceLineId: lineId, productId: product,
      productLabel: 'Evaluation rice', purchaseUnit: '1 kg', stockUnit: '1 kg',
      unitsPerPack: factor, deliveredMilli: delivered, acceptedMilli: accepted,
      damagedMilli: damaged, shortMilli: short, expectedMilli: expected,
      priorStockUnits: prior)]);

  WorkspaceFinanceSnapshot receiptFinanceFixture() => WorkspaceFinanceSnapshot(
    accountScope: 'account-A', workspaceId: 'store-A', revision: 1,
    asOf: DateTime.utc(2026, 10, 3), salesTodayMinor: 0, duesMinor: 0,
    availableMinor: 0, heldMinor: 0, requestedMinor: 0, paidOutMinor: 0,
    feesMinor: 0, deliveryAdjustmentsMinor: 0, refundsMinor: 0, taxWithheldMinor: 0,
    payments: const [], payouts: const [], historyComplete: true);

  WorkspaceInventoryLedger receiptInventoryFixture(List<WorkspaceStockMovement> movements) =>
    WorkspaceInventoryLedger(accountScope: 'account-A', workspaceId: 'store-A',
      revision: 1, asOf: DateTime.utc(2026, 10, 3),
      openingQuantities: const {'saved-product-A': 0}, movements: movements);

  WorkspaceStockMovement originalGoodsFixture({String id = 'original-stock',
    int quantity = 10, WorkspaceStockReferenceKind? referenceKind}) => WorkspaceStockMovement(
      id: id, productId: 'saved-product-A', productLabel: 'Evaluation rice',
      kind: WorkspaceStockMovementKind.openingStock, quantityDelta: quantity,
      reason: 'Opening quantity', occurredAt: DateTime.utc(2026, 10, 2),
      referenceKind: referenceKind, referenceId: referenceKind == null ? null : 'platform-receipt');

  WorkspaceSavedInventory receiptProjectionFixture({int revision = 1, int stock = 10,
    int? marker, List<WorkspaceStockMovement> movements = const [],
  }) => WorkspaceSavedInventory(account: 'account-A', store: 'store-A', qa: true,
    revision: revision, savedAt: DateTime.utc(2026, 10, 3),
    manualReceiptCheckpointRevision: marker,
    products: [workspaceMasterCatalogue.last.copyWith(stock: stock, publicListing: false)],
    movements: movements);

  WorkspaceSavedInventory projectedReceiptFixture() {
    final base = receiptProjectionFixture();
    final receipt = goodsReceiptFixture(product: base.products.single.id);
    return receiptProjectionFixture(revision: 2, stock: 16, marker: 2,
      movements: [receipt.movementFor(receipt.lines.single)!]);
  }

  // Host-only authoritative journal fixture, never phone storage injection.
  Future<void> seedReceiptJournalFixture(_OrderJournalStorage storage) async {
    final projection = projectedReceiptFixture();
    final receipt = goodsReceiptFixture(product: projection.products.single.id);
    final opening = confirmedOpeningFixture(openingFixture(amount: 0))!;
    final owner = SecureWorkLedgerCheckpointStore(accountScope: () => 'account-A', storage: storage);
    final inventory = WorkspaceInventoryLedger(accountScope: 'account-A', workspaceId: 'store-A',
      revision: 1, asOf: receipt.recordedAt,
      openingQuantities: {projection.products.single.id: 10}, movements: const []);
    await owner.save(WorkspaceLedgerCheckpoint(revision: 1, finance: receiptFinanceFixture(),
      inventory: inventory, supplierLedgers: {opening.supplierId: opening}), expectedRevision: null);
    final received = opening.receiveGoods(receipt, expectedRevision: 1)!;
    await owner.save(WorkspaceLedgerCheckpoint(revision: 2, finance: receiptFinanceFixture(),
      inventory: inventory.post(projection.movements, at: receipt.recordedAt),
      supplierLedgers: {received.supplierId: received}), expectedRevision: 1);
  }

  test('PURCHASERECEIVE inventory guard serializes projection against stale Stock writers', () async {
    final storage = _OrderJournalStorage();
    SecureWorkInventoryStore owner() => SecureWorkInventoryStore(
      accountScope: () => 'account-A', storage: storage);
    await owner().save(receiptProjectionFixture(), expectedRevision: null);
    final entered = Completer<void>(), release = Completer<void>();
    final projecting = owner().projectReceipt('account-A', 'store-A', qa: true,
      expectedRevision: 1, commit: (previous) async {
        expect(previous!.products.single.stock, 10);
        entered.complete();
        await release.future;
        return projectedReceiptFixture();
      });
    await entered.future;
    final stale = owner().save(receiptProjectionFixture(revision: 2, stock: 5), expectedRevision: 1);
    final rejected = expectLater(stale, throwsA(isA<WorkGatewayException>()));
    release.complete();
    expect(await projecting, isTrue);
    await rejected;
    final saved = (await owner().read('account-A', 'store-A', qa: true))!;
    expect(saved.products.single.stock, 16);
    expect(saved.manualReceiptCheckpointRevision, 2);
    expect(saved.movements.length, 1);
  });

  test('PURCHASERECEIVE pending Stock write invalidates receipt baseline before callback', () async {
    final storage = _OrderJournalStorage();
    final owner = SecureWorkInventoryStore(accountScope: () => 'account-A', storage: storage);
    await owner.save(receiptProjectionFixture(), expectedRevision: null);
    final writing = owner.save(receiptProjectionFixture(revision: 2), expectedRevision: 1);
    var commits = 0;
    final posting = owner.projectReceipt('account-A', 'store-A', qa: true,
      expectedRevision: 1, commit: (previous) async { commits++; return projectedReceiptFixture(); });
    final rejected = expectLater(posting, throwsA(isA<WorkGatewayException>()));
    await writing;
    await rejected;
    expect(commits, 0);
    expect((await owner.read('account-A', 'store-A', qa: true))!.revision, 2);
  });

  test('PURCHASERECEIVE projected Stock cannot lose receipt history or change units', () async {
    final storage = _OrderJournalStorage();
    final owner = SecureWorkInventoryStore(accountScope: () => 'account-A', storage: storage);
    await owner.save(receiptProjectionFixture(), expectedRevision: null);
    final projection = projectedReceiptFixture();
    expect(await owner.projectReceipt('account-A', 'store-A', qa: true,
      expectedRevision: 1, commit: (previous) async => projection), isTrue);
    final writes = storage.writes.length;
    await expectLater(owner.save(
      receiptProjectionFixture(revision: 3, stock: 16, movements: projection.movements),
      expectedRevision: 2), throwsFormatException,
      reason: 'A manual receipt movement without its projection marker is malformed.');
    for (final changed in [
      receiptProjectionFixture(revision: 3, stock: 16, marker: 2),
      receiptProjectionFixture(revision: 3, stock: 10, marker: 2, movements: projection.movements),
      WorkspaceSavedInventory.fromJson({...projection.toJson(), 'revision': 3,
        'products': [projection.products.single.copyWith(pack: 'Changed pack').toInventoryJson()]}),
    ]) {
      await expectLater(owner.save(changed, expectedRevision: 2), throwsA(isA<WorkGatewayException>()));
    }
    expect(storage.writes.length, writes);
    final priceOnly = WorkspaceSavedInventory.fromJson({...projection.toJson(), 'revision': 3,
      'products': [projection.products.single.copyWith(sellingPrice: 31).toInventoryJson()]});
    await expectLater(owner.save(priceOnly, expectedRevision: 2), throwsA(isA<WorkGatewayException>()),
      reason: 'A projection marker alone does not supply authoritative receipt evidence.');
    await seedReceiptJournalFixture(storage);
    await owner.save(priceOnly, expectedRevision: 2);
    final saved = (await owner.read('account-A', 'store-A', qa: true))!;
    expect(saved.products.single.stock, 16);
    expect(saved.products.single.sellingPrice, 31);
    expect(saved.manualReceiptCheckpointRevision, 2);
  });

  test('PURCHASERECEIVE projection failure and lost reply retain exact replay quantity', () async {
    final storage = _OrderJournalStorage();
    final owner = SecureWorkInventoryStore(accountScope: () => 'account-A', storage: storage);
    await owner.save(receiptProjectionFixture(), expectedRevision: null);
    await expectLater(owner.projectReceipt('account-A', 'store-A', qa: true,
      expectedRevision: 1, commit: (previous) async {
        storage.failWrite = true;
        return projectedReceiptFixture();
      }), throwsStateError);
    storage.failWrite = false;
    expect((await owner.read('account-A', 'store-A', qa: true))!.products.single.stock, 10);
    storage.loseWriteResponseOnce = true;
    expect(await owner.projectReceipt('account-A', 'store-A', qa: true,
      expectedRevision: 1, commit: (previous) async => projectedReceiptFixture()), isTrue);
    final saved = (await owner.read('account-A', 'store-A', qa: true))!;
    expect(saved.products.single.stock, 16);
    expect(saved.movements.length, 1);
    final writes = storage.writes.length;
    await owner.save(saved, expectedRevision: 1);
    expect(storage.writes.length, writes);
  });

  test('PURCHASERECEIVE fully linked goods still preserve a projection checkpoint marker', () async {
    final storage = _OrderJournalStorage();
    final owner = SecureWorkInventoryStore(accountScope: () => 'account-A', storage: storage);
    await owner.save(receiptProjectionFixture(), expectedRevision: null);
    expect(await owner.projectReceipt('account-A', 'store-A', qa: true,
      expectedRevision: 1, commit: (previous) async => receiptProjectionFixture(revision: 2, marker: 2)), isTrue);
    await expectLater(owner.save(receiptProjectionFixture(revision: 3), expectedRevision: 2),
      throwsA(isA<WorkGatewayException>()));
    await expectLater(owner.save(receiptProjectionFixture(revision: 3, stock: 5, marker: 2), expectedRevision: 2),
      throwsA(isA<WorkGatewayException>()));
    expect((await owner.read('account-A', 'store-A', qa: true))!.products.single.stock, 10);
  });

  test('PURCHASERECEIVE inventory guard rejects production and wrong scope', () async {
    final storage = _OrderJournalStorage();
    final owner = SecureWorkInventoryStore(accountScope: () => 'account-A', storage: storage);
    var called = false;
    Future<WorkspaceSavedInventory?> commit(WorkspaceSavedInventory? previous) async {
      called = true;
      return projectedReceiptFixture();
    }
    await expectLater(owner.projectReceipt('account-A', 'store-A', qa: false,
      expectedRevision: null, commit: commit), throwsA(isA<WorkGatewayException>()));
    await expectLater(owner.projectReceipt('other-account', 'store-A', qa: true,
      expectedRevision: null, commit: commit), throwsA(isA<WorkGatewayException>()));
    expect(called, isFalse);
    expect(storage.writes, isEmpty);
  });

  test('PURCHASERECEIVE latest journal Stock movement cannot be lost in a price edit', () async {
    final storage = _OrderJournalStorage();
    final owner = SecureWorkInventoryStore(accountScope: () => 'account-A', storage: storage);
    await owner.save(receiptProjectionFixture(), expectedRevision: null);
    final projection = projectedReceiptFixture();
    await seedReceiptJournalFixture(storage);
    expect(await owner.projectReceipt('account-A', 'store-A', qa: true,
      expectedRevision: 1, commit: (previous) async => projection), isTrue);
    final journal = SecureWorkLedgerCheckpointStore(accountScope: () => 'account-A', storage: storage);
    final old = (await journal.read('account-A', 'store-A'))!;
    final adjustment = WorkspaceStockMovement(id: 'later-counted-adjustment',
      productId: projection.products.single.id, productLabel: 'Evaluation rice',
      kind: WorkspaceStockMovementKind.adjustment, quantityDelta: -2,
      reason: 'Counted two fewer', occurredAt: DateTime.utc(2026, 10, 3));
    await journal.save(WorkspaceLedgerCheckpoint(revision: 3, finance: old.finance,
      inventory: old.inventory!.post([adjustment], at: adjustment.occurredAt),
      supplierLedgers: old.supplierLedgers), expectedRevision: 2);
    final stalePriceEdit = WorkspaceSavedInventory.fromJson({...projection.toJson(),
      'revision': 3, 'products': [projection.products.single.copyWith(sellingPrice: 31).toInventoryJson()]});
    final writes = storage.writes.length;
    await expectLater(owner.save(stalePriceEdit, expectedRevision: 2), throwsA(isA<WorkGatewayException>()));
    expect(storage.writes.length, writes);
    expect((await journal.read('account-A', 'store-A'))!.inventory!.quantities![adjustment.productId], 14);
    expect(() => WorkspaceSavedInventory.fromJson({...projection.toJson(),
      'manualReceiptCheckpointRevision': null}), throwsFormatException);
    expect(() => WorkspaceSavedInventory.fromJson({for (final entry in projection.toJson().entries)
      if (entry.key != 'manualReceiptCheckpointRevision') entry.key: entry.value}), throwsFormatException);
  });

  test('PURCHASERECEIVE partial damage and shortage retain evidence without money effects', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 50000))!;
    final first = goodsReceiptFixture(accepted: 5000, damaged: 1000, short: 6000);
    final second = goodsReceiptFixture(id: 'receipt-B');
    final partial = opening.receiveGoods(first, expectedRevision: 1)!;
    final completedDelivery = partial.receiveGoods(second, expectedRevision: 2)!;
    expect(completedDelivery.balanceMinor, 50000);
    expect(completedDelivery.entries, isEmpty);
    expect(completedDelivery.goodsReceipts.length, 2);
    expect(completedDelivery.goodsReceipts['receipt-A']!.lines.single.shortMilli, 6000);
    expect(completedDelivery.goodsReceipts['receipt-A']!.lines.single.damagedMilli, 1000);
    expect(completedDelivery.goodsReceipts.values.expand((r) => r.lines)
      .fold<int>(0, (sum, line) => sum + line.acceptedMilli), 11000);
    expect(completedDelivery.receiveGoods(second, expectedRevision: 1), same(completedDelivery));
    expect(completedDelivery.receiveGoods(goodsReceiptFixture(id: 'receipt-C'),
      expectedRevision: 3), isNull);
    expect(WorkspaceSupplierLedger.fromJson(completedDelivery.toJson())!.toJson(), completedDelivery.toJson());
  });

  test('PURCHASERECEIVE exact fractional conversion rejects rounding and overflow', () {
    expect(goodsReceiptFixture(delivered: 1250, accepted: 1250, factor: 4).lines.single.acceptedStockUnits, 5);
    expect(goodsReceiptFixture(delivered: 1250, accepted: 1250, factor: 4).valid, isTrue);
    expect(goodsReceiptFixture(delivered: 1250, accepted: 1250).valid, isFalse);
    expect(goodsReceiptFixture(accepted: 5000).valid, isFalse);
    expect(goodsReceiptFixture(accepted: -1000).valid, isFalse);
    expect(goodsReceiptFixture(factor: 1000001).valid, isFalse);
    expect(goodsReceiptFixture(delivered: 2147483647, accepted: 2147483647,
      expected: null, factor: 1000000).valid, isFalse);
    expect(goodsReceiptFixture(prior: const {'original-stock': 7}).valid, isFalse);
  });

  test('PURCHASERECEIVE partial line mapping cannot switch product or units', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 0))!;
    final saved = opening.receiveGoods(goodsReceiptFixture(), expectedRevision: 1)!;
    expect(saved.receiveGoods(goodsReceiptFixture(id: 'receipt-B', product: 'different-product'),
      expectedRevision: 2), isNull);
    expect(saved.receiveGoods(goodsReceiptFixture(id: 'receipt-B', factor: 2),
      expectedRevision: 2), isNull);
    expect(saved.receiveGoods(goodsReceiptFixture(id: 'receipt-B', expected: null),
      expectedRevision: 2), isNull);
    final repeatChanged = goodsReceiptFixture(accepted: 5000, damaged: 1000);
    expect(saved.receiveGoods(repeatChanged, expectedRevision: 1), isNull);
    final dropped = WorkspaceSupplierLedger.fromJson({
      for (final entry in saved.toJson().entries)
        if (entry.key != 'goodsReceipts') entry.key: entry.value,
    })!;
    expect(dropped.canFollow(saved), isFalse);
    expect(WorkspaceSupplierLedger.fromJson({...saved.toJson(), 'goodsReceipts': null}), isNull);
  });

  test('PURCHASERECEIVE stock increment and receipt proof must commit together', () {
    final receipt = goodsReceiptFixture();
    final opening = confirmedOpeningFixture(openingFixture(amount: 0))!;
    final saved = opening.receiveGoods(receipt, expectedRevision: 1)!;
    final movement = receipt.movementFor(receipt.lines.single)!;
    WorkspaceLedgerCheckpoint checkpoint(WorkspaceSupplierLedger ledger,
      List<WorkspaceStockMovement> movements) => WorkspaceLedgerCheckpoint(
        revision: 1, finance: receiptFinanceFixture(), inventory: receiptInventoryFixture(movements),
        supplierLedgers: {ledger.supplierId: ledger});
    expect(checkpoint(saved, [movement]).valid, isTrue);
    expect(checkpoint(saved, const []).valid, isFalse);
    expect(checkpoint(opening, [movement]).valid, isFalse);
    final changed = WorkspaceStockMovement(id: movement.id, productId: movement.productId,
      productLabel: movement.productLabel, kind: movement.kind, quantityDelta: 5,
      reason: movement.reason, occurredAt: movement.occurredAt,
      referenceKind: movement.referenceKind, referenceId: movement.referenceId);
    expect(checkpoint(saved, [changed]).valid, isFalse);
  });

  test('PURCHASERECEIVE prior stock links exactly once and survives subsequent sales', () {
    final receipt = goodsReceiptFixture(prior: const {'original-stock': 4});
    final opening = confirmedOpeningFixture(openingFixture(amount: 0))!;
    final saved = opening.receiveGoods(receipt, expectedRevision: 1)!;
    final original = originalGoodsFixture();
    final addition = receipt.movementFor(receipt.lines.single)!;
    expect(addition.quantityDelta, 2);
    final sale = WorkspaceStockMovement(id: 'later-sale', productId: original.productId,
      productLabel: original.productLabel, kind: WorkspaceStockMovementKind.sale,
      quantityDelta: -8, reason: 'Counter sale', occurredAt: DateTime.utc(2026, 10, 3));
    final inventory = receiptInventoryFixture([original, sale, addition]);
    final checkpoint = WorkspaceLedgerCheckpoint(revision: 1, finance: receiptFinanceFixture(),
      inventory: inventory, supplierLedgers: {saved.supplierId: saved});
    expect(checkpoint.valid, isTrue);
    expect(inventory.quantities!['saved-product-A'], 4);
    final fullyLinked = goodsReceiptFixture(prior: const {'original-stock': 6});
    expect(fullyLinked.movementFor(fullyLinked.lines.single), isNull);
    final linkedLedger = opening.receiveGoods(fullyLinked, expectedRevision: 1)!;
    expect(WorkspaceLedgerCheckpoint(revision: 1, finance: receiptFinanceFixture(),
      inventory: receiptInventoryFixture([original, sale]),
      supplierLedgers: {linkedLedger.supplierId: linkedLedger}).valid, isTrue);
  });

  test('PURCHASERECEIVE prior movement cannot be overallocated or claimed from platform receipt', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 0))!;
    final first = goodsReceiptFixture(prior: const {'original-stock': 6});
    final second = goodsReceiptFixture(id: 'receipt-B', prior: const {'original-stock': 6});
    final saved = opening.receiveGoods(first, expectedRevision: 1)!
      .receiveGoods(second, expectedRevision: 2)!;
    WorkspaceLedgerCheckpoint checkpoint(WorkspaceSupplierLedger ledger,
      WorkspaceStockMovement original) => WorkspaceLedgerCheckpoint(revision: 1,
        finance: receiptFinanceFixture(), inventory: receiptInventoryFixture([original]),
        supplierLedgers: {ledger.supplierId: ledger});
    expect(checkpoint(saved, originalGoodsFixture()).valid, isFalse);
    final one = opening.receiveGoods(first, expectedRevision: 1)!;
    expect(checkpoint(one, originalGoodsFixture(referenceKind: WorkspaceStockReferenceKind.supplierReceipt)).valid, isFalse);
    expect(checkpoint(one, originalGoodsFixture(id: 'other-movement')).valid, isFalse);
  });

  test('PURCHASEPOST confirmed opening distinguishes zero dues and advance', () {
    for (final (amount, credit, balance) in [
      (0, false, 0),
      (50000, false, 50000),
      (50000, true, -50000),
    ]) {
      final record = openingFixture(amount: amount, credit: credit);
      final ledger = confirmedOpeningFixture(record)!;
      expect(ledger.valid, isTrue);
      expect(ledger.balanceMinor, balance);
      expect(ledger.entries, isEmpty);
      expect(ledger.openingRecord!.toJson(), record.toJson());
      final restored = WorkspaceSupplierLedger.fromJson(
        jsonDecode(jsonEncode(ledger.toJson())),
      )!;
      expect(restored.toJson(), ledger.toJson());
      expect(restored.payableMinor, credit ? 0 : amount);
      expect(restored.creditMinor, credit ? amount : 0);
    }
  });

  test('PURCHASEPOST unknown opening and unreviewed inclusion cannot post', () {
    expect(confirmedOpeningFixture(openingFixture()), isNull);
    final known = openingFixture(amount: 50000);
    expect(confirmedOpeningFixture(known, account: 'account-B'), isNull);
    expect(confirmedOpeningFixture(known, store: 'store-B'), isNull);
    expect(confirmedOpeningFixture(known, supplier: 'supplier-B'), isNull);
    expect(confirmedOpeningFixture(known, qa: false), isNull);
    expect(confirmedOpeningFixture(known, at: DateTime.utc(2026, 10, 1)), isNull);
    final unreviewed = openingFixture(amount: 50000, bills: [
      const WorkspaceOpeningBillLink(
        copyId: 'reviewed-copy-A', copyRevision: 2,
        draftId: 'manual-draft-A',
        inclusion: WorkspaceOpeningBillInclusion.unknown,
      ),
    ]);
    expect(confirmedOpeningFixture(unreviewed), isNull);
  });

  test('PURCHASEPOST opening proof prevents duplicate liability and rewriting', () {
    final record = openingFixture(amount: 50000);
    final opening = confirmedOpeningFixture(record)!;
    final bill = WorkspaceSupplierLedgerEntry(
      operationId: 'included-bill-operation',
      origin: WorkspaceSupplierEntryOrigin.manualPurchase,
      purchaseId: 'reviewed-copy-A',
      billId: 'supplier-bill-A', reference: 'SUPPLIER-INV-A',
      kind: WorkspaceSupplierEntryKind.bill,
      amountMinor: 50000, postedAt: DateTime.utc(2026, 10, 3),
    );
    expect(opening.appendConfirmed(bill, expectedRevision: 1), isNull);
    final duplicate = {...opening.toJson(), 'entries': [bill.toJson()]};
    expect(WorkspaceSupplierLedger.fromJson(duplicate), isNull);
    final excluded = openingFixture(amount: 50000, bills: [
      const WorkspaceOpeningBillLink(copyId: 'reviewed-copy-A',
        copyRevision: 2, draftId: 'manual-draft-A',
        inclusion: WorkspaceOpeningBillInclusion.excluded),
    ]);
    final separate = confirmedOpeningFixture(excluded)!;
    final posted = separate.appendConfirmed(bill, expectedRevision: 1)!;
    expect(posted.balanceMinor, 100000);
    expect(posted.openingRecord!.toJson(), excluded.toJson());
    expect(posted.appendConfirmed(bill, expectedRevision: 1), same(posted));
    final lostProof = WorkspaceSupplierLedger.fromJson({
      ...posted.toJson(), 'openingRecord': null,
    });
    expect(lostProof, isNull);
    final legacyWithoutProof = WorkspaceSupplierLedger.fromJson({
      for (final entry in posted.toJson().entries)
        if (entry.key != 'openingRecord') entry.key: entry.value,
    })!;
    expect(legacyWithoutProof.canFollow(posted), isFalse);
    final changedProof = WorkspaceSupplierLedger.fromJson({
      ...posted.toJson(),
      'openingRecord': {...excluded.toJson(), 'sourceNote': 'Changed later'},
    })!;
    expect(changedProof.canFollow(posted), isFalse);
    expect(WorkspaceSupplierLedger.fromJson({
      ...opening.toJson(), 'openingBalanceMinor': 0,
    }), isNull);
  });

  test('PURCHASEPOST later copy cannot repost a bill included in opening balance', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 50000))!;
    final laterCopy = WorkspaceSupplierLedgerEntry(
      operationId: 'later-copy-operation',
      origin: WorkspaceSupplierEntryOrigin.manualPurchase,
      purchaseId: 'reviewed-copy-A-revision-3',
      billId: 'manual-draft-A',
      reference: 'SUPPLIER-INV-A',
      kind: WorkspaceSupplierEntryKind.bill,
      amountMinor: 50000,
      postedAt: DateTime.utc(2026, 10, 3),
    );
    expect(opening.appendConfirmed(laterCopy, expectedRevision: 1), isNull);
    expect(WorkspaceSupplierLedger.fromJson({
      ...opening.toJson(), 'entries': [laterCopy.toJson()],
    }), isNull);
    final excluded = confirmedOpeningFixture(openingFixture(amount: 50000,
      bills: [const WorkspaceOpeningBillLink(copyId: 'reviewed-copy-A',
        copyRevision: 2, draftId: 'manual-draft-A',
        inclusion: WorkspaceOpeningBillInclusion.excluded)]))!;
    final posted = excluded.appendConfirmed(laterCopy, expectedRevision: 1)!;
    expect(posted.balanceMinor, 100000);
    final nextCopy = WorkspaceSupplierLedgerEntry(
      operationId: 'next-copy-operation',
      origin: WorkspaceSupplierEntryOrigin.manualPurchase,
      purchaseId: 'reviewed-copy-A-revision-4',
      billId: laterCopy.billId, reference: laterCopy.reference,
      kind: laterCopy.kind, amountMinor: laterCopy.amountMinor,
      postedAt: laterCopy.postedAt,
    );
    expect(posted.appendConfirmed(nextCopy, expectedRevision: 2), isNull);
    expect(posted.appendConfirmed(laterCopy, expectedRevision: 1), same(posted));
    expect(posted.openingRecord!.toJson(), excluded.openingRecord!.toJson());
  });

  WorkspaceSupplierBillAcceptance acceptanceFixture({
    String id = 'reviewed-copy-A', String draftId = 'manual-draft-A',
    String date = '2026-09-30', String total = '500.00',
    String reference = 'EVAL-P-001',
    WorkspaceOpeningBillInclusion treatment = WorkspaceOpeningBillInclusion.included,
  }) {
    final base = copyFixture();
    final draft = WorkspacePurchaseEntryDraft.fromJson({...base.draft.toJson(),
      'id': draftId, 'invoiceDate': date, 'invoiceReference': reference,
      'details': {'invoiceTotal': total}});
    return WorkspaceSupplierBillAcceptance(copy: WorkspacePurchaseSavedCopy(
      id: id, storeName: base.storeName, revision: base.revision,
      savedAt: base.savedAt, supplier: base.supplier, draft: draft, labels: base.labels),
      acceptedAt: DateTime.utc(2026, 10, 3), openingTreatment: treatment);
  }

  for (final date in ['2026-09-30', '2026-10-01']) {
    for (final treatment in [WorkspaceOpeningBillInclusion.included, WorkspaceOpeningBillInclusion.excluded]) {
      test('PURCHASELATE $date ${treatment.name} freezes reviewed opening classification', () {
        // Host-only accounting fixtures, not physical-device evaluation records.
        final opening = confirmedOpeningFixture(openingFixture(amount: 50000, bills: const []))!;
        final base = acceptanceFixture(date: date, treatment: treatment);
        final proof = WorkspaceSupplierBillOpeningReview(openingId: opening.openingRecord!.id,
          openingRevision: opening.openingRecord!.revision, treatment: treatment);
        WorkspaceSupplierBillAcceptance bill(WorkspaceSupplierBillOpeningReview review) =>
          WorkspaceSupplierBillAcceptance(copy: base.copy, acceptedAt: base.acceptedAt,
            openingTreatment: treatment, openingReview: review);
        expect(opening.acceptReviewedBill(base, expectedRevision: 1), isNull);
        final posted = opening.acceptReviewedBill(bill(proof), expectedRevision: 1)!;
        expect(posted.balanceMinor, treatment == WorkspaceOpeningBillInclusion.included ? 50000 : 100000);
        expect(posted.openingRecord!.toJson(), opening.openingRecord!.toJson());
        expect(posted.goodsReceipts, isEmpty);
        expect(posted.billGoodsAllocations, isEmpty);
        expect(posted.entries.where((e) => e.kind == WorkspaceSupplierEntryKind.payment), isEmpty);
        expect(WorkspaceSupplierLedger.fromJson(posted.toJson())!.toJson(), posted.toJson());
        expect(posted.acceptReviewedBill(bill(proof), expectedRevision: 1), same(posted));
        final wrongId = WorkspaceSupplierBillOpeningReview(openingId: 'another-opening',
          openingRevision: proof.openingRevision, treatment: treatment);
        final wrongRevision = WorkspaceSupplierBillOpeningReview(openingId: proof.openingId,
          openingRevision: proof.openingRevision + 1, treatment: treatment);
        for (final wrong in [wrongId, wrongRevision]) {
          expect(opening.acceptReviewedBill(bill(wrong), expectedRevision: 1), isNull);
          expect(posted.acceptReviewedBill(bill(wrong), expectedRevision: 2), isNull);
        }
        final linkedOpening = confirmedOpeningFixture(openingFixture(amount: 50000))!;
        final conflict = WorkspaceSupplierBillAcceptance(copy: base.copy, acceptedAt: base.acceptedAt,
          openingTreatment: WorkspaceOpeningBillInclusion.excluded,
          openingReview: WorkspaceSupplierBillOpeningReview(openingId: linkedOpening.openingRecord!.id,
            openingRevision: linkedOpening.openingRecord!.revision, treatment: WorkspaceOpeningBillInclusion.excluded));
        expect(linkedOpening.acceptReviewedBill(conflict, expectedRevision: 1), isNull,
          reason: 'A new review cannot bypass an existing included assertion.');
        expect(WorkspaceSupplierBillAcceptance.fromJson(bill(proof).toJson()).toJson(), bill(proof).toJson());
        expect(WorkspaceSupplierBillAcceptance.fromJson(base.toJson()).toJson(), base.toJson(),
          reason: 'Legacy documents omit the optional proof key unchanged.');
      });
    }
  }

  test('PURCHASEPOST included and zero bills retain acceptance without new debt', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 50000))!;
    final bill = acceptanceFixture();
    final posted = opening.acceptReviewedBill(bill, expectedRevision: 1)!;
    expect(posted.balanceMinor, 50000);
    expect(posted.entries, isEmpty);
    expect(posted.purchaseBills.values.single.copy.toJson(), bill.copy.toJson());
    expect(posted.acceptReviewedBill(bill, expectedRevision: 1), same(posted));
    final zero = acceptanceFixture(id: 'free-copy', draftId: 'free-bill',
      date: '2026-10-02', total: '0', reference: 'FREE-1',
      treatment: WorkspaceOpeningBillInclusion.excluded);
    final next = posted.acceptReviewedBill(zero, expectedRevision: 2)!;
    expect(next.entries, isEmpty);
    expect(next.purchaseBills.length, 2);
    expect(next.balanceMinor, 50000);
    expect(WorkspaceSupplierLedger.fromJson(next.toJson())!.toJson(), next.toJson());
  });

  test('PURCHASEPOST excluded bill posts exact debt and newer copy cannot repost', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!;
    final bill = acceptanceFixture(id: 'new-copy', draftId: 'new-bill',
      date: '02/10/2026', total: '2840.75',
      treatment: WorkspaceOpeningBillInclusion.excluded);
    final posted = opening.acceptReviewedBill(bill, expectedRevision: 1)!;
    expect(posted.balanceMinor, 284075);
    expect(posted.entries.single.purchaseId, 'new-copy');
    expect(posted.entries.single.billId, 'new-bill');
    expect(posted.entries.single.orderId, isNull);
    final changed = acceptanceFixture(id: 'newer-copy', draftId: 'new-bill',
      date: '02/10/2026', total: '2840.75',
      treatment: WorkspaceOpeningBillInclusion.excluded);
    expect(posted.acceptReviewedBill(changed, expectedRevision: 2), isNull);
    final duplicateNumber = acceptanceFixture(id: 'another-copy', draftId: 'another-bill',
      date: '02/10/2026', total: '2840.75',
      treatment: WorkspaceOpeningBillInclusion.excluded);
    expect(posted.acceptReviewedBill(duplicateNumber, expectedRevision: 2), isNull);
    expect(opening.acceptReviewedBill(bill, expectedRevision: 2), isNull);
  });

  test('PURCHASEPOST acceptance cannot omit or change its linked debt', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!;
    final bill = acceptanceFixture(id: 'new-copy', draftId: 'new-bill',
      date: '2026-10-02', treatment: WorkspaceOpeningBillInclusion.excluded);
    final posted = opening.acceptReviewedBill(bill, expectedRevision: 1)!;
    expect(WorkspaceSupplierLedger.fromJson({...posted.toJson(), 'entries': []}), isNull);
    expect(WorkspaceSupplierLedger.fromJson({...posted.toJson(),
      'entries': [{...posted.entries.single.toJson(), 'amountMinor': 49999}]}), isNull);
    final dropped = WorkspaceSupplierLedger.fromJson({
      for (final entry in posted.toJson().entries)
        if (entry.key != 'purchaseBills') entry.key: entry.value,
    })!;
    expect(dropped.canFollow(posted), isFalse);
    final payment = WorkspaceSupplierLedgerEntry(operationId: 'supplier-payment',
      reference: 'PAY-1', origin: WorkspaceSupplierEntryOrigin.supplierAccount,
      kind: WorkspaceSupplierEntryKind.payment, amountMinor: 1000,
      paymentMethod: 'Cash', postedAt: DateTime.utc(2026, 10, 3),
      moneyReview: WorkspaceSupplierMoneyReview(occurredOn: '2026-10-03',
        openingId: opening.openingRecord!.id,
        openingRevision: opening.openingRecord!.revision, notIncludedInOpening: true));
    final next = posted.appendConfirmed(payment, expectedRevision: 2)!;
    expect(next.purchaseBills['new-bill']!.toJson(), bill.toJson());
    expect(next.balanceMinor, 49000);
  });

  test('PURCHASEPOST old bills need exact cutoff proof; unknown is not zero', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!;
    expect(opening.acceptReviewedBill(acceptanceFixture(), expectedRevision: 1), isNull);
    expect(opening.acceptReviewedBill(acceptanceFixture(date: '2026-10-01',
      treatment: WorkspaceOpeningBillInclusion.excluded), expectedRevision: 1), isNull);
    expect(opening.acceptReviewedBill(acceptanceFixture(date: '2026-10-02'),
      expectedRevision: 1), isNull);
    expect(opening.acceptReviewedBill(acceptanceFixture(date: '2026-10-04',
      treatment: WorkspaceOpeningBillInclusion.excluded), expectedRevision: 1), isNull);
    expect(acceptanceFixture(total: '').valid, isFalse);
    expect(acceptanceFixture(total: '-1').valid, isFalse);
    expect(acceptanceFixture(date: '31/02/2026').valid, isFalse);
    expect(acceptanceFixture(treatment: WorkspaceOpeningBillInclusion.unknown).valid, isFalse);
  });

  WorkspaceSupplierBillMoneyAllocation moneyAllocationFixture(WorkspaceSupplierLedger ledger,
      WorkspaceSupplierBillAcceptance bill, {String id = 'money-link-A', int amount = 10000,
      WorkspaceSupplierMoneySourceKind kind = WorkspaceSupplierMoneySourceKind.openingAdvance,
      String? source}) => WorkspaceSupplierBillMoneyAllocation(operationId: id,
    accountScope: ledger.accountScope, workspaceId: ledger.workspaceId, supplierId: ledger.supplierId,
    sourceKind: kind, sourceId: source ?? ledger.openingRecord!.id,
    openingId: ledger.openingRecord!.id, openingRevision: ledger.openingRecord!.revision,
    billId: bill.billId, copyId: bill.copy.id, copyRevision: bill.copy.revision,
    amountMinor: amount, committedRevision: ledger.revision + 1,
    requestedAt: DateTime.utc(2026, 10, 3),
    recordedAt: DateTime.utc(2026, 10, 3));

  test('PURCHASEALLOC local bill timestamp survives UTC checkpoint recovery', () {
    // Host-only regression: never creates phone evaluation records.
    final opening = confirmedOpeningFixture(openingFixture(
      amount: 50000, credit: true, bills: const []))!;
    final base = acceptanceFixture(total: '230', date: '2026-10-02',
      treatment: WorkspaceOpeningBillInclusion.excluded);
    final bill = WorkspaceSupplierBillAcceptance(copy: base.copy,
      acceptedAt: base.acceptedAt.add(const Duration(hours: 1)).toLocal(),
      openingTreatment: base.openingTreatment);
    final live = opening.acceptReviewedBill(bill, expectedRevision: 1)!;
    final checkpoint = WorkspaceLedgerCheckpoint(revision: 1,
      finance: receiptFinanceFixture(), supplierLedgers: {live.supplierId: live});
    final saved = WorkspaceLedgerCheckpoint.fromJson(
      jsonDecode(jsonEncode(checkpoint.toJson())))!.supplierLedgers[live.supplierId]!;
    expect(live.asOf.isUtc, isFalse);
    expect(saved.asOf.isUtc, isTrue);
    expect(saved.canFollow(live), isTrue);
    expect(live.canFollow(saved), isTrue);
    expect(saved.manualBillRemainingMinor(bill.billId), 23000);
    expect(saved.creditMinor, 27000);
    expect(saved.entries.length, live.entries.length);
    expect(saved.goodsReceipts, isEmpty);
    final changedTime = WorkspaceSupplierLedger.fromJson({...saved.toJson(),
      'asOf': saved.asOf.add(const Duration(microseconds: 1)).toIso8601String()})!;
    expect(changedTime.canFollow(live), isFalse);
    final changedName = WorkspaceSupplierLedger.fromJson({...saved.toJson(),
      'supplierName': 'Different supplier name'})!;
    expect(changedName.canFollow(live), isFalse);
  });

  test('PURCHASEALLOC opening advance with zero net credit links without another money fact', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 50000, credit: true, bills: const []))!;
    final bill = acceptanceFixture(id: 'allocated-copy', draftId: 'allocated-bill',
      date: '2026-10-02', treatment: WorkspaceOpeningBillInclusion.excluded);
    final accepted = opening.acceptReviewedBill(bill, expectedRevision: 1)!;
    expect(accepted.balanceMinor, 0);
    expect(accepted.creditMinor, 0);
    final link = moneyAllocationFixture(accepted, bill, amount: 50000);
    final allocated = accepted.allocateRecordedMoney(link, expectedRevision: 2)!;
    expect(allocated.balanceMinor, 0);
    expect(allocated.entries.map((e) => e.toJson()).toList(), accepted.entries.map((e) => e.toJson()).toList());
    expect(allocated.goodsReceipts, accepted.goodsReceipts);
    expect(allocated.manualBillRemainingMinor(bill.billId), 0);
    expect(allocated.unallocatedMoneyMinor(link.sourceKind, link.sourceId), 0);
    expect(allocated.allocateRecordedMoney(link, expectedRevision: 2), same(allocated));
    expect(WorkspaceSupplierLedger.fromJson(allocated.toJson())!.toJson(), allocated.toJson());
    final changed = WorkspaceSupplierBillMoneyAllocation.fromJson({...link.toJson(), 'amountMinor': 49999});
    expect(allocated.allocateRecordedMoney(changed, expectedRevision: 2), isNull);
    final dropped = WorkspaceSupplierLedger.fromJson({...allocated.toJson(), 'billMoneyAllocations': {}})!;
    expect(dropped.canFollow(allocated), isFalse);
  });

  test('PURCHASEALLOC account payment attribution does not pretend opening dues stayed settled', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 10000, bills: const []))!;
    final money = WorkspaceSupplierLedgerEntry(operationId: 'account-paid-opening', reference: 'HOST-ACCOUNT-PAY',
      origin: WorkspaceSupplierEntryOrigin.supplierAccount, kind: WorkspaceSupplierEntryKind.payment,
      amountMinor: 10000, paymentMethod: 'Cash', postedAt: DateTime.utc(2026, 10, 3),
      moneyReview: WorkspaceSupplierMoneyReview(occurredOn: '2026-10-03',
        openingId: opening.openingRecord!.id, openingRevision: opening.openingRecord!.revision,
        notIncludedInOpening: true));
    final paid = opening.recordReviewedMoney(money, expectedRevision: 1)!;
    expect(paid.balanceMinor, 0);
    final bill = acceptanceFixture(id: 'later-copy', draftId: 'later-bill', total: '100',
      date: '2026-10-02', treatment: WorkspaceOpeningBillInclusion.excluded);
    final accepted = paid.acceptReviewedBill(bill, expectedRevision: 2)!;
    final link = moneyAllocationFixture(accepted, bill,
      kind: WorkspaceSupplierMoneySourceKind.accountPayment, source: money.operationId);
    final linked = accepted.allocateRecordedMoney(link, expectedRevision: 3)!;
    expect(linked.manualBillRemainingMinor(bill.billId), 0);
    expect(linked.payableMinor, 10000, reason: 'Attribution moves no money; the aggregate remaining account dues persist.');
    expect(linked.unassignedAccountBalanceMinor, 10000);
    expect(linked.entries.length, accepted.entries.length);
    final wrong = WorkspaceSupplierBillMoneyAllocation.fromJson({...link.toJson(), 'sourceKind': 'accountAdvance'});
    expect(accepted.allocateRecordedMoney(wrong, expectedRevision: 3), isNull);
    expect(accepted.allocateRecordedMoney(WorkspaceSupplierBillMoneyAllocation.fromJson(
      {...link.toJson(), 'supplierId': 'different-supplier'}), expectedRevision: 3), isNull);
  });

  test('PURCHASEALLOC split source exhaustion and subsequent constructors retain attribution', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 10000, credit: true, bills: const []))!;
    final a = acceptanceFixture(id: 'split-copy-A', draftId: 'split-bill-A', reference: 'SPLIT-A', total: '60',
      date: '2026-10-02', treatment: WorkspaceOpeningBillInclusion.excluded);
    final b = acceptanceFixture(id: 'split-copy-B', draftId: 'split-bill-B', reference: 'SPLIT-B', total: '60',
      date: '2026-10-02', treatment: WorkspaceOpeningBillInclusion.excluded);
    final billed = opening.acceptReviewedBill(a, expectedRevision: 1)!.acceptReviewedBill(b, expectedRevision: 2)!;
    final first = billed.allocateRecordedMoney(moneyAllocationFixture(billed, a, amount: 6000), expectedRevision: 3)!;
    final secondLink = moneyAllocationFixture(first, b, id: 'money-link-B', amount: 4000);
    final second = first.allocateRecordedMoney(secondLink, expectedRevision: 4)!;
    expect(second.balanceMinor, billed.balanceMinor);
    expect(second.manualBillRemainingMinor(a.billId), 0);
    expect(second.manualBillRemainingMinor(b.billId), 2000);
    final reversed = WorkspaceSupplierLedger.fromJson({...second.toJson(), 'billMoneyAllocations': {
      for (final entry in second.billMoneyAllocations.entries.toList().reversed) entry.key: entry.value.toJson()}})!;
    expect(reversed.manualBillRemainingMinor(b.billId), 2000);
    expect(reversed.unallocatedMoneyMinor(secondLink.sourceKind, secondLink.sourceId), 0);
    expect(second.allocateRecordedMoney(moneyAllocationFixture(second, b, id: 'overdraw-source', amount: 1),
      expectedRevision: 5), isNull);
    final goods = second.receiveGoods(goodsReceiptFixture(), expectedRevision: 5)!;
    expect(goods.billMoneyAllocations.length, 2);
    final c = acceptanceFixture(id: 'split-copy-C', draftId: 'split-bill-C', reference: 'SPLIT-C', total: '60',
      date: '2026-10-02', treatment: WorkspaceOpeningBillInclusion.excluded);
    expect(goods.acceptReviewedBill(c, expectedRevision: 6)!.billMoneyAllocations.length, 2);
    final forged = WorkspaceSupplierBillMoneyAllocation.fromJson({...secondLink.toJson(),
      'operationId': 'forged-revision', 'committedRevision': 99});
    expect(first.allocateRecordedMoney(forged, expectedRevision: 4), isNull);
    expect(second.canFollow(opening), isFalse,
      reason: 'A generic save cannot introduce sources/bills and their allocation in one transition.');
  });

  for (final paymentFirst in [false, true]) {
    test('PURCHASEALLOC direct payment and allocation cannot overfill in either order paymentFirst=$paymentFirst', () {
      final opening = confirmedOpeningFixture(openingFixture(amount: 50000, bills: const []))!;
      final advance = WorkspaceSupplierLedgerEntry(operationId: 'allocation-advance', reference: 'HOST-ADV',
        origin: WorkspaceSupplierEntryOrigin.supplierAccount, kind: WorkspaceSupplierEntryKind.advance,
        amountMinor: 10000, paymentMethod: 'Cash', postedAt: DateTime.utc(2026, 10, 3),
        moneyReview: WorkspaceSupplierMoneyReview(occurredOn: '2026-10-03',
          openingId: opening.openingRecord!.id, openingRevision: opening.openingRecord!.revision,
          notIncludedInOpening: true));
      final advanced = opening.recordReviewedMoney(advance, expectedRevision: 1)!;
      final bill = acceptanceFixture(id: 'overfill-copy', draftId: 'overfill-bill', total: '500',
        date: '2026-10-02', treatment: WorkspaceOpeningBillInclusion.excluded);
      final billed = advanced.acceptReviewedBill(bill, expectedRevision: 2)!;
      WorkspaceSupplierLedgerEntry payment(int amount) => WorkspaceSupplierLedgerEntry(
        operationId: 'direct-overfill-payment', reference: 'HOST-DIRECT',
        origin: WorkspaceSupplierEntryOrigin.manualPurchase, purchaseId: bill.copy.id, billId: bill.billId,
        kind: WorkspaceSupplierEntryKind.payment, amountMinor: amount, paymentMethod: 'Cash',
        postedAt: DateTime.utc(2026, 10, 3), moneyReview: advance.moneyReview);
      WorkspaceSupplierBillMoneyAllocation link(WorkspaceSupplierLedger owner) => moneyAllocationFixture(owner, bill,
        kind: WorkspaceSupplierMoneySourceKind.accountAdvance, source: advance.operationId);
      if (paymentFirst) {
        final paid = billed.recordReviewedMoney(payment(45000), expectedRevision: 3)!;
        expect(paid.allocateRecordedMoney(link(paid), expectedRevision: 4), isNull);
        expect(paid.manualBillRemainingMinor(bill.billId), 5000);
      } else {
        final allocated = billed.allocateRecordedMoney(link(billed), expectedRevision: 3)!;
        expect(allocated.recordReviewedMoney(payment(45000), expectedRevision: 4), isNull);
        final paid = allocated.recordReviewedMoney(payment(40000), expectedRevision: 4)!;
        expect(paid.manualBillRemainingMinor(bill.billId), 0);
        expect(paid.billMoneyAllocations.length, 1);
        expect(paid.unassignedAccountBalanceMinor, paid.balanceMinor);
      }
    });
  }

  WorkspaceSupplierRefundIntent refundIntentFixture(WorkspaceSupplierLedger ledger, {
    WorkspaceSupplierRefundSourceKind kind = WorkspaceSupplierRefundSourceKind.openingAdvance,
    String? source, WorkspaceSupplierBillAcceptance? bill,
  }) => WorkspaceSupplierRefundIntent(operationId: 'refund-reviewed',
    accountScope: ledger.accountScope, workspaceId: ledger.workspaceId,
    supplierId: ledger.supplierId, qa: ledger.openingRecord!.qa,
    sourceKind: kind, sourceId: source ?? ledger.openingRecord!.id,
    openingId: ledger.openingRecord!.id, openingRevision: ledger.openingRecord!.revision,
    reference: 'HOST-REFUND-1', occurredOn: '2026-10-03', paymentMethod: 'Cash',
    amountMinor: 1000, requestedAt: ledger.asOf,
    copyId: bill?.copy.id, copyRevision: bill?.copy.revision);

  test('PURCHASEREFUND frozen review binds source scope date and no commit proof', () {
    final ledger = confirmedOpeningFixture(openingFixture(amount: 50000, credit: true))!;
    final intent = refundIntentFixture(ledger);
    expect(intent.valid, isTrue);
    expect(WorkspaceSupplierRefundIntent.fromJson(jsonDecode(jsonEncode(intent.toJson()))).toJson(),
      intent.toJson());
    for (final mutation in <Map<String, Object?>>[
      {'operationId': ''}, {'reference': ' padded'}, {'amountMinor': 0},
      {'occurredOn': '2026-02-30'}, {'occurredOn': '2026-10-04'},
      {'openingRevision': 0}, {'paymentMethod': 'unknown'}, {'copyId': 'unrelated'},
      {'sourceKind': 'manualBillSurplus'}, {'committedRevision': 2}, {'recordedAt': '2026-10-03'},
    ]) {
      expect(() => WorkspaceSupplierRefundIntent.fromJson({...intent.toJson(), ...mutation}),
        throwsA(anything));
    }
    final missing = {...intent.toJson()}..remove('qa');
    expect(() => WorkspaceSupplierRefundIntent.fromJson(missing), throwsFormatException);
  });

  test('PURCHASEREFUND opening capacity is shared with bill allocations without mutation', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 50000,
      credit: true, bills: const []))!;
    expect(opening.reviewedRefundCapacity(refundIntentFixture(opening)), 50000);
    final bill = acceptanceFixture(id: 'refund-copy', draftId: 'refund-bill',
      date: '2026-10-02', treatment: WorkspaceOpeningBillInclusion.excluded);
    final billed = opening.acceptReviewedBill(bill, expectedRevision: 1)!;
    // The unassigned advance still exists, but net dues consume aggregate credit.
    expect(billed.reviewedRefundCapacity(refundIntentFixture(billed)), 0);
    final linked = billed.allocateRecordedMoney(moneyAllocationFixture(billed, bill,
      amount: 50000), expectedRevision: billed.revision)!;
    expect(linked.reviewedRefundCapacity(refundIntentFixture(linked)), 0);
    expect(linked.unallocatedMoneyMinor(WorkspaceSupplierMoneySourceKind.openingAdvance,
      opening.openingRecord!.id), 0);
    final before = jsonEncode(linked.toJson());
    linked.reviewedRefundCapacity(refundIntentFixture(linked));
    expect(jsonEncode(linked.toJson()), before);
    for (final mutation in <Map<String, Object?>>[
      {'accountScope': 'another'}, {'workspaceId': 'another'}, {'supplierId': 'another'},
      {'qa': !opening.openingRecord!.qa}, {'openingId': 'another'},
      {'openingRevision': 99}, {'sourceId': 'missing'},
      {'requestedAt': opening.asOf.subtract(const Duration(days: 1)).toIso8601String(),
        'occurredOn': '2026-10-02'},
    ]) {
      expect(linked.reviewedRefundCapacity(WorkspaceSupplierRefundIntent.fromJson(
        {...refundIntentFixture(linked).toJson(), ...mutation})), isNull);
    }
  });

  test('PURCHASEREFUND reviewed advance is exact source not a platform order or payment', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!;
    final advance = WorkspaceSupplierLedgerEntry(operationId: 'refund-advance', reference: 'ADV-R',
      origin: WorkspaceSupplierEntryOrigin.supplierAccount, paymentMethod: 'UPI',
      kind: WorkspaceSupplierEntryKind.advance, amountMinor: 10000,
      postedAt: DateTime.utc(2026, 10, 3, 12),
      moneyReview: WorkspaceSupplierMoneyReview(occurredOn: '2026-10-03',
        openingId: opening.openingRecord!.id, openingRevision: opening.openingRecord!.revision,
        notIncludedInOpening: true));
    final ledger = opening.recordReviewedMoney(advance, expectedRevision: opening.revision)!;
    final intent = refundIntentFixture(ledger,
      kind: WorkspaceSupplierRefundSourceKind.accountAdvance, source: advance.operationId);
    expect(ledger.reviewedRefundCapacity(intent), 10000);
    expect(ledger.reviewedRefundCapacity(WorkspaceSupplierRefundIntent.fromJson(
      {...intent.toJson(), 'occurredOn': '2026-10-02'})), isNull,
      reason: 'Refund date cannot precede the actual funding advance.');
    expect(WorkspaceSupplierLedger.fromJson(ledger.toJson())!.reviewedRefundCapacity(intent), 10000);
    expect(ledger.reviewedRefundCapacity(refundIntentFixture(ledger,
      kind: WorkspaceSupplierRefundSourceKind.accountAdvance, source: 'unverified')), isNull);
    expect(ledger.goodsReceipts, isEmpty);
    expect(ledger.entries, hasLength(1));
  });

  test('PURCHASEREFUND native posting consumes advance once and exact retry precedes capacity', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 10000,
      credit: true, bills: const []))!;
    final intent = WorkspaceSupplierRefundIntent.fromJson(
      {...refundIntentFixture(opening).toJson(), 'amountMinor': 4000});
    final posted = opening.recordReviewedRefund(intent, expectedRevision: opening.revision,
      recordedAt: opening.asOf)!;
    expect(posted.balanceMinor, -6000);
    expect(posted.unallocatedMoneyMinor(WorkspaceSupplierMoneySourceKind.openingAdvance,
      opening.openingRecord!.id), 6000);
    expect(posted.entries.single.kind, WorkspaceSupplierEntryKind.refund);
    expect(posted.entries.single.payableDeltaMinor, 4000);
    expect(posted.refunds, hasLength(1));
    expect(posted.goodsReceipts, isEmpty);
    expect(posted.goodsReturns, isEmpty);
    expect(posted.recordReviewedRefund(intent, expectedRevision: 1,
      recordedAt: opening.asOf.add(const Duration(days: 1))), same(posted));
    final restored = WorkspaceSupplierLedger.fromJson(jsonDecode(jsonEncode(posted.toJson())))!;
    expect(restored.toJson(), posted.toJson());
    expect(restored.recordReviewedRefund(intent, expectedRevision: 1,
      recordedAt: opening.asOf), same(restored));
    final changed = WorkspaceSupplierRefundIntent.fromJson({...intent.toJson(), 'amountMinor': 4001});
    expect(restored.recordReviewedRefund(changed, expectedRevision: 1,
      recordedAt: opening.asOf), isNull);
    final secondIntent = WorkspaceSupplierRefundIntent.fromJson({...intent.toJson(),
      'operationId': 'second-refund', 'reference': 'REFUND-2', 'amountMinor': 2000});
    final second = restored.recordReviewedRefund(secondIntent, expectedRevision: restored.revision,
      recordedAt: restored.asOf)!;
    expect(second.creditMinor, 4000);
    expect(second.unallocatedMoneyMinor(WorkspaceSupplierMoneySourceKind.openingAdvance,
      opening.openingRecord!.id), 4000);
    expect(second.refunds, hasLength(2));
    expect(second.recordReviewedRefund(intent, expectedRevision: 1,
      recordedAt: opening.asOf), same(second));
    final excess = WorkspaceSupplierRefundIntent.fromJson({...intent.toJson(),
      'operationId': 'new-refund', 'reference': 'NEW-REFUND', 'amountMinor': 6001});
    expect(restored.recordReviewedRefund(excess, expectedRevision: restored.revision,
      recordedAt: restored.asOf), isNull);
    expect(restored.appendConfirmed(excess.commit(revision: restored.revision + 1,
      at: restored.asOf).entry, expectedRevision: restored.revision), isNull);
    expect(WorkspaceSupplierLedger.fromJson({...posted.toJson(),
      'refunds': {'wrong-key': posted.refunds.values.single.toJson()}}), isNull);
    expect(WorkspaceSupplierLedger.fromJson({...posted.toJson(), 'refunds': {
      intent.operationId: {...posted.refunds.values.single.toJson(),
        'intent': {...intent.toJson(), 'amountMinor': 4001}},
    }}), isNull);
    final legacy = WorkspaceSupplierLedger.fromJson({...posted.toJson(), 'refunds': {}})!;
    expect(legacy.entries.single.toJson(), posted.entries.single.toJson());
    expect(legacy.reviewedRefundCapacity(refundIntentFixture(legacy)), isNull,
      reason: 'Legacy unallocated refunds remain readable, not guessed source authority.');
    expect(legacy.canFollow(posted), isFalse);
  });

  StoreSupplierStatement supplierStatement(WorkspaceSupplierLedger ledger, {DateTime? from, DateTime? until}) =>
    StoreSupplierStatement(source: ledger, storeName: 'HOST evaluation Store', reviewOnly: true,
      from: from ?? DateTime(2026, 10, 1), until: until ?? DateTime(2026, 10, 4), generatedAt: DateTime.utc(2026, 10, 4));

  test('SUPPLIERSTATEMENT negative opening and backdated refund reconcile exact period', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 50000, credit: true, bills: const []))!;
    final intent = WorkspaceSupplierRefundIntent.fromJson({...refundIntentFixture(opening).toJson(),
      'amountMinor': 4000, 'occurredOn': '2026-10-02'});
    final posted = opening.recordReviewedRefund(intent, expectedRevision: 1, recordedAt: DateTime.utc(2026, 10, 3))!;
    final report = supplierStatement(posted, from: DateTime(2026, 10, 2), until: DateTime(2026, 10, 3));
    expect(report.opening, -50000); expect(report.addedMinor, 4000); expect(report.reducedMinor, 0);
    expect(report.closing, -46000); expect(report.entries.single.operationId, intent.operationId);
    expect(report.rows[1][0], '02/10/2026'); expect(report.rows[1][5], -460);
    expect(report.report.rows, report.rows);
    final later = supplierStatement(posted, from: DateTime(2026, 10, 3));
    expect(later.opening, -46000); expect(later.entries, isEmpty); expect(later.closing, -46000);
    expect(posted.entries.single.postedAt, DateTime.utc(2026, 10, 3));
    expect(report.reference, supplierStatement(posted, from: report.from, until: report.until).reference);
    expect(StoreSupplierStatement.amount(-12345678), '-₹1,23,456.78');
  });

  test('SUPPLIERSTATEMENT opening-included and zero bills retain evidence without new dues', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 50000))!;
    final accepted = opening.acceptReviewedBill(acceptanceFixture(), expectedRevision: 1)!;
    final report = supplierStatement(accepted);
    expect(report.opening, 50000); expect(report.closing, 50000); expect(report.entries, isEmpty);
    expect(report.addedMinor, 0); expect(report.rows.where((r) => r[1] == 'Supporting purchase bill'), hasLength(1));
    expect(report.rows.last[6], contains('Already in starting balance'));
    final zeroOpening = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!;
    final zero = acceptanceFixture(id: 'zero-copy', draftId: 'zero-bill', total: '0', date: '2026-10-02',
      treatment: WorkspaceOpeningBillInclusion.excluded);
    final zeroAccount = zeroOpening.acceptReviewedBill(zero, expectedRevision: 1)!;
    expect(supplierStatement(zeroAccount).rows.last[6], contains('Zero-value bill'));
    expect(supplierStatement(zeroAccount).closing, 0);
  });

  test('SUPPLIERSTATEMENT excluded historical bill is in opening not silently omitted or doubled', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 0, bills: const [
      WorkspaceOpeningBillLink(copyId: 'reviewed-copy-A', copyRevision: 2, draftId: 'manual-draft-A',
        inclusion: WorkspaceOpeningBillInclusion.excluded)]))!;
    final accepted = opening.acceptReviewedBill(acceptanceFixture(treatment: WorkspaceOpeningBillInclusion.excluded), expectedRevision: 1)!;
    final report = supplierStatement(accepted);
    expect(report.opening, 50000); expect(report.closing, 50000); expect(report.addedMinor, 0);
    expect(report.rows.last[1], 'Earlier adjustment'); expect(report.rows.last[2], 'EVAL-P-001');
    expect(report.rows.last[6], contains('included in report opening'));
    final before = supplierStatement(accepted, from: DateTime(2026, 9, 30));
    expect(before.opening, isNull);
    expect(before.rows.where((row) => row[1] == 'Earlier adjustment'), isEmpty);
    expect(before.entries, hasLength(1));
    expect(before.addedMinor, 50000);
  });

  test('SUPPLIERSTATEMENT advance allocation is information not another payment', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 50000, credit: true, bills: const []))!;
    final bill = acceptanceFixture(id: 'statement-copy', draftId: 'statement-bill', date: '2026-10-02',
      treatment: WorkspaceOpeningBillInclusion.excluded);
    final accepted = opening.acceptReviewedBill(bill, expectedRevision: 1)!;
    final allocated = accepted.allocateRecordedMoney(moneyAllocationFixture(accepted, bill, amount: 50000), expectedRevision: 2)!;
    final report = supplierStatement(allocated);
    expect(report.opening, -50000); expect(report.addedMinor, 50000); expect(report.reducedMinor, 0);
    expect(report.closing, 0); expect(report.entries, hasLength(1));
    expect(report.rows.last[1], 'Recorded money linked'); expect(report.rows.last[5], '');
    expect(report.rows.last[6], contains('no account-balance change'));
  });

  test('SUPPLIERSTATEMENT incomplete or before-coverage history never becomes zero balance', () {
    final legacy = WorkspaceSupplierLedger(accountScope: 'account-A', workspaceId: 'store-A',
      supplierId: 'legacy-supplier', supplierName: 'HOST legacy supplier', revision: 1,
      asOf: DateTime.utc(2026, 10, 3), historyComplete: false, entries: const []);
    final report = supplierStatement(legacy);
    expect(report.balancesReady, isFalse); expect(report.opening, isNull); expect(report.closing, isNull);
    expect(report.rows.first[5], isNull);
    expect(report.report.metadata.singleWhere((row) => row.first == 'Coverage').last, contains('balances unavailable'));
    final known = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!;
    expect(supplierStatement(known, from: DateTime(2026, 9, 30)).opening, isNull);
    expect(() => StoreSupplierStatement(source: known, storeName: 'HOST', reviewOnly: false,
      from: DateTime(2026, 10, 1), until: DateTime(2026, 10, 4), generatedAt: DateTime.utc(2026, 10, 4)), throwsFormatException);
  });

  test('PURCHASEREFUND statement uses received date and preserves recording date and legacy fallback', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 10000,
      credit: true, bills: const []))!;
    final intent = WorkspaceSupplierRefundIntent.fromJson({
      ...refundIntentFixture(opening).toJson(), 'occurredOn': '2026-10-01',
      'paymentMethod': 'Bank transfer', 'amountMinor': 4000,
    });
    final posted = opening.recordReviewedRefund(intent, expectedRevision: opening.revision,
      recordedAt: DateTime.utc(2026, 10, 3))!;
    final restored = WorkspaceSupplierLedger.fromJson(jsonDecode(jsonEncode(posted.toJson())))!;
    WorkspaceMoneyStatement statement(WorkspaceSupplierLedger owner, int day) =>
      WorkspaceMoneyStatement.fromLedgers(finance: receiptFinanceFixture(),
        suppliers: [owner], expenses: const [], start: DateTime(2026, 10, day),
        end: DateTime(2026, 10, day + 1))!;
    final received = statement(restored, 1);
    expect(received.entries, hasLength(1));
    expect(received.entries.single.label, 'Supplier refund');
    expect(received.entries.single.reference, intent.reference);
    expect(received.entries.single.method, 'Bank transfer');
    expect(received.entries.single.occurredAt, DateTime(2026, 10, 1));
    expect(received.recordedInMinor, 4000); expect(received.recordedOutMinor, 0);
    expect(statement(restored, 3).entries, isEmpty);
    expect(restored.entries.single.postedAt, DateTime.utc(2026, 10, 3));
    expect(restored.creditMinor, 6000);
    final legacy = WorkspaceSupplierLedger.fromJson({...posted.toJson(), 'refunds': {}})!;
    expect(statement(legacy, 1).entries, isEmpty);
    expect(statement(legacy, 3).recordedInMinor, 4000);
    expect(legacy.entries.single.toJson(), posted.entries.single.toJson());
  });

  test('PURCHASEREFUND allocation and refund share capacity in both commit orders', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 100000,
      credit: true, bills: const []))!;
    final bill = acceptanceFixture(id: 'refund-race-copy', draftId: 'refund-race-bill',
      date: '2026-10-02', treatment: WorkspaceOpeningBillInclusion.excluded);
    final billed = opening.acceptReviewedBill(bill, expectedRevision: 1)!;
    final intent = WorkspaceSupplierRefundIntent.fromJson(
      {...refundIntentFixture(billed).toJson(), 'amountMinor': 50000});
    for (final refundFirst in [true, false]) {
      var ledger = billed;
      if (refundFirst) {
        ledger = ledger.recordReviewedRefund(intent, expectedRevision: ledger.revision,
          recordedAt: ledger.asOf)!;
      }
      ledger = ledger.allocateRecordedMoney(moneyAllocationFixture(ledger, bill,
        amount: 50000), expectedRevision: ledger.revision)!;
      if (!refundFirst) {
        expect(ledger.recordReviewedRefund(intent, expectedRevision: billed.revision,
          recordedAt: ledger.asOf), isNull, reason: 'New posting requires a fresh ledger revision.');
        ledger = ledger.recordReviewedRefund(intent, expectedRevision: ledger.revision,
          recordedAt: ledger.asOf)!;
      }
      expect(ledger.balanceMinor, 0);
      expect(ledger.manualBillRemainingMinor(bill.billId), 0);
      expect(ledger.unallocatedMoneyMinor(WorkspaceSupplierMoneySourceKind.openingAdvance,
        opening.openingRecord!.id), 0);
      expect(WorkspaceSupplierLedger.fromJson(ledger.toJson())!.valid, isTrue);
      expect(ledger.recordReviewedRefund(intent, expectedRevision: billed.revision,
        recordedAt: ledger.asOf), same(ledger));
    }
  });

  test('PURCHASEREFUND frozen request survives unrelated ledger progress at fresh commit time', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 10000,
      credit: true, bills: const []))!;
    final intent = refundIntentFixture(opening);
    final updated = opening.receiveGoods(goodsReceiptFixture(), expectedRevision: opening.revision)!;
    final at = updated.asOf.add(const Duration(hours: 1));
    final posted = updated.recordReviewedRefund(intent, expectedRevision: updated.revision,
      recordedAt: at)!;
    expect(posted.refunds.values.single.intent.requestedAt, intent.requestedAt);
    expect(posted.goodsReceipts, updated.goodsReceipts);
    expect(posted.recordReviewedRefund(intent, expectedRevision: opening.revision,
      recordedAt: opening.asOf), same(posted));
  });

  test('PURCHASEREFUND unpaid accepted bill has no refundable money', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!;
    final bill = acceptanceFixture(id: 'refund-copy', draftId: 'refund-bill',
      date: '2026-10-02', treatment: WorkspaceOpeningBillInclusion.excluded);
    final ledger = opening.acceptReviewedBill(bill, expectedRevision: 1)!;
    final intent = refundIntentFixture(ledger,
      kind: WorkspaceSupplierRefundSourceKind.manualBillSurplus, source: bill.billId, bill: bill);
    expect(ledger.reviewedRefundCapacity(intent), 0);
    expect(ledger.reviewedRefundCapacity(WorkspaceSupplierRefundIntent.fromJson(
      {...intent.toJson(), 'copyRevision': bill.copy.revision + 1})), isNull);
  });

  test('PURCHASECREDIT support and reviewed document retain exact immutable identities', () {
    const returned = WorkspaceSupplierCreditSupport(
      kind: WorkspaceSupplierCreditSupportKind.goodsReturned,
      receiptId: 'receipt', receiptLineId: 'line', billLineIndex: 0,
      quantityMilli: 1250, returnOperationId: 'return');
    final source = <WorkspaceSupplierCreditSupport>[returned];
    final note = WorkspaceSupplierCreditNote(operationId: 'credit',
      accountScope: 'account', workspaceId: 'store', supplierId: 'supplier',
      billId: 'bill', copyId: 'copy', copyRevision: 2,
      openingId: 'opening', openingRevision: 1, reference: 'CN-01',
      occurredOn: '2026-10-02', reason: 'Returned goods', amountMinor: 3000,
      recordedAt: DateTime.utc(2026, 10, 3, 12), committedRevision: 4,
      supports: source);
    source.clear();
    expect(note.valid, isTrue);
    expect(note.supports, hasLength(1));
    expect(() => note.supports.clear(), throwsUnsupportedError);
    final encoded = jsonDecode(jsonEncode(note.toJson()));
    expect(WorkspaceSupplierCreditNote.fromJson(encoded).toJson(), note.toJson());
    for (final alteration in <Map<String, Object?>>[
      {'occurredOn': '2026-02-30'}, {'occurredOn': '2026-10-04'},
      {'amountMinor': 0}, {'copyRevision': 0}, {'openingRevision': 0},
      {'committedRevision': 1}, {'reference': ' CN-01'}, {'reason': ''},
      {'supports': <Object?>[]}, {'unknown': true},
      {'supports': [returned.toJson(), {...returned.toJson(), 'billLineIndex': 1}]},
    ]) {
      expect(() => WorkspaceSupplierCreditNote.fromJson(
        {...note.toJson(), ...alteration}), throwsA(anything));
    }
    final missing = {...note.toJson()}..remove('supplierId');
    expect(() => WorkspaceSupplierCreditNote.fromJson(missing), throwsFormatException);
  });

  test('PURCHASECREDIT support refuses invented return links and invalid quantities', () {
    for (final kind in WorkspaceSupplierCreditSupportKind.values) {
      final support = WorkspaceSupplierCreditSupport(kind: kind,
        receiptId: 'receipt', receiptLineId: 'line', billLineIndex: 0,
        quantityMilli: 500,
        shortageClaimId: kind == WorkspaceSupplierCreditSupportKind.shortage ? 'claim' : null,
        returnOperationId: kind == WorkspaceSupplierCreditSupportKind.goodsReturned
          ? 'return' : null);
      expect(support.valid, isTrue);
      expect(WorkspaceSupplierCreditSupport.fromJson(support.toJson()).toJson(),
        support.toJson());
      for (final alteration in <Map<String, Object?>>[
        {'quantityMilli': 0}, {'quantityMilli': -1}, {'quantityMilli': 2147483648},
        {'billLineIndex': -1}, {'billLineIndex': 200}, {'receiptId': ''},
        {'receiptLineId': ' line'}, {'extra': 'unreviewed'},
        {'returnOperationId': kind == WorkspaceSupplierCreditSupportKind.goodsReturned
          ? null : 'invented-return'},
        {'shortageClaimId': kind == WorkspaceSupplierCreditSupportKind.shortage ? null : 'invented-claim'},
      ]) {
        expect(() => WorkspaceSupplierCreditSupport.fromJson(
          {...support.toJson(), ...alteration}), throwsA(anything));
      }
    }
  });

  test('PURCHASEMONEY reviewed manual bill payments retain identity and residual', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!;
    final bill = acceptanceFixture(id: 'money-copy', draftId: 'money-bill',
      date: '2026-10-02', treatment: WorkspaceOpeningBillInclusion.excluded);
    final accepted = opening.acceptReviewedBill(bill, expectedRevision: 1)!;
    WorkspaceSupplierLedgerEntry payment({String id = 'money-payment',
      int amount = 20000, String copy = 'money-copy', String billId = 'money-bill',
      String method = 'Cash', String date = '2026-10-03', bool excluded = true,
      String? openingId, int? openingRevision}) => WorkspaceSupplierLedgerEntry(
        operationId: id, reference: 'PAY-$id',
        origin: WorkspaceSupplierEntryOrigin.manualPurchase,
        purchaseId: copy, billId: billId, paymentMethod: method,
        kind: WorkspaceSupplierEntryKind.payment, amountMinor: amount,
        postedAt: DateTime.utc(2026, 10, 3, 12),
        moneyReview: WorkspaceSupplierMoneyReview(occurredOn: date,
          openingId: openingId ?? opening.openingRecord!.id,
          openingRevision: openingRevision ?? opening.openingRecord!.revision,
          notIncludedInOpening: excluded));
    expect(accepted.manualBillRemainingMinor('money-bill'), 50000);
    final partial = accepted.recordReviewedMoney(payment(), expectedRevision: 2)!;
    expect(partial.manualBillRemainingMinor('money-bill'), 30000);
    expect(partial.balanceMinor, 30000);
    expect(partial.goodsReceipts, isEmpty);
    expect(partial.entries.last.orderId, isNull);
    expect(partial.recordReviewedMoney(payment(), expectedRevision: 2), same(partial));
    expect(partial.recordReviewedMoney(payment(amount: 20001), expectedRevision: 2), isNull);
    for (final invalid in [payment(id: 'excess', amount: 30001),
      payment(id: 'wrong-copy', copy: 'another-copy'),
      payment(id: 'missing-bill', billId: 'not-accepted'),
      payment(id: 'future', date: '2026-10-04'),
      payment(id: 'bad-day', date: '2026-02-30'),
      payment(id: 'included', excluded: false), payment(id: 'no-method', method: ''),
      payment(id: 'wrong-opening', openingId: 'another-opening'),
      payment(id: 'wrong-revision', openingRevision: 99)]) {
      expect(partial.recordReviewedMoney(invalid, expectedRevision: 3), isNull);
      expect(partial.appendConfirmed(invalid, expectedRevision: 3), isNull);
    }
    expect(partial.recordReviewedMoney(payment(id: 'stale'), expectedRevision: 2), isNull);
    final full = partial.recordReviewedMoney(payment(id: 'final', amount: 30000),
      expectedRevision: 3)!;
    expect(full.manualBillRemainingMinor('money-bill'), 0);
    expect(full.balanceMinor, 0);
    final restored = WorkspaceSupplierLedger.fromJson(jsonDecode(jsonEncode(full.toJson())))!;
    expect(restored.toJson(), full.toJson());
    expect(restored.recordReviewedMoney(payment(), expectedRevision: 2), same(restored));
    final corrupt = jsonDecode(jsonEncode(full.toJson())) as Map<String, dynamic>;
    (corrupt['entries'] as List).last['amountMinor'] = 30001;
    expect(WorkspaceSupplierLedger.fromJson(corrupt), isNull);
  });

  test('PURCHASEMONEY supplier advance precedes bill and goods without auto allocation', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!;
    final advance = WorkspaceSupplierLedgerEntry(operationId: 'reviewed-advance',
      reference: 'ADV-1', origin: WorkspaceSupplierEntryOrigin.supplierAccount,
      paymentMethod: 'UPI', kind: WorkspaceSupplierEntryKind.advance,
      amountMinor: 10000, postedAt: DateTime.utc(2026, 10, 3, 12),
      moneyReview: WorkspaceSupplierMoneyReview(occurredOn: '2026-10-01',
        openingId: opening.openingRecord!.id,
        openingRevision: opening.openingRecord!.revision, notIncludedInOpening: true));
    final advanced = opening.recordReviewedMoney(advance, expectedRevision: 1)!;
    expect(advanced.balanceMinor, -10000);
    expect(advanced.purchaseBills, isEmpty);
    expect(advanced.goodsReceipts, isEmpty);
    expect(advanced.entries.single.billId, isNull);
    expect(advanced.recordReviewedMoney(advance, expectedRevision: 1), same(advanced));
    final bill = acceptanceFixture(id: 'advance-copy', draftId: 'advance-bill',
      date: '2026-10-02', treatment: WorkspaceOpeningBillInclusion.excluded);
    final accepted = advanced.acceptReviewedBill(bill, expectedRevision: 2)!;
    expect(accepted.balanceMinor, 40000);
    expect(accepted.manualBillRemainingMinor('advance-bill'), 50000);
    expect(accepted.entries.where((e) => e.kind == WorkspaceSupplierEntryKind.payment), isEmpty);
    expect(WorkspaceSupplierLedger.fromJson(accepted.toJson())!.toJson(), accepted.toJson());
  });

  test('PURCHASEMONEY opening-included bill remains unknown despite account payment', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 50000))!;
    final accepted = opening.acceptReviewedBill(acceptanceFixture(), expectedRevision: 1)!;
    final payment = WorkspaceSupplierLedgerEntry(operationId: 'opening-payment',
      reference: 'PAY-OPENING', origin: WorkspaceSupplierEntryOrigin.supplierAccount,
      paymentMethod: 'Bank transfer', kind: WorkspaceSupplierEntryKind.payment,
      amountMinor: 10000, postedAt: DateTime.utc(2026, 10, 3, 12),
      moneyReview: WorkspaceSupplierMoneyReview(occurredOn: '2026-10-03',
        openingId: opening.openingRecord!.id,
        openingRevision: opening.openingRecord!.revision, notIncludedInOpening: true));
    final paid = accepted.recordReviewedMoney(payment, expectedRevision: 2)!;
    expect(paid.balanceMinor, 40000);
    expect(paid.manualBillRemainingMinor('manual-draft-A'), isNull);
    expect(WorkspaceSupplierLedger.fromJson({...paid.toJson(),
      'entries': [{...payment.toJson(), 'amountMinor': 50001}]}), isNull);
    final forged = {...payment.toJson(), 'origin': 'manualPurchase',
      'purchaseId': 'reviewed-copy-A', 'billId': 'manual-draft-A'};
    expect(WorkspaceSupplierLedger.fromJson({...paid.toJson(),
      'entries': [forged]}), isNull);
    expect(WorkspaceSupplierLedger.fromJson({...paid.toJson(),
      'entries': [{...payment.toJson(), 'moneyReview': null}]}), isNull);
  });

  test('PURCHASEMONEY legacy retention is not permission for new unreviewed money', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!;
    final legacyAdvance = WorkspaceSupplierLedgerEntry(operationId: 'old-advance',
      reference: 'LEGACY-ADV', origin: WorkspaceSupplierEntryOrigin.supplierAccount,
      kind: WorkspaceSupplierEntryKind.advance, amountMinor: 10000,
      postedAt: DateTime.utc(2026, 10, 3));
    final old = WorkspaceSupplierLedger.fromJson({...opening.toJson(), 'revision': 2,
      'entries': [legacyAdvance.toJson()]})!;
    expect(old.entries.single.toJson().containsKey('moneyReview'), isFalse);
    expect(WorkspaceSupplierLedger.fromJson(old.toJson())!.toJson(), old.toJson());
    expect(old.appendConfirmed(legacyAdvance, expectedRevision: 1), same(old));
    expect(opening.appendConfirmed(legacyAdvance, expectedRevision: 1), isNull);
    expect(old.canFollow(opening), isFalse);
    expect(old.canFollow(old), isTrue);
  });

  test('PURCHASEMONEY statement uses occurrence date without a null order reference', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!;
    final entry = WorkspaceSupplierLedgerEntry(operationId: 'dated-advance',
      reference: 'PAID-ON-FIRST', origin: WorkspaceSupplierEntryOrigin.supplierAccount,
      kind: WorkspaceSupplierEntryKind.advance, amountMinor: 10000,
      paymentMethod: 'Cash', postedAt: DateTime.utc(2026, 10, 3),
      moneyReview: WorkspaceSupplierMoneyReview(occurredOn: '2026-10-01',
        openingId: opening.openingRecord!.id,
        openingRevision: opening.openingRecord!.revision, notIncludedInOpening: true));
    final advanced = opening.recordReviewedMoney(entry, expectedRevision: 1)!;
    final actualDay = DateTime(2026, 10, 1);
    final dayOne = WorkspaceMoneyStatement.fromLedgers(finance: receiptFinanceFixture(),
      suppliers: [advanced], expenses: const [], start: actualDay,
      end: actualDay.add(const Duration(days: 1)))!;
    expect(dayOne.recordedOutMinor, 10000);
    expect(dayOne.entries.single.reference, 'PAID-ON-FIRST');
    expect(dayOne.entries.single.occurredAt, actualDay);
    expect(advanced.entries.single.postedAt, DateTime.utc(2026, 10, 3));
    final recordingDay = WorkspaceMoneyStatement.fromLedgers(finance: receiptFinanceFixture(),
      suppliers: [advanced], expenses: const [], start: DateTime(2026, 10, 3),
      end: DateTime(2026, 10, 4))!;
    expect(recordingDay.entries, isEmpty);
  });

  for (final priorKind in [WorkspaceSupplierEntryKind.payment, WorkspaceSupplierEntryKind.advance]) {
    test('PURCHASEMONEY ${priorKind.name} then bill payment cannot create implicit excess credit', () {
      final opening = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!;
      final bill = acceptanceFixture(id: 'capacity-copy', draftId: 'capacity-bill',
        date: '2026-10-02', treatment: WorkspaceOpeningBillInclusion.excluded);
      final review = WorkspaceSupplierMoneyReview(occurredOn: '2026-10-03',
        openingId: opening.openingRecord!.id,
        openingRevision: opening.openingRecord!.revision, notIncludedInOpening: true);
      final accountMoney = WorkspaceSupplierLedgerEntry(operationId: 'account-money',
        reference: 'ACCOUNT-1', origin: WorkspaceSupplierEntryOrigin.supplierAccount,
        kind: priorKind, amountMinor: 10000, paymentMethod: 'Cash',
        postedAt: DateTime.utc(2026, 10, 3), moneyReview: review);
      final beforeBill = priorKind == WorkspaceSupplierEntryKind.advance
        ? opening.recordReviewedMoney(accountMoney, expectedRevision: 1)! : opening;
      final accepted = beforeBill.acceptReviewedBill(bill, expectedRevision: beforeBill.revision)!;
      final current = priorKind == WorkspaceSupplierEntryKind.payment
        ? accepted.recordReviewedMoney(accountMoney, expectedRevision: accepted.revision)! : accepted;
      expect(current.balanceMinor, 40000);
      expect(current.manualBillRemainingMinor(bill.billId), 50000);
      WorkspaceSupplierLedgerEntry billPayment(int amount) => WorkspaceSupplierLedgerEntry(
        operationId: 'bill-money', reference: 'BILL-PAY',
        origin: WorkspaceSupplierEntryOrigin.manualPurchase, purchaseId: bill.copy.id,
        billId: bill.billId, kind: WorkspaceSupplierEntryKind.payment, amountMinor: amount,
        paymentMethod: 'Cash', postedAt: DateTime.utc(2026, 10, 3), moneyReview: review);
      expect(current.recordReviewedMoney(billPayment(50000), expectedRevision: current.revision), isNull);
      final paid = current.recordReviewedMoney(billPayment(40000), expectedRevision: current.revision)!;
      expect(paid.balanceMinor, 0);
      expect(paid.manualBillRemainingMinor(bill.billId), 10000);
      expect(paid.goodsReceipts, isEmpty);
    });
  }

  test('PURCHASEMONEY legacy manual payment remains readable with unknown bill residual', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!;
    final bill = acceptanceFixture(id: 'legacy-money-copy', draftId: 'legacy-money-bill',
      date: '2026-10-02', treatment: WorkspaceOpeningBillInclusion.excluded);
    final accepted = opening.acceptReviewedBill(bill, expectedRevision: 1)!;
    final legacy = WorkspaceSupplierLedgerEntry(operationId: 'legacy-manual-payment',
      reference: 'OLD-PAY', origin: WorkspaceSupplierEntryOrigin.manualPurchase,
      purchaseId: bill.copy.id, billId: bill.billId,
      kind: WorkspaceSupplierEntryKind.payment, amountMinor: 10000,
      postedAt: DateTime.utc(2026, 10, 3));
    final old = WorkspaceSupplierLedger.fromJson({...accepted.toJson(), 'revision': 3,
      'entries': [...accepted.entries.map((e) => e.toJson()), legacy.toJson()]})!;
    expect(WorkspaceSupplierLedger.fromJson(old.toJson())!.toJson(), old.toJson());
    expect(old.manualBillRemainingMinor(bill.billId), isNull);
    expect(old.balanceMinor, 40000);
    expect(old.appendConfirmed(legacy, expectedRevision: 2), same(old));
    expect(accepted.appendConfirmed(legacy, expectedRevision: 2), isNull);
    expect(old.canFollow(accepted), isFalse);
    expect(old.canFollow(old), isTrue);
  });

  // Labelled encrypted-form contract fixtures only; not device acceptance data.
  WorkspaceLedgerFormDraft moneyDraftFixture({int revision = 1, bool frozen = false,
      Map<String, String>? fields}) {
    final entry = WorkspaceSupplierLedgerEntry(operationId: 'frozen-form-operation',
      reference: 'ADV-FORM-1', origin: WorkspaceSupplierEntryOrigin.supplierAccount,
      kind: WorkspaceSupplierEntryKind.advance, amountMinor: 10000,
      paymentMethod: 'Cash', postedAt: DateTime.utc(2026, 10, 3),
      moneyReview: const WorkspaceSupplierMoneyReview(occurredOn: '2026-10-03',
        openingId: 'opening-A-r3', openingRevision: 3, notIncludedInOpening: true));
    return WorkspaceLedgerFormDraft(key: (account: 'account-A', store: 'store-A',
      customer: 'private-supplier-A', invoice: 'opening-A-r3',
      order: 'account-advance:opening-A-r3', kind: 'supplierMoney', ledgerRevision: 3),
      revision: revision, fields: fields ?? {'amount': '100.00', 'channel': 'Cash',
        'reference': 'ADV-FORM-1', 'occurredOn': '2026-10-03', 'notIncludedInOpening': 'true',
        if (frozen) 'attempt': jsonEncode(WorkspaceSupplierMoneyAttempt(entry: entry, expectedRevision: 1).toJson())});
  }

  test('PURCHASEMONEYDRAFT frozen input cannot be overwritten or removed by another sheet', () async {
    final bytes = _OrderJournalStorage();
    SecureWorkLedgerFormDraftStore owner() => SecureWorkLedgerFormDraftStore(accountScope: () => 'account-A', storage: bytes);
    final editable = moneyDraftFixture();
    final frozen = moneyDraftFixture(revision: 2, frozen: true);
    await owner().save(editable, expectedRevision: null);
    await owner().save(frozen, expectedRevision: 1);
    final writes = bytes.writes.length;
    await owner().save(frozen, expectedRevision: 1);
    expect(bytes.writes.length, writes);
    await expectLater(owner().save(moneyDraftFixture(revision: 3), expectedRevision: 2),
      throwsA(isA<WorkGatewayException>()));
    final raw = jsonDecode(frozen.fields['attempt']!) as Map<String, dynamic>;
    (raw['entry'] as Map)['reference'] = 'REPLACED';
    final changed = moneyDraftFixture(revision: 3, fields: {...frozen.fields,
      'reference': 'REPLACED', 'attempt': jsonEncode(raw)});
    expect(changed.valid, isTrue);
    await expectLater(owner().save(changed, expectedRevision: 2), throwsA(isA<WorkGatewayException>()));
    expect((await owner().read(frozen.key))!.toJson(), frozen.toJson());
    expect(bytes.writes.length, writes);
    for (final bad in [{...frozen.fields, 'channel': 'UPI'},
      {...frozen.fields, 'amount': '100.01'}, {...frozen.fields, 'notIncludedInOpening': 'false'},
      {...frozen.fields, 'attempt': '{broken'}, {...frozen.fields, 'attempt': 'x' * 8193}]) {
      expect(moneyDraftFixture(fields: bad).valid, isFalse);
    }
  });

  test('PURCHASEMONEYDRAFT lost freeze reply retains same operation and guard excludes queued edits', () async {
    final bytes = _OrderJournalStorage();
    final owner = SecureWorkLedgerFormDraftStore(accountScope: () => 'account-A', storage: bytes);
    final frozen = moneyDraftFixture(frozen: true);
    bytes.loseWriteResponseOnce = true;
    await expectLater(owner.save(frozen, expectedRevision: null), throwsStateError);
    final writes = bytes.writes.length;
    expect((await owner.read(frozen.key))!.supplierMoneyAttempt!.entry.operationId, 'frozen-form-operation');
    await owner.save(frozen, expectedRevision: null);
    expect(bytes.writes.length, writes);
    final entered = Completer<void>(), release = Completer<void>();
    final posting = owner.withFrozenSupplierMoney(frozen.key, frozen.fields['attempt']!, () async {
      entered.complete(); await release.future; return true;
    });
    await entered.future;
    final competing = owner.save(moneyDraftFixture(revision: 2), expectedRevision: 1);
    final rejection = expectLater(competing, throwsA(isA<WorkGatewayException>()));
    release.complete();
    expect(await posting, isTrue);
    await rejection;
    expect(bytes.writes.length, writes);
    expect((await owner.read(frozen.key))!.toJson(), frozen.toJson());
  });

  test('PURCHASEMONEYDRAFT reset requires exact committed proof and lost reset reply is idempotent', () async {
    final bytes = _OrderJournalStorage();
    final owner = SecureWorkLedgerFormDraftStore(accountScope: () => 'account-A', storage: bytes);
    final frozen = moneyDraftFixture(frozen: true);
    await owner.save(frozen, expectedRevision: null);
    final reset = moneyDraftFixture(revision: 2, fields: {'amount': '', 'reference': '',
      'channel': 'Cash', 'occurredOn': '2026-10-03', 'notIncludedInOpening': 'false'});
    await expectLater(owner.resetConfirmedSupplierMoneyDraft(reset, expectedRevision: 1,
      verifyCommitted: (_) async => false), throwsA(isA<WorkGatewayException>()));
    expect((await owner.read(frozen.key))!.toJson(), frozen.toJson());
    bytes.loseWriteResponseOnce = true;
    await expectLater(owner.resetConfirmedSupplierMoneyDraft(reset, expectedRevision: 1,
      verifyCommitted: (entry) async {
        expect(entry.toJson(), frozen.supplierMoneyAttempt!.entry.toJson()); return true;
      }), throwsStateError);
    final writes = bytes.writes.length;
    expect((await owner.read(reset.key))!.supplierMoneyAttempt, isNull);
    await owner.resetConfirmedSupplierMoneyDraft(reset, expectedRevision: 1,
      verifyCommitted: (_) async => throw StateError('Exact reset retry must not reverify or rewrite'));
    expect(bytes.writes.length, writes);
  });

  test('PURCHASEPOST manual bill and supplier advance need no invented order', () {
    final at = DateTime.utc(2026, 10, 3);
    final bill = WorkspaceSupplierLedgerEntry(
      operationId: 'manual-bill-operation',
      purchaseId: 'reviewed-manual-copy',
      origin: WorkspaceSupplierEntryOrigin.manualPurchase,
      billId: 'manual-bill',
      reference: 'SUPPLIER-INV-1',
      kind: WorkspaceSupplierEntryKind.bill,
      amountMinor: 200000,
      postedAt: at,
    );
    final advance = WorkspaceSupplierLedgerEntry(
      operationId: 'advance-operation',
      origin: WorkspaceSupplierEntryOrigin.supplierAccount,
      reference: 'ADVANCE-1',
      paymentMethod: 'Cash',
      kind: WorkspaceSupplierEntryKind.advance,
      amountMinor: 50000,
      postedAt: at,
    );
    final ledger = WorkspaceSupplierLedger(
      accountScope: 'account-A',
      workspaceId: 'store-A',
      supplierId: 'supplier-A',
      supplierName: 'Automated supplier fixture',
      revision: 1,
      asOf: at,
      historyComplete: true,
      openingBalanceMinor: 0,
      entries: [bill, advance],
    );
    expect(ledger.valid, isTrue);
    expect(ledger.payableMinor, 150000);
    expect(bill.orderId, isNull);
    expect(advance.orderId, isNull);
    final restored = WorkspaceSupplierLedger.fromJson(
      jsonDecode(jsonEncode(ledger.toJson())),
    )!;
    expect(restored.toJson(), ledger.toJson());
    expect(restored.entries.first.purchaseId, 'reviewed-manual-copy');
    expect(restored.entries.last.origin,
        WorkspaceSupplierEntryOrigin.supplierAccount);
    expect(restored.appendConfirmed(bill, expectedRevision: 1), same(restored));
    final changedSource = WorkspaceSupplierLedgerEntry(
      operationId: bill.operationId,
      orderId: 'unrelated-platform-order',
      billId: bill.billId,
      reference: bill.reference,
      kind: bill.kind,
      amountMinor: bill.amountMinor,
      postedAt: at,
    );
    expect(restored.appendConfirmed(changedSource, expectedRevision: 1), isNull);
  });

  test('PURCHASEPOST source identity cannot be ambiguous or silently inferred', () {
    final at = DateTime.utc(2026, 10, 3);
    WorkspaceSupplierLedgerEntry entry({
      WorkspaceSupplierEntryOrigin origin =
          WorkspaceSupplierEntryOrigin.moolSocialOrder,
      String? order,
      String? purchase,
      WorkspaceSupplierEntryKind kind = WorkspaceSupplierEntryKind.bill,
    }) => WorkspaceSupplierLedgerEntry(
      operationId: 'operation',
      origin: origin,
      orderId: order,
      purchaseId: purchase,
      billId: 'bill',
      reference: 'REF-1',
      kind: kind,
      amountMinor: 100,
      postedAt: at,
    );
    expect(entry().valid, isFalse);
    expect(entry(order: 'order').valid, isTrue);
    expect(entry(order: 'order', purchase: 'copy').valid, isFalse);
    expect(entry(origin: WorkspaceSupplierEntryOrigin.manualPurchase).valid,
        isFalse);
    expect(entry(origin: WorkspaceSupplierEntryOrigin.manualPurchase,
        purchase: 'copy', order: 'order').valid, isFalse);
    expect(entry(origin: WorkspaceSupplierEntryOrigin.manualPurchase,
        purchase: ' ').valid, isFalse);
    expect(entry(origin: WorkspaceSupplierEntryOrigin.supplierAccount).valid,
        isFalse);
    expect(entry(origin: WorkspaceSupplierEntryOrigin.supplierAccount,
        kind: WorkspaceSupplierEntryKind.advance).valid, isTrue);
    expect(entry(origin: WorkspaceSupplierEntryOrigin.supplierAccount,
        kind: WorkspaceSupplierEntryKind.advance, purchase: 'copy').valid,
        isFalse);
    final legacy = WorkspaceSupplierLedger(
      accountScope: 'account-A', workspaceId: 'store-A',
      supplierId: 'supplier-A', supplierName: 'Automated supplier fixture',
      revision: 1, asOf: at, historyComplete: true, openingBalanceMinor: 0,
      entries: [entry(order: 'order')],
    );
    final legacyBytes = legacy.toJson();
    expect(legacy.entries.single.toJson().containsKey('origin'), isFalse);
    expect(legacy.entries.single.toJson().containsKey('purchaseId'), isFalse);
    expect(WorkspaceSupplierLedger.fromJson(legacyBytes)!.toJson(), legacyBytes);
    final invalidSource = {...legacy.entries.single.toJson(), 'origin': 'guessed'};
    expect(WorkspaceSupplierLedger.fromJson({...legacyBytes,
      'entries': [invalidSource]}), isNull);
    final unlabelledManual = {...legacy.entries.single.toJson(),
      'orderId': null, 'purchaseId': 'copy'};
    expect(WorkspaceSupplierLedger.fromJson({...legacyBytes,
      'entries': [unlabelledManual]}), isNull);
  });

  // Automated session fixtures only, not injected device acceptance records.
  Future<WorkSession> openingPostingSession(_OrderJournalStorage storage,
      {WorkspaceSupplierOpeningRecord? initialRecord, bool inventory = false,
      WorkLedgerFormDraftStore? moneyStore,
      WorkspaceStockEntryMethod method = WorkspaceStockEntryMethod.manual}) async {
    final account = _CommandAccountStore();
    final purchaseStore = SecureWorkPurchaseEntryStore(
      accountScope: () => account.accountScope, storage: storage);
    if (initialRecord != null) {
      await purchaseStore.save(entryFixture(), expectedRevision: null);
      await purchaseStore.save(copyBook(), expectedRevision: 1);
      await purchaseStore.save(openingBook(records: [initialRecord]), expectedRevision: 2);
    }
    final session = WorkSession(gateway: ReviewWorkGateway(),
      contactDraftStore: account, purchaseEntryStore: purchaseStore,
      ledgerFormDraftStore: moneyStore,
      inventoryStore: inventory ? SecureWorkInventoryStore(
        accountScope: () => account.accountScope, storage: storage) : null)
      ..activeWorkspace = _commandStore;
    addTearDown(session.dispose);
    final finance = WorkspaceFinanceSnapshot(accountScope: 'account-A',
      workspaceId: 'store-A', revision: 1, asOf: DateTime.utc(2026, 10, 3),
      salesTodayMinor: 0, duesMinor: 0, availableMinor: 0, heldMinor: 0,
      requestedMinor: 0, paidOutMinor: 0, feesMinor: 0,
      deliveryAdjustmentsMinor: 0, refundsMinor: 0, taxWithheldMinor: 0,
      payments: const [], payouts: const [], historyComplete: true);
    expect(session.applyWorkspaceFinance(finance), isTrue);
    expect(session.bindCustomerCollectionGateway(accountScope: 'account-A',
      storeId: 'store-A', adapter: StoreReviewCustomerCollectionGateway(finance),
      checkpointStore: SecureWorkLedgerCheckpointStore(
        accountScope: () => account.accountScope, storage: storage)), isTrue);
    expect(await session.loadWorkspaceSuppliers(), isTrue);
    if (inventory) {
      expect(await session.loadWorkspaceInventory(), isTrue);
      if (session.workspaceCatalogueItems.isEmpty) {
        final product = workspaceMasterCatalogue.last.copyWith(stock: 10, publicListing: false);
        expect(method == WorkspaceStockEntryMethod.csv
          ? session.importWorkspaceProducts([product], addOnly: true, stockEntryMethod: method)
          : session.addOrUpdateWorkspaceProduct(product, stockEntryMethod: method), isTrue);
        expect(await session.workspaceInventorySaved, isTrue);
      }
    }
    return session;
  }

  WorkspaceSupplierGoodsReceipt sessionReceipt(WorkSession session, {Map<String, int> prior = const {}}) {
    final product = session.workspaceCatalogueItems.single;
    return WorkspaceSupplierGoodsReceipt(id: 'session-receipt-A', expectedDeliveryId: 'session-delivery-A',
      reference: 'DEL-SESSION-A', deliveredOn: '2026-10-02', recordedAt: DateTime.now().toUtc(),
      lines: [WorkspaceSupplierGoodsReceiptLine(sourceLineId: 'session-line-A', productId: product.id,
        productLabel: '${product.title} · ${product.pack}', purchaseUnit: product.pack,
        stockUnit: product.pack, unitsPerPack: 1, deliveredMilli: 6000, acceptedMilli: 6000,
        damagedMilli: 0, shortMilli: 0, expectedMilli: 12000, priorStockUnits: prior)]);
  }

  test('RECEIVINGINPUT bounded incomplete input is not posting authority', () {
    const key = (account: 'account-A', store: 'store-A', customer: 'supplier-A',
      invoice: 'receiving-input', order: 'receiving-input:qa', kind: 'supplierReceivingInput', ledgerRevision: 1);
    final line = ['line-A', '', true, 'kg', '1', '2.', 'not checked', '0', '', {'prior-A': '1.'}];
    final fields = {'arrivalId': 'arrival-A', 'groupId': 'group-A', 'input': jsonEncode(['Bill pending', '', line])};
    final draft = WorkspaceLedgerFormDraft(key: key, revision: 1, fields: fields);
    expect(draft.valid, isTrue, reason: 'Host-only unsent input may be incomplete or numerically invalid.');
    expect(WorkspaceLedgerFormDraft.fromJson(draft.toJson())!.fields, fields);
    expect(draft.supplierGoodsReturnIntent, isNull);
    for (final bad in [
      {...fields, 'attempt': '{}'}, {...fields}..remove('groupId'),
      {...fields, 'arrivalId': ''},
      {...fields, 'input': jsonEncode(['ref', 'day', line, line])},
      {...fields, 'input': jsonEncode(['ref', 'day', [...line.take(9), 'not a map']])},
      {...fields, 'input': jsonEncode(['ref', 'day', [...line.take(2), 'true', ...line.skip(3)]])},
      {...fields, 'input': jsonEncode(['x' * 513, 'day', line])},
    ]) {
      expect(WorkspaceLedgerFormDraft(key: key, revision: 1, fields: bad).valid, isFalse);
    }
    expect(WorkspaceLedgerFormDraft(key: (account: key.account, store: key.store, customer: key.customer,
      invoice: key.invoice, order: 'receiving-input:unknown', kind: key.kind, ledgerRevision: 1),
      revision: 1, fields: fields).valid, isFalse);
  });

  test('RECEIVINGINPUT encrypted restart conflict lost acknowledgement and isolation', () async {
    // Host-only storage fixture; never supplies runtime Stock or transactions.
    const key = (account: 'account-A', store: 'store-A', customer: 'supplier-A',
      invoice: 'receiving-input', order: 'receiving-input:qa', kind: 'supplierReceivingInput', ledgerRevision: 1);
    final fields = {'arrivalId': 'arrival-A', 'groupId': 'group-A',
      'input': jsonEncode(['Goods before bill', '2026-10-04', ['line-A', 'product-A', true, 'kg', '1', '2.', '', '0', '0', <String, String>{}]])};
    final storage = _OrderJournalStorage();
    SecureWorkLedgerFormDraftStore owner() => SecureWorkLedgerFormDraftStore(accountScope: () => 'account-A', storage: storage);
    final first = WorkspaceLedgerFormDraft(key: key, revision: 1, fields: fields);
    await owner().save(first, expectedRevision: null);
    expect((await owner().read(key))!.toJson(), first.toJson());
    final second = WorkspaceLedgerFormDraft(key: key, revision: 2, fields: {...fields, 'arrivalId': 'arrival-B'});
    storage.loseWriteResponseOnce = true;
    await expectLater(owner().save(second, expectedRevision: 1), throwsA(isA<StateError>()));
    expect((await owner().read(key))!.toJson(), second.toJson());
    await owner().save(second, expectedRevision: 1);
    await expectLater(owner().save(WorkspaceLedgerFormDraft(key: key, revision: 2,
      fields: {...fields, 'arrivalId': 'competing-arrival'}), expectedRevision: 1), throwsA(isA<WorkGatewayException>()));
    for (final other in [
      (account: key.account, store: 'store-B', customer: key.customer, invoice: key.invoice, order: key.order, kind: key.kind, ledgerRevision: 1),
      (account: key.account, store: key.store, customer: 'supplier-B', invoice: key.invoice, order: key.order, kind: key.kind, ledgerRevision: 1),
      (account: key.account, store: key.store, customer: key.customer, invoice: key.invoice, order: 'receiving-input:live', kind: key.kind, ledgerRevision: 1),
    ]) { expect(await owner().read(other), isNull); }
    expect(storage.values.length, 1);
    expect(storage.values.keys.single, contains('ledger-form'));
  });

  test('PURCHASEREVIEW codec preserves legacy bytes and rejects broken relationships', () {
    final old = entryFixture();
    expect(old.toJson().containsKey('goodsReceiptDrafts'), isFalse);
    expect(WorkspacePurchaseEntryBook.fromJson(old.toJson()).toJson(), old.toJson());
    final review = WorkspaceSupplierGoodsReceiptDraft(supplierId: old.profiles.single.id,
      revision: 2, receipt: goodsReceiptFixture());
    final raw = {...old.toJson(), 'revision': 2, 'goodsReceiptDrafts': [review.toJson()]};
    expect(WorkspacePurchaseEntryBook.fromJson(raw).goodsReceiptDrafts.single.toJson(), review.toJson());
    for (final bad in [
      {...raw, 'goodsReceiptDrafts': null},
      {...raw, 'goodsReceiptDrafts': [review.toJson(), review.toJson()]},
      {...raw, 'revision': 1},
      {...raw, 'goodsReceiptDrafts': [{...review.toJson(), 'supplierId': 'missing'}]},
    ]) {
      expect(() => WorkspacePurchaseEntryBook.fromJson(bad), throwsFormatException);
    }
  });

  test('PURCHASEREVIEW secure storage forbids dropping or rewriting reviewed arrivals', () async {
    final storage = _OrderJournalStorage();
    final owner = SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage);
    final old = entryFixture();
    await owner.save(old, expectedRevision: null);
    final review = WorkspaceSupplierGoodsReceiptDraft(supplierId: old.profiles.single.id,
      revision: 2, receipt: goodsReceiptFixture());
    final saved = WorkspacePurchaseEntryBook.fromJson({...old.toJson(), 'revision': 2,
      'goodsReceiptDrafts': [review.toJson()]});
    await owner.save(saved, expectedRevision: 1);
    final writes = storage.writes.length;
    await owner.save(saved, expectedRevision: 1);
    expect(storage.writes.length, writes);
    await expectLater(owner.save(WorkspacePurchaseEntryBook.fromJson({...old.toJson(), 'revision': 3}),
      expectedRevision: 2), throwsA(isA<WorkGatewayException>()));
    final changed = {...review.toJson(), 'receipt': {...review.receipt.toJson(), 'reference': 'changed'}};
    await expectLater(owner.save(WorkspacePurchaseEntryBook.fromJson({...saved.toJson(),
      'revision': 3, 'goodsReceiptDrafts': [changed]}), expectedRevision: 2), throwsA(isA<WorkGatewayException>()));
    expect((await owner.read(old.account, old.store, qa: old.qa))!.toJson(), saved.toJson());
  });

  for (final mode in ['ordinary', 'lost-response', 'failed-save', 'competing']) {
    test('PURCHASEREVIEW SESSION $mode retains operation without stock or debt', () async {
      final storage = _OrderJournalStorage();
      final opening = openingFixture(amount: 0);
      final session = await openingPostingSession(storage, initialRecord: opening, inventory: true);
      final other = mode == 'competing' ? await openingPostingSession(storage, inventory: true) : null;
      final receipt = sessionReceipt(session);
      final stock = session.workspaceCatalogueItems.map((p) => (p.id, p.stock)).toList();
      final finance = session.workspaceFinance;
      if (mode == 'lost-response') storage.loseWriteResponseOnce = true;
      if (mode == 'failed-save') storage.failWrite = true;
      final saved = await session.saveWorkspaceGoodsReceiptDraft(receipt,
        supplierId: opening.supplierId, scope: session.workspaceSupplierScope!, expectedRevision: 3);
      expect(saved, mode != 'failed-save', reason: session.workspaceSupplierError);
      if (mode == 'failed-save') {
        expect(session.workspaceSupplierError, contains('unverified'));
        storage.failWrite = false;
        expect(await session.loadWorkspaceSuppliers(retry: true), isTrue);
        expect(session.workspaceGoodsReceiptDrafts, isEmpty);
        expect(await session.saveWorkspaceGoodsReceiptDraft(receipt, supplierId: opening.supplierId,
          scope: session.workspaceSupplierScope!, expectedRevision: 3), isTrue);
      }
      if (other != null) {
        expect(await other.saveWorkspaceGoodsReceiptDraft(receipt, supplierId: opening.supplierId,
          scope: other.workspaceSupplierScope!, expectedRevision: 3), isTrue,
          reason: 'Secure writer acknowledges exact same snapshot before stale CAS.');
      }
      final writes = storage.writes.length;
      expect(await session.saveWorkspaceGoodsReceiptDraft(receipt, supplierId: opening.supplierId,
        scope: session.workspaceSupplierScope!, expectedRevision: 3), isTrue);
      expect(storage.writes.length, writes);
      final changed = WorkspaceSupplierGoodsReceipt.fromJson({...receipt.toJson(), 'reference': 'changed'});
      expect(await session.saveWorkspaceGoodsReceiptDraft(changed, supplierId: opening.supplierId,
        scope: session.workspaceSupplierScope!, expectedRevision: 4), isFalse);
      final reopened = await openingPostingSession(storage, inventory: true);
      expect(reopened.workspaceGoodsReceiptDrafts.single.receipt.toJson(), receipt.toJson());
      final another = WorkspaceSupplierGoodsReceipt.fromJson({...receipt.toJson(), 'id': 'second-arrival'});
      expect(await reopened.saveWorkspaceGoodsReceiptDraft(another, supplierId: opening.supplierId,
        scope: reopened.workspaceSupplierScope!, expectedRevision: 4), isFalse);
      expect(reopened.workspaceSupplierError, contains('Resume'));
      expect(reopened.workspaceCatalogueItems.map((p) => (p.id, p.stock)), stock);
      expect(session.workspaceFinance, same(finance));
      expect(reopened.workspaceSupplierLedger(opening.supplierId), isNull);
    });
  }

  for (final projection in ['saved', 'pending', 'financial-only',
      'missing-movement', 'wrong-quantity', 'future-marker', 'missing-product', 'orphan-receipt']) {
    test('PURCHASEREVIEW SESSION frozen commit and fresh projection admission $projection', () async {
      final storage = _OrderJournalStorage();
      final opening = openingFixture(amount: 0);
      final owner = await openingPostingSession(storage, initialRecord: opening, inventory: true);
      expect(await owner.confirmWorkspaceSupplierOpeningRecord(opening, scope: owner.workspaceSupplierScope!,
        expectedRevision: 3, confirmedAt: DateTime.utc(2026, 10, 3)), isTrue);
      final receipt = sessionReceipt(owner);
      Future<WorkspaceGoodsReceiptSaveResult> post(WorkspaceSupplierGoodsReceipt value, int bookRevision) =>
        owner.confirmWorkspaceSupplierGoodsReceipt(value, supplierId: opening.supplierId,
          scope: owner.workspaceSupplierScope!, expectedPurchaseRevision: bookRevision,
          expectedSupplierRevision: 1, requireSavedReview: true);
      expect(await post(receipt, 3), WorkspaceGoodsReceiptSaveResult.notPosted);
      expect(owner.workspaceSupplierLedger(opening.supplierId)!.goodsReceipts, isEmpty);
      expect(await owner.saveWorkspaceGoodsReceiptDraft(receipt, supplierId: opening.supplierId,
        scope: owner.workspaceSupplierScope!, expectedRevision: 3), isTrue);
      final other = await openingPostingSession(storage, inventory: true);
      expect(await other.recoverCustomerLedger(), isTrue);
      final changed = WorkspaceSupplierGoodsReceipt.fromJson({...receipt.toJson(), 'reference': 'tampered'});
      expect(await post(changed, 4), WorkspaceGoodsReceiptSaveResult.notPosted);
      expect(owner.workspaceCatalogueItems.single.stock, 10);
      if (projection == 'pending') {
        storage.failWriteKey = storage.values.keys.singleWhere((key) => key.contains('workspace.inventory.'));
      }
      expect(await post(receipt, 4), projection == 'pending'
        ? WorkspaceGoodsReceiptSaveResult.stockRecoveryPending : WorkspaceGoodsReceiptSaveResult.saved);
      if (projection != 'saved' && projection != 'pending') {
        // Host-only flow: a financial commit must not invalidate projected Stock.
        final advance = WorkspaceSupplierLedgerEntry(operationId: 'next-arrival-advance',
          reference: 'HOST-NEXT-ARRIVAL-ADV', origin: WorkspaceSupplierEntryOrigin.supplierAccount,
          kind: WorkspaceSupplierEntryKind.advance, amountMinor: 10000,
          paymentMethod: 'Cash', postedAt: DateTime.utc(2026, 10, 3),
          moneyReview: WorkspaceSupplierMoneyReview(occurredOn: '2026-10-03',
            openingId: opening.id, openingRevision: opening.revision, notIncludedInOpening: true));
        expect(await owner.recordWorkspaceSupplierMoney(opening.supplierId,
          accountScope: 'account-A', workspaceId: 'store-A', entry: advance, expectedRevision: 2), isTrue);
        final savedStock = (await SecureWorkInventoryStore(accountScope: () => 'account-A', storage: storage)
          .read('account-A', 'store-A', qa: true))!;
        final journal = (await SecureWorkLedgerCheckpointStore(accountScope: () => 'account-A', storage: storage)
          .read('account-A', 'store-A'))!;
        expect(savedStock.manualReceiptCheckpointRevision, lessThan(journal.revision));
        expect(savedStock.products.single.stock, 16);
        final stockKey = storage.values.keys.singleWhere((key) => key.contains('workspace.inventory.'));
        // Deliberately corrupt host fixtures only; never actual device data.
        final raw = jsonDecode(storage.values[stockKey]!) as Map<String, dynamic>;
        if (projection == 'missing-movement') raw['movements'] = [];
        if (projection == 'wrong-quantity') {
          raw['products'] = [{...savedStock.products.single.toInventoryJson(), 'stock': 15}];
        }
        if (projection == 'future-marker') raw['manualReceiptCheckpointRevision'] = journal.revision + 1;
        if (projection == 'missing-product') raw['products'] = [];
        if (projection == 'orphan-receipt') {
          final savedMovements = raw['movements'] as List<dynamic>;
          final receiptMovement = savedStock.movements.singleWhere((m) =>
            m.referenceKind == WorkspaceStockReferenceKind.manualSupplierReceipt);
          final receiptBytes = savedMovements.cast<Map<String, dynamic>>().singleWhere((m) =>
            m['id'] == receiptMovement.id);
          raw['movements'] = [...savedMovements,
            {...receiptBytes, 'id': 'host-orphan-receipt-movement', 'quantityDelta': 1}];
          raw['products'] = [{...savedStock.products.single.toInventoryJson(), 'stock': 17}];
          expect(WorkspaceSavedInventory.fromJson(raw).products.single.stock, 17);
        }
        if (projection != 'financial-only') storage.values[stockKey] = jsonEncode(raw);
      }
      final stockKey = storage.values.keys.singleWhere((key) => key.contains('workspace.inventory.'));
      final stockBytes = storage.values[stockKey];
      final next = WorkspaceSupplierGoodsReceipt.fromJson({...receipt.toJson(), 'id': 'next-arrival'});
      final invalidProjection = ['missing-movement', 'wrong-quantity', 'future-marker', 'missing-product', 'orphan-receipt'].contains(projection);
      expect(await other.saveWorkspaceGoodsReceiptDraft(next, supplierId: opening.supplierId,
        scope: other.workspaceSupplierScope!, expectedRevision: 4), projection != 'pending' && !invalidProjection);
      expect(storage.values[stockKey], stockBytes, reason: 'Review admission never changes Stock bytes or marker.');
      if (invalidProjection) {
        expect(other.workspaceGoodsReceiptDrafts, hasLength(1));
        return;
      }
      if (projection == 'pending') {
        expect(other.workspaceSupplierError, contains('Stock recovery'));
        storage.failWriteKey = null;
        expect(await post(receipt, 4), WorkspaceGoodsReceiptSaveResult.saved);
        expect(await other.saveWorkspaceGoodsReceiptDraft(next, supplierId: opening.supplierId,
          scope: other.workspaceSupplierScope!, expectedRevision: 4), isTrue);
      }
      expect(other.workspaceGoodsReceiptDrafts.length, 2);
      expect((await SecureWorkInventoryStore(accountScope: () => 'account-A', storage: storage)
        .read('account-A', 'store-A', qa: true))!.products.single.stock, 16);
    });
  }

  test('PURCHASECANCEL native exact retry checks authoritative status and keeps history', () async {
    final storage = _OrderJournalStorage();
    final owner = SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage);
    final old = entryFixture();
    await owner.save(old, expectedRevision: null);
    final review = WorkspaceSupplierGoodsReceiptDraft(supplierId: old.profiles.single.id,
      revision: 2, receipt: goodsReceiptFixture());
    final book = WorkspacePurchaseEntryBook.fromJson({...old.toJson(), 'revision': 2,
      'goodsReceiptDrafts': [review.toJson()]});
    await owner.save(book, expectedRevision: 1);
    final cancellation = WorkspaceGoodsReceiptReviewCancellation(receiptId: review.receipt.id,
      supplierId: review.supplierId, revision: 3, cancelledAt: review.receipt.recordedAt,
      reason: 'Correct quantities before receiving');
    Future<WorkspacePurchaseEntryBook?> cancel(bool verified) => owner.abandonReviewedReceipt(
      old.account, old.store, qa: old.qa, expectedRevision: 2,
      cancellation: cancellation, verifyUncommitted: (_) async => verified);
    expect(await cancel(false), isNull);
    storage.loseWriteResponseOnce = true;
    final saved = (await cancel(true))!;
    expect(saved.goodsReceiptDrafts.single.toJson(), review.toJson());
    final writes = storage.writes.length;
    expect((await cancel(true))!.toJson(), saved.toJson());
    expect(storage.writes.length, writes);
    expect(await cancel(false), isNull, reason: 'Contradictory receipt evidence must not acknowledge cancellation.');
    final reopened = SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage);
    expect((await reopened.read(old.account, old.store, qa: old.qa))!.toJson(), saved.toJson());
    await expectLater(owner.save(WorkspacePurchaseEntryBook.fromJson({...book.toJson(), 'revision': 4}),
      expectedRevision: 3), throwsA(isA<WorkGatewayException>()));
    storage.failRead = true;
    await expectLater(cancel(true), throwsA(isA<StateError>()));
  });

  for (final cancellationFirst in [true, false]) {
    test('PURCHASECANCEL shared queue cancellation first $cancellationFirst', () async {
      final storage = _OrderJournalStorage();
      final owner = SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage);
      final other = SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage);
      final old = entryFixture();
      await owner.save(old, expectedRevision: null);
      final review = WorkspaceSupplierGoodsReceiptDraft(supplierId: old.profiles.single.id,
        revision: 2, receipt: goodsReceiptFixture());
      await owner.save(WorkspacePurchaseEntryBook.fromJson({...old.toJson(), 'revision': 2,
        'goodsReceiptDrafts': [review.toJson()]}), expectedRevision: 1);
      final entered = Completer<void>(), release = Completer<void>();
      bool committed = false;
      Future<WorkspacePurchaseEntryBook?> cancel() => owner.abandonReviewedReceipt(
        old.account, old.store, qa: old.qa, expectedRevision: 2,
        cancellation: WorkspaceGoodsReceiptReviewCancellation(receiptId: review.receipt.id,
          supplierId: review.supplierId, revision: 3, cancelledAt: review.receipt.recordedAt, reason: 'Correct quantity'),
        verifyUncommitted: (_) async {
          if (cancellationFirst) { entered.complete(); await release.future; }
          return !committed;
        });
      Future<bool> commit() => other.withReviewedBook(old.account, old.store, qa: old.qa,
        expectedRevision: 2, action: (book) async {
          if (!cancellationFirst) { entered.complete(); await release.future; }
          if (book.goodsReceiptCancellations.isNotEmpty) return false;
          committed = true;
          return true;
        });
      final first = cancellationFirst ? cancel() : commit();
      await entered.future;
      final second = cancellationFirst ? commit() : cancel();
      release.complete();
      final results = await Future.wait<Object?>([first, second]);
      expect(committed, !cancellationFirst);
      expect(results[0], cancellationFirst ? isA<WorkspacePurchaseEntryBook>() : isTrue);
      expect(results[1], cancellationFirst ? isFalse : isNull);
      final saved = (await owner.read(old.account, old.store, qa: old.qa))!;
      expect(saved.goodsReceiptCancellations.length, cancellationFirst ? 1 : 0);
      expect(saved.goodsReceiptDrafts.single.toJson(), review.toJson());
    });
  }

  for (final failure in ['contradiction', 'book-read']) {
    test('PURCHASECANCEL committed receipt $failure remains unresolved not unposted', () async {
      final storage = _OrderJournalStorage();
      final opening = openingFixture(amount: 0);
      final owner = await openingPostingSession(storage, initialRecord: opening, inventory: true);
      expect(await owner.confirmWorkspaceSupplierOpeningRecord(opening, scope: owner.workspaceSupplierScope!,
        expectedRevision: 3, confirmedAt: DateTime.utc(2026, 10, 3)), isTrue);
      final receipt = sessionReceipt(owner);
      expect(await owner.saveWorkspaceGoodsReceiptDraft(receipt, supplierId: opening.supplierId,
        scope: owner.workspaceSupplierScope!, expectedRevision: 3), isTrue);
      Future<WorkspaceGoodsReceiptSaveResult> post() => owner.confirmWorkspaceSupplierGoodsReceipt(receipt,
        supplierId: opening.supplierId, scope: owner.workspaceSupplierScope!, expectedPurchaseRevision: 4,
        expectedSupplierRevision: 1, requireSavedReview: true);
      expect(await post(), WorkspaceGoodsReceiptSaveResult.saved);
      final bookKey = storage.values.keys.singleWhere((key) => key.contains('workspace.purchase-entry.'));
      if (failure == 'book-read') {
        storage.failReadKey = bookKey;
      } else {
        // Labelled corrupt-storage fixture, never an actual runtime acceptance record.
        final raw = jsonDecode(storage.values[bookKey]!) as Map<String, dynamic>;
        storage.values[bookKey] = jsonEncode({...raw, 'revision': 5,
          'goodsReceiptCancellations': [WorkspaceGoodsReceiptReviewCancellation(receiptId: receipt.id,
            supplierId: opening.supplierId, revision: 5, cancelledAt: receipt.recordedAt,
            reason: 'Deliberately contradictory automated fixture').toJson()]});
      }
      final writes = storage.writes.length;
      expect(await post(), WorkspaceGoodsReceiptSaveResult.statusUnknown);
      expect(storage.writes.length, writes);
      expect(owner.workspaceCatalogueItems.single.stock, 16);
      expect(owner.workspaceSupplierError, isNotNull);
      expect(owner.updateWorkspaceStock(productId: owner.workspaceCatalogueItems.single.id,
        quantity: 99, reason: 'Automated recovery lock check'), isFalse);
      expect(owner.workspaceCatalogueItems.single.stock, 16);
    });
  }

  for (final failure in ['none', 'read', 'wrong-supplier']) {
    test('PURCHASECANCEL SESSION $failure never changes goods or money', () async {
      final storage = _OrderJournalStorage();
      final opening = openingFixture(amount: 0);
      final owner = await openingPostingSession(storage, initialRecord: opening, inventory: true);
      final receipt = sessionReceipt(owner);
      expect(await owner.saveWorkspaceGoodsReceiptDraft(receipt, supplierId: opening.supplierId,
        scope: owner.workspaceSupplierScope!, expectedRevision: 3), isTrue);
      final stock = owner.workspaceCatalogueItems.map((p) => (p.id, p.stock)).toList();
      final finance = owner.workspaceFinance;
      storage.failRead = failure == 'read';
      final cancelled = await owner.abandonWorkspaceGoodsReceiptReview(receipt.id,
        supplierId: failure == 'wrong-supplier' ? 'other-supplier' : opening.supplierId,
        scope: owner.workspaceSupplierScope!, expectedRevision: 4,
        cancelledAt: receipt.recordedAt, reason: 'Correct received quantity');
      expect(cancelled, failure == 'none', reason: owner.workspaceSupplierError);
      expect(owner.workspaceCatalogueItems.map((p) => (p.id, p.stock)), stock);
      expect(owner.workspaceFinance, same(finance));
      storage.failRead = false;
      final reopened = await openingPostingSession(storage, inventory: true);
      expect(reopened.workspaceGoodsReceiptDrafts.single.receipt.toJson(), receipt.toJson());
      expect(reopened.workspaceGoodsReceiptCancellations.length, failure == 'none' ? 1 : 0);
      if (failure == 'none') {
        expect(await reopened.saveWorkspaceGoodsReceiptDraft(receipt, supplierId: opening.supplierId,
          scope: reopened.workspaceSupplierScope!, expectedRevision: 5), isFalse);
        expect(await reopened.confirmWorkspaceSupplierGoodsReceipt(receipt, supplierId: opening.supplierId,
          scope: reopened.workspaceSupplierScope!, expectedPurchaseRevision: 5,
          expectedSupplierRevision: 0, requireSavedReview: true), WorkspaceGoodsReceiptSaveResult.notPosted);
        final corrected = WorkspaceSupplierGoodsReceipt.fromJson({...receipt.toJson(), 'id': 'corrected-arrival'});
        expect(await reopened.saveWorkspaceGoodsReceiptDraft(corrected, supplierId: opening.supplierId,
          scope: reopened.workspaceSupplierScope!, expectedRevision: 5), isTrue,
          reason: reopened.workspaceSupplierError);
      }
    });
  }

  for (final method in WorkspaceStockEntryMethod.values) {
    test('PURCHASERECEIVE SESSION ${method.name} prior Stock and restart preserve one receipt', () async {
      final storage = _OrderJournalStorage();
      final opening = openingFixture(amount: 0);
      final session = await openingPostingSession(storage, initialRecord: opening, inventory: true, method: method);
      expect(await session.confirmWorkspaceSupplierOpeningRecord(opening,
        scope: session.workspaceSupplierScope!, expectedRevision: 3, confirmedAt: DateTime.utc(2026, 10, 3)), isTrue);
      final receipt = sessionReceipt(session, prior: {session.workspaceStockMovements.single.id: 4});
      expect(session.workspaceReceiptPriorStock(session.workspaceCatalogueItems.single.id).values.single, 10);
      final financial = session.workspaceFinance;
      Future<WorkspaceGoodsReceiptSaveResult> receive(WorkSession owner) => owner.confirmWorkspaceSupplierGoodsReceipt(
        receipt, supplierId: opening.supplierId, scope: owner.workspaceSupplierScope!,
        expectedPurchaseRevision: 3, expectedSupplierRevision: 1);
      expect(await receive(session), WorkspaceGoodsReceiptSaveResult.saved, reason: session.workspaceSupplierError);
      expect(session.workspaceCatalogueItems.single.stock, 12);
      expect(session.workspaceReceiptPriorStock(session.workspaceCatalogueItems.single.id).values.single, 6,
        reason: 'Remaining original evidence is10 minus4 linked, not current on-hand12.');
      expect(session.workspaceFinance, same(financial));
      final writes = storage.writes.length;
      expect(await receive(session), WorkspaceGoodsReceiptSaveResult.saved);
      expect(storage.writes.length, writes);
      final restarted = await openingPostingSession(storage, inventory: true);
      expect(await restarted.recoverCustomerLedger(), isTrue);
      expect(restarted.workspaceCatalogueItems.single.stock, 12);
      expect(restarted.workspaceReceiptPriorStock(restarted.workspaceCatalogueItems.single.id).values.single, 6);
      expect(restarted.workspaceSupplierLedger(opening.supplierId)!.goodsReceipts.length, 1);
      expect(await receive(restarted), WorkspaceGoodsReceiptSaveResult.saved);
      expect(storage.writes.length, writes);
      expect(restarted.workspaceCatalogueItems.single.stockEntry!.method, method);
    });
  }

  test('PURCHASERECEIVE SESSION lease rejects Stock edits while saving and keeps originals', () async {
    final storage = _OrderJournalStorage();
    final opening = openingFixture(amount: 0);
    final session = await openingPostingSession(storage, initialRecord: opening, inventory: true);
    expect(await session.confirmWorkspaceSupplierOpeningRecord(opening, scope: session.workspaceSupplierScope!,
      expectedRevision: 3, confirmedAt: DateTime.utc(2026, 10, 3)), isTrue);
    final product = session.workspaceCatalogueItems.single;
    storage.holdWrite = Completer<void>();
    final posting = session.confirmWorkspaceSupplierGoodsReceipt(sessionReceipt(session), supplierId: opening.supplierId,
      scope: session.workspaceSupplierScope!, expectedPurchaseRevision: 3, expectedSupplierRevision: 1);
    expect(session.workspaceGoodsReceiptBusy, isTrue);
    expect(session.addOrUpdateWorkspaceProduct(product.copyWith(stock: 99)), isFalse);
    expect(session.importWorkspaceProducts([product.copyWith(stock: 99)]), isFalse);
    expect(session.updateWorkspaceStock(productId: product.id, quantity: 99, reason: 'Count'), isFalse);
    expect(session.retireWorkspaceProduct(product.id), isFalse);
    expect(session.restoreWorkspaceProduct(product.id), isFalse);
    expect(await session.retryWorkspaceInventorySave(), isFalse);
    expect(session.workspaceCatalogueItems.single.stock, 10);
    storage.holdWrite!.complete();
    expect(await posting, WorkspaceGoodsReceiptSaveResult.saved, reason: session.workspaceSupplierError);
    storage.holdWrite = null;
    expect(session.workspaceGoodsReceiptBusy, isFalse);
    expect(session.workspaceCatalogueItems.single.stock, 16);
  });

  test('PURCHASERECEIVE SESSION committed receipt projection failure blocks stale writers and recovers', () async {
    final storage = _OrderJournalStorage();
    final opening = openingFixture(amount: 0);
    final session = await openingPostingSession(storage, initialRecord: opening, inventory: true);
    expect(await session.confirmWorkspaceSupplierOpeningRecord(opening, scope: session.workspaceSupplierScope!,
      expectedRevision: 3, confirmedAt: DateTime.utc(2026, 10, 3)), isTrue);
    final stockStore = SecureWorkInventoryStore(accountScope: () => 'account-A', storage: storage);
    final oldStock = (await stockStore.read('account-A', 'store-A', qa: true))!;
    final receipt = sessionReceipt(session);
    final stockKey = storage.values.keys.singleWhere((key) => key.contains('workspace.inventory.'));
    storage.failWriteKey = stockKey;
    Future<WorkspaceGoodsReceiptSaveResult> receive(WorkSession owner) => owner.confirmWorkspaceSupplierGoodsReceipt(
      receipt, supplierId: opening.supplierId, scope: owner.workspaceSupplierScope!,
      expectedPurchaseRevision: 3, expectedSupplierRevision: 1);
    expect(await receive(session), WorkspaceGoodsReceiptSaveResult.stockRecoveryPending);
    expect(session.workspaceCatalogueItems.single.stock, 10);
    expect(session.addOrUpdateWorkspaceProduct(session.workspaceCatalogueItems.single.copyWith(stock: 99)), isFalse);
    final ledgerStore = SecureWorkLedgerCheckpointStore(accountScope: () => 'account-A', storage: storage);
    final committed = (await ledgerStore.read('account-A', 'store-A'))!;
    expect(committed.inventory!.quantities!.values.single, 16);
    expect(committed.supplierLedgers[opening.supplierId]!.goodsReceipts.length, 1);
    storage.failWriteKey = null;
    await expectLater(stockStore.save(WorkspaceSavedInventory.fromJson({...oldStock.toJson(),
      'revision': oldStock.revision + 1,
      'products': [oldStock.products.single.copyWith(sellingPrice: 77).toInventoryJson()]}),
      expectedRevision: oldStock.revision), throwsA(isA<WorkGatewayException>()),
      reason: 'Another instance with no marker must not overwrite a committed first receipt.');
    final restarted = await openingPostingSession(storage, inventory: true);
    expect(restarted.addOrUpdateWorkspaceProduct(restarted.workspaceCatalogueItems.single.copyWith(stock: 99)), isFalse,
      reason: 'A restarted session must block editing its unprojected receipt before mutation.');
    expect(await receive(restarted), WorkspaceGoodsReceiptSaveResult.saved,
      reason: restarted.workspaceSupplierError);
    expect(restarted.workspaceCatalogueItems.single.stock, 16);
    final recovered = (await ledgerStore.read('account-A', 'store-A'))!;
    expect(recovered.revision, committed.revision);
    expect(recovered.supplierLedgers[opening.supplierId]!.goodsReceipts.length, 1);
    final writes = storage.writes.length;
    expect(await receive(restarted), WorkspaceGoodsReceiptSaveResult.saved);
    expect(storage.writes.length, writes);
  });

  test('PURCHASERECEIVE SESSION exact receipt retry survives a later purchase book revision', () async {
    final storage = _OrderJournalStorage();
    final opening = openingFixture(amount: 0);
    final session = await openingPostingSession(storage, initialRecord: opening, inventory: true);
    expect(await session.confirmWorkspaceSupplierOpeningRecord(opening, scope: session.workspaceSupplierScope!,
      expectedRevision: 3, confirmedAt: DateTime.utc(2026, 10, 3)), isTrue);
    final receipt = sessionReceipt(session);
    Future<WorkspaceGoodsReceiptSaveResult> receive() => session.confirmWorkspaceSupplierGoodsReceipt(
      receipt, supplierId: opening.supplierId, scope: session.workspaceSupplierScope!,
      expectedPurchaseRevision: 3, expectedSupplierRevision: 1);
    expect(await receive(), WorkspaceGoodsReceiptSaveResult.saved);
    final books = SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage);
    final previous = (await books.read('account-A', 'store-A', qa: true))!;
    await books.save(WorkspacePurchaseEntryBook.fromJson({...previous.toJson(), 'revision': 4}), expectedRevision: 3);
    final writes = storage.writes.length;
    expect(await receive(), WorkspaceGoodsReceiptSaveResult.saved);
    expect(storage.writes.length, writes);
    expect(session.workspaceCatalogueItems.single.stock, 16);
  });

  test('PURCHASERECEIVE SESSION uncertain save and lost reply retry one goods operation', () async {
    final storage = _OrderJournalStorage();
    final opening = openingFixture(amount: 0);
    final session = await openingPostingSession(storage, initialRecord: opening, inventory: true);
    expect(await session.confirmWorkspaceSupplierOpeningRecord(opening, scope: session.workspaceSupplierScope!,
      expectedRevision: 3, confirmedAt: DateTime.utc(2026, 10, 3)), isTrue);
    final receipt = sessionReceipt(session);
    Future<WorkspaceGoodsReceiptSaveResult> receive() => session.confirmWorkspaceSupplierGoodsReceipt(
      receipt, supplierId: opening.supplierId, scope: session.workspaceSupplierScope!,
      expectedPurchaseRevision: 3, expectedSupplierRevision: 1);
    storage.failWrite = true;
    expect(await receive(), WorkspaceGoodsReceiptSaveResult.statusUnknown);
    expect(session.workspaceCatalogueItems.single.stock, 10);
    storage.failWrite = false;
    storage.loseWriteResponseOnce = true;
    expect(await receive(), WorkspaceGoodsReceiptSaveResult.saved, reason: session.workspaceSupplierError);
    expect(session.workspaceCatalogueItems.single.stock, 16);
    expect(session.workspaceSupplierLedger(opening.supplierId)!.goodsReceipts.length, 1);
  });

  test('PURCHASERECEIVE SESSION receiving preserves independent unavailability', () async {
    final storage = _OrderJournalStorage();
    final opening = openingFixture(amount: 0);
    final session = await openingPostingSession(storage, initialRecord: opening, inventory: true);
    expect(session.addOrUpdateWorkspaceProduct(session.workspaceCatalogueItems.single.copyWith(available: false)), isTrue);
    expect(await session.workspaceInventorySaved, isTrue);
    expect(await session.confirmWorkspaceSupplierOpeningRecord(opening, scope: session.workspaceSupplierScope!,
      expectedRevision: 3, confirmedAt: DateTime.utc(2026, 10, 3)), isTrue);
    expect(await session.confirmWorkspaceSupplierGoodsReceipt(sessionReceipt(session), supplierId: opening.supplierId,
      scope: session.workspaceSupplierScope!, expectedPurchaseRevision: 3, expectedSupplierRevision: 1),
      WorkspaceGoodsReceiptSaveResult.saved);
    expect(session.workspaceCatalogueItems.single.stock, 16);
    expect(session.workspaceCatalogueItems.single.available, isFalse);
    expect(session.workspaceCatalogueItems.single.publicListing, isFalse);
  });

  test('PURCHASEPOST opening confirmation saves once and reopens without stock changes', () async {
    final storage = _OrderJournalStorage();
    final record = openingFixture(amount: 50000);
    final session = await openingPostingSession(storage, initialRecord: record);
    final scope = session.workspaceSupplierScope!;
    final stock = session.workspaceCatalogueItems.map((p) => (p.id, p.stock)).toList();
    final finance = session.workspaceFinance;
    storage.holdWrite = Completer<void>();
    final posting = session.confirmWorkspaceSupplierOpeningRecord(record,
      scope: scope, expectedRevision: 3, confirmedAt: DateTime.utc(2026, 10, 3));
    await Future<void>.delayed(Duration.zero);
    expect(session.workspaceSupplierSaving, isTrue);
    expect(await session.saveWorkspaceSupplierOpeningRecord(
      openingFixture(revision: 4, amount: 60000), scope: scope,
      expectedRevision: 3), isFalse);
    storage.holdWrite!.complete();
    expect(await posting, isTrue);
    storage.holdWrite = null;
    expect(session.workspaceSupplierLedger(record.supplierId)!.payableMinor, 50000);
    expect(session.workspaceCatalogueItems.map((p) => (p.id, p.stock)), stock);
    expect(session.workspaceFinance, same(finance));
    final writes = storage.writes.length;
    expect(await session.confirmWorkspaceSupplierOpeningRecord(record,
      scope: scope, expectedRevision: 3, confirmedAt: DateTime.utc(2026, 10, 4)), isTrue);
    expect(storage.writes.length, writes);
    final reopened = await openingPostingSession(storage);
    expect(await reopened.recoverCustomerLedger(), isTrue);
    expect(reopened.workspaceSupplierLedger(record.supplierId)!.openingRecord!.toJson(), record.toJson());
    expect(reopened.workspaceSupplierLedger(record.supplierId)!.payableMinor, 50000);
    final base = entryFixture();
    expect(await reopened.saveWorkspacePurchaseEntry(base.profiles.single,
      scope: scope, draft: base.draft!, expectedRevision: 3), isTrue);
    final afterNewBook = storage.writes.length;
    expect(await reopened.confirmWorkspaceSupplierOpeningRecord(record,
      scope: scope, expectedRevision: 3, confirmedAt: DateTime.utc(2026, 10, 4)), isTrue);
    expect(storage.writes.length, afterNewBook);
  });

  test('PURCHASEPOST separate sessions cannot confirm a superseded purchase book', () async {
    final storage = _OrderJournalStorage();
    final record = openingFixture(amount: 50000);
    final first = await openingPostingSession(storage, initialRecord: record);
    final second = await openingPostingSession(storage);
    final corrected = openingFixture(revision: 4, amount: 60000);
    expect(await second.saveWorkspaceSupplierOpeningRecord(corrected,
      scope: second.workspaceSupplierScope!, expectedRevision: 3), isTrue);
    expect(await first.confirmWorkspaceSupplierOpeningRecord(record,
      scope: first.workspaceSupplierScope!, expectedRevision: 3,
      confirmedAt: DateTime.utc(2026, 10, 3)), isFalse);
    expect(first.workspaceSupplierLedger(record.supplierId), isNull);
    expect(await second.confirmWorkspaceSupplierOpeningRecord(corrected,
      scope: second.workspaceSupplierScope!, expectedRevision: 4,
      confirmedAt: DateTime.utc(2026, 10, 3)), isTrue);
    expect(second.workspaceSupplierLedger(record.supplierId)!.payableMinor, 60000);
  });

  test('PURCHASEPOST opening failure and lost response recover without duplicate balance', () async {
    final storage = _OrderJournalStorage();
    final record = openingFixture(amount: 25000, credit: true);
    final session = await openingPostingSession(storage, initialRecord: record);
    Future<bool> post(WorkSession owner) => owner.confirmWorkspaceSupplierOpeningRecord(record,
      scope: owner.workspaceSupplierScope!, expectedRevision: 3,
      confirmedAt: DateTime.utc(2026, 10, 3));
    storage.failWrite = true;
    expect(await post(session), isFalse);
    expect(session.workspaceSupplierLedger(record.supplierId), isNull);
    storage.failWrite = false;
    storage.loseWriteResponseOnce = true;
    expect(await post(session), isFalse);
    final reopened = await openingPostingSession(storage);
    expect(await post(reopened), isTrue);
    final ledger = reopened.workspaceSupplierLedger(record.supplierId)!;
    expect(ledger.creditMinor, 25000);
    expect(ledger.entries, isEmpty);
    expect(ledger.revision, 1);
  });

  test('PURCHASEPOST opening rejects unknown stale and unreviewed evidence', () async {
    for (final record in [openingFixture(), openingFixture(amount: 0, bills: const [])]) {
      final storage = _OrderJournalStorage();
      final session = await openingPostingSession(storage, initialRecord: record);
      final writes = storage.writes.length;
      expect(await session.confirmWorkspaceSupplierOpeningRecord(record,
        scope: session.workspaceSupplierScope!, expectedRevision: 3,
        confirmedAt: DateTime.utc(2026, 10, 3)), isFalse);
      expect(session.workspaceSupplierLedger(record.supplierId), isNull);
      expect(storage.writes.length, writes);
    }
    final storage = _OrderJournalStorage();
    final record = openingFixture(amount: 0);
    final session = await openingPostingSession(storage, initialRecord: record);
    expect(await session.confirmWorkspaceSupplierOpeningRecord(record,
      scope: session.workspaceSupplierScope!, expectedRevision: 2,
      confirmedAt: DateTime.utc(2026, 10, 3)), isFalse);
    expect(await session.confirmWorkspaceSupplierOpeningRecord(record,
      scope: session.workspaceSupplierScope!, expectedRevision: 3,
      confirmedAt: DateTime.utc(2026, 9, 30)), isFalse);
    expect(session.workspaceSupplierLedger(record.supplierId), isNull);
  });

  Future<WorkSession> billPostingSession(_OrderJournalStorage storage,
      WorkspaceSupplierBillAcceptance bill, {WorkLedgerFormDraftStore? moneyStore, bool inventory = false}) async {
    final record = openingFixture(amount: 0);
    final session = await openingPostingSession(storage, initialRecord: record, moneyStore: moneyStore, inventory: inventory);
    expect(await session.confirmWorkspaceSupplierOpeningRecord(record,
      scope: session.workspaceSupplierScope!, expectedRevision: 3,
      confirmedAt: DateTime.utc(2026, 10, 3)), isTrue);
    final owner = SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage);
    final old = (await owner.read('account-A', 'store-A', qa: true))!;
    final next = WorkspacePurchaseEntryBook.fromJson({...old.toJson(),
      'revision': 4, 'copies': [...old.copies.map((copy) => copy.toJson()), bill.copy.toJson()]});
    await owner.save(next, expectedRevision: 3);
    expect(await session.loadWorkspaceSuppliers(retry: true), isTrue);
    return session;
  }

  WorkspaceSupplierBillAcceptance newBillFixture() => acceptanceFixture(
    id: 'new-copy', draftId: 'new-bill', date: '2026-10-02',
    reference: 'SUP-NEW-1', total: '2840.75',
    treatment: WorkspaceOpeningBillInclusion.excluded);

  WorkspaceSupplierBillAcceptance allocatedBillFixture({String unit = '1 kg', String quantity = '12',
      String product = 'saved-product-A', String? freeQuantity, String total = '2840.75'}) {
    final bill = acceptanceFixture(id: 'new-copy', draftId: 'new-bill', date: '2026-10-02',
      reference: 'SUP-NEW-1', total: total, treatment: WorkspaceOpeningBillInclusion.excluded);
    final goods = {...bill.copy.draft.goods.first, 'productId': product,
      'pack': unit, 'quantity': quantity};
    if (freeQuantity != null) {
      goods['freeQuantity'] = freeQuantity;
    }
    final copy = WorkspacePurchaseSavedCopy.fromJson({...bill.copy.toJson(),
      'draft': {...bill.copy.draft.toJson(), 'goods': [goods]}});
    return WorkspaceSupplierBillAcceptance(copy: copy, acceptedAt: bill.acceptedAt,
      openingTreatment: bill.openingTreatment);
  }
  WorkspaceSupplierBillGoodsAllocation billGoodsLink(WorkspaceSupplierBillAcceptance bill, {
    String id = 'link-A', String receipt = 'receipt-A', int accepted = 5000,
    int damaged = 1000, int quantity = 6000, int numerator = 1, int denominator = 1,
    int freeQuantity = 0,
  }) => WorkspaceSupplierBillGoodsAllocation(operationId: id, receiptId: receipt,
    receiptLineId: 'line-A', billId: bill.billId, copyId: bill.copy.id,
    copyRevision: bill.copy.revision, billLineIndex: 0, productId: 'saved-product-A',
    billUnit: bill.copy.draft.goods.first['pack']!, stockUnit: '1 kg',
    stockUnitsNumerator: numerator, stockUnitsDenominator: denominator,
    billQuantityMilli: quantity, acceptedReceiptMilli: accepted, damagedReceiptMilli: damaged,
    freeBillQuantityMilli: freeQuantity,
    conversionReviewed: true, linkedAt: DateTime.utc(2026, 10, 4));

  WorkspaceSupplierGoodsReturn goodsReturnFixture(WorkspaceSupplierLedger ledger, {
    String id = 'physical-return-A', int accepted = 2000, int damaged = 0,
  }) {
    final receipt = ledger.goodsReceipts['receipt-A']!, line = receipt.lines.single;
    return WorkspaceSupplierGoodsReturn(operationId: id, accountScope: ledger.accountScope,
      workspaceId: ledger.workspaceId, supplierId: ledger.supplierId, receiptId: receipt.id,
      reference: 'HOST-RET-$id', reason: 'Damaged packaging', returnedOn: '2026-10-03',
      recordedAt: ledger.asOf, committedRevision: ledger.revision + 1,
      lines: [WorkspaceSupplierGoodsReturnLine(receiptLineId: line.sourceLineId,
        productId: line.productId, productLabel: line.productLabel, purchaseUnit: line.purchaseUnit,
        stockUnit: line.stockUnit, unitsPerPack: line.unitsPerPack, acceptedMilli: accepted, damagedMilli: damaged)]);
  }

  WorkspaceSupplierCreditIntent creditIntentFixture() => WorkspaceSupplierCreditIntent(
    operationId: 'host-credit-intent', accountScope: 'account-A', workspaceId: 'store-A',
    supplierId: 'supplier-A', billId: 'bill-A', copyId: 'copy-A', copyRevision: 2,
    openingId: 'opening-A', openingRevision: 1, reference: 'HOST-CN-1',
    occurredOn: '2026-10-03', reason: 'Damaged goods', amountMinor: 3000,
    requestedAt: DateTime.utc(2026, 10, 3), supports: [const WorkspaceSupplierCreditSupport(
      kind: WorkspaceSupplierCreditSupportKind.arrivalDamage, receiptId: 'receipt-A',
      receiptLineId: 'line-A', billLineIndex: 0, quantityMilli: 1000)]);
  WorkspaceLedgerFormDraft creditDraftFixture(WorkspaceSupplierCreditIntent intent, {int revision = 1}) =>
    WorkspaceLedgerFormDraft(key: (account: intent.accountScope, store: intent.workspaceId,
      customer: intent.supplierId, invoice: intent.billId, order: 'credit-copy:${intent.copyId}',
      kind: 'supplierCredit', ledgerRevision: intent.copyRevision), revision: revision,
      fields: {'amount': '30.00', 'reference': intent.reference, 'reason': intent.reason,
        'occurredOn': intent.occurredOn, 'supports': jsonEncode(intent.supports.map((s) => s.toJson()).toList()),
        'attempt': jsonEncode(intent.toJson())});

  test('PURCHASECREDITINTENT request excludes commit proof and binds exact reviewed fields', () {
    final intent = creditIntentFixture(), draft = creditDraftFixture(creditIntentFixture());
    expect(intent.valid, isTrue);
    expect(draft.valid, isTrue);
    expect(intent.toJson().containsKey('committedRevision'), isFalse);
    expect(intent.toJson().containsKey('recordedAt'), isFalse);
    expect(WorkspaceSupplierCreditIntent.fromJson(jsonDecode(jsonEncode(intent.toJson()))).toJson(), intent.toJson());
    final committed = intent.commit(revision: 7, at: intent.requestedAt.add(const Duration(minutes: 1)));
    expect(intent.matches(committed), isTrue);
    final legacy = {...committed.toJson()}..remove('requestedAt');
    expect(WorkspaceSupplierCreditNote.fromJson(legacy).valid, isTrue);
    expect(intent.matches(WorkspaceSupplierCreditNote.fromJson(legacy)), isFalse);
    expect(() => WorkspaceSupplierCreditIntent.fromJson({...intent.toJson(), 'committedRevision': 7}), throwsFormatException);
    expect(() => WorkspaceSupplierCreditIntent.fromJson({...intent.toJson(), 'recordedAt': committed.recordedAt.toIso8601String()}), throwsFormatException);
    for (final change in <Map<String, String>>[
      {'amount': '30.01'}, {'reference': 'another-note'}, {'reason': 'Changed'},
      {'occurredOn': '2026-10-02'}, {'supports': '[]'},
    ]) {
      expect(WorkspaceLedgerFormDraft(key: draft.key, revision: 1,
        fields: {...draft.fields, ...change}).valid, isFalse);
    }
    expect(WorkspaceLedgerFormDraft(key: (account: 'wrong-account', store: draft.key.store,
      customer: draft.key.customer, invoice: draft.key.invoice, order: draft.key.order,
      kind: draft.key.kind, ledgerRevision: draft.key.ledgerRevision), revision: 1, fields: draft.fields).valid, isFalse);
  });

  test('PURCHASECREDITINTENT encrypted request serializes posting and proven reset', () async {
    final storage = _OrderJournalStorage(), intent = creditIntentFixture();
    final draft = creditDraftFixture(intent);
    SecureWorkLedgerFormDraftStore owner() => SecureWorkLedgerFormDraftStore(accountScope: () => 'account-A', storage: storage);
    await owner().save(draft, expectedRevision: null);
    expect((await owner().read(draft.key))!.supplierCreditIntent!.toJson(), intent.toJson());
    final entered = Completer<void>(), release = Completer<void>();
    final posting = owner().withFrozenSupplierCredit(draft.key, jsonEncode(intent.toJson()), () async {
      entered.complete();
      await release.future;
      return true;
    });
    await entered.future;
    final clear = WorkspaceLedgerFormDraft(key: draft.key, revision: 2, fields: const {});
    final edit = owner().save(clear, expectedRevision: 1);
    final rejectedEdit = expectLater(edit, throwsA(isA<WorkGatewayException>()));
    release.complete();
    expect(await posting, isTrue);
    await rejectedEdit;
    final writes = storage.writes.length;
    await expectLater(owner().resetConfirmedSupplierCreditDraft(clear, expectedRevision: 1,
      verifyCommitted: (_) async => false), throwsA(isA<WorkGatewayException>()));
    expect(storage.writes.length, writes);
    storage.failRead = true;
    await expectLater(owner().resetConfirmedSupplierCreditDraft(clear, expectedRevision: 1,
      verifyCommitted: (_) async => true), throwsA(anything));
    storage.failRead = false;
    expect(storage.writes.length, writes);
    final committed = intent.commit(revision: 7, at: intent.requestedAt.add(const Duration(minutes: 1)));
    await owner().resetConfirmedSupplierCreditDraft(clear, expectedRevision: 1,
      verifyCommitted: (saved) async => saved.matches(committed));
    expect((await owner().read(draft.key))!.supplierCreditIntent, isNull);
    expect(storage.writes.length, writes + 1);
    await owner().resetConfirmedSupplierCreditDraft(clear, expectedRevision: 1,
      verifyCommitted: (_) async => false);
    expect(storage.writes.length, writes + 1);
  });

  test('PURCHASECREDITINTENT lost draft reply retains exact request and scope', () async {
    final storage = _OrderJournalStorage()..loseWriteResponseOnce = true;
    var account = 'account-A';
    final owner = SecureWorkLedgerFormDraftStore(accountScope: () => account, storage: storage);
    final intent = creditIntentFixture(), draft = creditDraftFixture(creditIntentFixture());
    await expectLater(owner.save(draft, expectedRevision: null), throwsStateError);
    expect((await owner.read(draft.key))!.supplierCreditIntent!.toJson(), intent.toJson());
    final writes = storage.writes.length;
    await owner.save(draft, expectedRevision: null);
    expect(storage.writes.length, writes);
    account = 'account-B';
    await expectLater(owner.withFrozenSupplierCredit(draft.key, jsonEncode(intent.toJson()), () async => true),
      throwsA(isA<WorkGatewayException>()));
    expect(storage.writes.length, writes);
  });

  for (final fault in ['ordinary', 'lost-refund-reply', 'failed-refund-save', 'unavailable-read']) {
    test('PURCHASEREFUNDSESSION $fault preserves review and refunds exactly once', () async {
      // Host-only encrypted-storage evidence, not phone acceptance data.
      final storage = _OrderJournalStorage();
      final forms = SecureWorkLedgerFormDraftStore(accountScope: () => 'account-A', storage: storage);
      final opening = openingFixture(amount: 50000, credit: true);
      var owner = await openingPostingSession(storage, initialRecord: opening, inventory: true, moneyStore: forms);
      expect(await owner.confirmWorkspaceSupplierOpeningRecord(opening, scope: owner.workspaceSupplierScope!,
        expectedRevision: 3, confirmedAt: DateTime.utc(2026, 10, 3)), isTrue);
      final ledger = owner.workspaceSupplierLedger(opening.supplierId)!;
      final intent = WorkspaceSupplierRefundIntent.fromJson({...refundIntentFixture(ledger).toJson(),
        'requestedAt': DateTime.now().toUtc().toIso8601String()});
      final key = owner.supplierRefundRecoveryFormKey(supplierId: opening.supplierId,
        sourceKind: intent.sourceKind, sourceId: intent.sourceId, openingRevision: intent.openingRevision)!;
      expect(key, intent.formKey);
      final draft = WorkspaceLedgerFormDraft(key: key, revision: 1, fields: {
        'amount': '10.00', 'channel': intent.paymentMethod, 'reference': intent.reference,
        'occurredOn': intent.occurredOn, 'sourceKind': intent.sourceKind.name,
        'sourceId': intent.sourceId, 'attempt': jsonEncode(intent.toJson()),
      });
      expect(draft.valid, isTrue);
      await owner.saveLedgerForm(draft, expectedRevision: null);
      final stock = owner.workspaceCatalogueItems.single.stock;
      expect(await owner.readWorkspaceSupplierRefundStatus(key, intent), isNull);
      await expectLater(forms.save(WorkspaceLedgerFormDraft(key: key, revision: 2,
        fields: const {}), expectedRevision: 1), throwsA(isA<WorkGatewayException>()));
      expect(await owner.resetConfirmedWorkspaceSupplierRefundDraft(
        WorkspaceLedgerFormDraft(key: key, revision: 2, fields: const {}), expectedRevision: 1), isFalse);
      if (fault == 'lost-refund-reply') storage.loseWriteResponseOnce = true;
      if (fault == 'failed-refund-save') storage.failWrite = true;
      if (fault == 'unavailable-read') storage.failRead = true;
      expect(await owner.recordWorkspaceSupplierRefundDraft(key, intent),
        fault != 'failed-refund-save' && fault != 'unavailable-read');
      storage.failWrite = false;
      storage.failRead = false;
      expect((await forms.read(key))!.supplierRefundIntent!.toJson(), intent.toJson());
      owner = await openingPostingSession(storage, inventory: true, moneyStore: forms);
      expect(await owner.recordWorkspaceSupplierRefundDraft(key, intent), isTrue);
      expect((await owner.readWorkspaceSupplierRefundStatus(key, intent))!.intent.toJson(), intent.toJson());
      expect(await owner.recoverCustomerLedger(), isTrue);
      final saved = owner.workspaceSupplierLedger(opening.supplierId)!;
      expect(saved.refunds.length, 1);
      expect(saved.balanceMinor, -49000);
      expect(owner.workspaceCatalogueItems.single.stock, stock);
      final writes = storage.writes.length;
      expect(await owner.recordWorkspaceSupplierRefundDraft(key, intent), isTrue);
      expect(storage.writes.length, writes);
      final changed = WorkspaceSupplierRefundIntent.fromJson({...intent.toJson(), 'amountMinor': 1001});
      expect(await owner.recordWorkspaceSupplierRefundDraft(key, changed), isFalse);
      expect(storage.writes.length, writes);
      if (fault == 'ordinary') {
        // A later receipt has committed, but its independent Stock projection
        // fails. That must not hide an already recorded refund or write it twice.
        final stockKey = storage.values.keys.singleWhere((k) => k.contains('workspace.inventory.'));
        storage.failWriteKey = stockKey;
        expect(await owner.confirmWorkspaceSupplierGoodsReceipt(sessionReceipt(owner),
          supplierId: opening.supplierId, scope: owner.workspaceSupplierScope!,
          expectedPurchaseRevision: 3, expectedSupplierRevision: saved.revision),
          WorkspaceGoodsReceiptSaveResult.stockRecoveryPending);
        final pendingWrites = storage.writes.length;
        expect(await owner.recordWorkspaceSupplierRefundDraft(key, intent), isTrue);
        expect(storage.writes.length, pendingWrites);
        expect((await owner.readWorkspaceSupplierRefundStatus(key, intent))!.intent.toJson(), intent.toJson());
        storage.failWriteKey = null;
      }
      expect(await owner.resetConfirmedWorkspaceSupplierRefundDraft(
        WorkspaceLedgerFormDraft(key: key, revision: 2, fields: const {}), expectedRevision: 1), isTrue);
      expect((await forms.read(key))!.supplierRefundIntent, isNull);
    });
  }

  for (final fault in ['ordinary', 'lost-credit-reply', 'failed-credit-save', 'unavailable-read']) {
    test('PURCHASECREDITSESSION $fault posts one credit through saved bill and delivery', () async {
      // Host-only native-storage journey; not phone acceptance data.
      final storage = _OrderJournalStorage();
      final formStore = SecureWorkLedgerFormDraftStore(accountScope: () => 'account-A', storage: storage);
      final opening = openingFixture(amount: 0);
      var owner = await openingPostingSession(storage, initialRecord: opening, inventory: true, moneyStore: formStore);
      final scope = owner.workspaceSupplierScope!;
      expect(await owner.confirmWorkspaceSupplierOpeningRecord(opening, scope: scope,
        expectedRevision: 3, confirmedAt: DateTime.utc(2026, 10, 3)), isTrue);
      final original = sessionReceipt(owner);
      final receipt = WorkspaceSupplierGoodsReceipt.fromJson({...original.toJson(),
        'lines': [{...original.lines.single.toJson(), 'acceptedMilli': 5000, 'damagedMilli': 1000}]});
      expect(await owner.confirmWorkspaceSupplierGoodsReceipt(receipt, supplierId: opening.supplierId,
        scope: scope, expectedPurchaseRevision: 3, expectedSupplierRevision: 1), WorkspaceGoodsReceiptSaveResult.saved);
      final product = owner.workspaceCatalogueItems.single;
      final base = allocatedBillFixture(product: product.id, unit: product.pack);
      final bill = WorkspaceSupplierBillAcceptance(copy: base.copy, acceptedAt: DateTime.now().toUtc(),
        openingTreatment: base.openingTreatment);
      final books = SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage);
      final oldBook = (await books.read('account-A', 'store-A', qa: true))!;
      await books.save(WorkspacePurchaseEntryBook.fromJson({...oldBook.toJson(), 'revision': 4,
        'copies': [...oldBook.copies.map((c) => c.toJson()), bill.copy.toJson()]}), expectedRevision: 3);
      expect(await owner.loadWorkspaceSuppliers(retry: true), isTrue);
      expect(await owner.confirmWorkspacePurchaseBill(bill.copy, scope: scope, expectedPurchaseRevision: 4,
        expectedLedgerRevision: 2, openingTreatment: bill.openingTreatment, confirmedAt: bill.acceptedAt), isTrue);
      final link = WorkspaceSupplierBillGoodsAllocation.fromJson({...billGoodsLink(bill).toJson(),
        'receiptId': receipt.id, 'receiptLineId': receipt.lines.single.sourceLineId,
        'productId': product.id, 'stockUnit': product.pack, 'linkedAt': DateTime.now().toUtc().toIso8601String()});
      expect(await owner.confirmWorkspaceSupplierBillGoodsAllocation(link, supplierId: opening.supplierId,
        scope: scope, expectedSupplierRevision: 3), isTrue);
      final ledger = owner.workspaceSupplierLedger(opening.supplierId)!;
      final intent = WorkspaceSupplierCreditIntent(operationId: 'host-session-credit',
        accountScope: ledger.accountScope, workspaceId: ledger.workspaceId, supplierId: ledger.supplierId,
        billId: bill.billId, copyId: bill.copy.id, copyRevision: bill.copy.revision,
        openingId: ledger.openingRecord!.id, openingRevision: ledger.openingRecord!.revision,
        reference: 'HOST-CN-SESSION', occurredOn: '2026-10-03', reason: 'Damaged goods', amountMinor: 3000,
        requestedAt: DateTime.now().toUtc(), supports: [WorkspaceSupplierCreditSupport(
          kind: WorkspaceSupplierCreditSupportKind.arrivalDamage, receiptId: receipt.id,
          receiptLineId: receipt.lines.single.sourceLineId, billLineIndex: 0, quantityMilli: 1000)]);
      final draft = creditDraftFixture(intent), key = owner.supplierCreditFormKey(bill.copy)!;
      expect(draft.key, key);
      await owner.saveLedgerForm(draft, expectedRevision: null);
      final stock = owner.workspaceCatalogueItems.single.stock, balance = ledger.balanceMinor!;
      expect(await owner.readWorkspaceSupplierCreditStatus(key, intent), isNull);
      if (fault == 'lost-credit-reply') storage.loseWriteResponseOnce = true;
      if (fault == 'failed-credit-save') storage.failWrite = true;
      if (fault == 'unavailable-read') storage.failRead = true;
      final posted = await owner.recordWorkspaceSupplierCreditDraft(key, intent);
      expect(posted, fault != 'failed-credit-save' && fault != 'unavailable-read');
      storage.failWrite = false;
      storage.failRead = false;
      expect((await formStore.read(key))!.supplierCreditIntent!.toJson(), intent.toJson());
      owner = await openingPostingSession(storage, inventory: true, moneyStore: formStore);
      expect(await owner.recordWorkspaceSupplierCreditDraft(key, intent), isTrue);
      final proof = (await owner.readWorkspaceSupplierCreditStatus(key, intent))!;
      expect(intent.matches(proof), isTrue);
      expect(owner.workspaceSupplierLedger(opening.supplierId)!.creditNotes.length, 1);
      expect(owner.workspaceSupplierLedger(opening.supplierId)!.balanceMinor, balance - 3000);
      expect(owner.workspaceCatalogueItems.single.stock, stock);
      final writes = storage.writes.length;
      expect(await owner.recordWorkspaceSupplierCreditDraft(key, intent), isTrue);
      expect(storage.writes.length, writes);
      final changed = WorkspaceSupplierCreditIntent.fromJson({...intent.toJson(), 'amountMinor': 3001});
      expect(await owner.recordWorkspaceSupplierCreditDraft(key, changed), isFalse);
      expect(storage.writes.length, writes);
      expect(await owner.resetConfirmedWorkspaceSupplierCreditDraft(
        WorkspaceLedgerFormDraft(key: key, revision: 2, fields: const {}), expectedRevision: 1), isTrue);
      expect((await formStore.read(key))!.supplierCreditIntent, isNull);
    });
  }

  for (final fault in ['ordinary', 'lost-shortage-reply', 'failed-shortage-save', 'unavailable-read']) {
    test('PURCHASESHORTAGESESSION $fault preserves exact review and commits once', () async {
      // Host-only storage journey, not an OPPO evaluation record.
      final storage = _OrderJournalStorage();
      final formStore = SecureWorkLedgerFormDraftStore(accountScope: () => 'account-A', storage: storage);
      final opening = openingFixture(amount: 0);
      var owner = await openingPostingSession(storage, initialRecord: opening, inventory: true, moneyStore: formStore);
      final scope = owner.workspaceSupplierScope!;
      expect(await owner.confirmWorkspaceSupplierOpeningRecord(opening, scope: scope,
        expectedRevision: 3, confirmedAt: DateTime.utc(2026, 10, 3)), isTrue);
      final original = sessionReceipt(owner);
      final receipt = WorkspaceSupplierGoodsReceipt.fromJson({...original.toJson(),
        'lines': [{...original.lines.single.toJson(), 'shortMilli': 6000}]});
      expect(await owner.confirmWorkspaceSupplierGoodsReceipt(receipt, supplierId: opening.supplierId,
        scope: scope, expectedPurchaseRevision: 3, expectedSupplierRevision: 1), WorkspaceGoodsReceiptSaveResult.saved);
      final product = owner.workspaceCatalogueItems.single;
      final base = allocatedBillFixture(product: product.id, unit: product.pack);
      final bill = WorkspaceSupplierBillAcceptance(copy: base.copy, acceptedAt: DateTime.now().toUtc(),
        openingTreatment: base.openingTreatment);
      final books = SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage);
      final oldBook = (await books.read('account-A', 'store-A', qa: true))!;
      await books.save(WorkspacePurchaseEntryBook.fromJson({...oldBook.toJson(), 'revision': 4,
        'copies': [...oldBook.copies.map((c) => c.toJson()), bill.copy.toJson()]}), expectedRevision: 3);
      expect(await owner.loadWorkspaceSuppliers(retry: true), isTrue);
      expect(await owner.confirmWorkspacePurchaseBill(bill.copy, scope: scope, expectedPurchaseRevision: 4,
        expectedLedgerRevision: 2, openingTreatment: bill.openingTreatment, confirmedAt: bill.acceptedAt), isTrue);
      final ledger = owner.workspaceSupplierLedger(opening.supplierId)!;
      final intent = ledger.reviewShortageIntent(operationId: 'host-session-shortage', billId: bill.billId,
        billLineIndex: 0, deliveryId: receipt.expectedDeliveryId, lineId: receipt.lines.single.sourceLineId,
        quantityMilli: 1000, attributionReviewed: true, requestedAt: DateTime.now().toUtc())!;
      final key = owner.supplierShortageFormKey(bill.copy)!;
      final draft = WorkspaceLedgerFormDraft(key: key, revision: 1, fields: {
        'billLineIndex': '${intent.billLineIndex}', 'deliveryId': intent.expectedDeliveryId,
        'lineId': intent.receiptLineId, 'quantityMilli': '${intent.quantityMilli}',
        'attributionReviewed': 'true', 'attempt': jsonEncode(intent.toJson())});
      await owner.saveLedgerForm(draft, expectedRevision: null);
      final stock = owner.workspaceCatalogueItems.single.stock, balance = ledger.balanceMinor;
      expect(await owner.readWorkspaceSupplierShortageStatus(key, intent), isNull);
      if (fault == 'lost-shortage-reply') storage.loseWriteResponseOnce = true;
      if (fault == 'failed-shortage-save') storage.failWrite = true;
      if (fault == 'unavailable-read') storage.failRead = true;
      expect(await owner.recordWorkspaceSupplierShortageDraft(key, intent),
        fault != 'failed-shortage-save' && fault != 'unavailable-read');
      storage.failWrite = false;
      storage.failRead = false;
      expect((await formStore.read(key))!.supplierShortageIntent!.toJson(), intent.toJson());
      owner = await openingPostingSession(storage, inventory: true, moneyStore: formStore);
      expect(await owner.recordWorkspaceSupplierShortageDraft(key, intent), isTrue);
      final proof = (await owner.readWorkspaceSupplierShortageStatus(key, intent))!;
      expect(intent.matches(proof), isTrue);
      expect(owner.workspaceSupplierLedger(opening.supplierId)!.shortageClaims.length, 1);
      expect(owner.workspaceSupplierLedger(opening.supplierId)!.balanceMinor, balance);
      expect(owner.workspaceCatalogueItems.single.stock, stock);
      final writes = storage.writes.length;
      expect(await owner.recordWorkspaceSupplierShortageDraft(key, intent), isTrue);
      expect(storage.writes.length, writes);
      final changed = WorkspaceSupplierShortageIntent.fromJson({...intent.toJson(), 'quantityMilli': 1001});
      expect(await owner.recordWorkspaceSupplierShortageDraft(key, changed), isFalse);
      expect(storage.writes.length, writes);
      expect(await owner.resetConfirmedWorkspaceSupplierShortageDraft(
        WorkspaceLedgerFormDraft(key: key, revision: 2, fields: const {}), expectedRevision: 1), isTrue);
      expect((await formStore.read(key))!.supplierShortageIntent, isNull);
    });
  }

  test('PURCHASESHORTAGE frozen review survives money but rejects changed arrivals', () async {
    final opening = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!;
    final bill = allocatedBillFixture(quantity: '10', total: '100');
    var ledger = opening.acceptReviewedBill(bill, expectedRevision: 1)!;
    WorkspaceSupplierGoodsReceipt arrival(String id, int delivered, int short) =>
      WorkspaceSupplierGoodsReceipt(id: id, expectedDeliveryId: 'delivery', reference: id,
        deliveredOn: '2026-10-03', recordedAt: ledger.asOf.add(const Duration(minutes: 1)),
        lines: [WorkspaceSupplierGoodsReceiptLine(sourceLineId: 'line-A', productId: 'saved-product-A',
          productLabel: 'Host shortage goods', purchaseUnit: '1 kg', stockUnit: '1 kg', unitsPerPack: 1,
          expectedMilli: 10000, deliveredMilli: delivered, acceptedMilli: delivered,
          damagedMilli: 0, shortMilli: short)]);
    ledger = ledger.receiveGoods(arrival('intent-arrival-1', 4000, 6000), expectedRevision: ledger.revision)!;
    ledger = ledger.receiveGoods(arrival('intent-arrival-2', 2000, 4000), expectedRevision: ledger.revision)!;
    final intent = ledger.reviewShortageIntent(operationId: 'reviewed-shortage', billId: bill.billId,
      billLineIndex: 0, deliveryId: 'delivery', lineId: 'line-A', quantityMilli: 1000,
      attributionReviewed: true, requestedAt: ledger.asOf)!;
    final encoded = intent.toJson();
    expect(encoded.containsKey('recordedAt'), isFalse);
    expect(encoded.containsKey('committedRevision'), isFalse);
    expect(intent.openingId, ledger.openingRecord!.id);
    expect(() => WorkspaceSupplierShortageIntent.fromJson({...encoded, 'recordedAt': encoded['requestedAt']}),
      throwsFormatException);
    expect(() => WorkspaceSupplierShortageIntent.fromJson({...encoded}..remove('openingRevision')),
      throwsFormatException);
    final reordered = WorkspaceSupplierShortageIntent.fromJson({...encoded,
      'receiptIds': intent.receiptIds.reversed.toList()});
    final originalRevision = ledger.revision;
    final paymentTime = ledger.asOf.add(const Duration(minutes: 1));
    ledger = ledger.recordReviewedMoney(WorkspaceSupplierLedgerEntry(
      operationId: 'unrelated-shortage-advance', reference: 'HOST-ADVANCE',
      origin: WorkspaceSupplierEntryOrigin.supplierAccount, kind: WorkspaceSupplierEntryKind.advance,
      amountMinor: 100, postedAt: paymentTime, paymentMethod: 'Cash',
      moneyReview: WorkspaceSupplierMoneyReview(occurredOn: '2026-10-03',
        openingId: ledger.openingRecord!.id, openingRevision: ledger.openingRecord!.revision,
        notIncludedInOpening: true)), expectedRevision: ledger.revision)!;
    final before = ledger;
    final committedAt = ledger.asOf.add(const Duration(minutes: 1));
    ledger = ledger.recordReviewedShortage(reordered, recordedAt: committedAt,
      expectedRevision: ledger.revision, attributionReviewed: true)!;
    final proof = ledger.shortageClaims[intent.operationId]!;
    expect(intent.matches(proof), isTrue);
    expect(proof.requestedAt, intent.requestedAt);
    expect(proof.recordedAt, committedAt);
    expect(ledger.entries.map((e) => e.toJson()).toList(), before.entries.map((e) => e.toJson()).toList());
    expect(ledger.balanceMinor, before.balanceMinor);
    final restored = WorkspaceSupplierLedger.fromJson(jsonDecode(jsonEncode(ledger.toJson())))!;
    expect(restored.recordReviewedShortage(intent, recordedAt: committedAt.add(const Duration(minutes: 1)),
      expectedRevision: originalRevision, attributionReviewed: true), same(restored));
    final changed = before.receiveGoods(arrival('intent-later-arrival', 1000, 3000),
      expectedRevision: before.revision)!;
    expect(changed.recordReviewedShortage(intent, recordedAt: changed.asOf,
      expectedRevision: changed.revision, attributionReviewed: true), isNull,
      reason: 'Later arrival must invalidate the frozen evidence, not silently recalculate it.');
    final key = (account: intent.accountScope, store: intent.workspaceId, customer: intent.supplierId,
      invoice: intent.billId, order: 'shortage-copy:${intent.copyId}', kind: 'supplierShortage',
      ledgerRevision: intent.copyRevision);
    final draft = WorkspaceLedgerFormDraft(key: key, revision: 1, fields: {
      'billLineIndex': '${intent.billLineIndex}', 'deliveryId': intent.expectedDeliveryId,
      'lineId': intent.receiptLineId, 'quantityMilli': '${intent.quantityMilli}',
      'attributionReviewed': 'true', 'attempt': jsonEncode(intent.toJson())});
    expect(draft.valid, isTrue);
    expect(WorkspaceLedgerFormDraft(key: key, revision: 1,
      fields: {...draft.fields, 'quantityMilli': '999'}).valid, isFalse);
    final storage = _OrderJournalStorage();
    final formStore = SecureWorkLedgerFormDraftStore(accountScope: () => key.account, storage: storage);
    await formStore.save(draft, expectedRevision: null);
    final reopened = SecureWorkLedgerFormDraftStore(accountScope: () => key.account, storage: storage);
    expect((await reopened.read(key))!.supplierShortageIntent!.toJson(), intent.toJson());
    final empty = WorkspaceLedgerFormDraft(key: key, revision: 2, fields: const {});
    await expectLater(reopened.save(empty, expectedRevision: 1), throwsA(isA<WorkGatewayException>()));
    var submitted = 0;
    expect(await reopened.withFrozenSupplierShortage(key, jsonEncode(intent.toJson()), () async {
      submitted++;
      return true;
    }), isTrue);
    expect(submitted, 1);
    await expectLater(reopened.withFrozenSupplierShortage(key, '${jsonEncode(reordered.toJson())} ', () async {
      submitted++;
      return true;
    }), throwsA(isA<WorkGatewayException>()));
    expect(submitted, 1);
    await expectLater(reopened.resetConfirmedSupplierShortageDraft(empty, expectedRevision: 1,
      verifyCommitted: (_) async => false), throwsA(isA<WorkGatewayException>()));
    expect((await reopened.read(key))!.supplierShortageIntent, isNotNull);
    await reopened.resetConfirmedSupplierShortageDraft(empty, expectedRevision: 1,
      verifyCommitted: (savedIntent) async => savedIntent.matches(proof));
    expect((await reopened.read(key))!.supplierShortageIntent, isNull);
  });

  test('PURCHASESHORTAGE shared delivery budget survives later goods and credit replay', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!;
    final bill = allocatedBillFixture(quantity: '10', total: '100');
    var ledger = opening.acceptReviewedBill(bill, expectedRevision: 1)!;
    WorkspaceSupplierGoodsReceipt receipt(String id, int delivered, int damaged, int short) =>
      WorkspaceSupplierGoodsReceipt(id: id, expectedDeliveryId: 'delivery', reference: id,
        deliveredOn: '2026-10-03', recordedAt: ledger.asOf.add(const Duration(minutes: 1)),
        lines: [WorkspaceSupplierGoodsReceiptLine(sourceLineId: 'line-A', productId: 'saved-product-A',
          productLabel: 'Host goods', purchaseUnit: '1 kg', stockUnit: '1 kg', unitsPerPack: 1,
          expectedMilli: 10000, deliveredMilli: delivered, acceptedMilli: delivered - damaged,
          damagedMilli: damaged, shortMilli: short)]);
    ledger = ledger.receiveGoods(receipt('arrival-1', 4000, 1000, 6000), expectedRevision: ledger.revision)!;
    ledger = ledger.receiveGoods(receipt('arrival-2', 2000, 0, 4000), expectedRevision: ledger.revision)!;
    WorkspaceSupplierLedger? claim(String id, int quantity, {bool reviewed = true}) =>
      ledger.recordShortageClaim(operationId: id, billId: bill.billId, billLineIndex: 0,
        deliveryId: 'delivery', lineId: 'line-A', quantityMilli: quantity,
        attributionReviewed: reviewed, recordedAt: ledger.asOf, expectedRevision: ledger.revision);
    expect(claim('unreviewed', 1000, reviewed: false), isNull);
    expect(claim('too-many', 4001), isNull, reason: 'Damaged but delivered goods are not shortage.');
    final originalReceipts = ledger.goodsReceipts.map((id, r) => MapEntry(id, r.toJson()));
    ledger = claim('claim-1', 2000)!;
    final first = ledger.shortageClaims['claim-1']!;
    expect(first.receiptIds, ['arrival-1', 'arrival-2']);
    expect(first.outstandingMilli, 4000);
    expect(first.priorClaimedMilli, 0);
    final omitted = {...ledger.toJson(), 'shortageClaims': {
      first.operationId: {...first.toJson(), 'receiptIds': ['arrival-2'], 'outstandingMilli': 8000}}};
    expect(WorkspaceSupplierLedger.fromJson(omitted), isNull,
      reason: 'An older saved arrival cannot be omitted to inflate the shortage.');
    final forgedPrior = {...ledger.toJson(), 'shortageClaims': {
      first.operationId: {...first.toJson(), 'priorClaimedMilli': 1}}};
    expect(WorkspaceSupplierLedger.fromJson(forgedPrior), isNull);
    final otherCopy = WorkspacePurchaseSavedCopy.fromJson({...bill.copy.toJson(),
      'id': 'short-other-copy', 'draft': {...bill.copy.draft.toJson(),
        'id': 'short-other-bill', 'invoiceReference': 'SUP-SHORT-OTHER'}});
    final otherBill = WorkspaceSupplierBillAcceptance(copy: otherCopy,
      acceptedAt: bill.acceptedAt, openingTreatment: bill.openingTreatment);
    final otherLedger = ledger.acceptReviewedBill(otherBill, expectedRevision: ledger.revision)!;
    expect(otherLedger.recordShortageClaim(operationId: 'other-bill-overflow', billId: otherBill.billId,
      billLineIndex: 0, deliveryId: 'delivery', lineId: 'line-A', quantityMilli: 2001,
      attributionReviewed: true, recordedAt: otherLedger.asOf, expectedRevision: otherLedger.revision), isNull,
      reason: 'Another bill cannot replenish the shared delivery shortage budget.');
    expect(ledger.balanceMinor, 10000);
    expect(ledger.goodsReceipts.map((id, r) => MapEntry(id, r.toJson())), originalReceipts);
    expect(claim('claim-2', 2001), isNull);
    ledger = claim('claim-2', 2000)!;
    expect(ledger.shortageClaims['claim-2']!.priorClaimIds, ['claim-1']);
    expect(claim('repeat-observation', 1), isNull);
    WorkspaceSupplierCreditNote credit(String id, String claimId, int quantity) => WorkspaceSupplierCreditNote(
      operationId: id, accountScope: ledger.accountScope, workspaceId: ledger.workspaceId,
      supplierId: ledger.supplierId, billId: bill.billId, copyId: bill.copy.id, copyRevision: bill.copy.revision,
      openingId: ledger.openingRecord!.id, openingRevision: ledger.openingRecord!.revision,
      reference: id, occurredOn: '2026-10-03', reason: 'Short delivery', amountMinor: 2000,
      recordedAt: ledger.asOf, committedRevision: ledger.revision + 1,
      supports: [WorkspaceSupplierCreditSupport(kind: WorkspaceSupplierCreditSupportKind.shortage,
        shortageClaimId: claimId, receiptId: 'arrival-1', receiptLineId: 'line-A',
        billLineIndex: 0, quantityMilli: quantity)]);
    final note = credit('CN-S1', 'claim-1', 2000);
    ledger = ledger.recordSupplierCredit(note, expectedRevision: ledger.revision)!;
    expect(ledger.recordSupplierCredit(credit('CN-duplicate', 'claim-1', 1), expectedRevision: ledger.revision), isNull);
    ledger = ledger.recordSupplierCredit(credit('CN-S2', 'claim-2', 2000), expectedRevision: ledger.revision)!;
    expect(ledger.balanceMinor, 6000);
    final savedClaims = ledger.shortageClaims.map((id, c) => MapEntry(id, c.toJson()));
    ledger = ledger.receiveGoods(receipt('arrival-3', 4000, 0, 0), expectedRevision: ledger.revision)!;
    expect(ledger.shortageClaims.map((id, c) => MapEntry(id, c.toJson())), savedClaims);
    expect(ledger.balanceMinor, 6000);
    expect(claim('late-extra', 1), isNull);
    final restored = WorkspaceSupplierLedger.fromJson(jsonDecode(jsonEncode(ledger.toJson())))!;
    expect(restored.toJson(), ledger.toJson());
    expect(restored.recordSupplierCredit(note, expectedRevision: note.committedRevision - 1), same(restored));
    expect(restored.recordShortageClaim(operationId: first.operationId, billId: first.billId,
      billLineIndex: first.billLineIndex, deliveryId: first.expectedDeliveryId, lineId: first.receiptLineId,
      quantityMilli: first.quantityMilli, attributionReviewed: true, recordedAt: first.recordedAt,
      expectedRevision: first.committedRevision - 1), same(restored));
  });

  for (final conversion in [1, 2]) {
    test('PURCHASECREDIT reviewed different-unit return conversion=$conversion', () {
      // Host-only regression: never injected into evaluation runtime storage.
      final opening = confirmedOpeningFixture(openingFixture(amount: 50000, credit: true, bills: const []))!;
      final bill = allocatedBillFixture(unit: conversion == 1 ? '1kg' : 'Carton',
        quantity: '1', total: '230');
      var ledger = opening.acceptReviewedBill(bill, expectedRevision: opening.revision)!;
      ledger = ledger.allocateRecordedMoney(moneyAllocationFixture(ledger, bill,
        amount: 23000, kind: WorkspaceSupplierMoneySourceKind.openingAdvance,
        source: ledger.openingRecord!.id), expectedRevision: ledger.revision)!;
      final receipt = WorkspaceSupplierGoodsReceipt(id: 'receipt-A', expectedDeliveryId: 'delivery',
        reference: 'HOST-DEL', deliveredOn: '2026-10-03', recordedAt: ledger.asOf,
        lines: [WorkspaceSupplierGoodsReceiptLine(sourceLineId: 'line-A', productId: 'saved-product-A',
          productLabel: 'Host goods', purchaseUnit: '1 kg', stockUnit: '1 kg', unitsPerPack: 1,
          deliveredMilli: 1000 * conversion, acceptedMilli: 1000 * conversion,
          damagedMilli: 0, shortMilli: 0)]);
      ledger = ledger.receiveGoods(receipt, expectedRevision: ledger.revision)!;
      final unmatched = ledger;
      final link = WorkspaceSupplierBillGoodsAllocation.fromJson({
        ...billGoodsLink(bill, accepted: 1000 * conversion, damaged: 0,
          quantity: 1000, numerator: conversion).toJson(),
        'linkedAt': ledger.asOf.toUtc().toIso8601String()});
      ledger = ledger.allocateBillGoods(link, expectedRevision: ledger.revision)!;
      final returned = goodsReturnFixture(ledger, accepted: 1000);
      ledger = ledger.recordGoodsReturned(returned, expectedRevision: ledger.revision)!;
      final support = ledger.availableCreditSupports(bill.billId).single.$1;
      expect(support.quantityMilli, 1000);
      final note = WorkspaceSupplierCreditNote(operationId: 'HOST-CN',
        accountScope: ledger.accountScope, workspaceId: ledger.workspaceId, supplierId: ledger.supplierId,
        billId: bill.billId, copyId: bill.copy.id, copyRevision: bill.copy.revision,
        openingId: ledger.openingRecord!.id, openingRevision: ledger.openingRecord!.revision,
        reference: 'HOST-CN', occurredOn: '2026-10-03', reason: 'Returned goods', amountMinor: 23000,
        recordedAt: ledger.asOf, committedRevision: ledger.revision + 1, supports: [support]);
      final credited = ledger.recordSupplierCredit(note, expectedRevision: ledger.revision);
      expect(credited, isNotNull);
      expect(credited!.manualBillRemainingMinor(bill.billId), -23000);
      expect(credited.creditMinor, 50000);
      expect(credited.unallocatedMoneyMinor(WorkspaceSupplierMoneySourceKind.openingAdvance,
        ledger.openingRecord!.id), 27000);
      expect(credited.goodsReceipts, ledger.goodsReceipts);
      expect(credited.goodsReturns, ledger.goodsReturns);
      expect(credited.billMoneyAllocations, ledger.billMoneyAllocations);
      expect(WorkspaceSupplierLedger.fromJson(credited.toJson())!.valid, isTrue);
      final unsupported = unmatched.recordGoodsReturned(goodsReturnFixture(unmatched, accepted: 1000),
        expectedRevision: unmatched.revision)!;
      final unsupportedNote = WorkspaceSupplierCreditNote.fromJson({...note.toJson(),
        'committedRevision': unsupported.revision + 1});
      expect(unsupported.recordSupplierCredit(unsupportedNote, expectedRevision: unsupported.revision), isNull);
      final excess = WorkspaceSupplierCreditNote.fromJson({...note.toJson(), 'supports': [
        {...support.toJson(), 'quantityMilli': 1001}]});
      expect(ledger.recordSupplierCredit(excess, expectedRevision: ledger.revision), isNull);
    });
  }

  test('PURCHASECREDIT paid bill preserves settlement capacity and immutable damage support', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!;
    final bill = allocatedBillFixture(quantity: '10', total: '100');
    var ledger = opening.acceptReviewedBill(bill, expectedRevision: 1)!;
    final receipt = WorkspaceSupplierGoodsReceipt(id: 'credit-receipt', expectedDeliveryId: 'delivery',
      reference: 'HOST-DEL', deliveredOn: '2026-10-03', recordedAt: ledger.asOf,
      lines: [WorkspaceSupplierGoodsReceiptLine(sourceLineId: 'line-A', productId: 'saved-product-A',
        productLabel: 'Host goods', purchaseUnit: '1 kg', stockUnit: '1 kg', unitsPerPack: 1,
        deliveredMilli: 10000, acceptedMilli: 7000, damagedMilli: 3000, shortMilli: 0)]);
    ledger = ledger.receiveGoods(receipt, expectedRevision: ledger.revision)!;
    final goodsLink = WorkspaceSupplierBillGoodsAllocation.fromJson({
      ...billGoodsLink(bill, receipt: receipt.id, accepted: 7000, damaged: 3000,
        quantity: 10000).toJson(), 'linkedAt': ledger.asOf.toUtc().toIso8601String()});
    ledger = ledger.allocateBillGoods(goodsLink, expectedRevision: ledger.revision)!;
    WorkspaceSupplierLedgerEntry payment(String id, int amount, {bool account = false}) =>
      WorkspaceSupplierLedgerEntry(operationId: id, reference: id,
        origin: account ? WorkspaceSupplierEntryOrigin.supplierAccount : WorkspaceSupplierEntryOrigin.manualPurchase,
        purchaseId: account ? null : bill.copy.id, billId: account ? null : bill.billId,
        kind: account ? WorkspaceSupplierEntryKind.advance : WorkspaceSupplierEntryKind.payment,
        amountMinor: amount, postedAt: ledger.asOf, paymentMethod: 'Cash',
        moneyReview: WorkspaceSupplierMoneyReview(occurredOn: '2026-10-03',
          openingId: ledger.openingRecord!.id, openingRevision: ledger.openingRecord!.revision,
          notIncludedInOpening: true));
    ledger = ledger.recordReviewedMoney(payment('paid', 6000), expectedRevision: ledger.revision)!;
    ledger = ledger.recordReviewedMoney(payment('advance', 4000, account: true), expectedRevision: ledger.revision)!;
    final allocation = moneyAllocationFixture(ledger, bill, amount: 4000,
      kind: WorkspaceSupplierMoneySourceKind.accountAdvance, source: 'advance');
    ledger = ledger.allocateRecordedMoney(allocation, expectedRevision: ledger.revision)!;
    WorkspaceSupplierCreditNote credit(String id, int quantity, int amount) => WorkspaceSupplierCreditNote(
      operationId: id, accountScope: ledger.accountScope, workspaceId: ledger.workspaceId,
      supplierId: ledger.supplierId, billId: bill.billId, copyId: bill.copy.id, copyRevision: bill.copy.revision,
      openingId: ledger.openingRecord!.id, openingRevision: ledger.openingRecord!.revision,
      reference: id, occurredOn: '2026-10-03', reason: 'Damaged on arrival', amountMinor: amount,
      recordedAt: ledger.asOf, committedRevision: ledger.revision + 1,
      supports: [WorkspaceSupplierCreditSupport(kind: WorkspaceSupplierCreditSupportKind.arrivalDamage,
        receiptId: receipt.id, receiptLineId: 'line-A', billLineIndex: 0, quantityMilli: quantity)]);
    final note = credit('CN-01', 2000, 2000);
    final secondCopy = WorkspacePurchaseSavedCopy.fromJson({...bill.copy.toJson(),
      'id': 'same-sku-copy', 'draft': {...bill.copy.draft.toJson(),
        'id': 'same-sku-bill', 'invoiceReference': 'SUP-OTHER'}});
    final secondBill = WorkspaceSupplierBillAcceptance(copy: secondCopy,
      acceptedAt: bill.acceptedAt, openingTreatment: bill.openingTreatment);
    final withOtherBill = ledger.acceptReviewedBill(secondBill, expectedRevision: ledger.revision)!;
    final wrongBill = WorkspaceSupplierCreditNote.fromJson({...note.toJson(),
      'billId': secondBill.billId, 'copyId': secondBill.copy.id,
      'copyRevision': secondBill.copy.revision, 'committedRevision': withOtherBill.revision + 1});
    expect(withOtherBill.recordSupplierCredit(wrongBill, expectedRevision: withOtherBill.revision), isNull,
      reason: 'Same product and unit on another bill do not prove receipt ownership.');
    // Host-only cross-bill credit attribution; no runtime records injected.
    final sourceCredit = WorkspaceSupplierCreditNote.fromJson({...note.toJson(),
      'committedRevision': withOtherBill.revision + 1});
    final funded = withOtherBill.recordSupplierCredit(sourceCredit, expectedRevision: withOtherBill.revision)!;
    WorkspaceSupplierBillMoneyAllocation surplusLink(WorkspaceSupplierLedger current,
        {int amount = 2000, String id = 'surplus-link'}) => WorkspaceSupplierBillMoneyAllocation(
      operationId: id, accountScope: current.accountScope, workspaceId: current.workspaceId,
      supplierId: current.supplierId, sourceKind: WorkspaceSupplierMoneySourceKind.manualBillSurplus,
      sourceId: bill.billId, sourceCopyId: bill.copy.id, sourceCopyRevision: bill.copy.revision,
      sourceEntryCount: current.entries.length, openingId: current.openingRecord!.id,
      openingRevision: current.openingRecord!.revision, billId: secondBill.billId,
      copyId: secondBill.copy.id, copyRevision: secondBill.copy.revision,
      amountMinor: amount, requestedAt: current.asOf, recordedAt: current.asOf,
      committedRevision: current.revision + 1);
    expect(withOtherBill.unallocatedMoneyMinor(WorkspaceSupplierMoneySourceKind.manualBillSurplus, bill.billId), 0);
    expect(withOtherBill.allocateRecordedMoney(surplusLink(withOtherBill), expectedRevision: withOtherBill.revision), isNull);
    final moved = funded.allocateRecordedMoney(surplusLink(funded), expectedRevision: funded.revision)!;
    expect(moved.manualBillRemainingMinor(bill.billId), 0);
    expect(moved.manualBillRemainingMinor(secondBill.billId), 8000);
    expect(moved.balanceMinor, funded.balanceMinor);
    expect(moved.entries.map((e) => e.toJson()), funded.entries.map((e) => e.toJson()));
    expect(moved.goodsReceipts, funded.goodsReceipts);
    final statement = StoreSupplierStatement(source: moved, storeName: 'HOST ONLY',
      from: DateTime(2026, 10, 1), until: DateTime(2026, 10, 4),
      generatedAt: DateTime.utc(2026, 10, 4), reviewOnly: true);
    final creditRow = statement.rows.singleWhere((r) => r[1] == 'Bill credit applied');
    expect(creditRow[2], secondBill.copy.draft.invoiceReference);
    expect(creditRow.sublist(3, 6), ['', '', '']);
    expect(creditRow[6], contains('From bill ${bill.copy.draft.invoiceReference}'));
    expect(statement.closing, moved.balanceMinor);
    expect(moved.unallocatedMoneyMinor(WorkspaceSupplierMoneySourceKind.manualBillSurplus, bill.billId), 0);
    expect(moved.unallocatedMoneyMinor(WorkspaceSupplierMoneySourceKind.accountAdvance, 'advance'), 0);
    expect(WorkspaceSupplierLedger.fromJson(moved.toJson())!.toJson(), moved.toJson());
    expect(moved.allocateRecordedMoney(surplusLink(funded), expectedRevision: funded.revision), same(moved));
    expect(moved.allocateRecordedMoney(surplusLink(moved, amount: 1, id: 'overdraw'), expectedRevision: moved.revision), isNull);
    for (final change in <Map<String, Object?>>[
      {'sourceCopyRevision': bill.copy.revision + 1}, {'sourceCopyId': 'wrong-copy'},
      {'sourceEntryCount': funded.entries.length - 1}, {'workspaceId': 'other-store'},
      {'supplierId': 'other-supplier'}, {'amountMinor': 2001},
    ]) {
      final forged = WorkspaceSupplierBillMoneyAllocation.fromJson({...surplusLink(funded).toJson(), ...change});
      expect(funded.allocateRecordedMoney(forged, expectedRevision: funded.revision), isNull);
    }
    final partial = funded.allocateRecordedMoney(surplusLink(funded, amount: 1000), expectedRevision: funded.revision)!;
    final exhausted = partial.allocateRecordedMoney(surplusLink(partial, amount: 1000, id: 'surplus-link-two'),
      expectedRevision: partial.revision)!;
    expect(exhausted.manualBillRemainingMinor(bill.billId), 0);
    expect(WorkspaceSupplierLedger.fromJson(exhausted.toJson())!.valid, isTrue);
    final missingCreditPrefix = {...moved.toJson(), 'billMoneyAllocations': {
      'surplus-link': {...moved.billMoneyAllocations['surplus-link']!.toJson(),
        'sourceEntryCount': funded.entries.length - 1}}};
    expect(WorkspaceSupplierLedger.fromJson(missingCreditPrefix), isNull);
    final futureFunding = {...moved.toJson(),
      'asOf': moved.asOf.add(const Duration(hours: 2)).toIso8601String(), 'billMoneyAllocations': {
      for (final a in moved.billMoneyAllocations.values) a.operationId: {
        ...a.toJson(), if (a.sourceKind == WorkspaceSupplierMoneySourceKind.accountAdvance)
          'recordedAt': moved.asOf.add(const Duration(hours: 1)).toIso8601String()}}};
    expect(WorkspaceSupplierLedger.fromJson(futureFunding), isNull);
    final request = WorkspaceSupplierMoneyAllocationIntent.fromJson(surplusLink(funded).intentToJson());
    expect(request.intentToJson().containsKey('sourceEntryCount'), isFalse);
    expect(() => WorkspaceSupplierMoneyAllocationIntent.fromJson({
      ...request.intentToJson(), 'sourceEntryCount': funded.entries.length}), throwsFormatException);
    expect(request.commit(revision: funded.revision + 1, at: funded.asOf,
      sourceEntryCount: funded.entries.length).toJson(), surplusLink(funded).toJson());
    ledger = ledger.recordSupplierCredit(note, expectedRevision: ledger.revision)!;
    final partialRefundIntent = WorkspaceSupplierRefundIntent.fromJson({
      ...refundIntentFixture(ledger, kind: WorkspaceSupplierRefundSourceKind.manualBillSurplus,
        source: bill.billId, bill: bill).toJson(), 'amountMinor': 1000});
    final refundFirst = ledger.recordReviewedRefund(partialRefundIntent, expectedRevision: ledger.revision,
      recordedAt: ledger.asOf)!;
    final refundThenTarget = refundFirst.acceptReviewedBill(secondBill, expectedRevision: refundFirst.revision)!;
    final refundThenLink = refundThenTarget.allocateRecordedMoney(surplusLink(refundThenTarget, amount: 1000),
      expectedRevision: refundThenTarget.revision)!;
    expect(refundThenLink.manualBillRemainingMinor(bill.billId), 0);
    expect(refundThenLink.manualBillRemainingMinor(secondBill.billId), 9000);
    final omittedEarlierRefund = {...refundThenLink.toJson(), 'billMoneyAllocations': {
      for (final a in refundThenLink.billMoneyAllocations.values) a.operationId: {
        ...a.toJson(), if (a.sourceKind == WorkspaceSupplierMoneySourceKind.manualBillSurplus) ...{
          'sourceEntryCount': ledger.entries.length, 'amountMinor': 2000}}}};
    expect(WorkspaceSupplierLedger.fromJson(omittedEarlierRefund), isNull);
    expect(WorkspaceSupplierLedger.fromJson(refundThenLink.toJson())!.valid, isTrue);
    expect(ledger.manualBillRemainingMinor(bill.billId), -2000);
    expect(ledger.balanceMinor, -2000);
    expect(ledger.unallocatedMoneyMinor(WorkspaceSupplierMoneySourceKind.accountAdvance, 'advance'), 0);
    expect(ledger.reviewedRefundCapacity(refundIntentFixture(ledger,
      kind: WorkspaceSupplierRefundSourceKind.accountAdvance, source: 'advance')), 0,
      reason: 'A later credit must not restore the advance already assigned to this bill.');
    expect(ledger.reviewedRefundCapacity(refundIntentFixture(ledger,
      kind: WorkspaceSupplierRefundSourceKind.manualBillSurplus, source: bill.billId, bill: bill)), 2000);
    expect(ledger.reviewedRefundCapacity(WorkspaceSupplierRefundIntent.fromJson(
      {...refundIntentFixture(ledger, kind: WorkspaceSupplierRefundSourceKind.manualBillSurplus,
        source: bill.billId, bill: bill).toJson(), 'occurredOn': '2026-10-02'})), isNull,
      reason: 'A refund cannot precede the credit that made the paid bill refundable.');
    expect(ledger.recordSupplierCredit(note, expectedRevision: note.committedRevision - 1), same(ledger));
    expect(ledger.recordReviewedMoney(payment('extra', 1), expectedRevision: ledger.revision), isNull);
    expect(ledger.allocateRecordedMoney(moneyAllocationFixture(ledger, bill, amount: 1,
      kind: WorkspaceSupplierMoneySourceKind.accountAdvance, source: 'advance'),
      expectedRevision: ledger.revision), isNull);
    expect(ledger.recordSupplierCredit(credit('CN-02', 1001, 1000), expectedRevision: ledger.revision), isNull);
    final finalNote = credit('CN-02', 1000, 1000);
    final complete = ledger.recordSupplierCredit(finalNote, expectedRevision: ledger.revision)!;
    expect(complete.balanceMinor, -3000);
    final refundIntent = WorkspaceSupplierRefundIntent.fromJson({
      ...refundIntentFixture(ledger, kind: WorkspaceSupplierRefundSourceKind.manualBillSurplus,
        source: bill.billId, bill: bill).toJson(), 'amountMinor': 2000,
    });
    final refunded = ledger.recordReviewedRefund(refundIntent, expectedRevision: ledger.revision,
      recordedAt: ledger.asOf)!;
    expect(refunded.balanceMinor, 0);
    final fundingAfterRefund = {...refunded.toJson(),
      'asOf': refunded.asOf.add(const Duration(hours: 2)).toIso8601String(),
      'billMoneyAllocations': {
        for (final a in refunded.billMoneyAllocations.values) a.operationId: {
          ...a.toJson(), if (a.sourceKind == WorkspaceSupplierMoneySourceKind.accountAdvance)
            'recordedAt': refunded.asOf.add(const Duration(hours: 1)).toIso8601String()}}};
    expect(WorkspaceSupplierLedger.fromJson(fundingAfterRefund), isNull,
      reason: 'An earlier revision cannot fund a refund using a transfer recorded afterwards.');
    expect(refunded.manualBillRemainingMinor(bill.billId), 0);
    expect(refunded.unallocatedMoneyMinor(WorkspaceSupplierMoneySourceKind.accountAdvance, 'advance'), 0);
    expect(refunded.billMoneyAllocations, ledger.billMoneyAllocations);
    expect(refunded.entries.where((e) => e.kind == WorkspaceSupplierEntryKind.payment)
      .map((e) => e.toJson()), ledger.entries.where((e) => e.kind == WorkspaceSupplierEntryKind.payment)
      .map((e) => e.toJson()));
    expect(refunded.goodsReceipts[receipt.id]!.toJson(), ledger.goodsReceipts[receipt.id]!.toJson());
    final refundRestored = WorkspaceSupplierLedger.fromJson(jsonDecode(jsonEncode(refunded.toJson())))!;
    expect(refundRestored.recordReviewedRefund(refundIntent, expectedRevision: ledger.revision,
      recordedAt: ledger.asOf), same(refundRestored));
    final changedSource = WorkspaceSupplierRefundIntent.fromJson({...refundIntent.toJson(),
      'sourceKind': 'accountAdvance', 'sourceId': 'advance', 'copyId': null, 'copyRevision': null});
    expect(refundRestored.recordReviewedRefund(changedSource, expectedRevision: ledger.revision,
      recordedAt: ledger.asOf), isNull);
    final forgedOrder = refunded.entries.toList();
    final refundEntry = forgedOrder.removeLast();
    forgedOrder.insert(forgedOrder.indexWhere((e) => e.operationId == note.operationId), refundEntry);
    expect(WorkspaceSupplierLedger.fromJson({...refunded.toJson(),
      'entries': forgedOrder.map((e) => e.toJson()).toList()}), isNull,
      reason: 'A refund cannot use a credit that occurs later in the journal.');
    expect(WorkspaceSupplierLedger.fromJson({...refunded.toJson(), 'refunds': {
      refundIntent.operationId: {...refunded.refunds.values.single.toJson(),
        'committedRevision': note.committedRevision},
    }}), isNull, reason: 'Credit and refund cannot share a committed revision.');
    final laterCredit = WorkspaceSupplierCreditNote.fromJson({...finalNote.toJson(),
      'committedRevision': refunded.revision + 1});
    final afterCredit = refunded.recordSupplierCredit(laterCredit, expectedRevision: refunded.revision)!;
    expect(afterCredit.balanceMinor, -1000);
    expect(afterCredit.refunds.values.single.toJson(), refunded.refunds.values.single.toJson());
    expect(complete.goodsReceipts[receipt.id]!.toJson(), receipt.toJson());
    expect(complete.goodsReturns, isEmpty);
    final restored = WorkspaceSupplierLedger.fromJson(jsonDecode(jsonEncode(complete.toJson())))!;
    expect(restored.toJson(), complete.toJson());
    final reversedMap = {for (final entry in complete.creditNotes.entries.toList().reversed)
      entry.key: entry.value.toJson()};
    expect(WorkspaceSupplierLedger.fromJson({...complete.toJson(), 'creditNotes': reversedMap})!.valid, isTrue);
    final reorderedEntries = complete.entries.toList();
    final last = reorderedEntries.removeLast();
    reorderedEntries.insert(reorderedEntries.length - 1, last);
    expect(WorkspaceSupplierLedger.fromJson({...complete.toJson(),
      'entries': reorderedEntries.map((e) => e.toJson()).toList()}), isNull);
    expect(WorkspaceSupplierLedger.fromJson({...complete.toJson(), 'billGoodsAllocations': {}}), isNull);
    expect(restored.recordSupplierCredit(finalNote, expectedRevision: finalNote.committedRevision - 1), same(restored));
    expect(WorkspaceSupplierLedger.fromJson({...complete.toJson(), 'creditNotes': {'bad': note.toJson()}}), isNull);
    expect(complete.appendConfirmed(WorkspaceSupplierLedgerEntry(operationId: 'unproved-credit',
      origin: WorkspaceSupplierEntryOrigin.manualPurchase, reference: 'CN-X',
      purchaseId: bill.copy.id, billId: bill.billId, kind: WorkspaceSupplierEntryKind.creditNote,
      amountMinor: 1, postedAt: complete.asOf), expectedRevision: complete.revision), isNull);
  });

  for (final fault in ['ordinary', 'projection-failure', 'lost-journal-reply',
    'committed-read-failure', 'independent-book-advance', 'known-stale-rejection']) {
    test('PURCHASEGOODRETURN SESSION $fault retries one negative Stock projection', () async {
      final storage = _OrderJournalStorage();
      final opening = openingFixture(amount: 0);
      final session = await openingPostingSession(storage, initialRecord: opening, inventory: true);
      expect(await session.confirmWorkspaceSupplierOpeningRecord(opening,
        scope: session.workspaceSupplierScope!, expectedRevision: 3,
        confirmedAt: DateTime.utc(2026, 10, 3)), isTrue);
      final receipt = sessionReceipt(session);
      expect(await session.confirmWorkspaceSupplierGoodsReceipt(receipt,
        supplierId: opening.supplierId, scope: session.workspaceSupplierScope!,
        expectedPurchaseRevision: 3, expectedSupplierRevision: 1), WorkspaceGoodsReceiptSaveResult.saved);
      final ledger = session.workspaceSupplierLedger(opening.supplierId)!;
      final line = receipt.lines.single;
      final returned = WorkspaceSupplierGoodsReturn(operationId: 'session-return-A',
        accountScope: ledger.accountScope, workspaceId: ledger.workspaceId,
        supplierId: ledger.supplierId, receiptId: receipt.id, reference: 'HOST-RETURN-A',
        reason: 'Damaged packaging', returnedOn: '2026-10-03',
        recordedAt: DateTime.now().toUtc(), committedRevision: ledger.revision + 1,
        lines: [WorkspaceSupplierGoodsReturnLine(receiptLineId: line.sourceLineId,
          productId: line.productId, productLabel: line.productLabel,
          purchaseUnit: line.purchaseUnit, stockUnit: line.stockUnit,
          unitsPerPack: line.unitsPerPack, acceptedMilli: 2000, damagedMilli: 0)]);
      Future<WorkspaceGoodsReceiptSaveResult> post(WorkSession owner) =>
        owner.confirmWorkspaceSupplierGoodsReturned(returned, scope: owner.workspaceSupplierScope!,
          expectedPurchaseRevision: 3, expectedSupplierRevision: ledger.revision);
      final finance = session.workspaceFinance;
      if (fault == 'known-stale-rejection') {
        final writes = storage.writes.length;
        expect(await session.confirmWorkspaceSupplierGoodsReturned(returned,
          scope: session.workspaceSupplierScope!, expectedPurchaseRevision: 3,
          expectedSupplierRevision: ledger.revision - 1), WorkspaceGoodsReceiptSaveResult.notPosted);
        expect(storage.writes.length, writes);
        expect(session.workspaceCatalogueItems.single.stock, 16);
        expect(session.workspaceSupplierLedger(opening.supplierId)!.goodsReturns, isEmpty);
        expect(session.addOrUpdateWorkspaceProduct(session.workspaceCatalogueItems.single), isTrue,
          reason: 'A proven rejection before writing must not strand Stock behind an uncertainty lock.');
        expect(await session.workspaceInventorySaved, isTrue);
        return;
      }
      if (fault == 'independent-book-advance') {
        final other = await openingPostingSession(storage, inventory: true);
        expect(await post(other), WorkspaceGoodsReceiptSaveResult.saved);
        final books = SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage);
        final book = (await books.read('account-A', 'store-A', qa: true))!;
        await books.save(WorkspacePurchaseEntryBook.fromJson({...book.toJson(),
          'revision': book.revision + 1}), expectedRevision: book.revision);
        final writes = storage.writes.length;
        expect(await post(session), WorkspaceGoodsReceiptSaveResult.saved,
          reason: session.workspaceSupplierError);
        expect(storage.writes.length, writes);
      }
      if (fault == 'projection-failure') {
        storage.failWriteKey = storage.values.keys.singleWhere((key) => key.contains('workspace.inventory.'));
      }
      if (fault == 'lost-journal-reply') storage.loseWriteResponseOnce = true;
      expect(await post(session), fault == 'projection-failure'
        ? WorkspaceGoodsReceiptSaveResult.stockRecoveryPending : WorkspaceGoodsReceiptSaveResult.saved,
        reason: session.workspaceSupplierError);
      final currentFinance = session.workspaceFinance!;
      expect((currentFinance.revision, currentFinance.salesTodayMinor, currentFinance.duesMinor,
        currentFinance.availableMinor, currentFinance.heldMinor, currentFinance.requestedMinor,
        currentFinance.paidOutMinor, currentFinance.feesMinor, currentFinance.deliveryAdjustmentsMinor,
        currentFinance.refundsMinor, currentFinance.taxWithheldMinor),
        (finance!.revision, finance.salesTodayMinor, finance.duesMinor, finance.availableMinor,
          finance.heldMinor, finance.requestedMinor, finance.paidOutMinor, finance.feesMinor,
          finance.deliveryAdjustmentsMinor, finance.refundsMinor, finance.taxWithheldMinor));
      if (fault == 'committed-read-failure') {
        storage.failRead = true;
        expect(await post(session), WorkspaceGoodsReceiptSaveResult.statusUnknown);
        expect(session.updateWorkspaceStock(productId: line.productId, quantity: 99, reason: 'Count'), isFalse);
        storage.failRead = false;
      }
      if (fault == 'projection-failure') {
        expect(session.workspaceCatalogueItems.single.stock, 16);
        expect(session.updateWorkspaceStock(productId: line.productId, quantity: 99, reason: 'Count'), isFalse);
      }
      storage.failWriteKey = null;
      final restarted = await openingPostingSession(storage, inventory: true);
      expect(await post(restarted), WorkspaceGoodsReceiptSaveResult.saved,
        reason: restarted.workspaceSupplierError);
      expect(restarted.workspaceCatalogueItems.single.stock, 14);
      final saved = restarted.workspaceSupplierLedger(opening.supplierId)!;
      expect(saved.goodsReturns.length, 1);
      expect(saved.entries, isEmpty);
      expect(saved.balanceMinor, 0);
      final writes = storage.writes.length;
      expect(await post(restarted), WorkspaceGoodsReceiptSaveResult.saved);
      expect(storage.writes.length, writes);
      expect(restarted.workspaceCatalogueItems.single.stock, 14);
    });
  }

  WorkspaceSupplierGoodsReturnIntent returnIntent(WorkspaceSupplierGoodsReturn record) =>
    WorkspaceSupplierGoodsReturnIntent.fromJson({for (final entry in record.toJson().entries)
      if (entry.key != 'recordedAt' && entry.key != 'committedRevision') entry.key: entry.value,
      'requestedAt': record.recordedAt.toUtc().toIso8601String()});
  WorkspaceLedgerFormDraft frozenReturnDraft(WorkspaceLedgerFormKey key,
      WorkspaceSupplierGoodsReturnIntent intent) => WorkspaceLedgerFormDraft(key: key, revision: 1,
        fields: {'reference': intent.reference, 'reason': intent.reason, 'returnedOn': intent.returnedOn,
          'items': jsonEncode(intent.lines.map((line) => line.toJson()).toList()),
          'attempt': jsonEncode(intent.toJson())});

  test('PURCHASERETURNINTENT codec binds receipt namespace and keeps legacy return bytes', () {
    final ledger = confirmedOpeningFixture(openingFixture(amount: 0))!
      .receiveGoods(goodsReceiptFixture(), expectedRevision: 1)!;
    final old = goodsReturnFixture(ledger), intent = returnIntent(old);
    expect(intent.valid, isTrue);
    expect(intent.matches(old), isFalse, reason: 'Never infer reviewed request from a legacy committed record.');
    expect(WorkspaceSupplierGoodsReturn.fromJson(old.toJson()).toJson(), old.toJson());
    expect(old.toJson().containsKey('requestedAt'), isFalse);
    final committed = intent.commit(revision: 9, at: intent.requestedAt.add(const Duration(seconds: 1)));
    expect(intent.matches(committed), isTrue);
    expect(intent.matches(WorkspaceSupplierGoodsReturn.fromJson(committed.toJson())), isTrue);
    final key = (account: intent.accountScope, store: intent.workspaceId, customer: intent.supplierId,
      invoice: intent.receiptId, order: 'return-receipt:${intent.receiptId}', kind: 'supplierGoodsReturn', ledgerRevision: 1);
    final draft = frozenReturnDraft(key, intent);
    expect(draft.valid, isTrue);
    expect(WorkspaceLedgerFormDraft.fromJson(draft.toJson())!.toJson(), draft.toJson());
    expect(WorkspaceLedgerFormDraft(key: (account: key.account, store: key.store, customer: key.customer,
      invoice: key.invoice, order: key.order, kind: key.kind, ledgerRevision: 2),
      revision: 1, fields: draft.fields).valid, isFalse);
    expect(WorkspaceLedgerFormDraft(key: key, revision: 1,
      fields: {...draft.fields, 'reason': 'Changed'}).valid, isFalse);
    expect(() => WorkspaceSupplierGoodsReturnIntent.fromJson({...intent.toJson(), 'creditAmount': 100}), throwsFormatException);
    expect(() => WorkspaceSupplierGoodsReturnIntent.fromJson({...intent.toJson(),
      'lines': [intent.lines.single.toJson(), intent.lines.single.toJson()]}), throwsFormatException);
  });

  for (final fault in ['ordinary', 'lost-draft-reply', 'lost-post-reply',
    'failed-draft-save', 'later-supplier-revision', 'committed-book-unavailable', 'two-instances']) {
    test('PURCHASERETURNINTENT SESSION $fault freezes before Stock and verifies reset', () async {
      final storage = _OrderJournalStorage();
      final drafts = SecureWorkLedgerFormDraftStore(accountScope: () => 'account-A', storage: storage);
      final opening = openingFixture(amount: 0);
      final session = await openingPostingSession(storage, initialRecord: opening, inventory: true, moneyStore: drafts);
      expect(await session.confirmWorkspaceSupplierOpeningRecord(opening,
        scope: session.workspaceSupplierScope!, expectedRevision: 3,
        confirmedAt: DateTime.utc(2026, 10, 3)), isTrue);
      final receipt = sessionReceipt(session);
      expect(await session.confirmWorkspaceSupplierGoodsReceipt(receipt, supplierId: opening.supplierId,
        scope: session.workspaceSupplierScope!, expectedPurchaseRevision: 3, expectedSupplierRevision: 1),
        WorkspaceGoodsReceiptSaveResult.saved);
      final ledger = session.workspaceSupplierLedger(opening.supplierId)!, line = receipt.lines.single;
      final intent = WorkspaceSupplierGoodsReturnIntent(operationId: 'draft-return-A',
        accountScope: ledger.accountScope, workspaceId: ledger.workspaceId, supplierId: ledger.supplierId,
        receiptId: receipt.id, reference: 'HOST-RETURN-DRAFT', reason: 'Damaged packaging', returnedOn: '2026-10-03',
        requestedAt: DateTime.now().toUtc(), lines: [WorkspaceSupplierGoodsReturnLine(
          receiptLineId: line.sourceLineId, productId: line.productId, productLabel: line.productLabel,
          purchaseUnit: line.purchaseUnit, stockUnit: line.stockUnit, unitsPerPack: line.unitsPerPack,
          acceptedMilli: 2000, damagedMilli: 0)]);
      final key = session.supplierGoodsReturnFormKey(opening.supplierId, receipt.id)!;
      expect(await session.recordWorkspaceSupplierGoodsReturnDraft(key, intent), isFalse,
        reason: 'An unsaved request must not post.');
      final frozen = frozenReturnDraft(key, intent);
      if (fault == 'failed-draft-save') {
        storage.failWrite = true;
        await expectLater(drafts.save(frozen, expectedRevision: null), throwsStateError);
        storage.failWrite = false;
        expect(await drafts.read(key), isNull);
        expect(await session.recordWorkspaceSupplierGoodsReturnDraft(key, intent), isFalse);
        expect(session.workspaceCatalogueItems.single.stock, 16);
      }
      if (fault == 'lost-draft-reply') storage.loseWriteResponseOnce = true;
      if (fault == 'lost-draft-reply') {
        await expectLater(drafts.save(frozen, expectedRevision: null), throwsStateError);
      } else { await drafts.save(frozen, expectedRevision: null); }
      expect((await drafts.read(key))!.toJson(), frozen.toJson());
      expect(session.workspaceCatalogueItems.single.stock, 16);
      await expectLater(drafts.save(WorkspaceLedgerFormDraft(key: key, revision: 2, fields: const {}),
        expectedRevision: 1), throwsA(isA<WorkGatewayException>()));
      final empty = WorkspaceLedgerFormDraft(key: key, revision: 2, fields: const {});
      expect(await session.resetConfirmedWorkspaceSupplierGoodsReturnDraft(empty, expectedRevision: 1), isFalse);
      final expectedStock = fault == 'later-supplier-revision' ? 13 : 14;
      if (fault == 'later-supplier-revision') {
        final other = intent.commit(revision: ledger.revision + 1, at: DateTime.now().toUtc());
        final changed = WorkspaceSupplierGoodsReturn.fromJson({...other.toJson(),
          'operationId': 'other-return', 'lines': [{...intent.lines.single.toJson(),
            'receiptLineId': line.sourceLineId, 'acceptedMilli': 1000, 'damagedMilli': 0}]
        });
        expect(await session.confirmWorkspaceSupplierGoodsReturned(changed,
          scope: session.workspaceSupplierScope!, expectedPurchaseRevision: 3,
          expectedSupplierRevision: ledger.revision), WorkspaceGoodsReceiptSaveResult.saved);
      }
      if (fault == 'two-instances') {
        final second = await openingPostingSession(storage, inventory: true, moneyStore: drafts);
        expect(await Future.wait([session.recordWorkspaceSupplierGoodsReturnDraft(key, intent),
          second.recordWorkspaceSupplierGoodsReturnDraft(key, intent)]), [true, true]);
      }
      if (fault == 'lost-post-reply') storage.loseWriteResponseOnce = true;
      expect(await session.recordWorkspaceSupplierGoodsReturnDraft(key, intent), isTrue,
        reason: session.workspaceSupplierError);
      expect(session.workspaceCatalogueItems.single.stock, expectedStock);
      final writes = storage.writes.length;
      final restarted = await openingPostingSession(storage, inventory: true, moneyStore: drafts);
      if (fault == 'committed-book-unavailable') {
        storage.failReadKey = storage.values.keys.singleWhere((key) => key.contains('workspace.purchase-entry.'));
      }
      expect(await restarted.recordWorkspaceSupplierGoodsReturnDraft(key, intent), isTrue,
        reason: restarted.workspaceSupplierError);
      storage.failReadKey = null;
      expect(storage.writes.length, writes);
      expect(restarted.workspaceCatalogueItems.single.stock, expectedStock);
      expect(restarted.workspaceSupplierLedger(opening.supplierId)!.goodsReturns.length,
        fault == 'later-supplier-revision' ? 2 : 1);
      storage.failRead = true;
      expect(await restarted.resetConfirmedWorkspaceSupplierGoodsReturnDraft(empty, expectedRevision: 1), isFalse);
      storage.failRead = false;
      storage.loseWriteResponseOnce = true;
      expect(await restarted.resetConfirmedWorkspaceSupplierGoodsReturnDraft(empty, expectedRevision: 1), isFalse);
      expect(await restarted.resetConfirmedWorkspaceSupplierGoodsReturnDraft(empty, expectedRevision: 1), isTrue);
      expect((await drafts.read(key))!.supplierGoodsReturnIntent, isNull);
      expect(await restarted.recordWorkspaceSupplierGoodsReturnDraft(key, intent), isFalse);
      expect(restarted.workspaceCatalogueItems.single.stock, expectedStock);
    });
  }

  test('PURCHASEGOODRETURN partial cumulative quantities retain receipt and no money effect', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 0))!;
    final receipt = goodsReceiptFixture(accepted: 5000, damaged: 1000);
    final received = opening.receiveGoods(receipt, expectedRevision: 1)!;
    final first = goodsReturnFixture(received);
    final returned = received.recordGoodsReturned(first, expectedRevision: 2)!;
    expect(returned.balanceMinor, received.balanceMinor);
    expect(returned.entries, received.entries);
    expect(returned.goodsReceipts['receipt-A']!.toJson(), receipt.toJson());
    expect(identical(returned.recordGoodsReturned(first, expectedRevision: 2), returned), isTrue);
    final last = goodsReturnFixture(returned, id: 'physical-return-B', accepted: 3000, damaged: 1000);
    final all = returned.recordGoodsReturned(last, expectedRevision: 3)!;
    expect(all.goodsReturns.length, 2);
    expect(all.recordGoodsReturned(goodsReturnFixture(all, id: 'over-return', accepted: 1000), expectedRevision: 4), isNull);
    expect(all.recordGoodsReturned(goodsReturnFixture(all, id: 'over-damage', accepted: 0, damaged: 1), expectedRevision: 4), isNull);
    expect(WorkspaceSupplierLedger.fromJson(all.toJson())!.toJson(), all.toJson());
    expect(WorkspaceSupplierLedger.fromJson({...all.toJson(), 'goodsReturns': null}), isNull);
    final changed = WorkspaceSupplierGoodsReturn.fromJson({...first.toJson(), 'reason': 'Changed reason'});
    expect(returned.recordGoodsReturned(changed, expectedRevision: 2), isNull);
    expect(WorkspaceSupplierLedger.fromJson({...all.toJson(), 'goodsReturns': {}})!.canFollow(all), isFalse);
  });

  test('PURCHASEGOODRETURN never-stocked damage has no Stock removal and rejects mapping drift', () {
    final received = confirmedOpeningFixture(openingFixture(amount: 0))!
      .receiveGoods(goodsReceiptFixture(accepted: 5000, damaged: 1000), expectedRevision: 1)!;
    final rejected = goodsReturnFixture(received, accepted: 0, damaged: 1000);
    expect(rejected.movementFor(rejected.lines.single), isNull);
    expect(received.recordGoodsReturned(rejected, expectedRevision: 2), isNotNull);
    for (final change in [<String, Object?>{'unitsPerPack': 2}, {'productId': 'other-product'}, {'receiptLineId': 'other-line'}]) {
      final changed = WorkspaceSupplierGoodsReturn.fromJson({...rejected.toJson(),
        'lines': [{...rejected.lines.single.toJson(), ...change}]});
      expect(received.recordGoodsReturned(changed, expectedRevision: 2), isNull);
    }
    expect(() => WorkspaceSupplierGoodsReturn.fromJson({...rejected.toJson(), 'creditAmount': 100}), throwsFormatException);
    expect(received.recordGoodsReturned(WorkspaceSupplierGoodsReturn.fromJson({...rejected.toJson(),
      'supplierId': 'other-supplier'}), expectedRevision: 2), isNull);
    expect(WorkspaceSupplierGoodsReturnLine(receiptLineId: 'line-A', productId: 'saved-product-A',
      productLabel: 'Rice', purchaseUnit: 'kg', stockUnit: 'kg', unitsPerPack: 1,
      acceptedMilli: 500, damagedMilli: 0).valid, isFalse);
  });

  test('PURCHASEGOODRETURN checkpoint requires exact Stock removal and keeps prior stock reservations', () {
    final receipt = goodsReceiptFixture(prior: const {'original-stock': 4});
    final received = confirmedOpeningFixture(openingFixture(amount: 0))!.receiveGoods(receipt, expectedRevision: 1)!;
    final record = goodsReturnFixture(received);
    final returned = received.recordGoodsReturned(record, expectedRevision: 2)!;
    final original = originalGoodsFixture(), addition = receipt.movementFor(receipt.lines.single)!;
    final removal = record.movementFor(record.lines.single)!;
    WorkspaceLedgerCheckpoint checkpoint(WorkspaceSupplierLedger ledger, List<WorkspaceStockMovement> movements) =>
      WorkspaceLedgerCheckpoint(revision: 1, finance: receiptFinanceFixture(), inventory: receiptInventoryFixture(movements),
        supplierLedgers: {ledger.supplierId: ledger});
    expect(checkpoint(returned, [original, addition, removal]).valid, isTrue);
    expect(checkpoint(returned, [original, addition]).valid, isFalse);
    expect(checkpoint(received, [original, addition, removal]).valid, isFalse);
    expect(returned.goodsReceipts['receipt-A']!.lines.single.priorStockUnits, {'original-stock': 4});
    final forged = WorkspaceStockMovement(id: removal.id, productId: removal.productId, productLabel: removal.productLabel,
      kind: removal.kind, quantityDelta: -1, reason: removal.reason, occurredAt: removal.occurredAt,
      referenceKind: removal.referenceKind, referenceId: removal.referenceId);
    expect(checkpoint(returned, [original, addition, forged]).valid, isFalse);
    for (final kind in [WorkspaceStockMovementKind.sale, WorkspaceStockMovementKind.reserved]) {
      final consumed = WorkspaceStockMovement(id: 'already-${kind.name}', productId: original.productId,
        productLabel: original.productLabel, kind: kind, quantityDelta: -12,
        reason: 'HOST existing sale or reservation', occurredAt: removal.occurredAt);
      expect(checkpoint(received, [original, addition, consumed]).valid, isTrue);
      expect(checkpoint(returned, [original, addition, consumed, removal]).valid, isFalse,
        reason: 'Received quantity alone does not prove currently available Stock.');
    }
    final laterReceipt = goodsReceiptFixture(id: 'receipt-B', group: 'expected-B',
      delivered: 7000, accepted: 7000, expected: 7000, prior: const {'original-stock': 7});
    final later = returned.receiveGoods(laterReceipt, expectedRevision: 3)!;
    expect(checkpoint(later, [original, addition, removal]).valid, isFalse,
      reason: 'Returned goods never release already-consumed original Stock provenance for relinking.');
  });

  for (final mode in ['absent-checkpoint', 'new-supplier', 'future-return', 'ordinary', 'damage-only']) {
    test('PURCHASEGOODRETURN native $mode enforces prior saved receipt without changing decoding', () async {
      final storage = _OrderJournalStorage();
      final journal = SecureWorkLedgerCheckpointStore(accountScope: () => 'account-A', storage: storage);
      final receipt = goodsReceiptFixture(accepted: 5000, damaged: 1000);
      final received = confirmedOpeningFixture(openingFixture(amount: 0))!.receiveGoods(receipt, expectedRevision: 1)!;
      final original = goodsReturnFixture(received, accepted: mode == 'damage-only' ? 0 : 2000,
        damaged: mode == 'damage-only' ? 1000 : 0);
      final record = mode != 'future-return' ? original : WorkspaceSupplierGoodsReturn.fromJson({...original.toJson(),
        'recordedAt': DateTime.now().toUtc().add(const Duration(days: 1)).toIso8601String()});
      final returned = received.recordGoodsReturned(record, expectedRevision: 2)!;
      final addition = receipt.movementFor(receipt.lines.single)!;
      final removal = record.movementFor(record.lines.single);
      WorkspaceLedgerCheckpoint checkpoint(int revision, Map<String, WorkspaceSupplierLedger> ledgers,
        List<WorkspaceStockMovement> movements, DateTime asOf) => WorkspaceLedgerCheckpoint(revision: revision,
        finance: receiptFinanceFixture(), inventory: WorkspaceInventoryLedger(accountScope: 'account-A', workspaceId: 'store-A',
          revision: revision, asOf: asOf, openingQuantities: const {'saved-product-A': 0}, movements: movements),
        supplierLedgers: ledgers);
      if (mode != 'absent-checkpoint') {
        await journal.save(checkpoint(1, mode == 'new-supplier' ? {} : {received.supplierId: received},
          mode == 'new-supplier' ? [] : [addition], received.asOf), expectedRevision: null);
      }
      final next = checkpoint(mode == 'absent-checkpoint' ? 1 : 2, {returned.supplierId: returned},
        [addition, ?removal], returned.asOf);
      expect(next.valid, isTrue);
      expect(WorkspaceLedgerCheckpoint.fromJson(next.toJson())!.valid, isTrue,
        reason: 'Historical decode does not require a predecessor that may no longer be available.');
      final writes = storage.writes.length;
      if (mode == 'ordinary' || mode == 'damage-only') {
        await journal.save(next, expectedRevision: 1);
        expect((await journal.read('account-A', 'store-A'))!.supplierLedgers[returned.supplierId]!.goodsReturns.length, 1);
        await journal.save(next, expectedRevision: 1);
        expect(storage.writes.length, writes + 1);
      } else {
        await expectLater(journal.save(next, expectedRevision: mode == 'absent-checkpoint' ? null : 1),
          throwsA(isA<WorkGatewayException>()));
        expect(storage.writes.length, writes);
      }
    });
  }

  test('PURCHASEGOODRETURN subsequent constructors preserve physical evidence and financial allocations', () {
    final bill = allocatedBillFixture();
    final opening = confirmedOpeningFixture(openingFixture(amount: 10000, credit: true, bills: const []))!;
    final received = opening.receiveGoods(goodsReceiptFixture(), expectedRevision: 1)!;
    final returned = received.recordGoodsReturned(goodsReturnFixture(received), expectedRevision: 2)!;
    final billed = returned.acceptReviewedBill(bill, expectedRevision: 3)!;
    final linked = billed.allocateBillGoods(billGoodsLink(bill, accepted: 6000, damaged: 0), expectedRevision: 4)!;
    final link = WorkspaceSupplierBillMoneyAllocation.fromJson({...moneyAllocationFixture(linked, bill).toJson(),
      'recordedAt': linked.asOf.toUtc().toIso8601String()});
    final paid = linked.allocateRecordedMoney(link, expectedRevision: 5)!;
    final later = paid.receiveGoods(goodsReceiptFixture(id: 'receipt-B'), expectedRevision: 6)!;
    expect(later.goodsReturns.values.single.toJson(), returned.goodsReturns.values.single.toJson());
    expect(later.billMoneyAllocations.length, 1);
    expect(later.billGoodsAllocations.length, 1);
    expect(later.balanceMinor, bill.amountMinor! - 10000);
    final money = WorkspaceSupplierLedgerEntry(operationId: 'payment-after-return', reference: 'HOST-PAY',
      origin: WorkspaceSupplierEntryOrigin.supplierAccount, kind: WorkspaceSupplierEntryKind.payment,
      amountMinor: 1000, paymentMethod: 'Cash', postedAt: later.asOf,
      moneyReview: WorkspaceSupplierMoneyReview(occurredOn: '2026-10-03',
        openingId: opening.openingRecord!.id, openingRevision: opening.openingRecord!.revision, notIncludedInOpening: true));
    expect(later.recordReviewedMoney(money, expectedRevision: 7)!.goodsReturns.length, 1);
  });

  for (final goodsFirst in [true, false]) {
    test('PURCHASELINK bill and goods arrival order $goodsFirst preserves separate effects', () {
      final opening = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!;
      final bill = allocatedBillFixture();
      final receipt = goodsReceiptFixture(accepted: 5000, damaged: 1000);
      final both = goodsFirst
        ? opening.receiveGoods(receipt, expectedRevision: 1)!.acceptReviewedBill(bill, expectedRevision: 2)!
        : opening.acceptReviewedBill(bill, expectedRevision: 1)!.receiveGoods(receipt, expectedRevision: 2)!;
      final linked = both.allocateBillGoods(billGoodsLink(bill), expectedRevision: 3)!;
      expect(linked.valid, isTrue);
      expect(linked.balanceMinor, both.balanceMinor);
      expect(linked.entries.map((e) => e.toJson()).toList(), both.entries.map((e) => e.toJson()).toList());
      expect(linked.goodsReceipts['receipt-A']!.toJson(), receipt.toJson());
      expect(linked.billGoodsAllocations.values.single.billQuantityMilli, 6000);
      expect(WorkspaceSupplierLedger.fromJson(linked.toJson())!.toJson(), linked.toJson());
    });
  }

  for (final failure in ['none', 'before-review', 'lost-review', 'lost-post', 'race-review-first', 'race-post-first']) {
    test('PURCHASELINKREVIEW $failure retains exact operation through restart without Stock or money changes', () async {
      // Host-only storage fixture, never runtime acceptance records.
      final storage = _OrderJournalStorage();
      final opening = openingFixture(amount: 0);
      final owner = await openingPostingSession(storage, initialRecord: opening, inventory: true);
      final scope = owner.workspaceSupplierScope!;
      expect(await owner.confirmWorkspaceSupplierOpeningRecord(opening, scope: scope,
        expectedRevision: 3, confirmedAt: DateTime.utc(2026, 10, 3)), isTrue);
      final receipt = sessionReceipt(owner);
      expect(await owner.saveWorkspaceGoodsReceiptDraft(receipt, supplierId: opening.supplierId,
        scope: scope, expectedRevision: 3), isTrue);
      expect(await owner.confirmWorkspaceSupplierGoodsReceipt(receipt, supplierId: opening.supplierId,
        scope: scope, expectedPurchaseRevision: 4, expectedSupplierRevision: 1,
        requireSavedReview: true), WorkspaceGoodsReceiptSaveResult.saved);
      final product = owner.workspaceCatalogueItems.single;
      final base = allocatedBillFixture(product: product.id, unit: product.pack);
      final bill = WorkspaceSupplierBillAcceptance(copy: base.copy,
        acceptedAt: DateTime.now().toUtc(), openingTreatment: base.openingTreatment);
      final books = SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage);
      final old = (await books.read('account-A', 'store-A', qa: true))!;
      await books.save(WorkspacePurchaseEntryBook.fromJson({...old.toJson(), 'revision': 5,
        'copies': [...old.copies.map((c) => c.toJson()), bill.copy.toJson()]}), expectedRevision: 4);
      expect(await owner.loadWorkspaceSuppliers(retry: true), isTrue);
      expect(await owner.confirmWorkspacePurchaseBill(bill.copy, scope: scope,
        expectedPurchaseRevision: 5, expectedLedgerRevision: 2,
        openingTreatment: bill.openingTreatment, confirmedAt: bill.acceptedAt), isTrue);
      final link = WorkspaceSupplierBillGoodsAllocation.fromJson({...billGoodsLink(bill).toJson(),
        'receiptId': receipt.id, 'receiptLineId': receipt.lines.single.sourceLineId,
        'productId': product.id, 'stockUnit': product.pack, 'acceptedReceiptMilli': 6000,
        'damagedReceiptMilli': 0, 'linkedAt': DateTime.now().toUtc().toIso8601String()});
      final stock = owner.workspaceCatalogueItems.single.stock;
      final balance = owner.workspaceSupplierLedger(opening.supplierId)!.balanceMinor;
      expect(await owner.confirmWorkspaceSupplierBillGoodsAllocation(link,
        supplierId: opening.supplierId, scope: scope, expectedSupplierRevision: 3,
        requireSavedReview: true, expectedPurchaseRevision: 5), isFalse,
        reason: 'Unreviewed operation may not post through the frontend lane.');
      if (failure.startsWith('race-')) {
        final other = await openingPostingSession(storage, inventory: true);
        expect(await other.recoverCustomerLedger(), isTrue);
        final conflicting = WorkspaceSupplierBillGoodsAllocation.fromJson({...link.toJson(),
          'acceptedReceiptMilli': 3000, 'billQuantityMilli': 3000});
        final held = Completer<void>();
        storage.holdWrite = held;
        final beforeWrites = storage.writes.length;
        Future<bool> review() => owner.saveWorkspaceBillGoodsReview(link, supplierId: opening.supplierId,
          scope: scope, expectedPurchaseRevision: 5, expectedSupplierRevision: 3);
        Future<bool> post() => other.confirmWorkspaceSupplierBillGoodsAllocation(conflicting,
          supplierId: opening.supplierId, scope: other.workspaceSupplierScope!, expectedSupplierRevision: 3);
        final first = failure == 'race-review-first' ? review() : post();
        for (var attempt = 0; attempt < 100 && storage.writes.length == beforeWrites; attempt++) {
          await Future<void>.delayed(Duration.zero);
        }
        expect(storage.writes.length, beforeWrites + 1, reason: 'First operation is live inside its guarded write.');
        final second = failure == 'race-review-first' ? post() : review();
        await Future<void>.delayed(Duration.zero);
        held.complete();
        expect(await first, isTrue);
        expect(await second, isFalse, reason: 'Conflicting review and posting cannot both become durable.');
        storage.holdWrite = null;
        expect(await owner.loadWorkspaceSuppliers(retry: true), isTrue);
        expect(await owner.recoverCustomerLedger(), isTrue);
        expect(owner.workspaceBillGoodsReviews.length, failure == 'race-review-first' ? 1 : 0);
        expect(owner.workspaceSupplierLedger(opening.supplierId)!.billGoodsAllocations.length,
          failure == 'race-post-first' ? 1 : 0);
        expect(owner.workspaceCatalogueItems.single.stock, stock);
        expect(owner.workspaceSupplierLedger(opening.supplierId)!.balanceMinor, balance);
        final restarted = await openingPostingSession(storage, inventory: true);
        expect(await restarted.recoverCustomerLedger(), isTrue);
        expect(restarted.workspaceBillGoodsReviews.length, failure == 'race-review-first' ? 1 : 0);
        expect(restarted.workspaceSupplierLedger(opening.supplierId)!.billGoodsAllocations.length,
          failure == 'race-post-first' ? 1 : 0);
        expect(restarted.workspaceCatalogueItems.single.stock, stock);
        expect(restarted.workspaceSupplierLedger(opening.supplierId)!.balanceMinor, balance);
        return;
      }
      storage.failWrite = failure == 'before-review';
      storage.loseWriteResponseOnce = failure == 'lost-review';
      final saved = await owner.saveWorkspaceBillGoodsReview(link, supplierId: opening.supplierId,
        scope: scope, expectedPurchaseRevision: 5, expectedSupplierRevision: 3);
      expect(saved, failure != 'before-review',
        reason: 'The secure store verifies identical saved bytes after a lost review-save reply.');
      storage.failWrite = false;
      final reopened = await openingPostingSession(storage, inventory: true);
      expect(await reopened.recoverCustomerLedger(), isTrue);
      if (failure == 'before-review') {
        expect(reopened.workspaceBillGoodsReviews, isEmpty);
        expect(await reopened.saveWorkspaceBillGoodsReview(link, supplierId: opening.supplierId,
          scope: reopened.workspaceSupplierScope!, expectedPurchaseRevision: 5, expectedSupplierRevision: 3), isTrue);
      }
      expect(reopened.workspaceBillGoodsReviews.single.allocation.toJson(), link.toJson());
      expect(reopened.workspaceSupplierLedger(opening.supplierId)!.billGoodsAllocations, isEmpty);
      final changed = WorkspaceSupplierBillGoodsAllocation.fromJson({...link.toJson(),
        'acceptedReceiptMilli': 3000, 'billQuantityMilli': 3000});
      expect(await reopened.confirmWorkspaceSupplierBillGoodsAllocation(changed,
        supplierId: opening.supplierId, scope: reopened.workspaceSupplierScope!,
        expectedSupplierRevision: 3), isFalse,
        reason: 'Optional review mode must not bypass an existing frozen operation.');
      final bookKey = storage.values.keys.singleWhere((key) =>
        storage.values[key]!.contains('billGoodsReviews'));
      storage.failReadKey = bookKey;
      expect(await reopened.confirmWorkspaceSupplierBillGoodsAllocation(link,
        supplierId: opening.supplierId, scope: reopened.workspaceSupplierScope!,
        expectedSupplierRevision: 3, requireSavedReview: true, expectedPurchaseRevision: 6), isFalse);
      expect(reopened.workspaceSupplierRecoveryRequired, isTrue);
      storage.failReadKey = null;
      expect(await reopened.loadWorkspaceSuppliers(retry: true), isTrue);
      expect(await reopened.recoverCustomerLedger(), isTrue);
      storage.loseWriteResponseOnce = failure == 'lost-post';
      final posted = await reopened.confirmWorkspaceSupplierBillGoodsAllocation(link,
        supplierId: opening.supplierId, scope: reopened.workspaceSupplierScope!,
        expectedSupplierRevision: 3, requireSavedReview: true, expectedPurchaseRevision: 6);
      expect(posted, failure != 'lost-post');
      expect(await reopened.recoverCustomerLedger(), isTrue);
      final writes = storage.writes.length;
      expect(await reopened.confirmWorkspaceSupplierBillGoodsAllocation(link,
        supplierId: opening.supplierId, scope: reopened.workspaceSupplierScope!,
        expectedSupplierRevision: 3, requireSavedReview: true, expectedPurchaseRevision: 6), isTrue);
      expect(storage.writes.length, writes);
      expect(reopened.workspaceCatalogueItems.single.stock, stock);
      expect(reopened.workspaceSupplierLedger(opening.supplierId)!.balanceMinor, balance);
      final persisted = (await books.read('account-A', 'store-A', qa: true))!;
      expect(() => WorkspacePurchaseEntryBook.fromJson({...persisted.toJson(),
        'billGoodsReviews': [{...persisted.billGoodsReviews.single.toJson(), 'supplierId': 'other-supplier'}]}), throwsFormatException);
      await expectLater(books.save(WorkspacePurchaseEntryBook.fromJson({...persisted.toJson(),
        'revision': 7, 'billGoodsReviews': <Object?>[]}), expectedRevision: 6), throwsA(isA<WorkGatewayException>()));
      await books.save(WorkspacePurchaseEntryBook.fromJson({...persisted.toJson(), 'revision': 7}), expectedRevision: 6);
      expect(await reopened.loadWorkspaceSuppliers(retry: true), isTrue);
      final laterWrites = storage.writes.length;
      expect(await reopened.confirmWorkspaceSupplierBillGoodsAllocation(link,
        supplierId: opening.supplierId, scope: reopened.workspaceSupplierScope!,
        expectedSupplierRevision: 3, requireSavedReview: true, expectedPurchaseRevision: 6), isTrue,
        reason: 'Exact committed proof survives unrelated later book revision.');
      expect(storage.writes.length, laterWrites);
    });
  }

  Future<(WorkSession, WorkspaceSupplierOpeningRecord, WorkspaceSupplierBillGoodsAllocation,
      SecureWorkPurchaseEntryStore)> preparedCancellation(_OrderJournalStorage storage) async {
    final opening = openingFixture(amount: 0);
    final owner = await openingPostingSession(storage, initialRecord: opening, inventory: true);
    final scope = owner.workspaceSupplierScope!;
    expect(await owner.confirmWorkspaceSupplierOpeningRecord(opening, scope: scope,
      expectedRevision: 3, confirmedAt: DateTime.utc(2026, 10, 3)), isTrue);
    final receipt = sessionReceipt(owner);
    expect(await owner.saveWorkspaceGoodsReceiptDraft(receipt, supplierId: opening.supplierId,
      scope: scope, expectedRevision: 3), isTrue);
    expect(await owner.confirmWorkspaceSupplierGoodsReceipt(receipt, supplierId: opening.supplierId,
      scope: scope, expectedPurchaseRevision: 4, expectedSupplierRevision: 1,
      requireSavedReview: true), WorkspaceGoodsReceiptSaveResult.saved);
    final product = owner.workspaceCatalogueItems.single;
    final base = allocatedBillFixture(product: product.id, unit: product.pack);
    final bill = WorkspaceSupplierBillAcceptance(copy: base.copy,
      acceptedAt: DateTime.now().toUtc(), openingTreatment: base.openingTreatment);
    final books = SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage);
    final old = (await books.read('account-A', 'store-A', qa: true))!;
    await books.save(WorkspacePurchaseEntryBook.fromJson({...old.toJson(), 'revision': 5,
      'copies': [...old.copies.map((c) => c.toJson()), bill.copy.toJson()]}), expectedRevision: 4);
    expect(await owner.loadWorkspaceSuppliers(retry: true), isTrue);
    expect(await owner.confirmWorkspacePurchaseBill(bill.copy, scope: scope,
      expectedPurchaseRevision: 5, expectedLedgerRevision: 2,
      openingTreatment: bill.openingTreatment, confirmedAt: bill.acceptedAt), isTrue);
    final link = WorkspaceSupplierBillGoodsAllocation.fromJson({...billGoodsLink(bill).toJson(),
      'receiptId': receipt.id, 'receiptLineId': receipt.lines.single.sourceLineId,
      'productId': product.id, 'stockUnit': product.pack, 'acceptedReceiptMilli': 6000,
      'damagedReceiptMilli': 0, 'linkedAt': DateTime.now().toUtc().toIso8601String()});
    expect(await owner.saveWorkspaceBillGoodsReview(link, supplierId: opening.supplierId,
      scope: scope, expectedPurchaseRevision: 5, expectedSupplierRevision: 3), isTrue);
    return (owner, opening, link, books);
  }

  for (final mode in ['ordinary', 'before-cancel', 'lost-cancel', 'missing-journal',
      'read-journal', 'corrupt-journal', 'committed', 'contradiction', 'race-cancel-first', 'race-post-first']) {
    test('PURCHASELINKCANCEL $mode keeps review audit and goods money identities', () async {
      // Deliberate host-only failure/race fixtures. Never runtime evaluation records.
      final storage = _OrderJournalStorage();
      final (owner, opening, link, books) = await preparedCancellation(storage);
      final scope = owner.workspaceSupplierScope!;
      final stock = owner.workspaceCatalogueItems.single.stock;
      final ledgerBefore = owner.workspaceSupplierLedger(opening.supplierId)!;
      final at = DateTime.now().toUtc();
      const reason = 'HOST correct matching details';
      Future<bool> cancel(WorkSession session) => session.abandonWorkspaceBillGoodsReview(link.operationId,
        supplierId: opening.supplierId, scope: session.workspaceSupplierScope!,
        expectedRevision: 6, cancelledAt: at, reason: reason);
      Future<bool> post(WorkSession session) => session.confirmWorkspaceSupplierBillGoodsAllocation(link,
        supplierId: opening.supplierId, scope: session.workspaceSupplierScope!,
        expectedSupplierRevision: 3, requireSavedReview: true, expectedPurchaseRevision: 6);
      if (mode.startsWith('race-')) {
        final other = await openingPostingSession(storage, inventory: true);
        expect(await other.recoverCustomerLedger(), isTrue);
        final hold = Completer<void>();
        storage.holdWrite = hold;
        final writes = storage.writes.length;
        final first = mode == 'race-cancel-first' ? cancel(owner) : post(owner);
        for (var i = 0; i < 100 && storage.writes.length == writes; i++) {
          await Future<void>.delayed(Duration.zero);
        }
        expect(storage.writes.length, writes + 1);
        final second = mode == 'race-cancel-first' ? post(other) : cancel(other);
        await Future<void>.delayed(Duration.zero);
        hold.complete();
        expect(await first, isTrue);
        expect(await second, isFalse);
        storage.holdWrite = null;
        final fresh = await openingPostingSession(storage, inventory: true);
        expect(await fresh.recoverCustomerLedger(), isTrue);
        expect(fresh.workspaceBillGoodsCancellations.length, mode == 'race-cancel-first' ? 1 : 0);
        expect(fresh.workspaceSupplierLedger(opening.supplierId)!.billGoodsAllocations.length,
          mode == 'race-post-first' ? 1 : 0);
        expect(fresh.workspaceCatalogueItems.single.stock, stock);
        expect(fresh.workspaceSupplierLedger(opening.supplierId)!.balanceMinor, ledgerBefore.balanceMinor);
        return;
      }
      if (mode == 'committed' || mode == 'contradiction') {
        expect(await post(owner), isTrue);
        final writes = storage.writes.length;
        expect(await cancel(owner), isFalse);
        expect(owner.workspaceBillGoodsCancellations, isEmpty);
        expect(owner.workspaceSupplierRecoveryRequired, isFalse);
        expect(storage.writes.length, writes);
        if (mode == 'contradiction') {
          final old = (await books.read('account-A', 'store-A', qa: true))!;
          final audit = WorkspaceBillGoodsReviewCancellation(operationId: link.operationId,
            supplierId: opening.supplierId, revision: 7, cancelledAt: at, reason: reason);
          final contradictory = WorkspacePurchaseEntryBook.fromJson({...old.toJson(),
            'revision': 7, 'billGoodsCancellations': [audit.toJson()]});
          // Simulate individually valid but contradictory cross-file evidence.
          final key = storage.values.keys.singleWhere((k) => storage.values[k]!.contains('billGoodsReviews'));
          storage.values[key] = jsonEncode(contradictory.toJson());
          expect(await owner.loadWorkspaceSuppliers(retry: true), isTrue);
          expect(await cancel(owner), isFalse);
          expect(owner.workspaceSupplierRecoveryRequired, isTrue);
          expect(await owner.loadWorkspaceSuppliers(retry: true), isTrue);
          expect(await owner.recoverCustomerLedger(), isTrue);
          expect(await post(owner), isFalse);
          expect(owner.workspaceSupplierRecoveryRequired, isTrue);
          expect(storage.writes.length, writes);
        }
        expect(owner.workspaceCatalogueItems.single.stock, stock);
        expect(owner.workspaceSupplierLedger(opening.supplierId)!.balanceMinor, ledgerBefore.balanceMinor);
        return;
      }
      final stale = await openingPostingSession(storage, inventory: true);
      expect(await stale.recoverCustomerLedger(), isTrue);
      final journalKey = storage.values.keys.singleWhere((k) => storage.values[k]!.contains('"supplierLedgers"'));
      final journalBytes = storage.values[journalKey]!;
      if (mode == 'missing-journal') storage.values.remove(journalKey);
      if (mode == 'corrupt-journal') storage.values[journalKey] = '{broken host-only journal';
      storage.failReadKey = mode == 'read-journal' ? journalKey : null;
      storage.failWrite = mode == 'before-cancel';
      storage.loseWriteResponseOnce = mode == 'lost-cancel';
      expect(await cancel(owner), ['ordinary', 'lost-cancel'].contains(mode));
      storage.values[journalKey] = journalBytes;
      storage.failReadKey = null;
      storage.failWrite = false;
      expect(await owner.loadWorkspaceSuppliers(retry: true), isTrue);
      expect(await owner.recoverCustomerLedger(), isTrue);
      if (!['ordinary', 'lost-cancel'].contains(mode)) {
        expect(owner.workspaceBillGoodsCancellations, isEmpty);
        expect(await cancel(owner), isTrue);
      }
      final audit = owner.workspaceBillGoodsCancellations.single;
      expect(audit.cancelledAt, at);
      expect(audit.reason, reason);
      expect(owner.workspaceBillGoodsReviews.single.allocation.toJson(), link.toJson());
      final writes = storage.writes.length;
      expect(await stale.saveWorkspaceBillGoodsReview(link, supplierId: opening.supplierId,
        scope: stale.workspaceSupplierScope!, expectedPurchaseRevision: 6, expectedSupplierRevision: 3), isFalse,
        reason: 'Cached review must not acknowledge an audit saved by another instance.');
      expect(storage.writes.length, writes);
      expect(await post(owner), isFalse);
      expect(await owner.confirmWorkspaceSupplierBillGoodsAllocation(link, supplierId: opening.supplierId,
        scope: scope, expectedSupplierRevision: 3), isFalse, reason: 'Optional review mode must also reject cancelled IDs.');
      final current = (await books.read('account-A', 'store-A', qa: true))!;
      await expectLater(books.save(WorkspacePurchaseEntryBook.fromJson({...current.toJson(), 'revision': 8,
        'billGoodsCancellations': <Object?>[]}), expectedRevision: 7), throwsA(isA<WorkGatewayException>()));
      await expectLater(books.save(WorkspacePurchaseEntryBook.fromJson({...current.toJson(), 'revision': 8,
        'billGoodsCancellations': [{...audit.toJson(), 'reason': 'Rewritten host-only reason'}]}),
        expectedRevision: 7), throwsA(isA<WorkGatewayException>()));
      await books.save(WorkspacePurchaseEntryBook.fromJson({...current.toJson(), 'revision': 8}), expectedRevision: 7);
      expect(await owner.loadWorkspaceSuppliers(retry: true), isTrue);
      final laterWrites = storage.writes.length;
      expect(await cancel(owner), isTrue, reason: 'Exact old audit retry must reverify and perform no write.');
      expect(storage.writes.length, laterWrites);
      expect(await owner.abandonWorkspaceBillGoodsReview(link.operationId, supplierId: opening.supplierId,
        scope: scope, expectedRevision: 6, cancelledAt: at, reason: 'Changed reason'), isFalse);
      final replacement = WorkspaceSupplierBillGoodsAllocation.fromJson({...link.toJson(),
        'operationId': 'replacement-link', 'linkedAt': DateTime.now().toUtc().toIso8601String()});
      expect(await owner.saveWorkspaceBillGoodsReview(replacement, supplierId: opening.supplierId,
        scope: scope, expectedPurchaseRevision: 8, expectedSupplierRevision: 3), isTrue);
      expect(await owner.confirmWorkspaceSupplierBillGoodsAllocation(replacement,
        supplierId: opening.supplierId, scope: scope, expectedSupplierRevision: 3,
        requireSavedReview: true, expectedPurchaseRevision: 9), isTrue);
      final reopened = await openingPostingSession(storage, inventory: true);
      expect(await reopened.recoverCustomerLedger(), isTrue);
      expect(reopened.workspaceBillGoodsCancellations.single.toJson(), audit.toJson());
      expect(reopened.workspaceBillGoodsReviews.map((r) => r.allocation.operationId), [link.operationId, replacement.operationId]);
      expect(reopened.workspaceSupplierLedger(opening.supplierId)!.billGoodsAllocations.keys, [replacement.operationId]);
      expect(reopened.workspaceCatalogueItems.single.stock, stock);
      expect(reopened.workspaceSupplierLedger(opening.supplierId)!.balanceMinor, ledgerBefore.balanceMinor);
    });
  }

  test('PURCHASELINK cumulative accepted damaged and invoiced caps reject duplicates', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!;
    final bill = allocatedBillFixture();
    final both = opening.acceptReviewedBill(bill, expectedRevision: 1)!
      .receiveGoods(goodsReceiptFixture(accepted: 5000, damaged: 1000), expectedRevision: 2)!;
    final first = billGoodsLink(bill);
    final linked = both.allocateBillGoods(first, expectedRevision: 3)!;
    expect(linked.allocateBillGoods(first, expectedRevision: 1), same(linked));
    expect(linked.allocateBillGoods(billGoodsLink(bill, id: 'another'), expectedRevision: 4), isNull);
    expect(linked.allocateBillGoods(billGoodsLink(bill, accepted: 4000, quantity: 5000), expectedRevision: 4), isNull);
    final received = linked.receiveGoods(goodsReceiptFixture(id: 'receipt-B'), expectedRevision: 4)!;
    final complete = received.allocateBillGoods(billGoodsLink(bill, id: 'link-B', receipt: 'receipt-B',
      accepted: 6000, damaged: 0), expectedRevision: 5)!;
    expect(complete.billGoodsAllocations.length, 2);
    expect(complete.balanceMinor, both.balanceMinor);
    final removed = WorkspaceSupplierLedger.fromJson({...complete.toJson(), 'revision': 7,
      'billGoodsAllocations': <String, Object?>{}})!;
    expect(removed.canFollow(complete), isFalse);
    final extra = WorkspaceSupplierLedgerEntry(operationId: 'account-advance',
      origin: WorkspaceSupplierEntryOrigin.supplierAccount, reference: 'ADV-1',
      kind: WorkspaceSupplierEntryKind.advance, amountMinor: 100,
      paymentMethod: 'Cash', postedAt: DateTime.utc(2026, 10, 4),
      moneyReview: WorkspaceSupplierMoneyReview(occurredOn: '2026-10-04',
        openingId: complete.openingRecord!.id,
        openingRevision: complete.openingRecord!.revision, notIncludedInOpening: true));
    expect(complete.appendConfirmed(extra, expectedRevision: 6)!.billGoodsAllocations.length, 2);
  });

  test('PURCHASELINK reviewed unit conversion is exact and fractional damage is retained', () {
    final bill = allocatedBillFixture(unit: 'Carton', quantity: '3');
    final both = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!
      .acceptReviewedBill(bill, expectedRevision: 1)!
      .receiveGoods(goodsReceiptFixture(accepted: 5000, damaged: 1000), expectedRevision: 2)!;
    final link = billGoodsLink(bill, quantity: 3000, numerator: 2);
    expect(both.allocateBillGoods(link, expectedRevision: 3), isNotNull);
    expect(both.allocateBillGoods(billGoodsLink(bill, quantity: 2999, numerator: 2), expectedRevision: 3), isNull);
    final broken = WorkspaceSupplierBillGoodsAllocation.fromJson({...link.toJson(),
      'copyId': 'different-copy'});
    expect(both.allocateBillGoods(broken, expectedRevision: 3), isNull);
    expect(() => WorkspaceSupplierBillGoodsAllocation.fromJson({...link.toJson(),
      'conversionReviewed': false}), throwsFormatException);
    expect(() => WorkspaceSupplierBillGoodsAllocation.fromJson({...link.toJson(),
      'stockUnitsNumerator': 4, 'stockUnitsDenominator': 2}), throwsFormatException);
    final bill2 = allocatedBillFixture(quantity: '1.5');
    final receipt = goodsReceiptFixture(delivered: 1500, accepted: 1000, damaged: 500, expected: 1500);
    final fractional = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!
      .acceptReviewedBill(bill2, expectedRevision: 1)!.receiveGoods(receipt, expectedRevision: 2)!;
    expect(fractional.allocateBillGoods(billGoodsLink(bill2, accepted: 1000, damaged: 500,
      quantity: 1500), expectedRevision: 3), isNotNull);
  });

  for (final mode in ['ordinary', 'lost-response', 'competing']) {
  test('PURCHASELINK SESSION $mode preserves Stock money scope and exact retry', () async {
    final storage = _OrderJournalStorage();
    final opening = openingFixture(amount: 0);
    final session = await openingPostingSession(storage, initialRecord: opening, inventory: true);
    expect(await session.confirmWorkspaceSupplierOpeningRecord(opening, scope: session.workspaceSupplierScope!,
      expectedRevision: 3, confirmedAt: DateTime.utc(2026, 10, 3)), isTrue);
    final receipt = sessionReceipt(session);
    expect(await session.confirmWorkspaceSupplierGoodsReceipt(receipt, supplierId: opening.supplierId,
      scope: session.workspaceSupplierScope!, expectedPurchaseRevision: 3, expectedSupplierRevision: 1),
      WorkspaceGoodsReceiptSaveResult.saved);
    final product = session.workspaceCatalogueItems.single;
    final base = allocatedBillFixture(product: product.id, unit: product.pack);
    final bill = WorkspaceSupplierBillAcceptance(copy: base.copy,
      acceptedAt: DateTime.now().toUtc(), openingTreatment: base.openingTreatment);
    final books = SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage);
    final old = (await books.read('account-A', 'store-A', qa: true))!;
    await books.save(WorkspacePurchaseEntryBook.fromJson({...old.toJson(), 'revision': 4,
      'copies': [...old.copies.map((c) => c.toJson()), bill.copy.toJson()]}), expectedRevision: 3);
    expect(await session.loadWorkspaceSuppliers(retry: true), isTrue);
    expect(await session.confirmWorkspacePurchaseBill(bill.copy, scope: session.workspaceSupplierScope!,
      expectedPurchaseRevision: 4, expectedLedgerRevision: 2, openingTreatment: bill.openingTreatment,
      confirmedAt: bill.acceptedAt), isTrue);
    final link = WorkspaceSupplierBillGoodsAllocation.fromJson({...billGoodsLink(bill).toJson(),
      'receiptId': receipt.id, 'receiptLineId': receipt.lines.single.sourceLineId,
      'productId': product.id, 'stockUnit': product.pack, 'acceptedReceiptMilli': 6000,
      'damagedReceiptMilli': 0, 'linkedAt': DateTime.now().toUtc().toIso8601String()});
    final selectedLink = mode == 'competing'
        ? WorkspaceSupplierBillGoodsAllocation.fromJson({...link.toJson(),
            'acceptedReceiptMilli': 3000, 'billQuantityMilli': 3000}) : link;
    WorkSession? competing;
    if (mode == 'competing') {
      competing = await openingPostingSession(storage, inventory: true);
      expect(await competing.recoverCustomerLedger(), isTrue);
    }
    final before = session.workspaceSupplierLedger(opening.supplierId)!;
    final stock = session.workspaceCatalogueItems.single.stock;
    if (mode == 'lost-response') {
      storage.loseWriteResponseOnce = true;
      expect(await session.confirmWorkspaceSupplierBillGoodsAllocation(selectedLink, supplierId: opening.supplierId,
        scope: session.workspaceSupplierScope!, expectedSupplierRevision: 3), isFalse);
      expect(session.noticeMessage, contains('unverified'));
      final journal = SecureWorkLedgerCheckpointStore(accountScope: () => 'account-A', storage: storage);
      final saved = (await journal.read('account-A', 'store-A'))!;
      expect(saved.supplierLedgers[opening.supplierId]!.billGoodsAllocations.length, 1);
      final attempts = storage.writes.length;
      expect(await session.recoverCustomerLedger(), isTrue);
      expect(await session.confirmWorkspaceSupplierBillGoodsAllocation(selectedLink, supplierId: opening.supplierId,
        scope: session.workspaceSupplierScope!, expectedSupplierRevision: 3), isTrue);
      expect(storage.writes.length, attempts);
    } else {
      expect(await session.confirmWorkspaceSupplierBillGoodsAllocation(selectedLink, supplierId: opening.supplierId,
        scope: session.workspaceSupplierScope!, expectedSupplierRevision: 3), isTrue);
    }
    expect(session.workspaceCatalogueItems.single.stock, stock);
    expect(session.workspaceSupplierLedger(opening.supplierId)!.balanceMinor, before.balanceMinor);
    final writes = storage.writes.length;
    expect(await session.confirmWorkspaceSupplierBillGoodsAllocation(selectedLink, supplierId: opening.supplierId,
      scope: session.workspaceSupplierScope!, expectedSupplierRevision: 3), isTrue);
    expect(storage.writes.length, writes);
    expect(await session.confirmWorkspaceSupplierBillGoodsAllocation(selectedLink, supplierId: opening.supplierId,
      scope: ('account-A', 'another-store', true), expectedSupplierRevision: 4), isFalse);
    if (competing != null) {
      final otherLink = WorkspaceSupplierBillGoodsAllocation.fromJson({...selectedLink.toJson(),
        'operationId': 'other-session-link'});
      expect(await competing.confirmWorkspaceSupplierBillGoodsAllocation(otherLink, supplierId: opening.supplierId,
        scope: competing.workspaceSupplierScope!, expectedSupplierRevision: 3), isFalse);
      expect(await competing.recoverCustomerLedger(), isTrue);
      expect(competing.workspaceSupplierLedger(opening.supplierId)!.billGoodsAllocations.length, 1);
      expect(await competing.confirmWorkspaceSupplierBillGoodsAllocation(otherLink, supplierId: opening.supplierId,
        scope: competing.workspaceSupplierScope!, expectedSupplierRevision: 4), isTrue);
      expect(competing.workspaceSupplierLedger(opening.supplierId)!.billGoodsAllocations.length, 2);
      expect(competing.workspaceCatalogueItems.single.stock, stock);
      expect(competing.workspaceSupplierLedger(opening.supplierId)!.balanceMinor, before.balanceMinor);
    }
    final restart = await openingPostingSession(storage, inventory: true);
    expect(await restart.recoverCustomerLedger(), isTrue);
    expect(restart.workspaceSupplierLedger(opening.supplierId)!.billGoodsAllocations.length, mode == 'competing' ? 2 : 1);
    expect(restart.workspaceCatalogueItems.single.stock, stock);
  });
  }

  test('PURCHASELINK bill already in Stock units must use identity conversion', () {
    final bill = allocatedBillFixture();
    final base = goodsReceiptFixture();
    final receipt = WorkspaceSupplierGoodsReceipt.fromJson({...base.toJson(), 'lines': [
      {...base.lines.single.toJson(), 'purchaseUnit': 'Carton', 'unitsPerPack': 2},
    ]});
    final both = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!
      .acceptReviewedBill(bill, expectedRevision: 1)!.receiveGoods(receipt, expectedRevision: 2)!;
    expect(both.allocateBillGoods(billGoodsLink(bill, accepted: 6000, damaged: 0,
      quantity: 12000), expectedRevision: 3), isNotNull);
    expect(both.allocateBillGoods(billGoodsLink(bill, accepted: 6000, damaged: 0,
      quantity: 6000, numerator: 2), expectedRevision: 3), isNull);
  });

  test('PURCHASEPROGRESS separates absent partial and full billed plus free matching', () {
    final bill = allocatedBillFixture(quantity: '10', freeQuantity: '2');
    final receipt = goodsReceiptFixture(delivered: 12000, accepted: 12000, expected: 12000);
    final both = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!
      .acceptReviewedBill(bill, expectedRevision: 1)!.receiveGoods(receipt, expectedRevision: 2)!;
    final absent = both.goodsProgressFor(bill.copy)!;
    expect(absent.hasMatches, isFalse); expect(absent.matchedItems, 0);
    final partial = both.allocateBillGoods(billGoodsLink(bill, accepted: 10000, damaged: 0,
      quantity: 8000, freeQuantity: 2000), expectedRevision: 3)!;
    final before = partial.toJson();
    final progress = partial.goodsProgressFor(bill.copy)!;
    expect(progress.hasMatches, isTrue); expect(progress.matchedItems, 0);
    expect(progress.totalItems, 1); expect(progress.damaged, isFalse);
    final full = partial.allocateBillGoods(billGoodsLink(bill, id: 'remaining-paid', accepted: 2000,
      damaged: 0, quantity: 2000), expectedRevision: 4)!;
    expect(full.goodsProgressFor(bill.copy)!.matchedItems, 1);
    expect(WorkspaceSupplierLedger.fromJson(full.toJson())!.goodsProgressFor(bill.copy), full.goodsProgressFor(bill.copy));
    expect(partial.toJson(), before); expect(full.balanceMinor, both.balanceMinor);
    expect(full.goodsProgressFor(newBillFixture().copy), isNull);
  });

  test('PURCHASEPROGRESS matched damaged delivery keeps return indication and money unchanged', () {
    final bill = allocatedBillFixture(quantity: '6');
    final receipt = goodsReceiptFixture(accepted: 5000, damaged: 1000);
    final both = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!
      .acceptReviewedBill(bill, expectedRevision: 1)!.receiveGoods(receipt, expectedRevision: 2)!;
    final linked = both.allocateBillGoods(billGoodsLink(bill), expectedRevision: 3)!;
    final matched = linked.goodsProgressFor(bill.copy)!;
    expect(matched.matchedItems, 1); expect(matched.damaged, isTrue);
    expect(matched.returnedOnMatchedDelivery, isFalse);
    final returned = linked.recordGoodsReturned(goodsReturnFixture(linked), expectedRevision: 4)!;
    final after = returned.goodsProgressFor(bill.copy)!;
    expect(after.matchedItems, 1); expect(after.damaged, isTrue);
    expect(after.returnedOnMatchedDelivery, isTrue);
    expect(returned.balanceMinor, linked.balanceMinor); expect(returned.entries, linked.entries);
    expect(returned.goodsReceipts['receipt-A']!.toJson(), receipt.toJson());
  });

  test('PURCHASEPROGRESS free-only bill is matched without payable creation', () {
    final bill = allocatedBillFixture(quantity: '0', freeQuantity: '2', total: '0');
    final both = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!
      .acceptReviewedBill(bill, expectedRevision: 1)!
      .receiveGoods(goodsReceiptFixture(delivered: 2000, accepted: 2000, expected: 2000), expectedRevision: 2)!;
    final full = both.allocateBillGoods(billGoodsLink(bill, accepted: 2000, damaged: 0,
      quantity: 0, freeQuantity: 2000), expectedRevision: 3)!;
    expect(full.goodsProgressFor(bill.copy)!.matchedItems, 1);
    expect(full.balanceMinor, 0); expect(full.entries, isEmpty);
  });

  test('PURCHASELINK free goods have a separate cap and cannot inflate paid quantities', () {
    final bill = allocatedBillFixture(quantity: '10', freeQuantity: '2');
    final receipt = goodsReceiptFixture(delivered: 12000, accepted: 12000, expected: 12000);
    final both = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!
      .acceptReviewedBill(bill, expectedRevision: 1)!.receiveGoods(receipt, expectedRevision: 2)!;
    expect(both.allocateBillGoods(billGoodsLink(bill, accepted: 12000, damaged: 0,
      quantity: 10000, freeQuantity: 2000), expectedRevision: 3), isNotNull);
    expect(both.allocateBillGoods(billGoodsLink(bill, accepted: 12000, damaged: 0,
      quantity: 12000), expectedRevision: 3), isNull);
    final partial = both.allocateBillGoods(billGoodsLink(bill, accepted: 10000, damaged: 0,
      quantity: 8000, freeQuantity: 2000), expectedRevision: 3)!;
    expect(partial.allocateBillGoods(billGoodsLink(bill, id: 'free-overflow', accepted: 1000,
      damaged: 0, quantity: 0, freeQuantity: 1000), expectedRevision: 4), isNull);
    expect(WorkspaceSupplierLedger.fromJson(partial.toJson())!.billGoodsAllocations.values.single.freeBillQuantityMilli, 2000);
  });

  test('PURCHASELINK partial allocations cannot switch the reviewed bill unit conversion', () {
    final bill = allocatedBillFixture(unit: 'Carton', quantity: '12');
    final both = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!
      .acceptReviewedBill(bill, expectedRevision: 1)!.receiveGoods(goodsReceiptFixture(), expectedRevision: 2)!;
    final first = both.allocateBillGoods(billGoodsLink(bill, accepted: 6000, damaged: 0,
      quantity: 3000, numerator: 2), expectedRevision: 3)!;
    final second = first.receiveGoods(goodsReceiptFixture(id: 'receipt-B'), expectedRevision: 4)!;
    expect(second.allocateBillGoods(billGoodsLink(bill, id: 'changed-conversion', receipt: 'receipt-B',
      accepted: 6000, damaged: 0, quantity: 6000), expectedRevision: 5), isNull);
  });

  test('PURCHASELINK free-only goods retain bill evidence without creating payable', () {
    final bill = allocatedBillFixture(quantity: '0', freeQuantity: '2', total: '0');
    expect(bill.valid, isTrue);
    final opening = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!;
    final receipt = goodsReceiptFixture(delivered: 2000, accepted: 2000, expected: 2000);
    final both = opening.acceptReviewedBill(bill, expectedRevision: 1)!
      .receiveGoods(receipt, expectedRevision: 2)!;
    final linked = both.allocateBillGoods(billGoodsLink(bill, accepted: 2000, damaged: 0,
      quantity: 0, freeQuantity: 2000), expectedRevision: 3)!;
    expect(linked.balanceMinor, 0);
    expect(linked.entries, isEmpty);
    expect(linked.purchaseBills.length, 1);
    expect(linked.billGoodsAllocations.values.single.freeBillQuantityMilli, 2000);
    expect(allocatedBillFixture(quantity: '0', freeQuantity: '0', total: '0').valid, isFalse);
  });

  test('PURCHASELINK legacy free text stays readable and blank means no free goods', () {
    for (final freeText in ['-', ' ', '0']) {
      final bill = allocatedBillFixture(freeQuantity: freeText);
      expect(bill.valid, isTrue);
      final both = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!
        .acceptReviewedBill(bill, expectedRevision: 1)!
        .receiveGoods(goodsReceiptFixture(), expectedRevision: 2)!;
      final reopened = WorkspaceSupplierLedger.fromJson(both.toJson())!;
      expect(reopened.toJson(), both.toJson());
      final allocated = reopened.allocateBillGoods(
        billGoodsLink(bill, accepted: 6000, damaged: 0), expectedRevision: 3);
      if (freeText == '-') {
        expect(allocated, isNull);
      } else {
        expect(allocated, isNotNull);
        expect(allocated!.billGoodsAllocations.values.single.freeBillQuantityMilli, 0);
      }
      expect(allocatedBillFixture(quantity: '0', freeQuantity: freeText).valid, isFalse);
    }
  });

  test('PURCHASERECEIVE goods before bill remains durable when bill later accepted', () {
    final opening = confirmedOpeningFixture(openingFixture(amount: 0, bills: const []))!;
    final receipt = goodsReceiptFixture();
    final received = opening.receiveGoods(receipt, expectedRevision: 1)!;
    expect(received.purchaseBills, isEmpty);
    expect(received.entries, isEmpty);
    final bill = newBillFixture();
    final billed = received.acceptReviewedBill(bill, expectedRevision: 2)!;
    expect(billed.goodsReceipts['receipt-A']!.toJson(), receipt.toJson());
    expect(billed.balanceMinor, 284075);
    final firstBill = opening.acceptReviewedBill(bill, expectedRevision: 1)!;
    final laterGoods = firstBill.receiveGoods(receipt, expectedRevision: 2)!;
    expect(laterGoods.purchaseBills['new-bill']!.toJson(), bill.toJson());
    expect(laterGoods.balanceMinor, billed.balanceMinor);
  });

  Future<bool> confirmBill(WorkSession session, WorkspaceSupplierBillAcceptance bill,
      {int bookRevision = 4, int ledgerRevision = 1}) =>
    session.confirmWorkspacePurchaseBill(bill.copy,
      scope: session.workspaceSupplierScope!, expectedPurchaseRevision: bookRevision,
      expectedLedgerRevision: ledgerRevision, openingTreatment: bill.openingTreatment,
      confirmedAt: bill.acceptedAt);

  test('PURCHASEALLOC SESSION receipt lease rejects attribution without journal write', () async {
    final storage = _OrderJournalStorage();
    final moneyStore = SecureWorkLedgerFormDraftStore(accountScope: () => 'account-A', storage: storage);
    final bill = newBillFixture();
    final session = await billPostingSession(storage, bill, inventory: true, moneyStore: moneyStore);
    expect(await confirmBill(session, bill), isTrue);
    final opening = session.workspaceSupplierLedger(bill.copy.supplier.id)!.openingRecord!;
    final advance = WorkspaceSupplierLedgerEntry(operationId: 'lease-source-advance', reference: 'HOST-LEASE-ADV',
      origin: WorkspaceSupplierEntryOrigin.supplierAccount, kind: WorkspaceSupplierEntryKind.advance,
      amountMinor: 10000, paymentMethod: 'Cash', postedAt: DateTime.utc(2026, 10, 3),
      moneyReview: WorkspaceSupplierMoneyReview(occurredOn: '2026-10-03', openingId: opening.id,
        openingRevision: opening.revision, notIncludedInOpening: true));
    expect(await session.recordWorkspaceSupplierMoney(opening.supplierId, accountScope: 'account-A',
      workspaceId: 'store-A', entry: advance, expectedRevision: 2), isTrue);
    final ledger = session.workspaceSupplierLedger(opening.supplierId)!;
    final link = moneyAllocationFixture(ledger, bill, kind: WorkspaceSupplierMoneySourceKind.accountAdvance,
      source: advance.operationId);
    expect(ledger.allocateRecordedMoney(link, expectedRevision: 3), isNotNull,
      reason: 'The requested link must otherwise be admissible to prove the receipt lease guard.');
    storage.holdWrite = Completer<void>();
    final posting = session.confirmWorkspaceSupplierGoodsReceipt(sessionReceipt(session), supplierId: opening.supplierId,
      scope: session.workspaceSupplierScope!, expectedPurchaseRevision: 4, expectedSupplierRevision: 3);
    expect(session.workspaceGoodsReceiptBusy, isTrue);
    final writes = storage.writes.length;
    expect(await session.allocateWorkspaceSupplierMoney(link, expectedRevision: 3), isFalse);
    expect(storage.writes.length, writes);
    storage.holdWrite!.complete();
    expect(await posting, WorkspaceGoodsReceiptSaveResult.saved);
    storage.holdWrite = null;
  });

  for (final mode in ['ordinary', 'failed-save', 'lost-response']) {
    test('PURCHASEMONEY SESSION $mode retry restart and no Stock effect', () async {
      // Labelled host journal fault test, not injected device acceptance data.
      final storage = _OrderJournalStorage();
      final bill = newBillFixture();
      final owner = await billPostingSession(storage, bill);
      expect(await confirmBill(owner, bill), isTrue);
      final opening = owner.workspaceSupplierLedger(bill.copy.supplier.id)!.openingRecord!;
      final payment = WorkspaceSupplierLedgerEntry(operationId: 'manual-money-session',
        reference: 'HOST-PAY-1', origin: WorkspaceSupplierEntryOrigin.manualPurchase,
        purchaseId: bill.copy.id, billId: bill.billId, paymentMethod: 'UPI',
        kind: WorkspaceSupplierEntryKind.payment, amountMinor: bill.amountMinor!,
        postedAt: DateTime.utc(2026, 10, 3),
        moneyReview: WorkspaceSupplierMoneyReview(occurredOn: '2026-10-03',
          openingId: opening.id, openingRevision: opening.revision,
          notIncludedInOpening: true));
      Future<bool> record(WorkSession session, {String store = 'store-A',
        WorkspaceSupplierLedgerEntry? entry}) => session.recordWorkspaceSupplierMoney(
          bill.copy.supplier.id, accountScope: 'account-A', workspaceId: store,
          entry: entry ?? payment, expectedRevision: 2);
      final stock = owner.workspaceCatalogueItems.map((p) => (p.id, p.stock)).toList();
      final writesBefore = storage.writes.length;
      expect(await record(owner, store: 'another-store'), isFalse);
      expect(storage.writes.length, writesBefore);
      final future = DateTime.now().add(const Duration(days: 1));
      final futureDay = '${future.year.toString().padLeft(4, '0')}-${future.month.toString().padLeft(2, '0')}-${future.day.toString().padLeft(2, '0')}';
      final futureEntry = WorkspaceSupplierLedgerEntry(operationId: 'future-payment',
        reference: payment.reference, origin: payment.origin,
        purchaseId: payment.purchaseId, billId: payment.billId,
        paymentMethod: payment.paymentMethod, kind: payment.kind,
        amountMinor: payment.amountMinor, postedAt: future,
        moneyReview: WorkspaceSupplierMoneyReview(occurredOn: futureDay,
          openingId: opening.id, openingRevision: opening.revision,
          notIncludedInOpening: true));
      expect(await record(owner, entry: futureEntry), isFalse);
      expect(storage.writes.length, writesBefore);
      final production = WorkSession.production(gateway: ReviewWorkGateway(),
        contactDraftStore: _CommandAccountStore())..activeWorkspace = _commandStore;
      addTearDown(production.dispose);
      expect(await record(production), isFalse);
      storage.failWrite = mode == 'failed-save';
      storage.loseWriteResponseOnce = mode == 'lost-response';
      expect(await record(owner), mode == 'ordinary');
      storage.failWrite = false;
      final reopened = await openingPostingSession(storage);
      expect(await reopened.recoverCustomerLedger(), isTrue);
      final beforeRetry = storage.writes.length;
      expect(await record(reopened), isTrue);
      expect(storage.writes.length, beforeRetry + (mode == 'failed-save' ? 1 : 0));
      final paid = reopened.workspaceSupplierLedger(bill.copy.supplier.id)!;
      expect(paid.balanceMinor, 0);
      expect(paid.manualBillRemainingMinor(bill.billId), 0);
      expect(paid.entries.where((e) => e.kind == WorkspaceSupplierEntryKind.payment), hasLength(1));
      final retryWrites = storage.writes.length;
      expect(await record(reopened), isTrue);
      expect(storage.writes.length, retryWrites);
      final changed = WorkspaceSupplierLedgerEntry(operationId: payment.operationId,
        reference: 'CHANGED', origin: payment.origin, purchaseId: payment.purchaseId,
        billId: payment.billId, paymentMethod: payment.paymentMethod,
        kind: payment.kind, amountMinor: payment.amountMinor,
        postedAt: payment.postedAt, moneyReview: payment.moneyReview);
      expect(await record(reopened, entry: changed), isFalse);
      expect(storage.writes.length, retryWrites);
      expect(reopened.workspaceCatalogueItems.map((p) => (p.id, p.stock)).toList(), stock);
      final statement = WorkspaceMoneyStatement.fromLedgers(finance: reopened.workspaceFinance!,
        suppliers: [paid], expenses: const [], end: DateTime.utc(2026, 10, 4))!;
      expect(statement.recordedOutMinor, bill.amountMinor);
      expect(statement.entries.single.reference, 'HOST-PAY-1 · SUP-NEW-1');
      expect(statement.entries.single.reference.contains('null'), isFalse);
      final finalRestart = await openingPostingSession(storage);
      expect(await finalRestart.recoverCustomerLedger(), isTrue);
      expect(finalRestart.workspaceSupplierLedger(bill.copy.supplier.id)!.toJson(), paid.toJson());
    });
  }

  for (final loseReply in [false, true]) {
    test('PURCHASEMONEYDRAFT SESSION frozen bill payment restart and reset lostReply=$loseReply', () async {
      // Encrypted host fault qualification only, never runtime/device injection.
      final storage = _OrderJournalStorage();
      SecureWorkLedgerFormDraftStore draftStore() => SecureWorkLedgerFormDraftStore(
        accountScope: () => 'account-A', storage: storage);
      final bill = newBillFixture();
      final owner = await billPostingSession(storage, bill, moneyStore: draftStore());
      expect(await confirmBill(owner, bill), isTrue);
      final key = owner.supplierMoneyFormKey(bill.copy.supplier.id, copy: bill.copy)!;
      final opening = owner.workspaceSupplierLedger(key.customer)!.openingRecord!;
      final entry = WorkspaceSupplierLedgerEntry(operationId: 'frozen-session-pay',
        reference: 'HOST-FROZEN-1', origin: WorkspaceSupplierEntryOrigin.manualPurchase,
        purchaseId: bill.copy.id, billId: bill.billId, paymentMethod: 'Cash',
        kind: WorkspaceSupplierEntryKind.payment, amountMinor: 10000,
        postedAt: DateTime.utc(2026, 10, 3),
        moneyReview: WorkspaceSupplierMoneyReview(occurredOn: '2026-10-03',
          openingId: opening.id, openingRevision: opening.revision,
          notIncludedInOpening: true));
      final attempt = WorkspaceSupplierMoneyAttempt(entry: entry, expectedRevision: 2);
      final frozen = WorkspaceLedgerFormDraft(key: key, revision: 1, fields: {
        'amount': '100.00', 'channel': 'Cash', 'reference': entry.reference,
        'occurredOn': '2026-10-03', 'notIncludedInOpening': 'true',
        'attempt': jsonEncode(attempt.toJson())});
      expect(frozen.valid, isTrue);
      await draftStore().save(frozen, expectedRevision: null);
      storage.loseWriteResponseOnce = loseReply;
      expect(await owner.recordWorkspaceSupplierMoneyDraft(key, attempt), !loseReply);
      final restarted = await openingPostingSession(storage, moneyStore: draftStore());
      expect(await restarted.recoverCustomerLedger(), isTrue);
      expect(restarted.supplierMoneyFormKey(key.customer, copy: bill.copy), key,
        reason: 'The form is bound to the accepted copy, not a mutable journal revision.');
      final writes = storage.writes.length;
      expect(await restarted.recordWorkspaceSupplierMoneyDraft(key, attempt), isTrue);
      expect(storage.writes.length, writes);
      final ledger = restarted.workspaceSupplierLedger(key.customer)!;
      expect(ledger.entries.where((item) => item.operationId == entry.operationId), hasLength(1));
      expect(ledger.balanceMinor, bill.amountMinor! - entry.amountMinor);
      final wrongMode = restarted.supplierMoneyFormKey(key.customer, advance: true)!;
      expect(await restarted.recordWorkspaceSupplierMoneyDraft(wrongMode, attempt), isFalse);
      expect(storage.writes.length, writes);
      final reset = WorkspaceLedgerFormDraft(key: key, revision: 2, fields: {
        'amount': '', 'channel': 'Cash', 'reference': '', 'occurredOn': '2026-10-03',
        'notIncludedInOpening': 'false'});
      expect(await restarted.resetConfirmedWorkspaceSupplierMoneyDraft(reset, expectedRevision: 1), isTrue);
      expect((await draftStore().read(key))!.supplierMoneyAttempt, isNull);
      final afterReset = storage.writes.length;
      expect(await restarted.resetConfirmedWorkspaceSupplierMoneyDraft(reset, expectedRevision: 1), isTrue);
      expect(storage.writes.length, afterReset);
      expect(await restarted.recordWorkspaceSupplierMoneyDraft(key, attempt), isFalse,
        reason: 'A cleared form must not silently resurrect a previous payment.');
      expect(restarted.workspaceSupplierLedger(key.customer)!.toJson(), ledger.toJson());
    });
  }

  for (final mode in ['ordinary', 'failed-save', 'lost-response', 'competing']) {
    test('PURCHASEALLOC SESSION $mode retains source bill and one attribution across restart', () async {
      // Host-only journal fault test, never injected physical Store data.
      final storage = _OrderJournalStorage();
      SecureWorkLedgerFormDraftStore draftStore() => SecureWorkLedgerFormDraftStore(
        accountScope: () => 'account-A', storage: storage);
      final bill = newBillFixture();
      final owner = await billPostingSession(storage, bill, moneyStore: draftStore());
      expect(await confirmBill(owner, bill), isTrue);
      final opening = owner.workspaceSupplierLedger(bill.copy.supplier.id)!.openingRecord!;
      final advance = WorkspaceSupplierLedgerEntry(operationId: 'allocation-session-advance', reference: 'HOST-ALLOC-ADV',
        origin: WorkspaceSupplierEntryOrigin.supplierAccount, kind: WorkspaceSupplierEntryKind.advance,
        amountMinor: 10000, paymentMethod: 'Cash', postedAt: DateTime.utc(2026, 10, 3),
        moneyReview: WorkspaceSupplierMoneyReview(occurredOn: '2026-10-03', openingId: opening.id,
          openingRevision: opening.revision, notIncludedInOpening: true));
      expect(await owner.recordWorkspaceSupplierMoney(bill.copy.supplier.id, accountScope: 'account-A',
        workspaceId: 'store-A', entry: advance, expectedRevision: 2), isTrue);
      final ledger = owner.workspaceSupplierLedger(bill.copy.supplier.id)!;
      final link = moneyAllocationFixture(ledger, bill, kind: WorkspaceSupplierMoneySourceKind.accountAdvance,
        source: advance.operationId);
      final entries = ledger.entries.map((e) => e.toJson()).toList();
      final stock = owner.workspaceCatalogueItems.map((p) => (p.id, p.stock)).toList();
      final other = mode == 'competing' ? await openingPostingSession(storage, moneyStore: draftStore()) : null;
      if (other != null) expect(await other.recoverCustomerLedger(), isTrue);
      storage.failWrite = mode == 'failed-save';
      storage.loseWriteResponseOnce = mode == 'lost-response';
      expect(await owner.allocateWorkspaceSupplierMoney(link, expectedRevision: 3),
        mode == 'ordinary' || mode == 'competing');
      storage.failWrite = false;
      if (other != null) {
        final competing = WorkspaceSupplierBillMoneyAllocation.fromJson({...link.toJson(), 'operationId': 'competing-allocation'});
        expect(await other.allocateWorkspaceSupplierMoney(competing, expectedRevision: 3), isFalse);
        expect(await other.recoverCustomerLedger(), isTrue);
        expect(await other.allocateWorkspaceSupplierMoney(competing, expectedRevision: 3), isFalse);
      }
      final reopened = await openingPostingSession(storage, moneyStore: draftStore());
      expect(await reopened.recoverCustomerLedger(), isTrue);
      final writes = storage.writes.length;
      expect(await reopened.allocateWorkspaceSupplierMoney(link, expectedRevision: 3), isTrue);
      expect(storage.writes.length, writes + (mode == 'failed-save' ? 1 : 0));
      final posted = reopened.workspaceSupplierLedger(link.supplierId)!;
      expect(posted.billMoneyAllocations.length, 1);
      expect(posted.balanceMinor, ledger.balanceMinor);
      expect(posted.entries.map((e) => e.toJson()).toList(), entries);
      expect(posted.manualBillRemainingMinor(bill.billId), bill.amountMinor! - 10000);
      expect(reopened.workspaceCatalogueItems.map((p) => (p.id, p.stock)).toList(), stock);
      final noWrite = storage.writes.length;
      expect(await reopened.allocateWorkspaceSupplierMoney(link, expectedRevision: 3), isTrue);
      expect(storage.writes.length, noWrite);
      expect(await reopened.allocateWorkspaceSupplierMoney(WorkspaceSupplierBillMoneyAllocation.fromJson(
        {...link.toJson(), 'amountMinor': 9999}), expectedRevision: 3), isFalse);
      expect(storage.writes.length, noWrite);
    });
  }

  for (final mode in ['ordinary', 'unrelated-revision', 'lost-response', 'stale-reset-proof']) {
    test('PURCHASEALLOC DRAFT $mode frozen intent survives commit recovery and verified reset', () async {
      // Host encrypted journal/draft qualification, not physical acceptance.
      final storage = _OrderJournalStorage();
      SecureWorkLedgerFormDraftStore draftStore() => SecureWorkLedgerFormDraftStore(
        accountScope: () => 'account-A', storage: storage);
      final bill = newBillFixture();
      final owner = await billPostingSession(storage, bill, moneyStore: draftStore());
      expect(await confirmBill(owner, bill), isTrue);
      final opening = owner.workspaceSupplierLedger(bill.copy.supplier.id)!.openingRecord!;
      WorkspaceSupplierLedgerEntry advance(String id) => WorkspaceSupplierLedgerEntry(operationId: id,
        reference: 'HOST-ALLOC-INTENT', origin: WorkspaceSupplierEntryOrigin.supplierAccount,
        kind: WorkspaceSupplierEntryKind.advance, amountMinor: 10000, paymentMethod: 'Cash',
        postedAt: DateTime.utc(2026, 10, 3), moneyReview: WorkspaceSupplierMoneyReview(
          occurredOn: '2026-10-03', openingId: opening.id, openingRevision: opening.revision,
          notIncludedInOpening: true));
      expect(await owner.recordWorkspaceSupplierMoney(opening.supplierId, accountScope: 'account-A',
        workspaceId: 'store-A', entry: advance('frozen-allocation-source'), expectedRevision: 2), isTrue);
      final key = owner.supplierAllocationFormKey(bill.copy)!;
      final intent = WorkspaceSupplierMoneyAllocationIntent.fromJson(moneyAllocationFixture(
        owner.workspaceSupplierLedger(opening.supplierId)!, bill,
        kind: WorkspaceSupplierMoneySourceKind.accountAdvance, source: 'frozen-allocation-source').intentToJson());
      final frozen = WorkspaceLedgerFormDraft(key: key, revision: 1, fields: {
        'amount': '100.00', 'sourceKind': intent.sourceKind.name, 'sourceId': intent.sourceId,
        'attempt': jsonEncode(intent.intentToJson())});
      expect(frozen.valid, isTrue);
      await draftStore().save(frozen, expectedRevision: null);
      final editable = WorkspaceLedgerFormDraft(key: key, revision: 2, fields: {
        'amount': '', 'sourceKind': '', 'sourceId': ''});
      await expectLater(draftStore().save(editable, expectedRevision: 1), throwsA(isA<WorkGatewayException>()));
      expect(() => WorkspaceSupplierMoneyAllocationIntent.fromJson({...intent.intentToJson(),
        'committedRevision': 4}), throwsFormatException);
      if (mode == 'unrelated-revision') {
        expect(await owner.recordWorkspaceSupplierMoney(opening.supplierId, accountScope: 'account-A',
          workspaceId: 'store-A', entry: advance('another-unrelated-advance'), expectedRevision: 3), isTrue);
      }
      storage.loseWriteResponseOnce = mode == 'lost-response';
      expect(await owner.recordWorkspaceSupplierAllocationDraft(key, intent), mode != 'lost-response');
      final restarted = await openingPostingSession(storage, moneyStore: draftStore());
      expect(await restarted.recoverCustomerLedger(), isTrue);
      final writes = storage.writes.length;
      expect(await restarted.recordWorkspaceSupplierAllocationDraft(key, intent), isTrue);
      expect(storage.writes.length, writes);
      final posted = restarted.workspaceSupplierLedger(opening.supplierId)!.billMoneyAllocations.values.single;
      expect(posted.intentToJson(), intent.intentToJson());
      expect(posted.committedRevision, mode == 'unrelated-revision' ? 5 : 4);
      expect(posted.recordedAt.isBefore(intent.requestedAt), isFalse);
      final changed = WorkspaceSupplierMoneyAllocationIntent.fromJson({...intent.intentToJson(), 'amountMinor': 9999});
      expect(await restarted.recordWorkspaceSupplierAllocationDraft(key, changed), isFalse);
      if (mode == 'stale-reset-proof') {
        final proofKey = storage.values.keys.singleWhere((k) => !k.contains('ledger-form') &&
          storage.values[k]!.contains('billMoneyAllocations'));
        storage.failReadKey = proofKey;
        expect(await restarted.resetConfirmedWorkspaceSupplierAllocationDraft(editable, expectedRevision: 1), isFalse,
          reason: 'Cached committed evidence cannot clear an attempt when its authoritative checkpoint is unreadable.');
        storage.failReadKey = null;
        expect((await draftStore().read(key))!.supplierAllocationIntent!.intentToJson(), intent.intentToJson());
      }
      expect(await restarted.resetConfirmedWorkspaceSupplierAllocationDraft(editable, expectedRevision: 1), isTrue);
      expect((await draftStore().read(key))!.supplierAllocationIntent, isNull);
      final afterReset = storage.writes.length;
      expect(await restarted.resetConfirmedWorkspaceSupplierAllocationDraft(editable, expectedRevision: 1), isTrue);
      expect(storage.writes.length, afterReset);
      expect(await restarted.recordWorkspaceSupplierAllocationDraft(key, intent), isFalse);
      expect(restarted.workspaceSupplierLedger(opening.supplierId)!.billMoneyAllocations.length, 1);
    });
  }

  test('PURCHASEALLOC DRAFT independent bill forms cannot spend one source twice', () async {
    // Host-only encrypted user-form concurrency evidence, not physical Store data.
    final storage = _OrderJournalStorage();
    SecureWorkLedgerFormDraftStore drafts() => SecureWorkLedgerFormDraftStore(
      accountScope: () => 'account-A', storage: storage);
    final first = newBillFixture();
    final second = acceptanceFixture(id: 'second-allocation-copy', draftId: 'second-allocation-bill',
      date: '2026-10-02', reference: 'HOST-SECOND-ALLOC', total: '2840.75',
      treatment: WorkspaceOpeningBillInclusion.excluded);
    final owner = await billPostingSession(storage, first, moneyStore: drafts());
    expect(await confirmBill(owner, first), isTrue);
    final bookStore = SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage);
    final book = (await bookStore.read('account-A', 'store-A', qa: true))!;
    await bookStore.save(WorkspacePurchaseEntryBook.fromJson({...book.toJson(),
      'revision': book.revision + 1, 'copies': [...book.copies.map((copy) => copy.toJson()), second.copy.toJson()]}),
      expectedRevision: book.revision);
    expect(await owner.loadWorkspaceSuppliers(retry: true), isTrue);
    expect(await confirmBill(owner, second, bookRevision: book.revision + 1, ledgerRevision: 2), isTrue);
    final opening = owner.workspaceSupplierLedger(first.copy.supplier.id)!.openingRecord!;
    final source = WorkspaceSupplierLedgerEntry(operationId: 'shared-bill-source', reference: 'HOST-SHARED-ADVANCE',
      origin: WorkspaceSupplierEntryOrigin.supplierAccount, kind: WorkspaceSupplierEntryKind.advance,
      amountMinor: 10000, paymentMethod: 'Cash', postedAt: DateTime.utc(2026, 10, 3),
      moneyReview: WorkspaceSupplierMoneyReview(occurredOn: '2026-10-03', openingId: opening.id,
        openingRevision: opening.revision, notIncludedInOpening: true));
    expect(await owner.recordWorkspaceSupplierMoney(opening.supplierId, accountScope: 'account-A',
      workspaceId: 'store-A', entry: source, expectedRevision: 3), isTrue);
    final other = await openingPostingSession(storage, moneyStore: drafts());
    expect(await other.recoverCustomerLedger(), isTrue);
    final current = owner.workspaceSupplierLedger(opening.supplierId)!;
    final stock = owner.workspaceCatalogueItems.map((item) => (item.id, item.stock)).toList();
    final entries = current.entries.map((entry) => entry.toJson()).toList();
    final keys = [owner.supplierAllocationFormKey(first.copy)!, other.supplierAllocationFormKey(second.copy)!];
    expect(keys[0], isNot(keys[1]));
    final intents = [for (final bill in [first, second]) WorkspaceSupplierMoneyAllocationIntent.fromJson(
      moneyAllocationFixture(current, bill, id: 'shared-intent-${bill.billId}',
        kind: WorkspaceSupplierMoneySourceKind.accountAdvance, source: source.operationId).intentToJson())];
    for (var index = 0; index < intents.length; index++) {
      await drafts().save(WorkspaceLedgerFormDraft(key: keys[index], revision: 1, fields: {
        'amount': '100.00', 'sourceKind': intents[index].sourceKind.name,
        'sourceId': intents[index].sourceId, 'attempt': jsonEncode(intents[index].intentToJson())}), expectedRevision: null);
    }
    expect(await owner.recordWorkspaceSupplierAllocationDraft(keys[0], intents[0]), isTrue);
    final writes = storage.writes.length;
    expect(await other.recordWorkspaceSupplierAllocationDraft(keys[1], intents[1]), isFalse);
    expect(storage.writes.length, writes);
    expect((await drafts().read(keys[1]))!.supplierAllocationIntent!.intentToJson(), intents[1].intentToJson());
    final reset = WorkspaceLedgerFormDraft(key: keys[1], revision: 2,
      fields: const {'amount': '', 'sourceKind': '', 'sourceId': ''});
    expect(await other.resetConfirmedWorkspaceSupplierAllocationDraft(reset, expectedRevision: 1), isFalse);
    final reopened = await openingPostingSession(storage, moneyStore: drafts());
    expect(await reopened.recoverCustomerLedger(), isTrue);
    expect(await reopened.recordWorkspaceSupplierAllocationDraft(keys[0], intents[0]), isTrue);
    expect(await reopened.recordWorkspaceSupplierAllocationDraft(keys[1], intents[1]), isFalse);
    expect(storage.writes.length, writes);
    final linked = reopened.workspaceSupplierLedger(opening.supplierId)!;
    expect(linked.billMoneyAllocations.length, 1);
    expect(linked.unallocatedMoneyMinor(WorkspaceSupplierMoneySourceKind.accountAdvance, source.operationId), 0);
    expect(linked.manualBillRemainingMinor(first.billId), first.amountMinor! - 10000);
    expect(linked.manualBillRemainingMinor(second.billId), second.amountMinor);
    expect(linked.balanceMinor, current.balanceMinor);
    expect(linked.entries.map((entry) => entry.toJson()).toList(), entries);
    expect(reopened.workspaceCatalogueItems.map((item) => (item.id, item.stock)).toList(), stock);
  });

  test('PURCHASELATE session lost reply restart and proof retries never duplicate liability', () async {
    // Host-only fault fixture. Not device acceptance or synthetic runtime data.
    final storage = _OrderJournalStorage();
    final bill = acceptanceFixture(id: 'late-copy', draftId: 'late-bill', date: '2026-10-01',
      reference: 'HOST-LATE-1', total: '2840.75', treatment: WorkspaceOpeningBillInclusion.excluded);
    final owner = await billPostingSession(storage, bill);
    final opening = owner.workspaceSupplierLedger(bill.copy.supplier.id)!.openingRecord!;
    final proof = WorkspaceSupplierBillOpeningReview(openingId: opening.id,
      openingRevision: opening.revision, treatment: bill.openingTreatment);
    final stock = owner.workspaceCatalogueItems.map((p) => (p.id, p.stock)).toList();
    Future<bool> confirm(WorkSession session, WorkspaceSupplierBillOpeningReview? review) =>
      session.confirmWorkspacePurchaseBill(bill.copy, scope: session.workspaceSupplierScope!,
        expectedPurchaseRevision: 4, expectedLedgerRevision: 1, openingTreatment: bill.openingTreatment,
        openingReview: review, confirmedAt: bill.acceptedAt);
    expect(await confirm(owner, null), isFalse);
    storage.failWrite = true;
    expect(await confirm(owner, proof), isFalse);
    storage.failWrite = false;
    expect(await owner.recoverCustomerLedger(), isTrue);
    expect(owner.workspaceSupplierLedger(bill.copy.supplier.id)!.purchaseBills, isEmpty);
    storage.loseWriteResponseOnce = true;
    expect(await confirm(owner, proof), isFalse);
    final writes = storage.writes.length;
    final restarted = await openingPostingSession(storage);
    expect(await confirm(restarted, proof), isTrue);
    expect(storage.writes.length, writes);
    final posted = restarted.workspaceSupplierLedger(bill.copy.supplier.id)!;
    expect(posted.balanceMinor, 284075);
    expect(posted.entries.length, 1);
    expect(posted.openingRecord!.toJson(), opening.toJson());
    expect(posted.purchaseBills.values.single.openingReview!.toJson(), proof.toJson());
    expect(posted.goodsReceipts, isEmpty);
    expect(await confirm(restarted, null), isFalse);
    expect(await confirm(restarted, WorkspaceSupplierBillOpeningReview(openingId: opening.id,
      openingRevision: opening.revision + 1, treatment: bill.openingTreatment)), isFalse);
    expect(storage.writes.length, writes);
    expect(restarted.workspaceCatalogueItems.map((p) => (p.id, p.stock)), stock);
  });

  test('PURCHASEPOST bill confirmation restart and retry preserve stock and customer finance', () async {
    final storage = _OrderJournalStorage();
    final bill = newBillFixture();
    final session = await billPostingSession(storage, bill);
    final stock = session.workspaceCatalogueItems.map((p) => (p.id, p.stock)).toList();
    final dues = session.workspaceFinance!.duesMinor;
    expect(await confirmBill(session, bill), isTrue);
    final ledger = session.workspaceSupplierLedger(bill.copy.supplier.id)!;
    expect(ledger.payableMinor, 284075);
    expect(ledger.purchaseBills['new-bill']!.copy.toJson(), bill.copy.toJson());
    final writes = storage.writes.length;
    expect(await confirmBill(session, bill), isTrue);
    expect(storage.writes.length, writes);
    final reopened = await openingPostingSession(storage);
    expect(await reopened.recoverCustomerLedger(), isTrue);
    expect(reopened.workspaceSupplierLedger(bill.copy.supplier.id)!.toJson(), ledger.toJson());
    expect(await confirmBill(reopened, bill, bookRevision: 1), isTrue);
    expect(storage.writes.length, writes);
    expect(session.workspaceCatalogueItems.map((p) => (p.id, p.stock)), stock);
    expect(session.workspaceFinance!.duesMinor, dues);
  });

  test('PURCHASEPOST failed bill save and lost reply recover without another liability', () async {
    final storage = _OrderJournalStorage();
    final bill = newBillFixture();
    final session = await billPostingSession(storage, bill);
    storage.failWrite = true;
    expect(await confirmBill(session, bill), isFalse);
    storage.failWrite = false;
    expect(await session.recoverCustomerLedger(), isTrue);
    expect(session.workspaceSupplierLedger(bill.copy.supplier.id)!.payableMinor, 0);
    storage.loseWriteResponseOnce = true;
    expect(await confirmBill(session, bill), isFalse);
    final writes = storage.writes.length;
    final reopened = await openingPostingSession(storage);
    expect(await confirmBill(reopened, bill), isTrue);
    expect(storage.writes.length, writes);
    final ledger = reopened.workspaceSupplierLedger(bill.copy.supplier.id)!;
    expect(ledger.entries.length, 1);
    expect(ledger.purchaseBills.length, 1);
    expect(ledger.payableMinor, 284075);
  });

  test('PURCHASEPOST bill checkpoint cannot duplicate a draft across suppliers', () async {
    final storage = _OrderJournalStorage();
    final bill = newBillFixture();
    final session = await billPostingSession(storage, bill);
    expect(await confirmBill(session, bill), isTrue);
    final first = session.workspaceSupplierLedger(bill.copy.supplier.id)!;
    final supplier = WorkspaceSupplierProfile.fromJson({
      ...bill.copy.supplier.toJson(), 'id': 'supplier-B'});
    final copy = WorkspacePurchaseSavedCopy.fromJson({...bill.copy.toJson(),
      'supplier': supplier.toJson(),
      'draft': {...bill.copy.draft.toJson(), 'supplierId': supplier.id}});
    final record = WorkspaceSupplierOpeningRecord.fromJson({
      ...openingFixture(amount: 0, bills: const []).toJson(), 'supplierId': supplier.id});
    final second = confirmedOpeningFixture(record, supplier: supplier.id)!
      .acceptReviewedBill(WorkspaceSupplierBillAcceptance(copy: copy,
        acceptedAt: bill.acceptedAt, openingTreatment: bill.openingTreatment),
        expectedRevision: 1)!;
    expect(first.valid, isTrue);
    expect(second.valid, isTrue);
    expect(WorkspaceLedgerCheckpoint(revision: 3, finance: session.workspaceFinance!,
      supplierLedgers: {first.supplierId: first, second.supplierId: second}).valid, isFalse);
    expect(WorkspaceSupplierLedger.fromJson({...first.toJson(), 'purchaseBills': null}), isNull);
  });

  test('PURCHASEPOST concurrent bill confirmations cannot overwrite the checkpoint', () async {
    final storage = _OrderJournalStorage();
    final bill = newBillFixture();
    final first = await billPostingSession(storage, bill);
    final second = await openingPostingSession(storage);
    expect(await second.recoverCustomerLedger(), isTrue);
    expect(second.workspaceSupplierLedger(bill.copy.supplier.id)!.revision, 1);
    expect(await confirmBill(first, bill), isTrue);
    final writes = storage.writes.length;
    expect(await confirmBill(second, bill), isTrue,
      reason: 'Identical persisted checkpoint is acknowledged without rewriting.');
    expect(storage.writes.length, writes);
    expect(await second.recoverCustomerLedger(), isTrue);
    expect(await confirmBill(second, bill), isTrue);
    expect(storage.writes.length, writes);
    expect(second.workspaceSupplierLedger(bill.copy.supplier.id)!.purchaseBills.length, 1);
    expect(second.workspaceSupplierLedger(bill.copy.supplier.id)!.payableMinor, 284075);
  });

  test('PURCHASEPOST different stale bill cannot erase another accepted bill', () async {
    final storage = _OrderJournalStorage();
    final bill = newBillFixture();
    final first = await billPostingSession(storage, bill);
    final otherBill = acceptanceFixture(id: 'other-copy', draftId: 'other-bill',
      date: '2026-10-02', reference: 'SUP-NEW-2', total: '100',
      treatment: WorkspaceOpeningBillInclusion.excluded);
    final owner = SecureWorkPurchaseEntryStore(accountScope: () => 'account-A', storage: storage);
    final old = (await owner.read('account-A', 'store-A', qa: true))!;
    await owner.save(WorkspacePurchaseEntryBook.fromJson({...old.toJson(),
      'revision': 5, 'copies': [...old.copies.map((copy) => copy.toJson()), otherBill.copy.toJson()]}),
      expectedRevision: 4);
    expect(await first.loadWorkspaceSuppliers(retry: true), isTrue);
    final second = await openingPostingSession(storage);
    expect(await second.recoverCustomerLedger(), isTrue);
    expect(await confirmBill(first, bill, bookRevision: 5), isTrue);
    final writes = storage.writes.length;
    expect(await confirmBill(second, otherBill, bookRevision: 5), isFalse);
    expect(storage.writes.length, writes);
    expect(await second.recoverCustomerLedger(), isTrue);
    final recovered = second.workspaceSupplierLedger(bill.copy.supplier.id)!;
    expect(recovered.purchaseBills.keys, ['new-bill']);
    expect(await confirmBill(second, otherBill, bookRevision: 5,
      ledgerRevision: recovered.revision), isTrue);
    final saved = second.workspaceSupplierLedger(bill.copy.supplier.id)!;
    expect(saved.purchaseBills.length, 2);
    expect(saved.entries.length, 2);
    expect(saved.payableMinor, 294075);
  });

  test('PURCHASEPOST missing pack identifies item without posting', () async {
    // Host-only regression fixture, not physical-device acceptance data.
    for (final unit in ['', '   ']) {
      final storage = _OrderJournalStorage();
      final bill = allocatedBillFixture(unit: unit);
      expect(bill.valid, isFalse);
      final session = await billPostingSession(storage, bill);
      final writes = storage.writes.length;
      final original = bill.copy.toJson();
      expect(await confirmBill(session, bill), isFalse);
      expect(session.workspaceSupplierError,
          'Item 1 is missing Pack / unit. Edit purchase, enter the pack or unit '
          'shown on the supplier bill, then save a new reviewed copy.');
      expect(storage.writes.length, writes);
      expect(session.workspaceSupplierLedger(bill.copy.supplier.id)!.purchaseBills, isEmpty);
      expect(bill.copy.toJson(), original);
      expect(session.workspaceStockMovements, isEmpty);
    }
  });

  test('PURCHASEPOST supplier unit is not replaced by Stock unit', () async {
    // Different bill units require later reviewed receipt conversion, not inference.
    final storage = _OrderJournalStorage();
    final bill = allocatedBillFixture(unit: 'carton of 12');
    final session = await billPostingSession(storage, bill);
    expect(await confirmBill(session, bill), isTrue);
    final saved = session.workspaceSupplierLedger(bill.copy.supplier.id)!;
    expect(saved.purchaseBills[bill.billId]!.copy.draft.goods.single['pack'], 'carton of 12');
    expect(session.workspaceStockMovements, isEmpty);
  });

  test('PURCHASEPOST stale bill book and wrong scope cannot confirm', () async {
    final storage = _OrderJournalStorage();
    final bill = newBillFixture();
    final session = await billPostingSession(storage, bill);
    final writes = storage.writes.length;
    expect(await confirmBill(session, bill, bookRevision: 3), isFalse);
    expect(await confirmBill(session, bill, ledgerRevision: 2), isFalse);
    expect(await session.confirmWorkspacePurchaseBill(bill.copy,
      scope: ('other-account', 'store-A', true), expectedPurchaseRevision: 4,
      expectedLedgerRevision: 1, openingTreatment: bill.openingTreatment,
      confirmedAt: bill.acceptedAt), isFalse);
    expect(storage.writes.length, writes);
    expect(session.workspaceSupplierLedger(bill.copy.supplier.id)!.purchaseBills, isEmpty);
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
          contactDraftStore: _CommandAccountStore(),
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
          WorkSession(
              gateway: ReviewWorkGateway(),
              contactDraftStore: account,
              pendingProofStore: account,
            )
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
          contactDraftStore: _CommandAccountStore(),
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
      final multiReturn = WorkspaceLedgerFormDraft(
        key: key(kind: 'return'), revision: 1,
        fields: {'items': jsonEncode({'sku-A': ['2', '1'], 'sku-B': ['bad input', '0']}),
          'reason': 'Two packs reviewed'},
      );
      final returnStorage = _OrderJournalStorage();
      SecureWorkLedgerFormDraftStore returnDrafts() => SecureWorkLedgerFormDraftStore(
        accountScope: () => account, storage: returnStorage);
      await returnDrafts().save(multiReturn, expectedRevision: null);
      expect((await returnDrafts().read(key(kind: 'return')))!.fields, multiReturn.fields);
      for (final invalid in ['{broken', '[]', '{"sku-A":[1,0]}', '{"sku-A":["1"]}']) {
        expect(WorkspaceLedgerFormDraft(key: key(kind: 'return'), revision: 2,
          fields: {'items': invalid}).valid, isFalse);
      }
      expect(WorkspaceLedgerFormDraft(key: key(), revision: 1,
        fields: multiReturn.fields).valid, isFalse);
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
    for (final (paid, seededOrders) in [
      for (final paid in [0, 600, 1000])
        for (final seededOrders in [0, 12]) (paid, seededOrders),
    ]) {
      test('LEDGER01 return posts once with collected=$paid seededOrders=$seededOrders', () async {
        final seed = StoreReviewSeed(
          accountScope: 'account-A',
          orderCount: seededOrders,
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
          reasonCode: 'damaged',
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
        expect(recoveredPending.pendingReturn!.request.reasonCode, 'damaged');
        final legacyReturn = returned.toJson()..remove('reasonCode');
        expect(WorkspaceCustomerReturn.fromJson(legacyReturn).reasonCode, isNull);
        expect(WorkspaceCustomerReturn.fromJson(legacyReturn).reason, 'Two packs returned');
        expect(() => WorkspaceCustomerReturn.fromJson({
          ...returned.toJson(), 'reasonCode': 'invented',
        }), throwsFormatException);
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
        expect(creditEntry.customerReturn!.reasonCode, 'damaged');
        final periodStart = creditEntry.occurredAt.subtract(const Duration(seconds: 1));
        final periodEnd = creditEntry.occurredAt.add(const Duration(seconds: 1));
        expect(result.returnReasonsBetween(periodStart, periodEnd), seededOrders == 0
          ? {'damaged': (count: 1, creditMinor: 666)} : isNull);
        expect(before.returnReasonsBetween(periodStart, periodEnd), seededOrders == 0 ? isEmpty : isNull,
          reason: 'Pending intents and original collections are not confirmed returns');
        expect(result.returnReasonsBetween(periodEnd, periodEnd.add(const Duration(days: 1))),
          seededOrders == 0 ? isEmpty : isNull);
        expect(result.returnReasonsBetween(periodEnd, periodStart), isNull);
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
          contactDraftStore: _CommandAccountStore(),
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
              contactDraftStore: _CommandAccountStore(),
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
          contactDraftStore: _CommandAccountStore(),
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
            contactDraftStore: _CommandAccountStore(),
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
          contactDraftStore: _CommandAccountStore(),
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
          contactDraftStore: _CommandAccountStore(),
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
    var approved = true;
    late _ProcurementBookmarks bookmarks;
    late WorkProcurementController controller;
    final states = <String, _ProcurementCustomerState>{};
    WorkProcurementController create() => WorkProcurementController(
      currentAccountId: () => account,
      currentStoreId: () => store,
      storeApproved: () => approved,
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
      approved = true;
      states.clear();
      bookmarks = _ProcurementBookmarks();
      controller = create();
    });
    tearDown(() => controller.dispose());
    for (final failure in ['approval', 'identity', 'read', 'write']) {
      test('opening failure guidance preserves saved purchase $failure', () async {
        expect(await controller.open(purpose: BuyV2ProcurementPurpose.restock,
          returnTo: 'dashboard'), isTrue);
        final original = controller.bookmark!.context.customerStateOwnerScope;
        final writes = bookmarks.saveAttempts;
        approved = failure != 'approval';
        if (failure == 'identity') account = '';
        bookmarks.failRead = failure == 'read';
        bookmarks.failSave = failure == 'write';
        expect(await controller.open(purpose: BuyV2ProcurementPurpose.restock,
          returnTo: 'dashboard'), isFalse);
        expect(controller.openFailureMessage, contains(switch (failure) {
          'approval' => 'verified Store', 'identity' => 'account is unavailable',
          'read' => 'could not be read', _ => 'could not be saved',
        }));
        expect(bookmarks.saveAttempts - writes, failure == 'write' ? 1 : 0);
        expect(controller.bookmark!.context.customerStateOwnerScope, original);
        approved = true;
        account = 'a';
        bookmarks.failRead = bookmarks.failSave = false;
        expect(await controller.open(purpose: BuyV2ProcurementPurpose.restock,
          returnTo: 'dashboard'), isTrue);
        expect(controller.openFailureMessage, isNull);
        expect(controller.bookmark!.context.customerStateOwnerScope, original);
      });
    }
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
        final firstDraft = (await journal.read('account-A', 'store-A'))!;
        expect(firstDraft.id, matches(RegExp(r'^BILL-[0-9a-f]{32}$')));
        expect(await work.saveWorkspaceCounterDraft(), isTrue);
        expect(
          (await journal.read('account-A', 'store-A'))!.id,
          firstDraft.id,
          reason: 'Saving again must preserve the original bill identity.',
        );
        final first = await work.submitWorkspaceCounterBill();
        expect(first, isNotNull);
        expect(first!.orderId, matches(RegExp(r'^ORD-[0-9a-f]{32}$')));
        expect(work.startNewWorkspaceOrder(), isTrue);
        expect(work.counterCustomerInput, isNull);
        await fill(work);
        final secondDraft = (await journal.read('account-A', 'store-A'))!;
        expect(secondDraft.id, matches(RegExp(r'^BILL-[0-9a-f]{32}$')));
        expect(secondDraft.id, isNot(firstDraft.id));
        work.updateWorkspaceCounterDetails(customer: '9000000014');
        final second = await work.submitWorkspaceCounterBill();
        expect(second, isNotNull);
        expect(second!.orderId, matches(RegExp(r'^ORD-[0-9a-f]{32}$')));
        expect(second.orderId, isNot(first.orderId));
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
        contactDraftStore: _CommandAccountStore(),
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
          contactDraftStore: _CommandAccountStore(),
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
        contactDraftStore: account,
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
      final work = WorkSession(
        contactDraftStore: _CommandAccountStore(),
        pendingProofStore: _CommandAccountStore(),
      )..activeWorkspace = _commandStore;
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
          contactDraftStore: account,
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
        contactDraftStore: account,
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
        contactDraftStore: _CommandAccountStore(),
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
      final session = WorkSession(
        gateway: gateway,
        contactDraftStore: account,
        pendingProofStore: account,
      )..activeWorkspace = _commandStore;
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
              contactDraftStore: _CommandAccountStore(),
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
        contactDraftStore: account,
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
        contactDraftStore: account,
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
        contactDraftStore: account,
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
    'catalogue import updates by SKU and retirement preserves stock and history',
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
      final movements = List.of(session.workspaceStockMovements);
      final invoices = List.of(session.workspaceInvoices);
      session.retireWorkspaceProduct('oil-1l');
      final retired = session.workspaceCatalogueItems.singleWhere(
        (item) => item.id == 'oil-1l',
      );
      expect(retired.stock, 18);
      expect(retired.sellingPrice, 155);
      expect(retired.sku, 'OIL-1L');
      expect(retired.available, isTrue);
      expect(retired.counterSaleAllowed, isFalse);
      expect(retired.publicListing, isTrue);
      expect(retired.published, isFalse);
      expect(retired.canSellAtCounter, isFalse);
      expect(session.workspaceStockMovements, orderedEquals(movements));
      expect(session.workspaceInvoices, orderedEquals(invoices));
      final activities = session.workspaceActivity.length;
      session.retireWorkspaceProduct('oil-1l');
      session.retireWorkspaceProduct('missing-product');
      expect(session.workspaceActivity, hasLength(activities));
      expect(session.workspaceStockMovements, orderedEquals(movements));
      expect(session.workspaceCatalogueItems, hasLength(2));
    },
  );

  test('STOCK-AUDIT-09 counter and public settings are independent and durable', () {
    final product = _product(stock: 10);
    final counterPaused = product.copyWith(counterSaleEnabled: false);
    expect(counterPaused.publicListing, product.publicListing);
    expect(counterPaused.published, product.published);
    expect(counterPaused.canSellAtCounter, isFalse);
    final saved = WorkspaceCatalogueItem.fromInventoryJson(counterPaused.toInventoryJson());
    expect(saved.counterSaleAllowed, isFalse);
    final publicHidden = product.copyWith(publicListing: false, counterSaleEnabled: true);
    expect(publicHidden.canSellAtCounter, isTrue);
    expect(publicHidden.published, isFalse);
    final legacy = product.copyWith(available: false).toInventoryJson()
      ..remove('counterSaleEnabled');
    expect(WorkspaceCatalogueItem.fromInventoryJson(legacy).counterSaleAllowed, isFalse);
  });

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
