import assert from 'node:assert/strict';
import test from 'node:test';
import {randomUUID, createHash} from 'node:crypto';
import {writeFileSync} from 'node:fs';
import {initializeApp, deleteApp} from 'firebase-admin/app';
import {getFirestore, type Transaction} from 'firebase-admin/firestore';
import {FirestoreWorkspaceLedgerRepository, type LedgerPurchaseAnchor} from './workspace_ledger_repository.js';
import {FirestorePurchaseEntryRepository} from './workspace_purchase_entry_repository.js';
import {OriginalStoreLedgerPreparationContext, CompositePreparationContext} from '../assistant/domain_context.js';
import {canonicalContextProjection} from '../assistant/domain_context_contract.js';
import {assertStrictSchema, command as checkedModelCommand, type PreparationRequest, type PreparationReply} from '../assistant/model_contract.js';
import {purchaseEntryCommandFingerprint, purchaseEntryOpeningCommandFingerprint, purchaseEntryDraftCommandFingerprint, checkedPurchaseEntryCopy,
  planPurchaseEntryOpening, workspaceOriginalRequestBodyLimit, WorkspacePurchaseEntryService,
  type PurchaseEntryBook} from './workspace_purchase_entry_service.js';
import {WorkspaceProfileError} from './workspace_profile_service.js';
import {
  WorkspaceLedgerService, checkedLedgerCommand, checkedLedgerExpense, checkedLedgerOpening,
  checkedLedgerSupplierBillAcceptance, ledgerPrintedPaise, checkedLedgerSupplierAllocationIntent, checkedLedgerSupplierAllocationProof,
  checkedLedgerSupplierRefundIntent, checkedLedgerSupplierRefundProof, ledgerSupplierRefundEntry, ledgerSupplierFinancialHistory,
  checkedLedgerSupplierCreditDocumentInput, ledgerSupplierCreditPrintedTotal,
  checkedLedgerSupplierCreditIntent, checkedLedgerSupplierCreditProof, ledgerSupplierCreditEntry, ledgerSupplierCreditInput,
  ledgerSupplierCreditGoodsSource, ledgerSupplierCreditHistory, ledgerSupplierAvailableCreditSupports,
  ledgerSupplierCreditParticularLimits, ledgerSupplierBillSurplusAt, ledgerBillLiabilityEntry,
  checkedLedgerRegisterHeader, checkedLedgerRegisterEntry, checkedLedgerSupplierMoneyEntry,
  ledgerSupplierMoneyMethods, ledgerCanonical, ledgerHash, ledgerClone,
  ledgerCommandFingerprint, ledgerCommandInput, ledgerCommandTarget, ledgerConfirmedOpening,
  type LedgerActor, type LedgerScope, type LedgerCommand, type LedgerExpenseCommand,
  type LedgerOpeningCommand, type LedgerRegisterCommand, type LedgerExpense, type LedgerOpeningRecord,
  type LedgerRegisterHeader, type LedgerRepository, type LedgerPage, type LedgerRow, type LedgerStatus,
  type LedgerReceipt, type LedgerSupplierMoneyCommand, type LedgerSupplierBillCommand, type LedgerSupplierAllocationCommand, type LedgerSupplierRefundCommand,
} from './workspace_ledger_service.js';

// Actual SDK tests below are deliberately restricted to an owned loopback
// emulator. These fixtures never implement or activate runtime membership.
const ledgerEmulator = process.env.FIRESTORE_EMULATOR_HOST;
async function sdkLedger() {
  assert.match(ledgerEmulator!, /^127\.0\.0\.1:\d+$/u);
  const projectId = 'demo-agg04-' + randomUUID().slice(0, 8), app = initializeApp({projectId}, 'agg04-' + randomUUID());
  const db = getFirestore(app), user = {...actor, projectId}, grant = db.doc('HOST_ONLY_LEDGER_AUTHORITY/current');
  await grant.set({label: 'ISOLATED HOST FIXTURE, NOT A RUNTIME MEMBERSHIP ISSUER', active: true, ...scope});
  let barrier: (() => Promise<void>) | undefined;
  const authority = {assertCurrent: async (tx: Transaction, actual: LedgerActor, requested: LedgerScope) => {
    if (barrier) await barrier();
    const current = await tx.get(grant);
    if (!current.exists || !current.get('active') || current.get('account') !== actual.uid ||
        current.get('store') !== requested.store || current.get('realm') !== requested.realm) {
      throw new WorkspaceProfileError('permission_denied', 'HOST revoked authority', 403);
    }
  }};
  const root = db.collection('privateWorkspaceLedgerV1').doc(ledgerHash({projectId, scope}));
  const purchaseRef = db.doc('HOST_ONLY_PURCHASE_ANCHOR/current');
  const purchase: LedgerPurchaseAnchor = {
    capture: async () => {const value = await purchaseRef.get(); return value.exists ? value.data() as unknown as PurchaseEntryBook : null;},
    assertCurrent: async (tx, actual, requested, captured) => {
      await authority.assertCurrent(tx, actual, requested);
      const current = await tx.get(purchaseRef);
      if (!current.exists || ledgerHash(current.data()) !== ledgerHash(captured)) {
        throw new WorkspaceProfileError('stale_evidence', 'HOST original changed', 409);
      }
    },
  };
  const repo = () => new FirestoreWorkspaceLedgerRepository(db, 'evaluation', projectId, authority, purchase, now);
  return {db, user, grant, root, purchaseRef, repo, authority, purchase,
    setBarrier: (value: (() => Promise<void>) | undefined) => {barrier = value;},
    close: async () => {await db.terminate(); await deleteApp(app);}};
}
function resign<T extends LedgerCommand>(value: T): T {
  const {fingerprint: _fingerprint, ...input} = value;
  return {...input, fingerprint: ledgerHash(input)} as T;
}
async function seedSdkRegister(f: Awaited<ReturnType<typeof sdkLedger>>, value = header()) {
  // Independent original fixture; there is intentionally no runtime API which
  // creates a bank/register or upgrades incomplete history to complete history.
  const kind = 'moneyRegister', json = ledgerCanonical(value), fingerprint = ledgerHash(value), bytes = Buffer.from(json);
  const payload = {id: ledgerHash({scope, kind, id: value.registerId, parentId: null, revision: value.revision, fingerprint}),
    fingerprint, byteLength: bytes.length, parts: 1};
  const ref = f.root.collection('payloads').doc(payload.id), id = value.registerId;
  await ref.collection('parts').doc('0000000000').set({schemaVersion: 1, index: 0, data: bytes.toString('base64'),
    fingerprint: createHash('sha256').update(bytes).digest('hex')});
  const identity = {schemaVersion: 1, projectId: f.user.projectId, scope, kind, id, parentId: null};
  const manifest = {...identity, revision: value.revision, ordinal: null, payload};
  await ref.set(manifest);
  const batch = f.db.batch();
  batch.create(f.root, {schemaVersion: 1, projectId: f.user.projectId, scope, revision: 1,
    counts: {supplierLedger: 0, expense: 0, moneyRegister: 1, moneyEntry: 0}, updatedAt: confirmedAt});
  batch.create(f.root.collection(kind).doc(ledgerHash({id})), {...manifest, writeRevision: 1});
  batch.create(f.root.collection('recordIdentities').doc(ledgerHash({kind, id, parent: null})), identity);
  await batch.commit();
}
async function seedOriginalPurchase(f: Awaited<ReturnType<typeof sdkLedger>>, book: PurchaseEntryBook) {
  const root = f.db.collection('privateWorkspacePurchaseEntriesV1').doc(ledgerHash({projectId: f.user.projectId, scope}));
  const bytes = Buffer.from(ledgerCanonical(book)), fingerprint = ledgerHash(book);
  const pointer = {id: ledgerHash({scope, revision: book.revision, fingerprint}), fingerprint,
    byteLength: bytes.length, parts: Math.ceil(bytes.length / (192 * 1024)), revision: book.revision};
  const ref = root.collection('originals').doc(pointer.id);
  for (let index = 0; index < pointer.parts; index++) {
    const part = bytes.subarray(index * 192 * 1024, (index + 1) * 192 * 1024);
    await ref.collection('parts').doc(String(index).padStart(5, '0')).create({schemaVersion: 1, index,
      data: part.toString('base64'), fingerprint: createHash('sha256').update(part).digest('hex')});
  }
  await ref.create({schemaVersion: 1, projectId: f.user.projectId, scope, ...pointer});
  await root.create({schemaVersion: 1, projectId: f.user.projectId, scope, original: pointer});
  return {root, repository: new FirestorePurchaseEntryRepository(f.db, 'evaluation', f.user.projectId, f.authority, now)};
}
function originalOpeningBook(record = opening()): PurchaseEntryBook {
  return {version: 1, account: scope.account, store: scope.store, qa: false, revision: 2,
    profiles: [{id: record.supplierId, name: 'HOST original supplier', phone: '', address: '', gstin: '',
      source: 'manual', createdAt: at, updatedAt: at}], draft: null, openingRecords: [record]};
}

async function sdkPreparation(f: Awaited<ReturnType<typeof sdkLedger>>, options: {posted?: boolean; newOpening?: boolean; unavailable?: boolean;
  existing?: {book: PurchaseEntryBook; purchase: Awaited<ReturnType<typeof seedOriginalPurchase>>}} = {}) {
  if (!options.existing) await seedSdkRegister(f);
  const book = options.existing?.book ?? (options.newOpening ? {...originalOpeningBook(), openingRecords: []} : originalOpeningBook());
  const purchase = options.existing?.purchase ?? await seedOriginalPurchase(f, book);
  const ledger = new WorkspaceLedgerService(new FirestoreWorkspaceLedgerRepository(f.db, 'evaluation', f.user.projectId,
    f.authority, purchase.repository.ledgerAnchor(), now), now);
  if (options.posted) await ledger.handle(f.user, 'confirmStoreSupplierOpening', body(resign({...openingCommand(),
    expectedRevision: 1, expectedPurchaseFingerprint: ledgerHash(book)})));
  const calls: string[] = [];
  let ownerRevision = 1, ownerReads = 0, changedOwner = false;
  let alter = (_frame: Record<string, unknown>, _operation: string, _body: Readonly<Record<string, unknown>>) => {};
  const authority = {async read() {
    ownerReads++; if (changedOwner && ownerReads > 1) ownerRevision++;
    return {revision: `HOST-preparation-owner-${ownerRevision}`, validUntil: new Date(now().getTime() + 120_000).toISOString(),
      modelContext: {audience: 'workspace', current: {id: scope.store}}, tools: [{name: 'HOST-approved-paid-port',
        actionId: 'AI-ACT-317', entityId: scope.store, sourceRevision: 'HOST-accepted-owner', description: 'HOST approval port only',
        parameters: {type: 'object', properties: {}, required: [], additionalProperties: false}, validate: () => true}]};
  }};
  const source = new OriginalStoreLedgerPreparationContext({realm: 'evaluation', authority, now,
    ledger: {async handle(who, operation, input) {
      calls.push(operation); assert.equal(operation, 'readStoreLedgerSource', 'Preparation cannot save, confirm, retry or read an attempt.');
      const frame = ledgerClone(await (options.unavailable ? new WorkspaceLedgerService(null) : ledger).handle(who, operation, input)) as Record<string, unknown>;
      alter(frame, operation, input); return frame;
    }}, purchase: new WorkspacePurchaseEntryService(purchase.repository, now)});
  const input: PreparationRequest = {scope: {audience: 'workspace', storeId: scope.store}, requestId: 'HOST-ledger-prepare',
    requestRevision: 1, message: 'HOST local preparation only', language: 'English', history: [], actionId: null,
    entityId: null, expectedEntitlementRevision: 'HOST-approved-paid-port'};
  return {source, input, calls, ledger, purchase, authority, book,
    alter: (fn: typeof alter) => {alter = fn;}, changeOwner: () => {changedOwner = true;}};
}

for (const scenario of ['unposted', 'new opening', 'posted'] as const) {
  test(`AGG04 SDK AI preparation joins original sources without writing: ${scenario}`, {skip: !ledgerEmulator}, async () => {
    const f = await sdkLedger();
    try {
      const prep = await sdkPreparation(f, {posted: scenario === 'posted', newOpening: scenario === 'new opening'});
      const before = ledgerHash((await f.root.get()).data()), attempts = (await f.root.collection('attempts').get()).size;
      const context = await prep.source.read(f.user, prep.input);
      const ids = context.tools.map(tool => tool.actionId);
      assert(ids.includes('AI-ACT-270')); assert(ids.includes('AI-ACT-271'));
      assert.equal(ids.includes('AI-ACT-268'), scenario === 'posted');
      assert.equal(ids.includes('AI-ACT-258'), scenario === 'unposted');
      assert.equal(ids.includes('AI-ACT-381'), scenario === 'unposted');
      assert.equal(ids.includes('AI-ACT-257'), scenario === 'new opening');
      for (const tool of context.tools) assertStrictSchema(tool.parameters);
      const expenseTool = context.tools.find(tool => tool.actionId === 'AI-ACT-270')!;
      const fields = {amount: '12.50', reference: 'HOST receipt', channel: 'Cash', category: 'Other', note: ''};
      assert(expenseTool.validate(fields)); assert(!expenseTool.validate({...fields, channel: ['Cash']}));
      assert(!expenseTool.validate({...fields, amount: '0'})); assert(!expenseTool.validate({...fields, approved: true}));
      const expenseTarget = expenseTool.resolveTarget!(fields);
      assert.equal(expenseTarget.sourceRevision, 'store-original-ledger-v1:' + ledgerHash([
        scope.account, scope.store, scope.realm, scenario === 'posted' ? 2 : 1, null, 'AI-ACT-270', null]));
      const entry = context.tools.find(tool => tool.actionId === 'AI-ACT-271')!;
      const entryFields = entry.resolveTarget!({amount: '1.25', reference: 'HOST movement', direction: 'out', occurredAt: null});
      assert.deepEqual(entryFields.fields, {amount: '1.25', reference: 'HOST movement', direction: 'out'});
      assert.equal(entryFields.entityId, 'ledger-register:' + ledgerHash(header().registerId));
      assert(!entry.validate({...entryFields.fields, direction: ['out']}));
      assert(!entry.validate({...entryFields.fields, occurredAt: 'ambiguous local date'}));
      const projection = canonicalContextProjection(f.user, prep.input.scope, context, 1);
      assert(!JSON.stringify(projection).includes('HOST receipt'));
      assert(!JSON.stringify(context.modelContext).includes('openingMinor'));
      const restored = await prep.source.readPrepared(f.user, {...prep.input, actionId: entry.actionId, entityId: entry.entityId},
        {kind: 'proposal', id: 'HOST-original-entry-proposal', actionId: entry.actionId, ...entryFields, title: 'Review', summary: 'HOST'});
      assert.equal(restored.tools.length, 1); assert.equal(restored.tools[0]!.sourceRevision, entryFields.sourceRevision);
      assert.equal(ledgerHash((await f.root.get()).data()), before);
      assert.equal((await f.root.collection('attempts').get()).size, attempts);
      assert(prep.calls.every(operation => operation === 'readStoreLedgerSource'));
      if (process.env.AGG04_CONTEXT_CAPTURE_PATH && scenario === 'unposted') {
        writeFileSync(process.env.AGG04_CONTEXT_CAPTURE_PATH, JSON.stringify({label: 'ISOLATED ACTUAL SDK AI CONTEXT; NO RUNTIME AUTHORITY',
          actor: f.user, scope: prep.input.scope, now: now().toISOString(), metadata: {ok: true, data: projection},
          nativeTargets: context.nativeTargets, entryFields: entryFields.fields}), 'utf8');
      }
    } finally {await f.close();}
  });
}

for (const fault of ['actor', 'store', 'realm', 'tenant', 'personal', 'expired frame', 'corrupt row', 'duplicate row',
  'count mismatch', 'changed head', 'changed owner', 'revoked membership', 'unavailable service'] as const) {
  test(`AGG04 SDK AI preparation fails closed without records or retry: ${fault}`, {skip: !ledgerEmulator}, async () => {
    const f = await sdkLedger();
    try {
      const prep = await sdkPreparation(f, {unavailable: fault === 'unavailable service'});
      const before = ledgerHash((await f.root.get()).data());
      let reads = 0;
      prep.alter((frame, _operation, body) => {
        reads++;
        if (fault === 'actor') frame.actorAccountId = 'HOST-foreign-owner';
        if (fault === 'store') frame.storeId = 'HOST-foreign-store';
        if (fault === 'realm') frame.realm = 'production';
        if (fault === 'expired frame') frame.observedAt = new Date(now().getTime() - 60_001).toISOString();
        if (fault === 'changed head' && reads > 1) frame.sourceRevision = 2;
        if (body.kind === 'moneyRegister') {
          const rows = frame.rows as LedgerRow[];
          if (fault === 'corrupt row') rows[0]!.json = rows[0]!.json.replace('HOST original manual register', 'HOST changed register');
          if (fault === 'duplicate row') {rows.push(rows[0]!); frame.totalCount = 2;}
          if (fault === 'count mismatch') frame.totalCount = 2;
        }
      });
      if (fault === 'changed owner') prep.changeOwner();
      if (fault === 'revoked membership') await f.grant.update({active: false});
      await assert.rejects(prep.source.read(fault === 'tenant' ? {...f.user, tenantId: 'HOST-forbidden'} : f.user,
        fault === 'personal' ? {...prep.input, scope: {audience: 'personal', storeId: null}} : prep.input));
      assert.equal(ledgerHash((await f.root.get()).data()), before);
      assert.equal((await f.root.collection('attempts').get()).size, 0);
      assert(prep.calls.every(operation => operation === 'readStoreLedgerSource'));
    } finally {await f.close();}
  });
}

test('AGG04 SDK AI preparation stale handoff rereads originals and unavailable optional source preserves Profile tools', {skip: !ledgerEmulator}, async () => {
  const f = await sdkLedger();
  try {
    const prep = await sdkPreparation(f), original = await prep.source.read(f.user, {...prep.input, actionId: 'AI-ACT-270'});
    const tool = original.tools[0]!, target = tool.resolveTarget!({amount: '1.25', reference: 'HOST receipt', channel: 'Cash', category: 'Other', note: ''});
    // Independent labelled owner action changes the original head between preparation and Review.
    await prep.ledger.handle(f.user, 'recordStoreExpense', body(resign({...expenseCommand(), expectedRevision: 1})));
    await assert.rejects(prep.source.readPrepared(f.user, {...prep.input, actionId: 'AI-ACT-270'},
      {kind: 'proposal', id: 'HOST-stale-review', actionId: 'AI-ACT-270', ...target, title: 'Review', summary: 'HOST'}), /stale_preparation/u);
    const missing = new OriginalStoreLedgerPreparationContext({realm: 'evaluation', authority: prep.authority,
      ledger: new WorkspaceLedgerService(null), now});
    const composite = new CompositePreparationContext({original: prep.authority, storeLedger: missing});
    const context = await composite.read(f.user, prep.input);
    assert(context.tools.some(tool => tool.actionId === 'AI-ACT-317'));
    assert(!context.tools.some(tool => tool.actionId === 'AI-ACT-270'));
    assert.equal((await f.root.collection('attempts').get()).size, 1);
  } finally {await f.close();}
});
test('AGG04 HTTP body allowance is bounded to large original commands and leaves other requests unchanged', () => {
  const largeOriginalEnvelope = 21 * 1024 * 1024;
  for (const operation of ['saveStorePurchaseDraft', 'saveStoreSupplierOpeningEvidence', 'confirmStoreSupplierOpening', 'confirmStoreSupplierBill']) {
    assert.ok(workspaceOriginalRequestBodyLimit(operation) >= largeOriginalEnvelope);
    assert.ok(workspaceOriginalRequestBodyLimit(operation) <= 24 * 1024 * 1024);
  }
  for (const operation of ['', 'unknown', 'saveStoreSupplierProfile', 'readStoreLedgerAttempt', 'readStorePurchaseEntryBook',
    'readPublicStoreCatalogue', 'saveStoreCoupon', 'recordStoreExpense']) assert.equal(workspaceOriginalRequestBodyLimit(operation), 64 * 1024);
});
test('AGG04 original evidence planner preserves native basis, revision and supporting-copy relationships', () => {
  const book = originalOpeningBook(), input = {scope, profile: book.profiles[0]!, expectedRevision: 2, idempotencyKey: 'HOST-evidence-rules',
    opening: {...opening(), id: 'HOST-new-evidence', revision: 3}};
  const command = {...input, fingerprint: purchaseEntryOpeningCommandFingerprint(input)}, before = ledgerCanonical(book);
  const saved = planPurchaseEntryOpening(command, book);
  assert.equal(saved.book.openingRecords?.length, 2); assert.equal(ledgerCanonical(book), before);
  const foreignBasis = {...command, opening: {...command.opening, basisId: 'HOST-other-basis'}};
  assert.throws(() => planPurchaseEntryOpening(foreignBasis, book), code('immutable_opening_conflict'));
  const unknownBill = {...command, opening: {...command.opening, bills: [{copyId: 'HOST-absent-copy', copyRevision: 1,
    draftId: 'HOST-original-draft', inclusion: 'unknown' as const}]}};
  assert.throws(() => planPurchaseEntryOpening(unknownBill, book), code('stale_opening'));
  const corrupt = {...book, openingRecords: [book.openingRecords![0], book.openingRecords![0]]};
  assert.throws(() => planPurchaseEntryOpening(command, corrupt), code('service_unavailable'));
  const copy = {id: 'HOST-owned-copy', revision: 1, storeName: 'HOST Store', savedAt: at, supplier: book.profiles[0]!,
    draft: {id: 'HOST-original-draft', supplierId: command.profile.id, invoiceReference: 'HOST-RELATION-1', invoiceDate: '29/10/2026',
      createdAt: at, updatedAt: at, source: 'manual', stage: 'draft',
      goods: [{productId: '', name: 'HOST printed item', pack: 'HOST unit', quantity: '1', cost: ''}]}, labels: {name: 'HOST printed item'}};
  const linked = {...command, opening: {...command.opening, bills: [{copyId: copy.id, copyRevision: 1,
    draftId: copy.draft.id, inclusion: 'unknown' as const}]}};
  const original = {...book, copies: [copy]};
  const linkedResult = planPurchaseEntryOpening(linked, original);
  assert.equal((linkedResult.book.openingRecords?.[1] as LedgerOpeningRecord).bills[0]?.inclusion, 'unknown');
  assert.throws(() => planPurchaseEntryOpening(linked, {...book, copies: [{...copy, draft: {...copy.draft, supplierId: 'HOST-other-supplier'}}]}), code('service_unavailable'));
});
test('AGG04 SDK opening evidence is append-only and unposted; unknown amount remains unknown', {skip: !ledgerEmulator}, async () => {
  const f = await sdkLedger();
  try {
    const book = {...originalOpeningBook(), openingRecords: []}, original = await seedOriginalPurchase(f, book);
    const input = {scope, profile: book.profiles[0]!, expectedRevision: 2, idempotencyKey: 'HOST-unposted-evidence',
      opening: {...opening(), id: 'HOST-new-evidence', revision: 3, amountMinor: null}};
    const command = {...input, fingerprint: purchaseEntryOpeningCommandFingerprint(input)};
    const saved = await original.repository.saveOpeningEvidence(f.user, command);
    assert.equal(saved.receipt?.status, 'saved'); assert.equal(saved.receipt?.operation, 'saveSupplierOpeningEvidence');
    assert.equal(saved.currentBook?.revision, 3); assert.deepEqual(saved.currentBook?.profiles, book.profiles);
    assert.equal(saved.currentBook?.draft, book.draft); assert.equal((saved.currentBook?.openingRecords?.[0] as {amountMinor: unknown}).amountMinor, null);
    assert.equal((await f.root.get()).exists, false);
    assert.deepEqual(await original.repository.saveOpeningEvidence(f.user, command), saved);
    const conflict = {...input, idempotencyKey: 'HOST-conflicting-evidence', expectedRevision: 3,
      opening: {...input.opening, amountMinor: 100}};
    assert.equal((await original.repository.saveOpeningEvidence(f.user, {...conflict,
      fingerprint: purchaseEntryOpeningCommandFingerprint(conflict)})).receipt?.reason, 'immutable_opening_conflict');
    const ledger = new FirestoreWorkspaceLedgerRepository(f.db, 'evaluation', f.user.projectId, f.authority, original.repository.ledgerAnchor(), now);
    const confirmed = resign({...openingCommand(), opening: input.opening, expectedPurchaseRevision: 3,
      expectedPurchaseFingerprint: ledgerHash(saved.currentBook)});
    assert.equal((await ledger.confirmOpening(f.user, confirmed)).receipt?.reason, 'opening_amount_unknown');
    assert.equal((await f.root.collection('supplierLedger').get()).size, 0);
    if (process.env.AGG04_NATIVE_CAPTURE_PATH) {
      const service = new WorkspacePurchaseEntryService(original.repository, now);
      const {scope: _scope, ...body} = command;
      const response = await service.handle(f.user, 'saveStoreSupplierOpeningEvidence', {schemaVersion: 1, purchaseEntryVersion: 1,
        actorAccountId: scope.account, realm: scope.realm, storeId: scope.store, ...body});
      writeFileSync(process.env.AGG04_NATIVE_CAPTURE_PATH + '.opening.json', JSON.stringify({label: 'ISOLATED ACTUAL SDK UNPOSTED OPENING RESPONSE',
        scope, now: now().toISOString(), command, response}), 'utf8');
    }
  } finally {await f.close();}
});
test('AGG04 SDK evidence correction uses a new revision and confirmation consumes only the latest exact original', {skip: !ledgerEmulator}, async () => {
  const f = await sdkLedger();
  try {
    const book = originalOpeningBook(), original = await seedOriginalPurchase(f, book);
    const input = {scope, profile: book.profiles[0]!, expectedRevision: 2, idempotencyKey: 'HOST-correct-evidence',
      opening: {...opening(), id: 'HOST-corrected-evidence', revision: 3, amountMinor: 23456, supplierCredit: true}};
    const saved = await original.repository.saveOpeningEvidence(f.user, {...input, fingerprint: purchaseEntryOpeningCommandFingerprint(input)});
    assert.equal(saved.currentBook?.openingRecords?.length, 2);
    assert.deepEqual(saved.currentBook?.openingRecords?.[0], book.openingRecords![0]);
    const ledger = new FirestoreWorkspaceLedgerRepository(f.db, 'evaluation', f.user.projectId, f.authority, original.repository.ledgerAnchor(), now);
    const old = resign({...openingCommand(), expectedPurchaseRevision: 3, expectedPurchaseFingerprint: ledgerHash(saved.currentBook)});
    assert.equal((await ledger.confirmOpening(f.user, old)).receipt?.reason, 'stale_evidence');
    const correct = resign({...old, idempotencyKey: 'HOST-confirm-corrected-evidence', opening: input.opening});
    const result = await ledger.confirmOpening(f.user, correct);
    assert.equal(result.receipt?.status, 'saved'); assert.equal(JSON.parse(result.current!.json).openingBalanceMinor, -23456);
    assert.deepEqual(await original.repository.read(f.user, scope), saved.currentBook);
    const stale = {...input, idempotencyKey: 'HOST-stale-evidence', opening: {...input.opening, id: 'HOST-stale-new'}};
    assert.equal((await original.repository.saveOpeningEvidence(f.user, {...stale,
      fingerprint: purchaseEntryOpeningCommandFingerprint(stale)})).receipt?.reason, 'stale_book');
    const wrongRevision = {...stale, idempotencyKey: 'HOST-wrong-evidence-revision', expectedRevision: 3};
    assert.equal((await original.repository.saveOpeningEvidence(f.user, {...wrongRevision,
      fingerprint: purchaseEntryOpeningCommandFingerprint(wrongRevision)})).receipt?.reason, 'stale_opening');
  } finally {await f.close();}
});
test('AGG04 SDK confirms through the actual purchase original and transaction-bound read-only anchor', {skip: !ledgerEmulator}, async () => {
  const f = await sdkLedger();
  try {
    const book = originalOpeningBook(), original = await seedOriginalPurchase(f, book);
    const repository = new FirestoreWorkspaceLedgerRepository(f.db, 'evaluation', f.user.projectId,
      f.authority, original.repository.ledgerAnchor(), now);
    const command = resign({...openingCommand(), expectedPurchaseFingerprint: ledgerHash(book)});
    const result = await repository.confirmOpening(f.user, command);
    assert.equal(result.receipt?.status, 'saved');
    assert.deepEqual(await original.repository.read(f.user, scope), book);
    assert.equal((await f.root.collection('supplierLedger').get()).size, 1);
    assert.equal((await f.root.collection('expense').get()).size, 0);
    assert.equal((await f.root.collection('moneyRegister').get()).size, 0);
  } finally {await f.close();}
});
test('AGG04 SDK malformed original bill copies never qualify supplier opening confirmation', {skip: !ledgerEmulator}, async () => {
  const f = await sdkLedger();
  try {
    const book = {...originalOpeningBook(), copies: [{id: 'HOST-malformed-original-copy', revision: 1,
      supplier: {id: opening().supplierId}, draft: {id: 'HOST-incomplete-draft'}}]}, original = await seedOriginalPurchase(f, book);
    const repository = new FirestoreWorkspaceLedgerRepository(f.db, 'evaluation', f.user.projectId, f.authority, original.repository.ledgerAnchor(), now);
    const command = resign({...openingCommand(), expectedPurchaseFingerprint: ledgerHash(book)});
    await assert.rejects(repository.confirmOpening(f.user, command), code('service_unavailable'));
    assert.equal((await f.root.get()).exists, false); assert.equal((await f.root.collection('attempts').get()).size, 0);
    assert.deepEqual(await original.repository.read(f.user, scope), book);
  } finally {await f.close();}
});
test('AGG04 SDK changed original purchase anchor atomically refuses opening and never changes that original', {skip: !ledgerEmulator}, async () => {
  const f = await sdkLedger();
  try {
    const book = originalOpeningBook(), original = await seedOriginalPurchase(f, book), anchor = original.repository.ledgerAnchor();
    const race: LedgerPurchaseAnchor = {capture: async (user, requested) => {
      const captured = await anchor.capture(user, requested), profile = {...book.profiles[0]!, name: 'HOST changed supplier original'};
      const input = {scope, profile, expectedRevision: 2, idempotencyKey: 'HOST-concurrent-original-save'};
      await original.repository.saveSupplier(f.user, {...input, fingerprint: purchaseEntryCommandFingerprint(input)});
      return captured;
    }, assertCurrent: anchor.assertCurrent};
    const repository = new FirestoreWorkspaceLedgerRepository(f.db, 'evaluation', f.user.projectId, f.authority, race, now);
    const command = resign({...openingCommand(), expectedPurchaseFingerprint: ledgerHash(book)});
    const result = await repository.confirmOpening(f.user, command);
    assert.equal(result.receipt?.status, 'not_saved'); assert.equal(result.receipt?.reason, 'stale_evidence');
    assert.equal(result.current, null); assert.equal(result.revision, null);
    assert.equal((await original.repository.read(f.user, scope))?.revision, 3);
    assert.deepEqual(await repository.status(f.user, scope, command.idempotencyKey, command.fingerprint), result);
    assert.equal((await f.root.collection('supplierLedger').get()).size, 0);
  } finally {await f.close();}
});
test('AGG04 SDK exact expense duplicate, restart and status do not create financial snapshots', {skip: !ledgerEmulator}, async () => {
  const f = await sdkLedger();
  try {
    const command = expenseCommand();
    const [one, two] = await Promise.all([f.repo().recordExpense(f.user, command), f.repo().recordExpense(f.user, command)]);
    assert.deepEqual(one, two); assert.equal(one.receipt?.status, 'saved'); assert.equal(one.revision, 1);
    assert.deepEqual(await f.repo().status(f.user, scope, command.idempotencyKey, command.fingerprint), one);
    const list = await f.repo().list(f.user, scope, 'expense', null, null);
    assert.equal(list.totalCount, 1); assert.equal(list.rows.length, 1); assert.equal(list.nextCursor, null);
    assert.deepEqual(JSON.parse(list.rows[0]!.json), command.expense);
    if (process.env.AGG04_NATIVE_CAPTURE_PATH) {
      const service = new WorkspaceLedgerService(f.repo(), now);
      const page = await service.handle(f.user, 'readStoreLedgerSource', {schemaVersion: 1, ledgerVersion: 1,
        operation: 'readStoreLedgerSource', scope, kind: 'expense', parentId: null, cursor: null});
      const status = await service.handle(f.user, 'readStoreLedgerAttempt', {schemaVersion: 1, ledgerVersion: 1,
        operation: 'readStoreLedgerAttempt', scope, idempotencyKey: command.idempotencyKey, fingerprint: command.fingerprint});
      writeFileSync(process.env.AGG04_NATIVE_CAPTURE_PATH, JSON.stringify({label: 'ISOLATED ACTUAL SDK/HANDLER CAPTURE; NOT PHONE DATA',
        scope, now: now().toISOString(), command, page, status}), 'utf8');
    }
    assert.deepEqual(Object.keys((await f.root.get()).data()!).sort(), ['counts', 'projectId', 'revision', 'schemaVersion', 'scope', 'updatedAt']);
    assert.equal((await f.repo().list(f.user, scope, 'supplierLedger', null, null)).totalCount, 0);
    await assert.rejects(f.repo().recordExpense(f.user, resign({...command, expense: {...command.expense, amountMinor: 1}})), code('idempotency_conflict'));
  } finally {await f.close();}
});
test('AGG04 SDK immutable operation identity conflicts and stale CAS produce durable refusals', {skip: !ledgerEmulator}, async () => {
  const f = await sdkLedger();
  try {
    const first = expenseCommand(); await f.repo().recordExpense(f.user, first);
    const same = resign({...first, idempotencyKey: 'HOST-expense-noop', expectedRevision: null});
    const noop = await f.repo().recordExpense(f.user, same); assert.equal(noop.receipt?.changed, false); assert.equal(noop.receipt?.status, 'saved');
    const conflict = resign({...same, idempotencyKey: 'HOST-expense-conflict', expense: {...first.expense, note: 'HOST conflicting record'}});
    assert.equal((await f.repo().recordExpense(f.user, conflict)).receipt?.reason, 'record_identity_conflict');
    const stale = resign({...first, idempotencyKey: 'HOST-stale', expense: {...first.expense, operationId: 'HOST-expense-2'}});
    assert.equal((await f.repo().recordExpense(f.user, stale)).receipt?.reason, 'stale_ledger');
    assert.deepEqual(await f.repo().recordExpense(f.user, stale), await f.repo().status(f.user, scope, stale.idempotencyKey, stale.fingerprint));
    assert.equal((await f.repo().list(f.user, scope, 'expense', null, null)).totalCount, 1);
  } finally {await f.close();}
});
test('AGG04 SDK current-source pagination survives repository restart and rejects stale/foreign cursors', {skip: !ledgerEmulator}, async () => {
  const f = await sdkLedger();
  try {
    for (let i = 0; i < 13; i++) {
      const input = expenseCommand(), command = resign({...input, idempotencyKey: 'HOST-page-' + i,
        expectedRevision: i === 0 ? null : i, expense: {...input.expense, operationId: 'HOST-expense-' + i}});
      assert.equal((await f.repo().recordExpense(f.user, command)).receipt?.status, 'saved');
    }
    const ids = new Set<string>(); let cursor: string | null = null, pages = 0;
    do {
      const page: LedgerPage = await f.repo().list(f.user, scope, 'expense', null, cursor);
      assert.equal(page.totalCount, 13); assert.equal(page.startsSource, cursor === null);
      for (const row of page.rows) {assert.equal(ids.has(row.id), false); ids.add(row.id);}
      cursor = page.nextCursor; pages++;
    } while (cursor);
    assert.equal(ids.size, 13); assert.equal(pages, 3);
    const first = await f.repo().list(f.user, scope, 'expense', null, null);
    await assert.rejects(f.repo().list(f.user, scope, 'supplierLedger', null, first.nextCursor), code('invalid_input'));
    const extra = expenseCommand();
    await f.repo().recordExpense(f.user, resign({...extra, idempotencyKey: 'HOST-page-extra', expectedRevision: 13,
      expense: {...extra.expense, operationId: 'HOST-extra'}}));
    await assert.rejects(f.repo().list(f.user, scope, 'expense', null, first.nextCursor), code('stale_ledger'));
  } finally {await f.close();}
});
test('AGG04 SDK revoked/foreign/unconfigured authority cannot read records or historical receipts', {skip: !ledgerEmulator}, async () => {
  const f = await sdkLedger();
  try {
    const command = expenseCommand(); await f.repo().recordExpense(f.user, command);
    await assert.rejects(f.repo().list({...f.user, uid: 'HOST-other'}, scope, 'expense', null, null), code('permission_denied'));
    await assert.rejects(new FirestoreWorkspaceLedgerRepository(f.db, 'evaluation', f.user.projectId)
      .list(f.user, scope, 'expense', null, null), code('service_unavailable'));
    await f.grant.update({active: false});
    await assert.rejects(f.repo().status(f.user, scope, command.idempotencyKey, command.fingerprint), code('permission_denied'));
    await assert.rejects(f.repo().recordExpense(f.user, command), code('permission_denied'));
    await assert.rejects(f.repo().list(f.user, scope, 'expense', null, null), code('permission_denied'));
  } finally {await f.close();}
});
test('AGG04 SDK erased head/record and damaged immutable payload never become empty or fresh writes', {skip: !ledgerEmulator}, async () => {
  const f = await sdkLedger();
  try {
    const command = expenseCommand(); await f.repo().recordExpense(f.user, command);
    const record = f.root.collection('expense').doc(ledgerHash({id: command.expense.operationId})), original = (await record.get()).data()!;
    const head = (await f.root.get()).data()!;
    await f.root.delete();
    await assert.rejects(f.repo().list(f.user, scope, 'expense', null, null), code('service_unavailable'));
    await f.root.set(head); await record.delete();
    await assert.rejects(f.repo().recordExpense(f.user, resign({...command, idempotencyKey: 'HOST-cannot-recreate'})), code('service_unavailable'));
    await record.set(original);
    await f.root.collection('payloads').doc(original.payload.id).collection('parts').doc('0000000000').update({data: 'ZGFtYWdlZA=='});
    await assert.rejects(f.repo().status(f.user, scope, command.idempotencyKey, command.fingerprint), code('service_unavailable'));
    await assert.rejects(f.repo().list(f.user, scope, 'expense', null, null), code('service_unavailable'));
  } finally {await f.close();}
});
test('AGG04 SDK lost transaction acknowledgement resolves only the original committed receipt', {skip: !ledgerEmulator}, async () => {
  const f = await sdkLedger();
  try {
    const original = f.db.runTransaction.bind(f.db); let lost = false;
    f.db.runTransaction = (async (...args: Parameters<typeof f.db.runTransaction>) => {
      const result = await original(...args);
      if (!lost && (await f.root.get()).exists) {lost = true; throw new Error('HOST lost committed acknowledgement');}
      return result;
    }) as typeof f.db.runTransaction;
    const command = expenseCommand(), saved = await f.repo().recordExpense(f.user, command);
    assert.equal(lost, true); assert.equal(saved.receipt?.status, 'saved'); assert.equal(saved.revision, 1);
    f.db.runTransaction = original;
    assert.deepEqual(await f.repo().status(f.user, scope, command.idempotencyKey, command.fingerprint), saved);
    assert.equal((await f.root.collection('expense').get()).size, 1);
  } finally {await f.close();}
});
test('AGG04 SDK register appends preserve unknown balance, prefix, opening and exact entry identity', {skip: !ledgerEmulator}, async () => {
  const f = await sdkLedger();
  try {
    await seedSdkRegister(f);
    const command = registerCommand(), saved = await f.repo().recordRegisterEntry(f.user, command);
    assert.equal(saved.receipt?.status, 'saved'); assert.equal(saved.revision, 2);
    const current = JSON.parse(saved.current!.json);
    assert.equal(current.openingMinor, null); assert.equal(current.historyComplete, false); assert.equal(current.entryCount, 1);
    assert.equal(current.openingAt, header().openingAt); assert.equal(current.label, header().label);
    const entries = await f.repo().list(f.user, scope, 'moneyEntry', command.registerId, null);
    assert.equal(entries.totalCount, 1); assert.deepEqual(JSON.parse(entries.rows[0]!.json), command.entry);
    assert.equal((await f.repo().recordRegisterEntry(f.user, resign({...command, idempotencyKey: 'HOST-entry-noop'}))).receipt?.changed, false);
    const conflict = resign({...command, idempotencyKey: 'HOST-entry-conflict', entry: {...command.entry, deltaMinor: 1}});
    assert.equal((await f.repo().recordRegisterEntry(f.user, conflict)).receipt?.reason, 'record_identity_conflict');
    const earlier = resign({...command, idempotencyKey: 'HOST-entry-earlier', expectedRevision: 2, expectedRegisterRevision: 2,
      capturedAt: '2026-10-29T03:00:00.000Z', entry: {...command.entry, id: 'HOST-entry-2', occurredAt: at}});
    assert.equal((await f.repo().recordRegisterEntry(f.user, earlier)).receipt?.reason, 'register_history_changed');
    assert.equal((await f.repo().list(f.user, scope, 'expense', null, null)).totalCount, 0);
  } finally {await f.close();}
});
test('AGG04 SDK missing register source refuses instead of creating a register or zero balance', {skip: !ledgerEmulator}, async () => {
  const f = await sdkLedger();
  try {
    const result = await f.repo().recordRegisterEntry(f.user, resign({...registerCommand(), expectedRevision: null}));
    assert.equal(result.receipt?.reason, 'register_unavailable'); assert.equal(result.current, null); assert.equal(result.revision, null);
    assert.equal((await f.repo().list(f.user, scope, 'moneyRegister', null, null)).totalCount, 0);
  } finally {await f.close();}
});
test('AGG04 SDK complete-register interval and safe-integer limits cannot be weakened by an append', {skip: !ledgerEmulator}, async () => {
  const f = await sdkLedger();
  try {
    await seedSdkRegister(f, {...header(), openingMinor: Number.MAX_SAFE_INTEGER, historyComplete: true,
      sequenceValidationMinor: Number.MAX_SAFE_INTEGER});
    const first = registerCommand();
    const earlier = resign({...first, idempotencyKey: 'HOST-complete-interval', entry: {...first.entry, occurredAt: '2026-10-29T00:30:00.000Z'}});
    assert.equal((await f.repo().recordRegisterEntry(f.user, earlier)).receipt?.reason, 'register_history_changed');
    const overflow = resign({...first, idempotencyKey: 'HOST-register-overflow', entry: {...first.entry, deltaMinor: 1}});
    assert.equal((await f.repo().recordRegisterEntry(f.user, overflow)).receipt?.reason, 'register_history_changed');
    const valid = await f.repo().recordRegisterEntry(f.user, first);
    assert.equal(valid.receipt?.status, 'saved');
    const value = JSON.parse(valid.current!.json); assert.equal(value.openingMinor, Number.MAX_SAFE_INTEGER);
    assert.equal(value.sequenceValidationMinor, Number.MAX_SAFE_INTEGER - 505); assert.equal(value.historyComplete, true);
  } finally {await f.close();}
});
test('AGG04 SDK mutable input is frozen and revocation before publication prevents a ledger write', {skip: !ledgerEmulator}, async () => {
  const f = await sdkLedger();
  try {
    const command = expenseCommand(), expected = ledgerClone(command.expense), pending = f.repo().recordExpense(f.user, command);
    command.expense.note = 'HOST caller mutation after dispatch';
    const saved = await pending; assert.deepEqual(JSON.parse(saved.current!.json), expected);
    let calls = 0;
    f.setBarrier(async () => {calls++; if (calls === 4) await f.grant.update({active: false});});
    const second = resign({...expenseCommand(), expectedRevision: 1, idempotencyKey: 'HOST-revoked-publication',
      expense: {...expense(), operationId: 'HOST-cannot-publish'}});
    await assert.rejects(f.repo().recordExpense(f.user, second), code('permission_denied'));
    assert.equal((await f.root.collection('expense').get()).size, 1);
    assert.equal((await f.root.get()).get('revision'), 1);
    assert.equal((await f.root.collection('attempts').get()).size, 1);
  } finally {await f.close();}
});
test('AGG04 SDK competing expense commands publish one CAS winner without losing unrelated records', {skip: !ledgerEmulator}, async () => {
  const f = await sdkLedger();
  try {
    const commands = [expenseCommand(), resign({...expenseCommand(), idempotencyKey: 'HOST-other-CAS',
      expense: {...expense(), operationId: 'HOST-other-expense'}})];
    const results = await Promise.all(commands.map(command => f.repo().recordExpense(f.user, command)));
    assert.equal(results.filter(value => value.receipt?.status === 'saved').length, 1);
    assert.equal(results.filter(value => value.receipt?.reason === 'stale_ledger').length, 1);
    assert.equal((await f.root.collection('expense').get()).size, 1);
    assert.equal((await f.root.collection('supplierLedger').get()).size, 0);
    assert.equal((await f.root.collection('moneyRegister').get()).size, 0);
    assert.equal((await f.root.collection('attempts').get()).size, 2);
  } finally {await f.close();}
});
for (const scenario of ['closed read', 'other invalid query', 'string code'] as const)
  test('AGG05 SDK missing-head read abort classification remains exact: ' + scenario, {skip: !ledgerEmulator}, async () => {
    const f = await sdkLedger();
    try {
      const run = f.db.runTransaction.bind(f.db);
      let injected = false, transactions = 0, failedAt = 0;
      f.db.runTransaction = (async (operation: (tx: Transaction) => Promise<unknown>) => run(async tx => {
        transactions++;
        const tracked = Object.create(tx) as Transaction;
        tracked.get = (async (ref: object) => {
          if (!injected && 'where' in ref) {
            injected = true; failedAt = transactions;
            throw Object.assign(new Error('HOST failed read only'), {code: scenario === 'string code' ? '3' : 3,
              details: scenario === 'other invalid query' ? 'Other invalid query.' : 'Transaction is invalid or closed.'});
          }
          return Reflect.apply(tx.get, tx, [ref]);
        }) as Transaction['get'];
        return operation(tracked);
      })) as typeof f.db.runTransaction;
      if (scenario === 'closed read') {
        const result = await f.repo().recordExpense(f.user, expenseCommand());
        assert.equal(result.receipt?.status, 'saved'); assert(transactions >= 2);
        assert.equal((await f.root.collection('expense').get()).size, 1);
        assert.equal((await f.root.collection('attempts').get()).size, 1);
      } else {
        await assert.rejects(f.repo().recordExpense(f.user, expenseCommand()),
          error => (error as {code?: unknown}).code === (scenario === 'string code' ? '3' : 3));
        assert.equal(transactions, failedAt, 'Unrelated invalid queries must not start another transaction callback.');
        assert.equal((await f.root.collection('expense').get()).size, 0);
        assert.equal((await f.root.collection('attempts').get()).size, 0);
      }
      assert(injected); assert.equal((await f.root.collection('supplierLedger').get()).size, 0);
    } finally {await f.close();}
  });
test('AGG05 SDK original missing-head query guards stay serial inside the real transaction', {skip: !ledgerEmulator}, async () => {
  const f = await sdkLedger();
  try {
    const run = f.db.runTransaction.bind(f.db);
    let active = 0, queryReads = 0, maximum = 0;
    f.db.runTransaction = (async (operation: (tx: Transaction) => Promise<unknown>) => run(async tx => {
      const tracked = Object.create(tx) as Transaction;
      tracked.get = (async (ref: object) => {
        if (!('where' in ref)) return Reflect.apply(tx.get, tx, [ref]);
        queryReads++; active++; maximum = Math.max(maximum, active);
        assert.equal(active, 1, 'One original transaction must not overlap its missing-head query guards.');
        try {
          await new Promise(resolve => setTimeout(resolve, 1));
          return await Reflect.apply(tx.get, tx, [ref]);
        } finally {active--;}
      }) as Transaction['get'];
      return operation(tracked);
    })) as typeof f.db.runTransaction;
    const saved = await f.repo().recordExpense(f.user, expenseCommand());
    assert.equal(saved.receipt?.status, 'saved'); assert.equal(queryReads >= 2, true); assert.equal(maximum, 1);
    assert.equal((await f.root.collection('expense').get()).size, 1);
    assert.equal((await f.root.collection('attempts').get()).size, 1);
  } finally {await f.close();}
});
test('AGG04 SDK multipart supplier opening keeps original evidence above a document size without a ledger book cap', {skip: !ledgerEmulator}, async () => {
  const f = await sdkLedger();
  try {
    const record = opening();
    record.bills = Array.from({length: 1000}, (_, i) => ({copyId: `HOST-${i}-` + 'મૂળ'.repeat(72),
      copyRevision: 1, draftId: `HOST-draft-${i}-` + 'મૂળ'.repeat(72), inclusion: 'included' as const}));
    const book = originalOpeningBook(record);
    book.copies = record.bills.map((link, index) => ({id: link.copyId, revision: link.copyRevision, storeName: 'HOST owned Store', savedAt: at,
      supplier: book.profiles[0], draft: {id: link.draftId, supplierId: record.supplierId, invoiceReference: `HOST-LARGE-${index}`,
        invoiceDate: '29/10/2026', createdAt: at, updatedAt: at, source: 'manual', stage: 'draft',
        goods: [{productId: '', name: 'HOST printed item', pack: 'HOST unit', quantity: '1', cost: ''}]}, labels: {name: 'HOST printed item'}}));
    assert.ok(Buffer.byteLength(ledgerCanonical(record)) > 1024 * 1024);
    const original = await seedOriginalPurchase(f, book);
    const repository = new FirestoreWorkspaceLedgerRepository(f.db, 'evaluation', f.user.projectId,
      f.authority, original.repository.ledgerAnchor(), now);
    const command = resign({...openingCommand(), opening: record, expectedPurchaseFingerprint: ledgerHash(book)});
    const saved = await repository.confirmOpening(f.user, command);
    assert.equal(saved.receipt?.status, 'saved'); assert.deepEqual(JSON.parse(saved.current!.json).openingRecord, record);
    const page = await repository.list(f.user, scope, 'supplierLedger', null, null);
    assert.equal(page.totalCount, 1); assert.equal(page.rows.length, 1);
    assert.deepEqual(JSON.parse(page.rows[0]!.json).openingRecord, record);
    assert.deepEqual(await original.repository.read(f.user, scope), book);
    const input = {scope, profile: book.profiles[0]!, expectedRevision: book.revision, idempotencyKey: 'HOST-large-original-evidence', opening: record};
    const commandData = {...input, fingerprint: purchaseEntryOpeningCommandFingerprint(input)}, {scope: _scope, ...fields} = commandData;
    const body = {schemaVersion: 1, purchaseEntryVersion: 1, actorAccountId: scope.account, realm: scope.realm, storeId: scope.store, ...fields};
    const wireBytes = Buffer.byteLength(JSON.stringify({operation: 'saveStoreSupplierOpeningEvidence', ...body}));
    assert.ok(wireBytes > 64 * 1024); assert.ok(wireBytes <= workspaceOriginalRequestBodyLimit('saveStoreSupplierOpeningEvidence'));
    const response = await new WorkspacePurchaseEntryService(original.repository, now).handle(f.user, 'saveStoreSupplierOpeningEvidence', body);
    assert.equal((response as {attempt: {changed: boolean}}).attempt.changed, false);
    if (process.env.AGG04_NATIVE_CAPTURE_PATH) writeFileSync(process.env.AGG04_NATIVE_CAPTURE_PATH + '.large.json',
      JSON.stringify({label: 'ISOLATED ACTUAL SDK LARGE ORIGINAL AND LEDGER READBACK', scope, now: now().toISOString(), command: commandData,
        response, row: page.rows[0]}), 'utf8');
  } finally {await f.close();}
});
test('AGG04 SDK exact opening confirmation binds original evidence and leaves purchase data unchanged', {skip: !ledgerEmulator}, async () => {
  const f = await sdkLedger();
  try {
    const command = openingCommand(), profile = {id: command.opening.supplierId, name: 'HOST original supplier', phone: '', address: '',
      gstin: '', source: 'manual' as const, createdAt: at, updatedAt: at};
    const book: PurchaseEntryBook = {version: 1, account: scope.account, store: scope.store, qa: false,
      revision: 2, profiles: [profile], draft: null, openingRecords: [command.opening]};
    await f.purchaseRef.set(book);
    const frozen = resign({...command, expectedPurchaseFingerprint: ledgerHash(book)});
    const result = await f.repo().confirmOpening(f.user, frozen);
    assert.equal(result.receipt?.status, 'saved'); assert.equal(result.revision, 1);
    const row = JSON.parse(result.current!.json); assert.deepEqual(row.openingRecord, command.opening);
    assert.equal(row.openingBalanceMinor, 0); assert.equal(row.historyComplete, true);
    assert.deepEqual((await f.purchaseRef.get()).data(), book);
    assert.equal((await f.repo().confirmOpening(f.user, resign({...frozen, idempotencyKey: 'HOST-opening-noop'}))).receipt?.changed, false);
    const correction = resign({...frozen, idempotencyKey: 'HOST-opening-cannot-replace', expectedRevision: 1,
      opening: {...command.opening, id: 'HOST-corrected-evidence'}});
    assert.equal((await f.repo().confirmOpening(f.user, correction)).receipt?.reason, 'supplier_has_records');
  } finally {await f.close();}
});

// Labelled isolated handler/validation fixtures. These do not qualify storage,
// original runtime membership, bank verification or a populated phone journey.
const scope: LedgerScope = {account: 'HOST-ledger-account', store: 'HOST-ledger-store', realm: 'evaluation'};
const actor: LedgerActor = {uid: scope.account, projectId: 'demo-agg04-host'};
const at = '2026-10-29T01:00:00.123456Z', confirmedAt = '2026-10-29T02:00:00.000Z';
const now = () => new Date(confirmedAt);
const expense = (): LedgerExpense => ({account: scope.account, store: scope.store, operationId: 'HOST-expense-1',
  amountMinor: 12505, category: 'HOST delivery expense', method: 'HOST manually recorded',
  reference: 'HOST મૂળ ખર્ચ', note: 'HOST original note; no provider confirmation', occurredAt: at});
const opening = (): LedgerOpeningRecord => ({id: 'HOST-opening-1', basisId: 'HOST-opening-basis',
  account: scope.account, store: scope.store, qa: false, supplierId: 'HOST-supplier-1', revision: 2,
  asOfDate: '2026-10-29', savedAt: at, currency: 'INR', amountMinor: 0, supplierCredit: false,
  sourceNote: 'HOST explicitly reviewed starting balance', bills: []});
const header = (): LedgerRegisterHeader => ({accountScope: scope.account, workspaceId: scope.store,
  registerId: 'HOST-register-1', label: 'HOST original manual register', revision: 1,
  openingAt: '2026-10-29T00:00:00.000Z', asOf: at, openingMinor: null, historyComplete: false,
  entryCount: 0, lastEntryAt: null, sequenceValidationMinor: 0});
function expenseCommand(): LedgerExpenseCommand {
  const input = {scope, operation: 'recordStoreExpense' as const, expectedRevision: null,
    idempotencyKey: 'HOST-expense-attempt', expense: expense()};
  return {...input, fingerprint: ledgerCommandFingerprint(input)};
}
function openingCommand(): LedgerOpeningCommand {
  const input = {scope, operation: 'confirmStoreSupplierOpening' as const, expectedRevision: null,
    idempotencyKey: 'HOST-opening-attempt', opening: opening(), expectedPurchaseRevision: 2,
    expectedPurchaseFingerprint: 'a'.repeat(64), confirmedAt, confirmedUtcOffsetMinutes: 330};
  return {...input, fingerprint: ledgerCommandFingerprint(input)};
}
function registerCommand(): LedgerRegisterCommand {
  const input = {scope, operation: 'recordStoreMoneyRegisterEntry' as const, expectedRevision: 1,
    idempotencyKey: 'HOST-register-attempt', registerId: header().registerId, expectedRegisterRevision: 1,
    entry: {id: 'HOST-entry-1', reference: 'HOST manually recorded money out', occurredAt: '2026-10-29T01:10:00.000Z', deltaMinor: -505},
    capturedAt: confirmedAt};
  return {...input, fingerprint: ledgerCommandFingerprint(input)};
}
function body(command: LedgerCommand): Record<string, unknown> {return {schemaVersion: 1, ledgerVersion: 1, ...ledgerClone(command)};}
function row(kind: LedgerRow['kind'], id: string, value: unknown, revision = 1): LedgerRow {
  return {kind, id, parentId: null, revision, json: ledgerCanonical(value), fingerprint: ledgerHash(value), ordinal: null};
}
function saved(command: LedgerCommand): LedgerStatus {
  if (command.operation === 'recordStoreSupplierMoney' || command.operation === 'confirmStoreSupplierBill' || command.operation === 'recordStoreSupplierMoneyAllocation' || command.operation === 'recordStoreSupplierRefund' || command.operation === 'recordStoreSupplierCreditNote') {
    throw new Error('Supplier financial qualification must use the original SDK receiver.');
  }
  const target = ledgerCommandTarget(command);
  const value = command.operation === 'recordStoreExpense' ? command.expense : command.operation === 'confirmStoreSupplierOpening'
    ? ledgerConfirmedOpening(command, 'HOST original supplier')
    : {...header(), revision: 2, asOf: command.capturedAt, entryCount: 1, lastEntryAt: command.entry.occurredAt,
      sequenceValidationMinor: command.entry.deltaMinor};
  const receipt: LedgerReceipt = {schemaVersion: 1, scope, operation: command.operation, idempotencyKey: command.idempotencyKey,
    fingerprint: command.fingerprint, inputFingerprint: ledgerHash(ledgerCommandInput(command)), status: 'saved', reason: null,
    changed: true, resultRevision: 2, targetKind: target.kind, targetId: target.id, entryId: target.entryId, recordedAt: confirmedAt};
  return {revision: 2, receipt, current: row(target.kind, target.id, value, command.operation === 'recordStoreMoneyRegisterEntry' ? 2 : 1)};
}
const code = (value: string) => (error: unknown) => error instanceof WorkspaceProfileError && error.code === value;
class HostHandlerSource implements LedgerRepository {
  readonly realm = 'evaluation' as const; readonly projectId = actor.projectId; configured = true;
  calls = 0; commands: LedgerCommand[] = []; gate: Promise<void> | null = null;
  statusResult: LedgerStatus = {revision: null, receipt: null, current: null};
  page: LedgerPage = {revision: null, kind: 'expense', parentId: null, totalCount: 0, startsSource: true, rows: [], nextCursor: null};
  async list(): Promise<LedgerPage> {this.calls++; return ledgerClone(this.page);}
  async status(): Promise<LedgerStatus> {this.calls++; return ledgerClone(this.statusResult);}
  async recordExpense(_actor: LedgerActor, command: LedgerExpenseCommand): Promise<LedgerStatus> {
    this.calls++; this.commands.push(ledgerClone(command)); const result = saved(command); if (this.gate) await this.gate; return result;
  }
  async confirmOpening(_actor: LedgerActor, command: LedgerOpeningCommand): Promise<LedgerStatus> {
    this.calls++; this.commands.push(ledgerClone(command)); return saved(command);
  }
  async recordRegisterEntry(_actor: LedgerActor, command: LedgerRegisterCommand): Promise<LedgerStatus> {
    this.calls++; this.commands.push(ledgerClone(command)); return saved(command);
  }
}
const read = () => ({operation: 'readStoreLedgerSource', schemaVersion: 1, ledgerVersion: 1, scope,
  kind: 'expense', parentId: null, cursor: null});

test('AGG04 original expense keeps native safe-integer limits and exact printed Unicode fields', () => {
  const input = {...expense(), amountMinor: Number.MAX_SAFE_INTEGER};
  assert.deepEqual(checkedLedgerExpense(input, scope), input);
  for (const amountMinor of [0, -1, 1.5, Number.MAX_SAFE_INTEGER + 1, NaN, Infinity]) {
    assert.throws(() => checkedLedgerExpense({...input, amountMinor}, scope), code('invalid_input'));
  }
  for (const bad of [{store: 'HOST-other'}, {account: 'HOST-other'}, {note: '\ud800'}, {reference: 'HOST\u0000bad'}, {note: 'x'.repeat(2001)}]) {
    assert.throws(() => checkedLedgerExpense({...input, ...bad}, scope), code('invalid_input'));
  }
});
test('AGG04 opening evidence preserves unknown versus zero and rejects duplicated supporting-copy identity', () => {
  assert.equal(checkedLedgerOpening({...opening(), amountMinor: null}, scope).amountMinor, null);
  assert.equal(checkedLedgerOpening(opening(), scope).amountMinor, 0);
  const link = {copyId: 'HOST-copy', copyRevision: 1, draftId: 'HOST-draft', inclusion: 'unknown'};
  assert.equal(checkedLedgerOpening({...opening(), bills: [link]}, scope).bills[0]!.inclusion, 'unknown');
  assert.throws(() => checkedLedgerOpening({...opening(), bills: [link, link]}, scope), code('invalid_input'));
  for (const bad of [{qa: true}, {amountMinor: -1}, {amountMinor: 1000000000000}, {currency: 'USD'},
    {asOfDate: '2026-02-30'}, {savedAt: '2026-10-29T01:00:00'}, {sourceNote: ' '}]) {
    assert.throws(() => checkedLedgerOpening({...opening(), ...bad}, scope), code('invalid_input'));
  }
});
test('AGG04 explicit opening confirmation follows native credit and calendar rules without creating tax or Stock facts', () => {
  const command = openingCommand(), expected = ledgerConfirmedOpening(command, 'HOST supplier');
  assert.equal(expected.openingBalanceMinor, 0); assert.equal(expected.historyComplete, true);
  assert.equal(Object.is(expected.openingBalanceMinor, -0), false);
  const credit = ledgerConfirmedOpening({...command, opening: {...command.opening, amountMinor: 12345, supplierCredit: true}}, 'HOST supplier');
  assert.equal(credit.openingBalanceMinor, -12345); assert.deepEqual(credit.entries, []);
  assert.equal('inventory' in credit, false); assert.equal('finance' in credit, false);
  assert.throws(() => ledgerConfirmedOpening({...command, opening: {...command.opening, amountMinor: null}}, 'HOST supplier'), code('opening_amount_unknown'));
  assert.throws(() => ledgerConfirmedOpening({...command, opening: {...command.opening, asOfDate: '2026-10-30'}}, 'HOST supplier'), code('opening_confirmation_invalid'));
  assert.throws(() => ledgerConfirmedOpening({...command, confirmedAt: '2026-10-29T00:59:59.999999Z'}, 'HOST supplier'), code('opening_confirmation_invalid'));
  const localDay = ledgerConfirmedOpening({...command, confirmedAt: '2026-10-29T23:59:59.999999Z',
    confirmedUtcOffsetMinutes: 330, opening: {...command.opening, asOfDate: '2026-10-30'}}, 'HOST supplier');
  assert.equal((localDay.openingRecord as LedgerOpeningRecord).asOfDate, '2026-10-30');
});
test('AGG04 unknown register opening remains unknown; an internal validation accumulator is not a displayed balance', () => {
  const partial = checkedLedgerRegisterHeader(header(), scope);
  assert.equal(partial.openingMinor, null); assert.equal(partial.historyComplete, false);
  assert.throws(() => checkedLedgerRegisterHeader({...partial, historyComplete: true}, scope), code('invalid_input'));
  assert.throws(() => checkedLedgerRegisterHeader({...partial, sequenceValidationMinor: 1}, scope), code('invalid_input'));
  assert.throws(() => checkedLedgerRegisterHeader({...partial, openingAt: confirmedAt}, scope), code('invalid_input'));
  assert.throws(() => checkedLedgerRegisterEntry({...registerCommand().entry, deltaMinor: 0}), code('invalid_input'));
  assert.equal(checkedLedgerRegisterEntry(registerCommand().entry).deltaMinor, -505);
});
test('AGG04 command identity pins source revisions, raw values, realm and explicit confirmation', () => {
  for (const command of [expenseCommand(), openingCommand(), registerCommand()]) {
    assert.deepEqual(checkedLedgerCommand(command), command);
    const changed = {...command, expectedRevision: 9};
    assert.throws(() => checkedLedgerCommand(changed), code('invalid_input'));
    assert.throws(() => checkedLedgerCommand({...command, sourceVerifiedByClient: true}), code('invalid_input'));
    assert.throws(() => checkedLedgerCommand({...command, scope: {...scope, realm: 'production'}}), code('invalid_input'));
  }
  const input = expenseCommand(), parsed = checkedLedgerCommand(input);
  input.expense.note = 'HOST later external mutation';
  assert.equal((parsed as LedgerExpenseCommand).expense.note, expense().note);
});
test('AGG04 private unconfigured ledger remains unavailable without constructing invented zero finance', async () => {
  await assert.rejects(new WorkspaceLedgerService(null).handle(actor, 'readStoreLedgerSource', read()), code('service_unavailable'));
  const source = new HostHandlerSource(); source.configured = false;
  await assert.rejects(new WorkspaceLedgerService(source).handle(actor, 'readStoreLedgerSource', read()), code('service_unavailable'));
  assert.equal(source.calls, 0);
});
for (const changed of [{uid: 'HOST-other'}, {projectId: 'HOST-other'}, {tenantId: 'HOST-tenant'}]) {
  test(`AGG04 private source rejects original ${Object.keys(changed)[0]} mismatch before source IO`, async () => {
    const source = new HostHandlerSource();
    await assert.rejects(new WorkspaceLedgerService(source).handle({...actor, ...changed}, 'readStoreLedgerSource', read()), code('permission_denied'));
    assert.equal(source.calls, 0);
  });
}
test('AGG04 empty owned source and unknown original status do not mean a zero balance or failed save', async () => {
  const source = new HostHandlerSource(), service = new WorkspaceLedgerService(source, now);
  const page = await service.handle(actor, 'readStoreLedgerSource', read()) as Record<string, unknown>;
  assert.equal(page.state, 'empty'); assert.equal('finance' in page, false); assert.equal('openingMinor' in page, false);
  const command = expenseCommand();
  const status = await service.handle(actor, 'readStoreLedgerAttempt', {operation: 'readStoreLedgerAttempt', schemaVersion: 1,
    ledgerVersion: 1, scope, idempotencyKey: command.idempotencyKey, fingerprint: command.fingerprint}) as Record<string, unknown>;
  assert.equal(status.attempt, null); assert.equal(source.commands.length, 0);
});
test('AGG04 manual expense handler passes only frozen original fields and has no subscription or source-creation input', async () => {
  const source = new HostHandlerSource(), service = new WorkspaceLedgerService(source, now), command = expenseCommand();
  let release!: () => void; source.gate = new Promise<void>(resolve => {release = resolve;});
  const input = body(command), promise = service.handle(actor, command.operation, input);
  (input.expense as LedgerExpense).note = 'HOST mutation after dispatch'; release();
  const result = await promise as Record<string, unknown>;
  assert.deepEqual(source.commands[0], command); assert.equal(result.state, 'ready'); assert.equal(source.calls, 1);
  assert.equal((result.attempt as LedgerReceipt).inputFingerprint, ledgerHash(command.expense));
  await assert.rejects(service.handle(actor, command.operation, {...body(command), paidSubscription: true}), code('invalid_input'));
  assert.equal(source.calls, 1);
});
test('AGG04 original opening and register handler frames retain their exact target identity', async () => {
  for (const command of [openingCommand(), registerCommand()]) {
    const source = new HostHandlerSource(), service = new WorkspaceLedgerService(source, now);
    const result = await service.handle(actor, command.operation, body(command)) as Record<string, unknown>;
    const target = ledgerCommandTarget(command), receipt = result.attempt as LedgerReceipt;
    assert.equal(receipt.targetId, target.id); assert.equal(receipt.entryId, target.entryId);
    assert.deepEqual(source.commands, [command]); assert.equal('bankVerified' in result, false);
  }
});
for (const damage of ['foreign-row', 'duplicate-row', 'missing-revision', 'cursor-loop', 'wrong-kind', 'false-start', 'changed-payload']) {
  test(`AGG04 source page rejects ${damage} instead of publishing partial or foreign account data`, async () => {
    const source = new HostHandlerSource(), original = expense(), record = row('expense', original.operationId, original);
    source.page = {revision: 1, kind: 'expense', parentId: null, totalCount: 1, startsSource: true, rows: [record], nextCursor: null};
    if (damage === 'foreign-row') {
      const foreign = {...original, account: 'HOST-other'}; source.page = {...source.page, rows: [row('expense', foreign.operationId, foreign)]};
    } else if (damage === 'duplicate-row') source.page = {...source.page, totalCount: 2, rows: [record, record]};
    else if (damage === 'missing-revision') source.page = {...source.page, revision: null};
    else if (damage === 'cursor-loop') source.page = {...source.page, nextCursor: ''};
    else if (damage === 'wrong-kind') source.page = {...source.page, kind: 'moneyRegister'};
    else if (damage === 'false-start') source.page = {...source.page, startsSource: false};
    else source.page = {...source.page, rows: [{...record, json: record.json + ' '}]};
    await assert.rejects(new WorkspaceLedgerService(source, now).handle(actor, 'readStoreLedgerSource', read()), code('service_unavailable'));
  });
}
test('AGG04 malformed terminal receipt or older current revision cannot qualify a recorded result', async () => {
  const command = expenseCommand(), source = new HostHandlerSource(), service = new WorkspaceLedgerService(source, now);
  const readStatus = {operation: 'readStoreLedgerAttempt', schemaVersion: 1, ledgerVersion: 1, scope,
    idempotencyKey: command.idempotencyKey, fingerprint: command.fingerprint};
  for (const damage of ['foreign-scope', 'old-current', 'missing-current', 'bad-status']) {
    const valid = saved(command);
    source.statusResult = damage === 'foreign-scope' ? {...valid, receipt: {...valid.receipt!, scope: {...scope, account: 'HOST-other'}}}
      : damage === 'old-current' ? {...valid, revision: 1} : damage === 'missing-current' ? {...valid, current: null}
      : {...valid, receipt: {...valid.receipt!, status: 'not_saved', reason: 'invented', changed: false}};
    await assert.rejects(service.handle(actor, 'readStoreLedgerAttempt', readStatus), code('service_unavailable'));
  }
});

// These are isolated raw native-input cases, not bank/provider or membership evidence.
function agg05MoneyInput() {
  return {operationId: 'HOST-manual-money', orderId: null, origin: 'supplierAccount',
    reference: 'HOST recorded cash evidence', billId: null, paymentMethod: 'Cash', kind: 'payment',
    amountMinor: 1250, postedAt: '2026-10-29T01:00:00.000Z',
    moneyReview: {occurredOn: '2026-10-28', openingId: 'HOST-opening-only', openingRevision: 1, notIncludedInOpening: true}};
}
test('AGG05 manual money keeps the accepted native methods and raw inputs without inventing verification', () => {
  assert.deepEqual([...ledgerSupplierMoneyMethods], ['UPI', 'Cheque', 'Bank transfer', 'NEFT', 'RTGS', 'Cash']);
  for (const paymentMethod of ledgerSupplierMoneyMethods) for (const kind of ['payment', 'advance']) {
    const input = {...agg05MoneyInput(), paymentMethod, kind};
    const parsed = checkedLedgerSupplierMoneyEntry(input);
    assert.deepEqual(parsed, input);
    assert.equal(Object.hasOwn(parsed, 'verified'), false);
    assert.notEqual(parsed, input); assert.notEqual(parsed.moneyReview, input.moneyReview);
    parsed.moneyReview.occurredOn = '2026-10-27'; assert.equal(input.moneyReview.occurredOn, '2026-10-28');
  }
});
test('AGG05 manual bill money requires its own copy and bill identities instead of an order', () => {
  const input = {...agg05MoneyInput(), origin: 'manualPurchase', purchaseId: 'HOST-copy', billId: 'HOST-bill'};
  assert.deepEqual(checkedLedgerSupplierMoneyEntry(input), input);
  for (const corrupt of [{...input, kind: 'advance'}, {...input, purchaseId: ''}, {...input, billId: null},
    {...input, orderId: 'HOST-forged-platform-order'}]) assert.throws(() => checkedLedgerSupplierMoneyEntry(corrupt), code('invalid_input'));
});
for (const [name, corrupt] of [
  ['no opening assertion', {...agg05MoneyInput(), moneyReview: null}],
  ['already included in opening', {...agg05MoneyInput(), moneyReview: {...agg05MoneyInput().moneyReview, notIncludedInOpening: false}}],
  ['invented verification', {...agg05MoneyInput(), verified: true}],
  ['missing reference', {...agg05MoneyInput(), reference: ' '}],
  ['unsupported payment method', {...agg05MoneyInput(), paymentMethod: 'confirmed-by-AI'}],
  ['invented refund kind', {...agg05MoneyInput(), kind: 'refund'}],
  ['platform order origin', {...agg05MoneyInput(), origin: 'moolSocialOrder', orderId: 'HOST-order'}],
  ['account bill identity', {...agg05MoneyInput(), billId: 'HOST-bill'}],
  ['account copy identity', {...agg05MoneyInput(), purchaseId: 'HOST-copy'}],
  ['zero amount', {...agg05MoneyInput(), amountMinor: 0}],
  ['fractional minor amount', {...agg05MoneyInput(), amountMinor: 0.5}],
  ['unsafe minor amount', {...agg05MoneyInput(), amountMinor: Number.MAX_SAFE_INTEGER + 1}],
  ['invalid occurrence calendar', {...agg05MoneyInput(), moneyReview: {...agg05MoneyInput().moneyReview, occurredOn: '2026-02-30'}}],
  ['missing opening revision', {...agg05MoneyInput(), moneyReview: {...agg05MoneyInput().moneyReview, openingRevision: 0}}],
  ['extra opening fields', {...agg05MoneyInput(), moneyReview: {...agg05MoneyInput().moneyReview, approval: true}}],
] as const) test('AGG05 manual money rejects ' + name, () => {
  assert.throws(() => checkedLedgerSupplierMoneyEntry(corrupt), code('invalid_input'));
});
test('AGG05 manual money preserves safe native minor-unit limits before source capacity validation', () => {
  for (const amountMinor of [1, Number.MAX_SAFE_INTEGER]) assert.equal(
    checkedLedgerSupplierMoneyEntry({...agg05MoneyInput(), amountMinor}).amountMinor, amountMinor);
});

function agg05BillInput() {
  const profile = originalOpeningBook().profiles[0]!;
  return {copy: {id: 'HOST-original-bill-copy', storeName: 'HOST Store', revision: 3, savedAt: at, supplier: profile,
    draft: {id: 'HOST-original-bill-draft', supplierId: profile.id, invoiceReference: 'HOST-INV-1', invoiceDate: '29/10/2026',
      createdAt: at, updatedAt: at, source: 'manual', stage: 'draft',
      goods: [{productId: '', name: 'HOST printed item', pack: '1 kg', quantity: '1', cost: '10.00'}],
      details: {invoiceTotal: '10.00'}}, labels: {}}, acceptedAt: confirmedAt, openingTreatment: 'excluded'};
}
test('AGG05 printed invoice inputs retain exact paise and never round or infer missing zero', () => {
  for (const [raw, expected] of [[' 12.5 ', 1250], ['0.01', 1], ['-0.25', -25], ['-0.00', 0], ['00010.00', 1000],
    ['999999999999.99', 99999999999999]] as const) assert.equal(ledgerPrintedPaise(raw), expected);
  for (const raw of [null, undefined, '', ' ', 10, '1,000.00', '.50', '1.005', '1e3', '1000000000000.00']) {
    assert.equal(ledgerPrintedPaise(raw), null);
  }
});
test('AGG05 reviewed original bill input preserves native evidence without creating liability or a payment', () => {
  const raw = agg05BillInput(), before = ledgerCanonical(raw), parsed = checkedLedgerSupplierBillAcceptance(raw);
  assert.equal(ledgerCanonical(parsed), before);
  raw.copy.draft.goods[0]!.name = 'HOST later edit';
  assert.equal(parsed.copy.draft.goods[0]!.name, 'HOST printed item');
  const reviewed = {...agg05BillInput(), openingReview: {openingId: opening().id,
    openingRevision: opening().revision, treatment: 'excluded'}};
  assert.deepEqual(checkedLedgerSupplierBillAcceptance(reviewed).openingReview, reviewed.openingReview);
});
for (const [name, change] of [
  ['unknown classification', {openingTreatment: 'unknown'}],
  ['earlier acceptance', {acceptedAt: '2026-10-29T00:00:00.000Z'}],
  ['invented confirmation', {confirmed: true}],
  ['contradictory review', {openingReview: {openingId: opening().id, openingRevision: 2, treatment: 'included'}}],
  ['empty review identity', {openingReview: {openingId: '', openingRevision: 2, treatment: 'excluded'}}],
  ['missing review revision', {openingReview: {openingId: opening().id, treatment: 'excluded'}}],
] as const) test('AGG05 reviewed bill rejects ' + name, () => {
  assert.throws(() => checkedLedgerSupplierBillAcceptance({...agg05BillInput(), ...change}), code('invalid_input'));
});
for (const [name, edit] of [
  ['missing invoice total', (bill: ReturnType<typeof agg05BillInput>) => {bill.copy.draft.details = {} as {invoiceTotal: string};}],
  ['negative invoice total', (bill: ReturnType<typeof agg05BillInput>) => {bill.copy.draft.details.invoiceTotal = '-1.00';}],
  ['invalid invoice date', (bill: ReturnType<typeof agg05BillInput>) => {bill.copy.draft.invoiceDate = '31/02/2026';}],
  ['missing pack', (bill: ReturnType<typeof agg05BillInput>) => {bill.copy.draft.goods[0]!.pack = '';}],
  ['missing unit cost', (bill: ReturnType<typeof agg05BillInput>) => {bill.copy.draft.goods[0]!.cost = '';}],
  ['unrounded cost', (bill: ReturnType<typeof agg05BillInput>) => {bill.copy.draft.goods[0]!.cost = '1.005';}],
  ['zero purchased and free quantity', (bill: ReturnType<typeof agg05BillInput>) => {bill.copy.draft.goods[0]!.quantity = '0';}],
  ['fractional quantity beyond native precision', (bill: ReturnType<typeof agg05BillInput>) => {bill.copy.draft.goods[0]!.quantity = '0.0001';}],
] as const) test('AGG05 reviewed bill rejects ' + name, () => {
  const bill = agg05BillInput(); edit(bill);
  assert.throws(() => checkedLedgerSupplierBillAcceptance(bill), code('invalid_input'));
});
test('AGG05 reviewed bill checks complete printed tax splits but preserves missing components as unknown', () => {
  const bill = agg05BillInput(), details = {invoiceTotal: '11.80', taxTreatment: 'CGST + SGST',
    totalTax: '1.80', cgst: '0.90', sgstAmount: '0.90', cess: '0.00', roundOff: '-0.25'};
  assert(checkedLedgerSupplierBillAcceptance({...bill, copy: {...bill.copy, draft: {...bill.copy.draft, details}}}));
  assert.throws(() => checkedLedgerSupplierBillAcceptance({...bill, copy: {...bill.copy,
    draft: {...bill.copy.draft, details: {...details, totalTax: '1.81'}}}}), code('invalid_input'));
  const missing = {...details, totalTax: '1.81', cess: ''};
  assert.deepEqual(checkedLedgerSupplierBillAcceptance({...bill, copy: {...bill.copy,
    draft: {...bill.copy.draft, details: missing}}}).copy.draft.details, missing);
  assert(checkedLedgerSupplierBillAcceptance({...bill, copy: {...bill.copy, draft: {...bill.copy.draft,
    goods: [{...bill.copy.draft.goods[0]!, quantity: '0', freeQuantity: '1', cost: '0'}], details: {invoiceTotal: '0'}}}}));
  if (process.env.AGG05_BILL_INPUT_CAPTURE_PATH) {
    const cases = [
      {name: 'explicit reviewed bill', input: bill, accepted: true},
      {name: 'complete printed tax', input: {...bill, copy: {...bill.copy, draft: {...bill.copy.draft, details}}}, accepted: true},
      {name: 'missing tax component stays unknown', input: {...bill, copy: {...bill.copy, draft: {...bill.copy.draft, details: missing}}}, accepted: true},
      {name: 'conflicting complete tax', input: {...bill, copy: {...bill.copy, draft: {...bill.copy.draft,
        details: {...details, totalTax: '1.81'}}}}, accepted: false},
      {name: 'unreviewed classification', input: {...bill, openingTreatment: 'unknown'}, accepted: false},
      {name: 'incomplete pack', input: {...bill, copy: {...bill.copy, draft: {...bill.copy.draft,
        goods: [{...bill.copy.draft.goods[0]!, pack: ''}]}}}, accepted: false},
    ];
    for (const value of cases) {
      let accepted = true; try {checkedLedgerSupplierBillAcceptance(value.input);} catch {accepted = false;}
      assert.equal(accepted, value.accepted);
    }
    writeFileSync(process.env.AGG05_BILL_INPUT_CAPTURE_PATH,
      JSON.stringify({label: 'ISOLATED ORIGINAL BILL INPUT PARITY; NO FINANCIAL AUTHORITY OR EFFECT', cases}), {encoding: 'utf8', flag: 'wx'});
  }
});

function supplierMoneyCommand(overrides: Partial<LedgerSupplierMoneyCommand> = {}): LedgerSupplierMoneyCommand {
  const entry = checkedLedgerSupplierMoneyEntry({...agg05MoneyInput(), operationId: 'HOST-supplier-money-event',
    postedAt: confirmedAt, moneyReview: {occurredOn: '2026-10-29', openingId: opening().id,
      openingRevision: opening().revision, notIncludedInOpening: true}});
  return resign({scope, operation: 'recordStoreSupplierMoney', supplierId: opening().supplierId,
    expectedRevision: 1, expectedSupplierRevision: 1, entry, confirmedUtcOffsetMinutes: 330,
    idempotencyKey: 'HOST-supplier-money-attempt', fingerprint: '', ...overrides});
}
function agg05AllocationInput(sourceKind = 'accountPayment') {
  return {operationId: 'HOST-allocation-intent', accountScope: scope.account, workspaceId: scope.store,
    supplierId: opening().supplierId, sourceKind, sourceId: sourceKind === 'manualBillSurplus' ? 'HOST-source-bill' : 'HOST-recorded-money',
    openingId: opening().id, openingRevision: opening().revision, billId: 'HOST-target-bill', copyId: 'HOST-target-copy',
    copyRevision: 3, amountMinor: 500, requestedAt: at,
    ...(sourceKind === 'manualBillSurplus' ? {sourceCopyId: 'HOST-source-copy', sourceCopyRevision: 2} : {})};
}
test('AGG05 allocation native input and committed-proof shapes preserve all existing source kinds without making a payment', () => {
  const cases: {name: string; kind: 'intent' | 'proof'; input: Record<string, unknown>; accepted: boolean}[] = [];
  for (const source of ['openingAdvance', 'accountPayment', 'accountAdvance', 'manualBillSurplus']) {
    const input = agg05AllocationInput(source);
    cases.push({name: source + ' intent', kind: 'intent', input, accepted: true});
    cases.push({name: source + ' original commit proof', kind: 'proof', input: {...input,
      committedRevision: 2, recordedAt: confirmedAt, ...(source === 'manualBillSurplus' ? {sourceEntryCount: 0} : {})}, accepted: true});
  }
  const input = agg05AllocationInput(), surplus = agg05AllocationInput('manualBillSurplus');
  const {sourceCopyId: _source, ...missingSourceCopy} = surplus;
  cases.push(
    {name: 'retailer cannot supply commit revision', kind: 'intent', input: {...input, committedRevision: 2}, accepted: false},
    {name: 'surplus requires original source copy', kind: 'intent', input: missingSourceCopy, accepted: false},
    {name: 'surplus cannot allocate to itself', kind: 'intent', input: {...surplus, sourceId: surplus.billId}, accepted: false},
    {name: 'fractional minor amount', kind: 'intent', input: {...input, amountMinor: 0.5}, accepted: false},
    {name: 'unrecognised source kind', kind: 'intent', input: {...input, sourceKind: 'available-cash'}, accepted: false},
    {name: 'bank verification is not attribution', kind: 'intent', input: {...input, verified: true}, accepted: false},
    {name: 'surplus proof needs source entry count', kind: 'proof', input: {...surplus, committedRevision: 2, recordedAt: confirmedAt}, accepted: false},
    {name: 'account proof cannot carry surplus count', kind: 'proof', input: {...input, committedRevision: 2, recordedAt: confirmedAt, sourceEntryCount: 0}, accepted: false},
    {name: 'proof cannot predate request', kind: 'proof', input: {...input, committedRevision: 2, recordedAt: '2026-10-29T00:59:59.999Z'}, accepted: false},
    {name: 'proof cannot replace initial revision', kind: 'proof', input: {...input, committedRevision: 1, recordedAt: confirmedAt}, accepted: false});
  for (const item of cases) {
    const before = ledgerHash(item.input);
    const parse = () => item.kind === 'intent' ? checkedLedgerSupplierAllocationIntent(item.input, scope)
      : checkedLedgerSupplierAllocationProof(item.input, scope);
    if (item.accepted) {assert.deepEqual(parse(), item.input); assert.notEqual(parse(), item.input);}
    else assert.throws(parse);
    assert.equal(ledgerHash(item.input), before);
  }
  if (process.env.AGG05_ALLOCATION_INPUT_CAPTURE_PATH) writeFileSync(process.env.AGG05_ALLOCATION_INPUT_CAPTURE_PATH,
    JSON.stringify({label: 'ISOLATED NATIVE ALLOCATION FORMAT PARITY; NOT CAPACITY, AUTHORITY OR POSTING', scope, cases}),
    {encoding: 'utf8', flag: 'wx'});
});
test('AGG05 allocation rejects foreign account and Store and unsafe amounts before any original source call', () => {
  const input = agg05AllocationInput();
  for (const patch of [{accountScope: 'HOST-other-account'}, {workspaceId: 'HOST-other-store'},
    {amountMinor: 0}, {amountMinor: -1}, {amountMinor: Number.MAX_SAFE_INTEGER + 1},
    {openingRevision: 0}, {copyRevision: 0}, {requestedAt: '2026-10-29T01:00:00'}, {sourceKind: {name: 'accountPayment'}}]) {
    assert.throws(() => checkedLedgerSupplierAllocationIntent({...input, ...patch}, scope), code('invalid_input'));
  }
  assert.equal(checkedLedgerSupplierAllocationIntent({...input, amountMinor: Number.MAX_SAFE_INTEGER}, scope).amountMinor, Number.MAX_SAFE_INTEGER);
});
test('AGG05 SDK AI account-money preparation preserves original identities and never records or confirms',
  {skip: !ledgerEmulator}, async () => {
    const f = await sdkLedger();
    try {
      const prep = await sdkPreparation(f, {posted: true});
      const before = ledgerHash((await f.root.get()).data()), attempts = (await f.root.collection('attempts').get()).size;
      const fields = {supplierId: opening().supplierId, openingId: opening().id, openingRevision: opening().revision,
        amount: '5.00', reference: 'HOST originally supplied payment', channel: 'Cash', occurredOn: '2026-10-29'};
      let staleProposal: PreparationReply['outcome'] | null = null;
      for (const actionId of ['AI-ACT-260', 'AI-ACT-261']) {
        const input = {...prep.input, actionId, entityId: opening().supplierId};
        const context = await prep.source.read(f.user, input);
        assert.equal(context.tools.length, 1); const tool = context.tools[0]!;
        assertStrictSchema(tool.parameters); assert(tool.validate(fields));
        const resolved = tool.resolveTarget!(fields);
        assert.deepEqual(resolved.fields, fields); assert.equal(resolved.entityId, opening().supplierId);
        assert.equal(resolved.sourceRevision, 'store-original-ledger-v1:' + ledgerHash([
          scope.account, scope.store, scope.realm, 2, prep.book.revision, actionId, opening().supplierId]));
        for (const changed of [{supplierId: 'HOST-other-supplier'}, {openingId: 'HOST-other-opening'},
          {openingRevision: opening().revision + 1}, {amount: 500}, {amount: '0'}, {channel: ['Cash']},
          {occurredOn: '2026-02-30'}, {occurredOn: '29/10/2026'}, {notIncludedInOpening: true},
          {operationId: 'HOST-invented-event'}, {idempotencyKey: 'HOST-invented-request'}, {copyId: 'HOST-opaque-copy'}]) {
          assert(!tool.validate({...fields, ...changed}));
        }
        assert(!tool.validate({...fields, reference: ''}));
        const {occurredOn: _date, ...missingDate} = fields; assert(!tool.validate(missingDate));
        const proposal = {kind: 'proposal' as const, id: 'HOST-money-preparation', actionId,
          ...resolved, title: 'Review original payment', summary: 'HOST native confirmation only'};
        const reopened = await prep.source.readPrepared(f.user, input, proposal);
        assert.equal(reopened.tools[0]!.sourceRevision, resolved.sourceRevision);
        staleProposal = proposal;
        if (process.env.AGG05_CONTEXT_CAPTURE_PATH) writeFileSync(process.env.AGG05_CONTEXT_CAPTURE_PATH + '.' + actionId + '.json',
          JSON.stringify({label: 'ISOLATED SDK ORIGINAL MONEY PREPARATION; NO LIVE MODEL OR AUTHORITY',
            actor: f.user, request: input, metadata: {ok: true, data: canonicalContextProjection(f.user, input.scope, context, 1)},
            proposal}), {encoding: 'utf8', flag: 'wx'});
      }
      assert.equal(ledgerHash((await f.root.get()).data()), before);
      assert.equal((await f.root.collection('attempts').get()).size, attempts);
      assert(prep.calls.every(operation => operation === 'readStoreLedgerSource'));
      // This original fixture has an explicit zero opening. An advance, not
      // an overpayment, creates the independent change used for staleness.
      const command = supplierMoneyCommand({expectedRevision: 2,
        entry: {...supplierMoneyCommand().entry, kind: 'advance', amountMinor: 500}});
      const changed = await prep.ledger.handle(f.user, command.operation, body(command)) as Record<string, unknown>;
      assert.equal((changed.attempt as Record<string, unknown>).status, 'saved');
      assert(staleProposal?.kind === 'proposal');
      await assert.rejects(prep.source.readPrepared(f.user,
        {...prep.input, actionId: staleProposal.actionId, entityId: staleProposal.entityId}, staleProposal), /stale_preparation/u);
    } finally {await f.close();}
  });

async function sdkReviewedBillFixture(treatment: 'included' | 'excluded' = 'excluded', balance = 10000) {
  const f = await sdkManualSupplierFixture(balance);
  try {
    const copy = checkedPurchaseEntryCopy({...agg05BillInput().copy, supplier: f.book.profiles[0]!}, true);
    const input = {scope, expectedRevision: f.book.revision, idempotencyKey: 'HOST-original-reviewed-copy',
      profile: copy.supplier, draft: copy.draft, reviewedCopy: copy, replaceReviewedDraftId: null};
    await f.original.repository.savePurchaseDraft(f.user, {...input, fingerprint: purchaseEntryDraftCommandFingerprint(input)});
    const book = (await f.original.repository.read(f.user, scope))!;
    assert.equal(book.revision, 3); assert.equal(book.copies?.length, 1);
    const bill = checkedLedgerSupplierBillAcceptance({copy, acceptedAt: confirmedAt, openingTreatment: treatment,
      openingReview: {openingId: opening().id, openingRevision: opening().revision, treatment}});
    const command: LedgerSupplierBillCommand = resign({scope, operation: 'confirmStoreSupplierBill',
      expectedRevision: 1, expectedSupplierRevision: 1, expectedPurchaseRevision: book.revision,
      expectedPurchaseFingerprint: ledgerHash(book), supplierId: copy.supplier.id,
      bill, confirmedUtcOffsetMinutes: 330, idempotencyKey: 'HOST-bill-confirmation', fingerprint: ''});
    return {...f, billBook: book, billCommand: command};
  } catch (error) {await f.close(); throw error;}
}
function billMoneyCommand(bill: LedgerSupplierBillCommand, overrides: Partial<LedgerSupplierMoneyCommand> = {}): LedgerSupplierMoneyCommand {
  const entry = checkedLedgerSupplierMoneyEntry({...supplierMoneyCommand().entry,
    operationId: 'HOST-original-bill-payment', origin: 'manualPurchase',
    purchaseId: bill.bill.copy.id, billId: bill.bill.copy.draft.id, amountMinor: 500});
  return supplierMoneyCommand({expectedRevision: 2, expectedSupplierRevision: 2,
    idempotencyKey: 'HOST-original-bill-payment-request', entry, ...overrides});
}
function refundCommand(kind: 'openingAdvance' | 'accountAdvance' = 'openingAdvance', overrides: Partial<LedgerSupplierRefundCommand> = {}): LedgerSupplierRefundCommand {
  return resign({scope, operation: 'recordStoreSupplierRefund', supplierId: opening().supplierId,
    expectedRevision: kind === 'openingAdvance' ? 1 : 2, expectedSupplierRevision: kind === 'openingAdvance' ? 1 : 2,
    idempotencyKey: 'HOST-original-refund-request', fingerprint: '', confirmedUtcOffsetMinutes: 330,
    intent: checkedLedgerSupplierRefundIntent({operationId: 'HOST-original-refund', accountScope: scope.account, workspaceId: scope.store,
      supplierId: opening().supplierId, qa: false, sourceKind: kind, sourceId: kind === 'openingAdvance' ? opening().id : supplierMoneyCommand().entry.operationId,
      openingId: opening().id, openingRevision: opening().revision, reference: 'HOST explicit refund receipt', occurredOn: '2026-10-29',
      paymentMethod: 'Cash', amountMinor: 250, requestedAt: confirmedAt, copyId: null, copyRevision: null}, scope), ...overrides});
}
test('AGG05 refund closed native intent and original command reject fabricated metadata and source kinds', () => {
  const command = refundCommand(), intent = command.intent;
  assert.deepEqual(checkedLedgerCommand(command), command);
  const cases: {name: string; input: unknown; accepted: boolean}[] = [
    ...(['openingAdvance', 'accountAdvance', 'manualBillSurplus'] as const).map(sourceKind => ({name: sourceKind,
      input: {...intent, sourceKind, ...(sourceKind === 'manualBillSurplus' ? {copyId: 'HOST-bill-copy', copyRevision: 3} : {})}, accepted: true})),
    ...[{sourceKind: 'accountPayment'}, {amountMinor: 0}, {amountMinor: -1}, {amountMinor: 1.25}, {amountMinor: Number.MAX_SAFE_INTEGER + 1},
      {accountScope: 'HOST-foreign'}, {workspaceId: 'HOST-foreign'}, {qa: 'false'}, {paymentMethod: 'NEFT'}, {occurredOn: '2026-02-30'},
      {reference: ' padded '}, {openingRevision: 0}, {copyId: 'unexpected'}, {copyRevision: 2}, {committedRevision: 2},
      {requestedAt: 'invalid'}, {sourceKind: 'manualBillSurplus'}].map((patch, index) => ({name: 'refused-' + index, input: {...intent, ...patch}, accepted: false})),
  ];
  for (const c of cases) {
    if (c.accepted) assert.deepEqual(checkedLedgerSupplierRefundIntent(c.input, scope), c.input);
    else assert.throws(() => checkedLedgerSupplierRefundIntent(c.input, scope), code('invalid_input'), c.name);
  }
  const proof = checkedLedgerSupplierRefundProof({intent, committedRevision: 2, recordedAt: confirmedAt}, scope);
  assert.equal(ledgerSupplierRefundEntry(proof).kind, 'refund');
  assert.throws(() => checkedLedgerSupplierRefundProof({...proof, committedRevision: 1}, scope), code('invalid_input'));
  assert.throws(() => checkedLedgerSupplierRefundProof({...proof, recordedAt: '2026-10-29T01:59:59.999999Z'}, scope), code('invalid_input'));
  assert.throws(() => checkedLedgerCommand(resign({...command, confirmedUtcOffsetMinutes: 841})), code('invalid_input'));
  assert.throws(() => checkedLedgerCommand({...command, intent: {...intent, amountMinor: 249}}), code('invalid_input'));
  if (process.env.AGG05_REFUND_INPUT_CAPTURE_PATH) writeFileSync(process.env.AGG05_REFUND_INPUT_CAPTURE_PATH,
    JSON.stringify({label: 'ISOLATED HOST FORMAT CASES; NO SOURCE CAPACITY OR FINANCIAL EFFECT', scope, cases, proof}), {encoding: 'utf8', flag: 'wx'});
});
function agg05CreditDocumentCases(): Array<{name: string; input: Record<string, unknown>; printedTotal: number | null}> {
  const row = {rate: '18', taxable: '100.00', cgst: '9.00', sgst: '9.00', igst: '0.00', cess: '0.00'};
  const particulars = {documentTitle: 'HOST supplier GST credit note', supplierName: 'HOST supplier',
    supplierAddress: 'HOST printed address', supplierGstin: 'HOST printed GSTIN', buyerName: 'HOST buyer',
    buyerAddress: 'HOST buyer address', buyerGstinUin: 'HOST printed recipient ID', deliveryAddress: 'HOST delivery',
    recipientState: 'HOST state', recipientStateCode: '24', invoiceReferences: 'HOST-INV-1 / 28-10-2026',
    signatureDetails: 'HOST signed copy', irn: 'HOST printed IRN', qrReference: 'HOST printed QR text ગુજરાતી हिन्दी'};
  return [
    {name: 'GST CGST SGST', input: {version: 1, treatment: 'gst', reasonCode: 'return', taxRows: [row]}, printedTotal: 11800},
    {name: 'GST IGST printed particulars', input: {version: 2, treatment: 'gst', reasonCode: 'tax',
      taxRows: [{...row, cgst: '0', sgst: '0', igst: '18.00'}], particulars}, printedTotal: 11800},
    {name: 'GST rates and cess', input: {version: 1, treatment: 'gst', reasonCode: 'damage', taxRows: [
      {rate: '5', taxable: '100.00', cgst: '2.50', sgst: '2.50', igst: '0', cess: '1.00'},
      {rate: '12', taxable: '50', cgst: '0', sgst: '0', igst: '6', cess: '0'}]}, printedTotal: 16200},
    {name: 'commercial GST unchanged', input: {version: 2, treatment: 'commercial', reasonCode: 'discount',
      taxRows: [], particulars: {...particulars, documentTitle: 'HOST commercial credit note'}}, printedTotal: null},
    {name: 'unclassified unsent draft', input: {version: 1, treatment: '', reasonCode: '', taxRows: []}, printedTotal: null},
    {name: 'incomplete GST preserved', input: {version: 1, treatment: 'gst', reasonCode: 'shortage',
      taxRows: [{...row, cgst: ''}]}, printedTotal: null},
    {name: 'unreadable printed amount preserved', input: {version: 1, treatment: 'gst', reasonCode: 'other',
      taxRows: [{...row, taxable: 'HOST unreadable'}]}, printedTotal: null},
    {name: 'commercial hidden rows preserved', input: {version: 1, treatment: 'commercial', reasonCode: 'price',
      taxRows: [row]}, printedTotal: null},
    {name: 'empty version2 particulars', input: {version: 2, treatment: 'gst', reasonCode: 'return',
      taxRows: [row], particulars: {}}, printedTotal: 11800},
  ];
}
for (const sample of agg05CreditDocumentCases()) test('AGG05 credit document codec preserves native printed fields: ' + sample.name, () => {
  const before = ledgerCanonical(sample.input), parsed = checkedLedgerSupplierCreditDocumentInput(sample.input);
  assert.deepEqual(parsed, sample.input); assert.equal(ledgerSupplierCreditPrintedTotal(parsed), sample.printedTotal);
  assert.notEqual(parsed, sample.input); assert.notEqual(parsed.taxRows, sample.input.taxRows);
  if (parsed.taxRows.length) parsed.taxRows[0]!.rate = 'HOST local mutation';
  assert.equal(ledgerCanonical(sample.input), before);
});
for (const [name, raw] of [
  ['null', null], ['array', []], ['unknown version', {version: 3, treatment: 'gst', reasonCode: 'return', taxRows: []}],
  ['missing reason', {version: 1, treatment: 'gst', taxRows: []}],
  ['unknown classification', {version: 1, treatment: 'vat', reasonCode: 'return', taxRows: []}],
  ['unknown reason', {version: 1, treatment: 'gst', reasonCode: 'HOST invented', taxRows: []}],
  ['extra field', {...agg05CreditDocumentCases()[0]!.input, approved: true}],
  ['numeric printed row', {version: 1, treatment: 'gst', reasonCode: 'return', taxRows: [{rate: 18, taxable: '1', cgst: '0', sgst: '0', igst: '0', cess: '0'}]}],
  ['missing row column', {version: 1, treatment: 'gst', reasonCode: 'return', taxRows: [{rate: '18'}]}],
  ['extra row column', {version: 1, treatment: 'gst', reasonCode: 'return', taxRows: [{rate: '18', taxable: '1', cgst: '0', sgst: '0', igst: '0', cess: '0', total: '1'}]}],
  ['too many rows', {version: 1, treatment: 'gst', reasonCode: 'return', taxRows: Array(101).fill({rate: '18', taxable: '1', cgst: '0', sgst: '0', igst: '0', cess: '0'})}],
  ['oversized printed value', {version: 1, treatment: 'gst', reasonCode: 'return', taxRows: [{rate: '1'.repeat(101), taxable: '1', cgst: '0', sgst: '0', igst: '0', cess: '0'}]}],
  ['version1 particulars', {...agg05CreditDocumentCases()[0]!.input, particulars: {}}],
  ['missing version2 particulars', {...agg05CreditDocumentCases()[0]!.input, version: 2}],
  ['extra particular', {...agg05CreditDocumentCases()[0]!.input, version: 2, particulars: {paymentVerified: 'yes'}}],
  ['numeric particular', {...agg05CreditDocumentCases()[0]!.input, version: 2, particulars: {supplierName: 42}}],
  ['oversized state code', {...agg05CreditDocumentCases()[0]!.input, version: 2, particulars: {recipientStateCode: '123'}}],
] as const) test('AGG05 credit document codec rejects unsupported payload: ' + name, () => {
  assert.throws(() => checkedLedgerSupplierCreditDocumentInput(raw), code('invalid_input'));
});
test('AGG05 credit document codec emits isolated native format evidence only', () => {
  if (process.env.AGG05_CREDIT_DOCUMENT_CAPTURE_PATH) writeFileSync(process.env.AGG05_CREDIT_DOCUMENT_CAPTURE_PATH,
    JSON.stringify({label: 'ISOLATED HOST DOCUMENT FORMAT; NO TAX AUTHORITY OR FINANCIAL EFFECT',
      cases: agg05CreditDocumentCases().map(sample => ({...sample, output: checkedLedgerSupplierCreditDocumentInput(sample.input)}))}),
    {encoding: 'utf8', flag: 'wx'});
});
function agg05StructuredCreditInput(kind: 'goodsReturned' | 'arrivalDamage' | 'shortage' = 'arrivalDamage', treatment: 'gst' | 'commercial' = 'gst') {
  return {operationId: 'HOST-structured-credit', accountScope: scope.account, workspaceId: scope.store,
    supplierId: 'HOST-credit-supplier', billId: 'HOST-credit-bill', copyId: 'HOST-credit-copy', copyRevision: 1,
    openingId: 'HOST-credit-opening', openingRevision: 1, reference: 'HOST-CN-1', occurredOn: '2026-10-29',
    reason: 'HOST printed supplier reason', amountMinor: 11800, requestedAt: at,
    supports: [{kind, receiptId: 'HOST-credit-receipt', receiptLineId: 'HOST-credit-line', billLineIndex: 0, quantityMilli: 1000,
      ...(kind === 'goodsReturned' ? {returnOperationId: 'HOST-original-return'} : {}),
      ...(kind === 'shortage' ? {shortageClaimId: 'HOST-original-shortage'} : {})}],
    documentInput: agg05CreditDocumentCases()[treatment === 'gst' ? 1 : 3]!.input};
}
for (const kind of ['goodsReturned', 'arrivalDamage', 'shortage'] as const) {
  test('AGG05 credit preparation support selectors match native identity and remaining original capacity: ' + kind, () => {
    const f = agg05OriginalCreditFixture(kind), before = ledgerCanonical(f.ledger);
    const remaining = ledgerSupplierAvailableCreditSupports(f.ledger, scope, opening().supplierId, f.proof.billId, f.bills);
    assert.equal(remaining.some(row => row.support.kind === kind), false, 'The original500-milli source is already fully credited.');
    for (const row of remaining) {
      const support = row.support;
      assert.equal(row.id, JSON.stringify([support.kind, support.receiptId, support.receiptLineId, support.billLineIndex,
        support.returnOperationId ?? null, support.shortageClaimId ?? null]));
      assert.equal(support.quantityMilli, 500); assert.equal(row.unit, 'pack');
    }
    assert.equal(ledgerCanonical(f.ledger), before);
    const empty = ledgerClone(f.ledger); empty.creditNotes = {}; empty.revision = 5;
    empty.entries = (empty.entries as Record<string, unknown>[]).filter(entry => entry.operationId !== f.proof.operationId);
    const available = ledgerSupplierAvailableCreditSupports(empty, scope, opening().supplierId, f.proof.billId, f.bills);
    assert.equal(available.find(row => row.support.kind === kind)?.support.quantityMilli, 500);
    assert.equal(ledgerSupplierAvailableCreditSupports(empty, scope, opening().supplierId, 'HOST-missing-bill', f.bills).length, 0);
    assert.throws(() => ledgerSupplierAvailableCreditSupports(empty, {...scope, account: 'HOST-foreign'}, opening().supplierId, f.proof.billId, f.bills));
  });
}
for (const kind of ['goodsReturned', 'arrivalDamage', 'shortage'] as const) for (const treatment of ['gst', 'commercial'] as const)
  test('AGG05 structured credit request codec keeps document and original support identities: ' + kind + ' ' + treatment, () => {
    const input = agg05StructuredCreditInput(kind, treatment), before = ledgerCanonical(input);
    const intent = checkedLedgerSupplierCreditIntent(input, scope);
    assert.deepEqual(intent, input); assert.equal(ledgerCanonical(input), before);
    const proof = checkedLedgerSupplierCreditProof({...intent, recordedAt: confirmedAt, committedRevision: 2}, scope);
    assert.deepEqual(proof.documentInput, intent.documentInput); assert.deepEqual(proof.supports, intent.supports);
    const entry = ledgerSupplierCreditEntry(proof);
    assert.deepEqual(entry, {operationId: intent.operationId, orderId: null, reference: intent.reference,
      billId: intent.billId, origin: 'manualPurchase', purchaseId: intent.copyId, kind: 'creditNote',
      amountMinor: intent.amountMinor, postedAt: confirmedAt});
    assert.equal(Object.hasOwn(entry, 'paymentVerified'), false);
    for (const patch of [{committedRevision: 1}, {recordedAt: '2026-10-28T01:00:00.000Z'}, {verified: true}])
      assert.throws(() => checkedLedgerSupplierCreditProof({...proof, ...patch}, scope), code('invalid_input'));
    if (process.env.AGG05_CREDIT_INTENT_CAPTURE_PATH) writeFileSync(process.env.AGG05_CREDIT_INTENT_CAPTURE_PATH + '.' + kind + '.' + treatment + '.json',
      JSON.stringify({label: 'ISOLATED HOST STRUCTURED CREDIT FORMAT; NO ORIGINAL SOURCE OR FINANCIAL AUTHORITY', scope, intent, proof, entry}),
      {encoding: 'utf8', flag: 'wx'});
  });
for (const [name, patch] of [
  ['missing document', {documentInput: undefined}], ['unclassified', {documentInput: {version: 1, treatment: '', reasonCode: 'return', taxRows: []}}],
  ['missing document reason', {documentInput: {version: 1, treatment: 'gst', reasonCode: '', taxRows: []}}],
  ['foreign account', {accountScope: 'HOST-other-account'}], ['foreign Store', {workspaceId: 'HOST-other-store'}],
  ['zero amount', {amountMinor: 0}], ['unsafe amount', {amountMinor: Number.MAX_SAFE_INTEGER + 1}], ['negative amount', {amountMinor: -1}],
  ['invalid date', {occurredOn: '2026-02-30'}], ['invented verification', {verified: true}], ['invented commit', {committedRevision: 2}],
  ['missing source supports', {supports: []}], ['unknown support', {supports: [{...agg05StructuredCreditInput().supports[0], kind: 'invented'}]}],
  ['negative bill line', {supports: [{...agg05StructuredCreditInput().supports[0], billLineIndex: -1}]}],
  ['zero quantity', {supports: [{...agg05StructuredCreditInput().supports[0], quantityMilli: 0}]}],
  ['overflow quantity', {supports: [{...agg05StructuredCreditInput().supports[0], quantityMilli: 2147483648}]}],
  ['unrelated return', {supports: [{...agg05StructuredCreditInput().supports[0], returnOperationId: 'HOST-unrelated'}]}],
  ['missing return', {supports: [{...agg05StructuredCreditInput().supports[0], kind: 'goodsReturned'}]}],
  ['missing claim', {supports: [{...agg05StructuredCreditInput().supports[0], kind: 'shortage'}]}],
  ['same source twice', {supports: [agg05StructuredCreditInput().supports[0], {...agg05StructuredCreditInput().supports[0], billLineIndex: 1}]}],
  ['same claim twice', {supports: [agg05StructuredCreditInput('shortage').supports[0],
    {...agg05StructuredCreditInput('shortage').supports[0], receiptId: 'HOST-other-receipt'}]}],
] as const) test('AGG05 structured credit request codec rejects unsupported request: ' + name, () => {
  assert.throws(() => checkedLedgerSupplierCreditIntent({...agg05StructuredCreditInput(), ...patch}, scope), code('invalid_input'));
});
function agg05CreditGoodsFixture(variant: 'plain' | 'lot' | 'restock' | 'legacy calendar' = 'plain') {
  const input = agg05BillInput(), supplier = originalOpeningBook().profiles[0]!;
  input.copy.supplier = supplier; input.copy.draft.supplierId = supplier.id;
  input.copy.draft.goods[0] = {...input.copy.draft.goods[0]!, productId: 'HOST-credit-product', pack: 'pack', quantity: '1'};
  const bill = checkedLedgerSupplierBillAcceptance({...input,
    openingReview: {openingId: opening().id, openingRevision: opening().revision, treatment: 'excluded'}});
  const receipt: Record<string, unknown> = {id: 'HOST-credit-receipt', expectedDeliveryId: 'HOST-credit-delivery', reference: 'HOST-delivery-copy',
    deliveredOn: '2026-10-29', recordedAt: '2026-10-29T02:10:00.000Z', recordedUtcOffsetMinutes: 330,
    lines: [{sourceLineId: 'HOST-credit-line', productId: 'HOST-credit-product', productLabel: 'HOST printed product',
      purchaseUnit: 'pack', stockUnit: 'piece', unitsPerPack: 2, deliveredMilli: 1000, acceptedMilli: 500,
      damagedMilli: 500, shortMilli: 0, expectedMilli: 1000, priorStockUnits: {}}]};
  if (variant === 'legacy calendar') delete receipt.recordedUtcOffsetMinutes;
  if (variant === 'lot') (receipt.lines as Record<string, unknown>[])[0]!.lotDetails = {
    schemaVersion: 1, batch: 'HOST printed batch', manufacturedLabel: 'HOST printed month', expiryLabel: '', mrpMinor: 1200};
  if (variant === 'restock') {
    const reference = {purchaseId: 'HOST-purchase', storeId: 'HOST-selling-store', orderId: 'HOST-order',
      originalFingerprint: ledgerHash('HOST retained purchase'), sourceRevision: 'HOST-original-revision'};
    receipt.expectedDeliveryId = 'restock-' + ledgerHash([scope.realm, scope.store, reference.purchaseId, reference.storeId, reference.orderId]);
    receipt.restockOriginal = {schemaVersion: 1, realm: scope.realm, accountScope: scope.account, buyingStoreId: scope.store,
      reference, lines: [{lineId: 'HOST-credit-line', quantityMilli: 1000, quantityUnit: 'pack'}]};
  }
  const link = {operationId: 'HOST-credit-goods-link', receiptId: receipt.id, receiptLineId: 'HOST-credit-line',
    billId: bill.copy.draft.id, copyId: bill.copy.id, copyRevision: bill.copy.revision, billLineIndex: 0,
    productId: 'HOST-credit-product', billUnit: 'pack', stockUnit: 'piece', stockUnitsNumerator: 2, stockUnitsDenominator: 1,
    billQuantityMilli: 1000, acceptedReceiptMilli: 500, damagedReceiptMilli: 500, conversionReviewed: true,
    linkedAt: '2026-10-29T02:20:00.000Z'};
  const ledger = {...ledgerConfirmedOpening(openingCommand(), 'HOST credit supplier'), revision: 4, asOf: '2026-10-29T03:00:00.000Z',
    purchaseBills: {[bill.copy.draft.id]: ledgerClone(bill)}, goodsReceipts: {[String(receipt.id)]: receipt},
    billGoodsAllocations: {[link.operationId]: link}, entries: [ledgerBillLiabilityEntry(bill)!]};
  return {ledger: ledger as Record<string, unknown>, bill, bills: new Map([[bill.copy.draft.id, ledgerClone(bill)]]), receipt, link,
    line: (receipt.lines as Record<string, unknown>[])[0]!};
}
function agg05CreditReturnFixture() {
  const f = agg05CreditGoodsFixture();
  const line: Record<string, unknown> = {receiptLineId: f.line.sourceLineId, productId: f.line.productId,
    productLabel: f.line.productLabel, purchaseUnit: f.line.purchaseUnit, stockUnit: f.line.stockUnit,
    unitsPerPack: f.line.unitsPerPack, acceptedMilli: 500, damagedMilli: 500};
  const returned: Record<string, unknown> = {operationId: 'HOST-credit-goods-return', accountScope: scope.account,
    workspaceId: scope.store, supplierId: opening().supplierId, receiptId: f.receipt.id, reference: 'HOST-return-copy',
    reason: 'HOST physically returned quantities', returnedOn: '2026-10-29', recordedAt: '2026-10-29T02:30:00.000Z',
    committedRevision: 5, lines: [line]};
  f.ledger.revision = 5; f.ledger.goodsReturns = {[String(returned.operationId)]: returned};
  return {...f, returned, returnLine: line};
}
test('AGG05 credit original returned goods preserves accepted and damaged quantities without financial effect', () => {
  const f = agg05CreditReturnFixture(), before = ledgerCanonical(f.ledger);
  const source = ledgerSupplierCreditGoodsSource(f.ledger, scope, opening().supplierId, f.bills);
  assert.deepEqual(source.returns.get(String(f.returned.operationId)), f.returned);
  assert.equal(source.legacyCalendar, true); // Original return format has no retained local offset.
  assert.equal(ledgerCanonical(f.ledger), before);
  if (process.env.AGG05_CREDIT_GOODS_CAPTURE_PATH) writeFileSync(process.env.AGG05_CREDIT_GOODS_CAPTURE_PATH + '.returned.json',
    JSON.stringify({label: 'ISOLATED HOST RETURN FORMAT; NO RUNTIME STOCK OR FINANCIAL AUTHORITY', scope, ledger: f.ledger,
      receiptCount: source.receipts.size, linkCount: source.links.size, returnCount: source.returns.size, legacyCalendar: source.legacyCalendar}),
    {encoding: 'utf8', flag: 'wx'});
});
for (const [name, mutate] of [
  ['foreign account', (f: ReturnType<typeof agg05CreditReturnFixture>) => {f.returned.accountScope = 'HOST-foreign';}],
  ['foreign Store', (f: ReturnType<typeof agg05CreditReturnFixture>) => {f.returned.workspaceId = 'HOST-foreign';}],
  ['foreign supplier', (f: ReturnType<typeof agg05CreditReturnFixture>) => {f.returned.supplierId = 'HOST-foreign';}],
  ['changed identity', (f: ReturnType<typeof agg05CreditReturnFixture>) => {f.returned.operationId = 'HOST-other';}],
  ['missing receipt', (f: ReturnType<typeof agg05CreditReturnFixture>) => {f.returned.receiptId = 'HOST-missing';}],
  ['before receipt', (f: ReturnType<typeof agg05CreditReturnFixture>) => {f.returned.recordedAt = '2026-10-29T02:00:00.000Z';}],
  ['after source', (f: ReturnType<typeof agg05CreditReturnFixture>) => {f.returned.recordedAt = '2026-10-29T04:00:00.000Z';}],
  ['before delivered day', (f: ReturnType<typeof agg05CreditReturnFixture>) => {f.returned.returnedOn = '2026-10-28';}],
  ['request after recording', (f: ReturnType<typeof agg05CreditReturnFixture>) => {f.returned.requestedAt = '2026-10-29T02:31:00.000Z';}],
  ['uncommitted revision', (f: ReturnType<typeof agg05CreditReturnFixture>) => {f.returned.committedRevision = 1;}],
  ['future revision', (f: ReturnType<typeof agg05CreditReturnFixture>) => {f.returned.committedRevision = 6;}],
  ['wrong product', (f: ReturnType<typeof agg05CreditReturnFixture>) => {f.returnLine.productId = 'HOST-other';}],
  ['wrong label', (f: ReturnType<typeof agg05CreditReturnFixture>) => {f.returnLine.productLabel = 'HOST-other';}],
  ['wrong pack', (f: ReturnType<typeof agg05CreditReturnFixture>) => {f.returnLine.purchaseUnit = 'HOST-other';}],
  ['wrong stock unit', (f: ReturnType<typeof agg05CreditReturnFixture>) => {f.returnLine.stockUnit = 'HOST-other';}],
  ['wrong conversion', (f: ReturnType<typeof agg05CreditReturnFixture>) => {f.returnLine.unitsPerPack = 4;}],
  ['excess accepted', (f: ReturnType<typeof agg05CreditReturnFixture>) => {f.returnLine.acceptedMilli = 1000;}],
  ['excess damaged', (f: ReturnType<typeof agg05CreditReturnFixture>) => {f.returnLine.damagedMilli = 501;}],
  ['fractional stock', (f: ReturnType<typeof agg05CreditReturnFixture>) => {f.returnLine.acceptedMilli = 1;}],
  ['empty return', (f: ReturnType<typeof agg05CreditReturnFixture>) => {f.returnLine.acceptedMilli = 0; f.returnLine.damagedMilli = 0;}],
  ['duplicate line', (f: ReturnType<typeof agg05CreditReturnFixture>) => {(f.returned.lines as unknown[]).push(ledgerClone(f.returnLine));}],
  ['duplicate revision', (f: ReturnType<typeof agg05CreditReturnFixture>) => {(f.ledger.goodsReturns as Record<string, unknown>)['HOST-second-return'] = {...ledgerClone(f.returned), operationId: 'HOST-second-return'};}],
  ['cumulative excess', (f: ReturnType<typeof agg05CreditReturnFixture>) => {f.ledger.revision = 6; (f.ledger.goodsReturns as Record<string, unknown>)['HOST-second-return'] = {...ledgerClone(f.returned), operationId: 'HOST-second-return', committedRevision: 6};}],
  ['unknown field', (f: ReturnType<typeof agg05CreditReturnFixture>) => {f.returned.invented = true;}],
] as const) test('AGG05 credit original returned goods refuses changed evidence: ' + name, () => {
  const f = agg05CreditReturnFixture(); mutate(f);
  assert.throws(() => ledgerSupplierCreditGoodsSource(f.ledger, scope, opening().supplierId, f.bills));
});
function agg05CreditShortageFixture(reviewed = true) {
  const f = agg05CreditGoodsFixture();
  f.line.expectedMilli = 1500; f.line.shortMilli = 500;
  const bill = {...f.bill, copy: {...f.bill.copy, draft: {...f.bill.copy.draft,
    goods: f.bill.copy.draft.goods.map((line, index) => index === 0 ? {...line, quantity: '1.5'} : line)}}};
  f.bills.set(bill.copy.draft.id, bill); f.ledger.purchaseBills = {[bill.copy.draft.id]: ledgerClone(bill)};
  const claim: Record<string, unknown> = {operationId: 'HOST-credit-shortage', accountScope: scope.account,
    workspaceId: scope.store, supplierId: opening().supplierId, billId: bill.copy.draft.id,
    copyId: bill.copy.id, copyRevision: bill.copy.revision, billLineIndex: 0, expectedDeliveryId: f.receipt.expectedDeliveryId,
    receiptLineId: f.line.sourceLineId, productId: f.line.productId, purchaseUnit: f.line.purchaseUnit,
    quantityMilli: 500, outstandingMilli: 500, priorClaimedMilli: 0, recordedAt: '2026-10-29T02:30:00.000Z',
    committedRevision: 5, receiptIds: [f.receipt.id], priorClaimIds: [], billAllocationIds: [f.link.operationId],
    ...(reviewed ? {requestedAt: '2026-10-29T02:25:00.000Z', openingId: opening().id, openingRevision: opening().revision} : {})};
  f.ledger.revision = 5; f.ledger.shortageClaims = {[String(claim.operationId)]: claim};
  return {...f, claim};
}
for (const reviewed of [true, false]) test('AGG05 credit original shortage reconstructs original snapshots ' + reviewed, () => {
  const f = agg05CreditShortageFixture(reviewed), before = ledgerCanonical(f.ledger);
  const source = ledgerSupplierCreditGoodsSource(f.ledger, scope, opening().supplierId, f.bills);
  assert.deepEqual(source.claims.get(String(f.claim.operationId)), f.claim);
  assert.equal(ledgerCanonical(f.ledger), before);
  if (process.env.AGG05_CREDIT_GOODS_CAPTURE_PATH) writeFileSync(process.env.AGG05_CREDIT_GOODS_CAPTURE_PATH + '.shortage-' + (reviewed ? 'reviewed' : 'legacy') + '.json',
    JSON.stringify({label: 'ISOLATED HOST SHORTAGE FORMAT; NO RUNTIME GOODS OR FINANCIAL AUTHORITY', scope, ledger: f.ledger,
      claimCount: source.claims.size, legacyCalendar: source.legacyCalendar}), {encoding: 'utf8', flag: 'wx'});
});
for (const [name, mutate] of [
  ['foreign owner', (f: ReturnType<typeof agg05CreditShortageFixture>) => {f.claim.accountScope = 'HOST-other';}],
  ['foreign Store', (f: ReturnType<typeof agg05CreditShortageFixture>) => {f.claim.workspaceId = 'HOST-other';}],
  ['foreign supplier', (f: ReturnType<typeof agg05CreditShortageFixture>) => {f.claim.supplierId = 'HOST-other';}],
  ['wrong identity', (f: ReturnType<typeof agg05CreditShortageFixture>) => {f.claim.operationId = 'HOST-other';}],
  ['wrong original copy', (f: ReturnType<typeof agg05CreditShortageFixture>) => {f.claim.copyId = 'HOST-other';}],
  ['wrong copy revision', (f: ReturnType<typeof agg05CreditShortageFixture>) => {f.claim.copyRevision = 999;}],
  ['future revision', (f: ReturnType<typeof agg05CreditShortageFixture>) => {f.claim.committedRevision = 6;}],
  ['future recorded time', (f: ReturnType<typeof agg05CreditShortageFixture>) => {f.claim.recordedAt = '2026-10-29T04:00:00.000Z';}],
  ['request before receipt', (f: ReturnType<typeof agg05CreditShortageFixture>) => {f.claim.requestedAt = '2026-10-29T02:05:00.000Z';}],
  ['request before allocation', (f: ReturnType<typeof agg05CreditShortageFixture>) => {f.claim.requestedAt = '2026-10-29T02:15:00.000Z';}],
  ['request after recording', (f: ReturnType<typeof agg05CreditShortageFixture>) => {f.claim.requestedAt = '2026-10-29T02:31:00.000Z';}],
  ['wrong opening', (f: ReturnType<typeof agg05CreditShortageFixture>) => {f.claim.openingId = 'HOST-other';}],
  ['wrong product', (f: ReturnType<typeof agg05CreditShortageFixture>) => {f.claim.productId = 'HOST-other';}],
  ['wrong pack', (f: ReturnType<typeof agg05CreditShortageFixture>) => {f.claim.purchaseUnit = 'HOST-other';}],
  ['wrong delivery', (f: ReturnType<typeof agg05CreditShortageFixture>) => {f.claim.expectedDeliveryId = 'HOST-other';}],
  ['empty receipt snapshot', (f: ReturnType<typeof agg05CreditShortageFixture>) => {f.claim.receiptIds = [];}],
  ['duplicate receipt', (f: ReturnType<typeof agg05CreditShortageFixture>) => {f.claim.receiptIds = [f.receipt.id, f.receipt.id];}],
  ['foreign receipt', (f: ReturnType<typeof agg05CreditShortageFixture>) => {f.claim.receiptIds = ['HOST-other'];}],
  ['omitted original allocation', (f: ReturnType<typeof agg05CreditShortageFixture>) => {f.claim.billAllocationIds = [];}],
  ['foreign allocation', (f: ReturnType<typeof agg05CreditShortageFixture>) => {f.claim.billAllocationIds = ['HOST-other'];}],
  ['invented prior claim', (f: ReturnType<typeof agg05CreditShortageFixture>) => {f.claim.priorClaimIds = ['HOST-other'];}],
  ['invented outstanding quantity', (f: ReturnType<typeof agg05CreditShortageFixture>) => {f.claim.outstandingMilli = 501;}],
  ['invented prior quantity', (f: ReturnType<typeof agg05CreditShortageFixture>) => {f.claim.priorClaimedMilli = 1;}],
  ['exceeded shortage', (f: ReturnType<typeof agg05CreditShortageFixture>) => {f.claim.quantityMilli = 501;}],
  ['incomplete reviewed original', (f: ReturnType<typeof agg05CreditShortageFixture>) => {delete f.claim.openingRevision;}],
  ['duplicate revision', (f: ReturnType<typeof agg05CreditShortageFixture>) => {(f.ledger.shortageClaims as Record<string, unknown>)['HOST-second-claim'] = {...ledgerClone(f.claim), operationId: 'HOST-second-claim'};}],
] as const) test('AGG05 credit original shortage refuses changed evidence: ' + name, () => {
  const f = agg05CreditShortageFixture(); mutate(f);
  assert.throws(() => ledgerSupplierCreditGoodsSource(f.ledger, scope, opening().supplierId, f.bills));
});
test('AGG05 credit original shortage accounts for prior claims once across group and bill', () => {
  const f = agg05CreditShortageFixture(); f.claim.quantityMilli = 250; f.ledger.revision = 6;
  const second: Record<string, unknown> = {...ledgerClone(f.claim), operationId: 'HOST-second-claim', committedRevision: 6,
    requestedAt: '2026-10-29T02:31:00.000Z', recordedAt: '2026-10-29T02:35:00.000Z',
    priorClaimedMilli: 250, priorClaimIds: [String(f.claim.operationId)]};
  (f.ledger.shortageClaims as Record<string, unknown>)[String(second.operationId)] = second;
  assert.equal(ledgerSupplierCreditGoodsSource(f.ledger, scope, opening().supplierId, f.bills).claims.size, 2);
  second.requestedAt = '2026-10-29T02:25:00.000Z';
  assert.throws(() => ledgerSupplierCreditGoodsSource(f.ledger, scope, opening().supplierId, f.bills));
  second.requestedAt = '2026-10-29T02:31:00.000Z';
  second.quantityMilli = 251;
  assert.throws(() => ledgerSupplierCreditGoodsSource(f.ledger, scope, opening().supplierId, f.bills));
});
test('AGG05 credit original shortage keeps later deliveries outside the frozen claim but rejects omitted earlier ones', () => {
  const f = agg05CreditShortageFixture();
  const later = {...ledgerClone(f.receipt), id: 'HOST-later-receipt', recordedAt: '2026-10-29T02:35:00.000Z',
    lines: [{...ledgerClone(f.line), deliveredMilli: 500, acceptedMilli: 500, damagedMilli: 0, shortMilli: 1000}]};
  (f.ledger.goodsReceipts as Record<string, unknown>)[later.id] = later;
  assert.equal(ledgerSupplierCreditGoodsSource(f.ledger, scope, opening().supplierId, f.bills).claims.size, 1);
  later.recordedAt = '2026-10-29T02:24:00.000Z';
  assert.throws(() => ledgerSupplierCreditGoodsSource(f.ledger, scope, opening().supplierId, f.bills));
});
test('AGG05 credit original shortage cannot exceed bill remainder even when delivery shortage is larger', () => {
  const f = agg05CreditShortageFixture();
  f.line.expectedMilli = 2000; f.line.shortMilli = 1000;
  f.claim.outstandingMilli = 1000; f.claim.quantityMilli = 1000;
  assert.throws(() => ledgerSupplierCreditGoodsSource(f.ledger, scope, opening().supplierId, f.bills));
});
function agg05OriginalCreditFixture(kind: 'goodsReturned' | 'arrivalDamage' | 'shortage' = 'arrivalDamage', treatment: 'gst' | 'commercial' = 'commercial') {
  const f = kind === 'shortage' ? agg05CreditShortageFixture() : kind === 'goodsReturned' ? agg05CreditReturnFixture() : agg05CreditGoodsFixture();
  const bill = [...f.bills.values()][0]!;
  const proof = checkedLedgerSupplierCreditProof({...agg05StructuredCreditInput(kind, treatment), supplierId: opening().supplierId,
    billId: bill.copy.draft.id, copyId: bill.copy.id, copyRevision: bill.copy.revision, openingId: opening().id,
    openingRevision: opening().revision, amountMinor: 100, requestedAt: '2026-10-29T02:40:00.000Z',
    recordedAt: '2026-10-29T02:45:00.000Z', committedRevision: 6,
    documentInput: {version: 1, treatment, reasonCode: kind === 'shortage' ? 'shortage' : kind === 'goodsReturned' ? 'return' : 'damage',
      taxRows: treatment === 'gst' ? [{rate: '0', taxable: '1.00', cgst: '0', sgst: '0', igst: '0', cess: '0'}] : []},
    supports: [{kind, receiptId: f.receipt.id, receiptLineId: f.line.sourceLineId, billLineIndex: 0, quantityMilli: 500,
      ...(kind === 'goodsReturned' ? {returnOperationId: 'HOST-credit-goods-return'} : {}),
      ...(kind === 'shortage' ? {shortageClaimId: 'HOST-credit-shortage'} : {})}]}, scope);
  f.ledger.revision = 6; f.ledger.creditNotes = {[proof.operationId]: proof};
  (f.ledger.entries as unknown[]).push(ledgerSupplierCreditEntry(proof));
  return {...f, proof};
}
for (const kind of ['goodsReturned', 'arrivalDamage', 'shortage'] as const) for (const treatment of ['gst', 'commercial'] as const)
  test('AGG05 credit original typed history preserves original source caps: ' + kind + ' ' + treatment, () => {
    const f = agg05OriginalCreditFixture(kind, treatment), before = ledgerCanonical(f.ledger);
    const history = ledgerSupplierCreditHistory(f.ledger, scope, opening().supplierId, f.bills);
    assert.deepEqual(history.credits.get(f.proof.operationId), f.proof); assert.equal(history.amounts.get(f.proof.billId), 100);
    assert.equal(ledgerCanonical(f.ledger), before);
    if (process.env.AGG05_CREDIT_HISTORY_CAPTURE_PATH) writeFileSync(process.env.AGG05_CREDIT_HISTORY_CAPTURE_PATH + '.' + kind + '-' + treatment + '.json',
      JSON.stringify({label: 'ISOLATED HOST CREDIT HISTORY FORMAT; NO ORIGINAL RECORDING OR TAX AUTHORITY', scope, ledger: f.ledger,
        creditCount: history.credits.size}), {encoding: 'utf8', flag: 'wx'});
  });
for (const [name, mutate] of [
  ['foreign supplier', (f: ReturnType<typeof agg05OriginalCreditFixture>) => {f.proof.supplierId = 'HOST-other';}],
  ['wrong original bill', (f: ReturnType<typeof agg05OriginalCreditFixture>) => {f.proof.billId = 'HOST-other';}],
  ['wrong original copy', (f: ReturnType<typeof agg05OriginalCreditFixture>) => {f.proof.copyId = 'HOST-other';}],
  ['wrong copy revision', (f: ReturnType<typeof agg05OriginalCreditFixture>) => {f.proof.copyRevision = 999;}],
  ['wrong opening', (f: ReturnType<typeof agg05OriginalCreditFixture>) => {f.proof.openingId = 'HOST-other';}],
  ['wrong opening revision', (f: ReturnType<typeof agg05OriginalCreditFixture>) => {f.proof.openingRevision = 999;}],
  ['future revision', (f: ReturnType<typeof agg05OriginalCreditFixture>) => {f.proof.committedRevision = 7;}],
  ['changed entry amount', (f: ReturnType<typeof agg05OriginalCreditFixture>) => {(f.ledger.entries as Record<string, unknown>[])[1]!.amountMinor = 101;}],
  ['missing entry', (f: ReturnType<typeof agg05OriginalCreditFixture>) => {(f.ledger.entries as unknown[]).pop();}],
  ['duplicate entry', (f: ReturnType<typeof agg05OriginalCreditFixture>) => {(f.ledger.entries as unknown[]).push(ledgerSupplierCreditEntry(f.proof));}],
  ['foreign receipt', (f: ReturnType<typeof agg05OriginalCreditFixture>) => {f.proof.supports[0]!.receiptId = 'HOST-other';}],
  ['foreign receipt line', (f: ReturnType<typeof agg05OriginalCreditFixture>) => {f.proof.supports[0]!.receiptLineId = 'HOST-other';}],
  ['foreign bill line', (f: ReturnType<typeof agg05OriginalCreditFixture>) => {f.proof.supports[0]!.billLineIndex = 1;}],
  ['excess source quantity', (f: ReturnType<typeof agg05OriginalCreditFixture>) => {f.proof.supports[0]!.quantityMilli = 501;}],
  ['missing original attribution', (f: ReturnType<typeof agg05OriginalCreditFixture>) => {f.ledger.billGoodsAllocations = {};}],
  ['later original attribution', (f: ReturnType<typeof agg05OriginalCreditFixture>) => {f.link.linkedAt = '2026-10-29T02:46:00.000Z';}],
] as const) test('AGG05 credit original typed history refuses changed evidence: ' + name, () => {
  const f = agg05OriginalCreditFixture(); mutate(f);
  assert.throws(() => ledgerSupplierCreditHistory(f.ledger, scope, opening().supplierId, f.bills));
});
test('AGG05 credit original typed history consumes repeated source quantities and references cumulatively', () => {
  const f = agg05OriginalCreditFixture(); f.proof.supports[0]!.quantityMilli = 250; f.ledger.revision = 7;
  const second = {...ledgerClone(f.proof), operationId: 'HOST-second-credit', reference: 'HOST-CN-2', committedRevision: 7,
    requestedAt: '2026-10-29T02:46:00.000Z', recordedAt: '2026-10-29T02:47:00.000Z'};
  (f.ledger.creditNotes as Record<string, unknown>)[second.operationId] = second;
  (f.ledger.entries as unknown[]).push(ledgerSupplierCreditEntry(second));
  assert.equal(ledgerSupplierCreditHistory(f.ledger, scope, opening().supplierId, f.bills).credits.size, 2);
  second.reference = f.proof.reference.toLowerCase(); (f.ledger.entries as unknown[])[2] = ledgerSupplierCreditEntry(second);
  assert.throws(() => ledgerSupplierCreditHistory(f.ledger, scope, opening().supplierId, f.bills));
  second.reference = 'HOST-CN-2'; (f.ledger.entries as unknown[])[2] = ledgerSupplierCreditEntry(second);
  second.supports[0]!.quantityMilli = 251;
  assert.throws(() => ledgerSupplierCreditHistory(f.ledger, scope, opening().supplierId, f.bills));
});
function agg05CreditSurplusFixture(kind: 'goodsReturned' | 'arrivalDamage' | 'shortage' = 'arrivalDamage', treatment: 'gst' | 'commercial' = 'commercial') {
  const f = agg05OriginalCreditFixture(kind, treatment), bill = [...f.bills.values()][0]!;
  const payment = checkedLedgerSupplierMoneyEntry({operationId: 'HOST-credit-funding', orderId: null, reference: 'HOST-payment-copy',
    origin: 'manualPurchase', purchaseId: bill.copy.id, billId: bill.copy.draft.id, paymentMethod: 'Cash', kind: 'payment', amountMinor: 1000,
    postedAt: '2026-10-29T02:30:00.000Z', moneyReview: {occurredOn: '2026-10-29', openingId: opening().id,
      openingRevision: opening().revision, notIncludedInOpening: true}});
  (f.ledger.entries as unknown[]).splice(1, 0, payment);
  const credits = ledgerSupplierCreditHistory(f.ledger, scope, opening().supplierId, f.bills).credits;
  const refunds = new Map<string, ReturnType<typeof checkedLedgerSupplierRefundProof>>();
  const allocations = new Map<string, ReturnType<typeof checkedLedgerSupplierAllocationProof>>();
  const surplus = (limit = (f.ledger.entries as unknown[]).length, revision = 7, time = '2026-10-29T03:00:00.000Z') =>
    ledgerSupplierBillSurplusAt(f.ledger, bill.copy.draft.id, limit, revision, time, f.bills, credits, refunds, allocations);
  return {...f, bill, payment, credits, refunds, allocations, surplus};
}
test('AGG05 credit original bill surplus uses paid and credited original entry prefix only', () => {
  const f = agg05CreditSurplusFixture(), before = ledgerCanonical(f.ledger);
  assert.equal(f.surplus(), 100); assert.equal(ledgerCanonical(f.ledger), before);
  f.payment.amountMinor = 900; assert.equal(f.surplus(), 0);
  f.payment.amountMinor = 1000;
  assert.equal(f.surplus(2, 6, '2026-10-29T02:40:00.000Z'), 0);
  if (process.env.AGG05_CREDIT_HISTORY_CAPTURE_PATH) writeFileSync(process.env.AGG05_CREDIT_HISTORY_CAPTURE_PATH + '.surplus.json',
    JSON.stringify({label: 'ISOLATED HOST BILL SURPLUS FORMAT; NO ORIGINAL FINANCIAL AUTHORITY', scope,
      ledger: f.ledger, billId: f.bill.copy.draft.id, amountMinor: f.surplus()}), {encoding: 'utf8', flag: 'wx'});
});
for (const [name, mutate] of [
  ['missing original bill entry', (f: ReturnType<typeof agg05CreditSurplusFixture>) => {(f.ledger.entries as unknown[]).shift();}],
  ['untyped credit', (f: ReturnType<typeof agg05CreditSurplusFixture>) => {f.credits.clear();}],
  ['future payment', (f: ReturnType<typeof agg05CreditSurplusFixture>) => {f.payment.postedAt = '2026-10-29T04:00:00.000Z';}],
  ['unreviewed payment', (f: ReturnType<typeof agg05CreditSurplusFixture>) => {delete (f.payment as unknown as Record<string, unknown>).moneyReview;}],
] as const) test('AGG05 credit original bill surplus refuses incomplete original prefix: ' + name, () => {
  const f = agg05CreditSurplusFixture(); mutate(f); assert.equal(f.surplus(), null);
});
test('AGG05 credit original bill surplus rejects later credits retroactively funding earlier prefixes', () => {
  const f = agg05CreditSurplusFixture();
  assert.equal(f.surplus(2, 7), null); assert.equal(f.surplus(3, 6), null);
  assert.equal(f.surplus(3, 7, '2026-10-29T02:44:00.000Z'), null);
  assert.equal(f.surplus(4), null); assert.equal(f.surplus(-1), null);
});
test('AGG05 credit original bill surplus subtracts prior returned and transferred amounts exactly once', () => {
  const f = agg05CreditSurplusFixture();
  // Isolated prefix arithmetic only: these shapes do not qualify a target bill or a refund command.
  const allocation = checkedLedgerSupplierAllocationProof({...agg05AllocationInput('manualBillSurplus'),
    sourceId: f.bill.copy.draft.id, sourceCopyId: f.bill.copy.id, sourceCopyRevision: f.bill.copy.revision,
    amountMinor: 25, requestedAt: '2026-10-29T02:46:00.000Z', recordedAt: '2026-10-29T02:47:00.000Z',
    committedRevision: 7, sourceEntryCount: 3}, scope);
  f.allocations.set(allocation.operationId, allocation);
  const intent = checkedLedgerSupplierRefundIntent({...refundCommand().intent, sourceKind: 'manualBillSurplus',
    sourceId: f.bill.copy.draft.id, copyId: f.bill.copy.id, copyRevision: f.bill.copy.revision,
    requestedAt: '2026-10-29T02:48:00.000Z', amountMinor: 50}, scope);
  const refund = checkedLedgerSupplierRefundProof({intent, recordedAt: '2026-10-29T02:49:00.000Z', committedRevision: 8}, scope);
  f.refunds.set(intent.operationId, refund); (f.ledger.entries as unknown[]).push(ledgerSupplierRefundEntry(refund));
  assert.equal(f.surplus(4, 9), 25);
  assert.equal(f.surplus(3, 8, '2026-10-29T02:48:00.000Z'), 75);
  assert.equal(f.surplus(3, 7, '2026-10-29T02:46:00.000Z'), 100);
  allocation.recordedAt = '2026-10-29T04:00:00.000Z';
  assert.equal(f.surplus(4, 9), null);
});
test('AGG05 credit financial history reconciles paid bill credit without inferring it from net balance', () => {
  const f = agg05CreditSurplusFixture(), before = ledgerCanonical(f.ledger);
  const history = ledgerSupplierFinancialHistory(f.ledger, scope, opening().supplierId);
  assert.equal(history.balance, -100); assert.equal(history.billRemaining(f.bill.copy.draft.id), -100);
  assert.equal(history.sourceAmount('manualBillSurplus', f.bill.copy.draft.id), 100);
  assert.equal(history.sourceAvailable('manualBillSurplus', f.bill.copy.draft.id), 100);
  assert.equal(history.credited.get(f.bill.copy.draft.id), 100); assert.equal(ledgerCanonical(f.ledger), before);
  if (process.env.AGG05_CREDIT_FINANCIAL_CAPTURE_PATH) writeFileSync(process.env.AGG05_CREDIT_FINANCIAL_CAPTURE_PATH + '.base.json',
    JSON.stringify({label: 'ISOLATED HOST FINANCIAL HISTORY FORMAT; NO ORIGINAL RECORDING AUTHORITY', ledger: f.ledger,
      sourceBillId: f.bill.copy.draft.id, balanceMinor: history.balance, remainingMinor: -100, availableMinor: 100}), {encoding: 'utf8', flag: 'wx'});
});
test('AGG05 credit financial history consumes original bill refund once and preserves remaining surplus', () => {
  const f = agg05CreditSurplusFixture();
  const intent = checkedLedgerSupplierRefundIntent({...refundCommand().intent, sourceKind: 'manualBillSurplus',
    sourceId: f.bill.copy.draft.id, copyId: f.bill.copy.id, copyRevision: f.bill.copy.revision,
    requestedAt: '2026-10-29T02:46:00.000Z', amountMinor: 50}, scope);
  const proof = checkedLedgerSupplierRefundProof({intent, recordedAt: '2026-10-29T02:47:00.000Z', committedRevision: 7}, scope);
  f.ledger.refunds = {[intent.operationId]: proof}; f.ledger.revision = 7;
  (f.ledger.entries as unknown[]).push(ledgerSupplierRefundEntry(proof));
  const history = ledgerSupplierFinancialHistory(f.ledger, scope, opening().supplierId);
  assert.equal(history.balance, -50); assert.equal(history.billRemaining(f.bill.copy.draft.id), -50);
  assert.equal(history.sourceAvailable('manualBillSurplus', f.bill.copy.draft.id), 50);
  assert.equal(history.used.get(history.sourceKey('manualBillSurplus', f.bill.copy.draft.id)), 50);
  if (process.env.AGG05_CREDIT_FINANCIAL_CAPTURE_PATH) writeFileSync(process.env.AGG05_CREDIT_FINANCIAL_CAPTURE_PATH + '.refund.json',
    JSON.stringify({label: 'ISOLATED HOST FINANCIAL HISTORY FORMAT; NO ORIGINAL RECORDING AUTHORITY', ledger: f.ledger,
      sourceBillId: f.bill.copy.draft.id, balanceMinor: history.balance, remainingMinor: -50, availableMinor: 50}), {encoding: 'utf8', flag: 'wx'});
  proof.intent.copyRevision = Number(proof.intent.copyRevision) + 1;
  assert.throws(() => ledgerSupplierFinancialHistory(f.ledger, scope, opening().supplierId));
});
test('AGG05 credit financial history transfers only original prefix surplus to another accepted bill', () => {
  const f = agg05CreditSurplusFixture();
  const target = checkedLedgerSupplierBillAcceptance({...ledgerClone(f.bill), acceptedAt: '2026-10-29T02:35:00.000Z',
    copy: {...ledgerClone(f.bill.copy), id: 'HOST-target-bill-copy', draft: {...ledgerClone(f.bill.copy.draft),
      id: 'HOST-target-bill-draft', invoiceReference: 'HOST-INV-2'}}});
  (f.ledger.purchaseBills as Record<string, unknown>)[target.copy.draft.id] = target;
  (f.ledger.entries as unknown[]).splice(2, 0, ledgerBillLiabilityEntry(target));
  const link = checkedLedgerSupplierAllocationProof({...agg05AllocationInput('manualBillSurplus'), amountMinor: 25,
    sourceId: f.bill.copy.draft.id, sourceCopyId: f.bill.copy.id, sourceCopyRevision: f.bill.copy.revision,
    billId: target.copy.draft.id, copyId: target.copy.id, copyRevision: target.copy.revision,
    requestedAt: '2026-10-29T02:46:00.000Z', recordedAt: '2026-10-29T02:47:00.000Z', committedRevision: 7, sourceEntryCount: 4}, scope);
  f.ledger.billMoneyAllocations = {[link.operationId]: link}; f.ledger.revision = 7;
  const history = ledgerSupplierFinancialHistory(f.ledger, scope, opening().supplierId);
  assert.equal(history.balance, 900); assert.equal(history.billRemaining(f.bill.copy.draft.id), -75);
  assert.equal(history.billRemaining(target.copy.draft.id), 975);
  assert.equal(history.sourceAvailable('manualBillSurplus', f.bill.copy.draft.id), 75);
  if (process.env.AGG05_CREDIT_FINANCIAL_CAPTURE_PATH) writeFileSync(process.env.AGG05_CREDIT_FINANCIAL_CAPTURE_PATH + '.transfer.json',
    JSON.stringify({label: 'ISOLATED HOST FINANCIAL HISTORY FORMAT; NO ORIGINAL RECORDING AUTHORITY', ledger: f.ledger,
      sourceBillId: f.bill.copy.draft.id, balanceMinor: history.balance, remainingMinor: -75, availableMinor: 75,
      targetBillId: target.copy.draft.id, targetRemainingMinor: 975}), {encoding: 'utf8', flag: 'wx'});
  link.sourceEntryCount = 3;
  assert.throws(() => ledgerSupplierFinancialHistory(f.ledger, scope, opening().supplierId));
});
async function sdkCreditHistoryFixture(withCredit = true, kind: 'goodsReturned' | 'arrivalDamage' | 'shortage' = 'arrivalDamage',
  treatment: 'gst' | 'commercial' = 'commercial', withTarget = false) {
  const f = await sdkLedger(), sample = agg05CreditSurplusFixture(kind, treatment);
  try {
    if (!withCredit) {
      sample.ledger.creditNotes = {}; sample.ledger.revision = 5;
      sample.ledger.entries = (sample.ledger.entries as Record<string, unknown>[]).filter(entry => entry.operationId !== sample.proof.operationId);
    }
    if (withTarget) {
      const target = checkedLedgerSupplierBillAcceptance({...sample.bill, acceptedAt: '2026-10-29T02:50:00.000Z',
        copy: {...sample.bill.copy, id: 'HOST-credit-target-copy', draft: {...sample.bill.copy.draft,
          id: 'HOST-credit-target-bill', invoiceReference: 'HOST-INV-TARGET'}}});
      sample.bills.set(target.copy.draft.id, target);
      (sample.ledger.purchaseBills as Record<string, unknown>)[target.copy.draft.id] = ledgerClone(target);
      (sample.ledger.entries as unknown[]).push(ledgerBillLiabilityEntry(target)!);
      sample.ledger.revision = Number(sample.ledger.revision) + 1;
    }
    // Independent, labelled HOST original history. No runtime producer, phone data or live authority is injected.
    const value = sample.ledger, kind = 'supplierLedger', id = opening().supplierId, revision = Number(value.revision);
    const json = ledgerCanonical(value), fingerprint = ledgerHash(value), bytes = Buffer.from(json);
    const payload = {id: ledgerHash({scope, kind, id, parentId: null, revision, fingerprint}), fingerprint, byteLength: bytes.length, parts: 1};
    const ref = f.root.collection('payloads').doc(payload.id);
    const manifest = {schemaVersion: 1, projectId: f.user.projectId, scope, kind, id, parentId: null, revision, ordinal: null, payload};
    await ref.collection('parts').doc('0000000000').create({schemaVersion: 1, index: 0, data: bytes.toString('base64'),
      fingerprint: createHash('sha256').update(bytes).digest('hex')});
    await ref.create(manifest);
    const batch = f.db.batch();
    batch.create(f.root, {schemaVersion: 1, projectId: f.user.projectId, scope, revision,
      counts: {supplierLedger: 1, expense: 0, moneyRegister: 0, moneyEntry: 0}, updatedAt: value.asOf});
    batch.create(f.root.collection(kind).doc(ledgerHash({id})), {...manifest, writeRevision: revision});
    batch.create(f.root.collection('recordIdentities').doc(ledgerHash({kind, id, parent: null})),
      {schemaVersion: 1, projectId: f.user.projectId, scope, kind, id, parentId: null});
    await batch.commit();
    const book: PurchaseEntryBook = {...originalOpeningBook(), revision: 3, copies: [...sample.bills.values()].map(bill => bill.copy)};
    const original = await seedOriginalPurchase(f, book);
    const clock = () => new Date('2026-10-29T04:00:00.000Z');
    const repo = () => new FirestoreWorkspaceLedgerRepository(f.db, 'evaluation', f.user.projectId, f.authority, original.repository.ledgerAnchor(), clock);
    return {...f, sample, clock, repo, book, original};
  } catch (error) {await f.close(); throw error;}
}
test('AGG05 SDK credit financial history bounds original refund and lost-reply status after restart', {skip: !ledgerEmulator}, async () => {
  const f = await sdkCreditHistoryFixture();
  try {
    const intent = checkedLedgerSupplierRefundIntent({...refundCommand().intent, sourceKind: 'manualBillSurplus',
      sourceId: f.sample.bill.copy.draft.id, copyId: f.sample.bill.copy.id, copyRevision: f.sample.bill.copy.revision,
      requestedAt: '2026-10-29T03:30:00.000Z', amountMinor: 50}, scope);
    const command = resign({...refundCommand(), expectedRevision: 6, expectedSupplierRevision: 6, intent});
    const service = new WorkspaceLedgerService(f.repo(), f.clock), response = await service.handle(f.user, command.operation, body(command));
    assert.equal((response as {attempt: LedgerReceipt}).attempt.status, 'saved');
    const current = JSON.parse((response as {current: LedgerRow}).current.json);
    assert.deepEqual(current.creditNotes, f.sample.ledger.creditNotes); assert.deepEqual(current.goodsReceipts, f.sample.ledger.goodsReceipts);
    const history = ledgerSupplierFinancialHistory(current, scope, command.supplierId);
    assert.equal(history.balance, -50); assert.equal(history.sourceAvailable('manualBillSurplus', intent.sourceId), 50);
    const restarted = new WorkspaceLedgerService(f.repo(), f.clock);
    assert.deepEqual(await restarted.handle(f.user, 'readStoreLedgerAttempt', {schemaVersion: 1, ledgerVersion: 1,
      operation: 'readStoreLedgerAttempt', scope, idempotencyKey: command.idempotencyKey, fingerprint: command.fingerprint}), response);
    assert.deepEqual(await restarted.handle(f.user, command.operation, body(command)), response);
  } finally {await f.close();}
});
test('AGG05 SDK credit financial history refuses payment beyond credited bill remainder', {skip: !ledgerEmulator}, async () => {
  const f = await sdkCreditHistoryFixture();
  try {
    const before = ledgerHash((await f.repo().list(f.user, scope, 'supplierLedger', null, null)).rows);
    const command = resign({...supplierMoneyCommand(), expectedRevision: 6, expectedSupplierRevision: 6,
      entry: {...supplierMoneyCommand().entry, operationId: 'HOST-credit-overpayment', origin: 'manualPurchase' as const,
        billId: f.sample.bill.copy.draft.id, purchaseId: f.sample.bill.copy.id, amountMinor: 1, postedAt: '2026-10-29T03:30:00.000Z'}});
    const response = await new WorkspaceLedgerService(f.repo(), f.clock).handle(f.user, command.operation, body(command));
    assert.equal((response as {attempt: LedgerReceipt}).attempt.status, 'not_saved');
    assert.equal((response as {attempt: LedgerReceipt}).attempt.reason, 'supplier_capacity_changed');
    assert.equal(ledgerHash((await f.repo().list(f.user, scope, 'supplierLedger', null, null)).rows), before);
  } finally {await f.close();}
});
function sdkSurplusPreparation(f: Awaited<ReturnType<typeof sdkCreditHistoryFixture>>) {
  const authority = {async read() {return {revision: 'HOST-surplus-owner',
    validUntil: new Date(f.clock().getTime() + 120000).toISOString(), modelContext: {audience: 'workspace', current: {id: scope.store}},
    tools: [{name: 'HOST-surplus-approved-owner', actionId: 'AI-ACT-317', entityId: scope.store,
      sourceRevision: 'HOST-surplus-approved', description: 'Isolated HOST authority only',
      parameters: {type: 'object', properties: {}, required: [], additionalProperties: false}, validate: () => true}]};}};
  const calls: string[] = [], service = new WorkspaceLedgerService(f.repo(), f.clock);
  const source = new OriginalStoreLedgerPreparationContext({realm: 'evaluation', authority, now: f.clock,
    purchase: new WorkspacePurchaseEntryService(f.original.repository, f.clock), ledger: {async handle(who, operation, input) {
      calls.push(operation); assert.equal(operation, 'readStoreLedgerSource'); return service.handle(who, operation, input);
    }}});
  const input: PreparationRequest = {scope: {audience: 'workspace', storeId: scope.store}, requestId: 'HOST-surplus-review',
    requestRevision: 1, message: 'Review original bill credit', language: 'English', history: [],
    actionId: null, entityId: null, expectedEntitlementRevision: 'HOST-surplus-owner'};
  return {source, input, calls};
}
test('AGG05 SDK surplus original refund preparation and exhausted-source recovery keep copy identity', {skip: !ledgerEmulator}, async () => {
  const f = await sdkCreditHistoryFixture(), prep = sdkSurplusPreparation(f);
  try {
    const copy = f.sample.bill.copy, entity = 'ledger-refund:' + ledgerHash([opening().supplierId, 'manualBillSurplus', copy.draft.id, copy.id]);
    const input = {...prep.input, actionId: 'AI-ACT-266', entityId: entity}, context = await prep.source.read(f.user, input);
    const tool = context.tools.find(tool => tool.actionId === 'AI-ACT-266')!; assert(tool); assertStrictSchema(tool.parameters);
    const fields = {supplierId: opening().supplierId, openingId: opening().id, openingRevision: opening().revision,
      sourceKind: 'manualBillSurplus', sourceId: copy.draft.id, copyId: copy.id, copyRevision: copy.revision,
      amount: '0.50', reference: 'HOST original refund receipt', channel: 'Cash', occurredOn: '2026-10-29'};
    assert(tool.validate(fields)); const target = tool.resolveTarget!(fields);
    assert.deepEqual(target.fields, fields);
    for (const invalid of [{...fields, copyId: 'HOST-foreign'}, {...fields, copyRevision: 999},
      {...fields, amount: '1.01'}, {...fields, occurredOn: '2026-10-28'}, {...fields, operationId: 'HOST-model-nonce'}]) assert(!tool.validate(invalid));
    assert.equal((await f.root.collection('attempts').get()).size, 0);
    const capture = (action: string, request: PreparationRequest, context: Awaited<ReturnType<typeof prep.source.read>>,
      target: ReturnType<NonNullable<typeof tool.resolveTarget>>) => {
      if (process.env.AGG05_SURPLUS_CONTEXT_CAPTURE_PATH) writeFileSync(process.env.AGG05_SURPLUS_CONTEXT_CAPTURE_PATH + '.' + action + '.json',
        JSON.stringify({label: 'ISOLATED SDK ORIGINAL BILL SURPLUS; NO RUNTIME AUTHORITY', actor: f.user, request,
          metadata: {ok: true, data: canonicalContextProjection(f.user, request.scope, context, 1)},
          proposal: {actionId: action, entityId: target.entityId, sourceRevision: target.sourceRevision, fields: target.fields}}),
        {encoding: 'utf8', flag: 'wx'});
    };
    capture('AI-ACT-266', input, context, target);
    const intent = checkedLedgerSupplierRefundIntent({...refundCommand().intent, sourceKind: 'manualBillSurplus', sourceId: copy.draft.id,
      copyId: copy.id, copyRevision: copy.revision, requestedAt: '2026-10-29T03:30:00.000Z', amountMinor: 100}, scope);
    const command = resign({...refundCommand(), expectedRevision: 6, expectedSupplierRevision: 6,
      idempotencyKey: 'HOST-surplus-fully-returned', intent});
    assert.equal((await f.repo().recordSupplierRefund(f.user, command)).receipt?.status, 'saved');
    await assert.rejects(prep.source.read(f.user, input), error => (error as {code?: string}).code === 'context_unavailable');
    for (const action of ['AI-ACT-267', 'AI-ACT-378']) {
      const request = {...input, actionId: action}, context = await prep.source.read(f.user, request);
      const tool = context.tools.find(tool => tool.actionId === action)!; assert(tool); assertStrictSchema(tool.parameters);
      assert(tool.validate({})); assert(!tool.validate({operationId: 'HOST-model-nonce'}));
      capture(action, request, context, tool.resolveTarget!({}));
    }
    assert.equal((await f.root.collection('attempts').get()).size, 1);
    assert(prep.calls.every(operation => operation === 'readStoreLedgerSource'));
  } finally {await f.close();}
});
test('AGG05 SDK surplus original allocation prepares exact source and records one prefix-qualified attribution', {skip: !ledgerEmulator}, async () => {
  const f = await sdkCreditHistoryFixture(true, 'arrivalDamage', 'commercial', true), prep = sdkSurplusPreparation(f);
  try {
    const original = f.sample.bill.copy, target = [...f.sample.bills.values()].find(bill => bill.copy.id !== original.id)!.copy;
    const input = {...prep.input, actionId: 'AI-ACT-262', entityId: target.id}, context = await prep.source.read(f.user, input);
    const tool = context.tools.find(tool => tool.actionId === 'AI-ACT-262')!; assert(tool); assertStrictSchema(tool.parameters);
    const fields = {supplierId: opening().supplierId, copyId: target.id, copyRevision: target.revision,
      openingId: opening().id, openingRevision: opening().revision, sourceKind: 'manualBillSurplus',
      sourceId: original.draft.id, amount: '0.50'};
    assert(tool.validate(fields)); const prepared = tool.resolveTarget!(fields); assert.deepEqual(prepared.fields, fields);
    assert(!tool.validate({...fields, sourceId: target.draft.id})); assert(!tool.validate({...fields, copyId: original.id}));
    assert(!tool.validate({...fields, operationId: 'HOST-model-nonce'})); assert.equal((await f.root.collection('attempts').get()).size, 0);
    if (process.env.AGG05_SURPLUS_CONTEXT_CAPTURE_PATH) writeFileSync(process.env.AGG05_SURPLUS_CONTEXT_CAPTURE_PATH + '.AI-ACT-262.json',
      JSON.stringify({label: 'ISOLATED SDK ORIGINAL BILL SURPLUS; NO RUNTIME AUTHORITY', actor: f.user, request: input,
        metadata: {ok: true, data: canonicalContextProjection(f.user, input.scope, context, 1)},
        proposal: {actionId: 'AI-ACT-262', entityId: prepared.entityId, sourceRevision: prepared.sourceRevision, fields: prepared.fields}}),
      {encoding: 'utf8', flag: 'wx'});
    const intent = checkedLedgerSupplierAllocationIntent({operationId: 'HOST-surplus-attribution', accountScope: scope.account,
      workspaceId: scope.store, supplierId: opening().supplierId, openingId: opening().id, openingRevision: opening().revision,
      sourceKind: 'manualBillSurplus', sourceId: original.draft.id, sourceCopyId: original.id, sourceCopyRevision: original.revision,
      billId: target.draft.id, copyId: target.id, copyRevision: target.revision, amountMinor: 50, requestedAt: '2026-10-29T03:30:00.000Z'}, scope);
    const command = resign({operation: 'recordStoreSupplierMoneyAllocation' as const, scope, expectedRevision: 7,
      expectedSupplierRevision: 7, supplierId: opening().supplierId, idempotencyKey: 'HOST-surplus-original-request', fingerprint: '', intent});
    const result = await f.repo().allocateSupplierMoney(f.user, command); assert.equal(result.receipt?.status, 'saved');
    const ledger = JSON.parse(result.current!.json), link = ledger.billMoneyAllocations[intent.operationId];
    assert.equal(link.sourceEntryCount, 4); assert.equal(link.sourceCopyId, original.id); assert.equal(link.sourceCopyRevision, original.revision);
    assert.deepEqual(await f.repo().allocateSupplierMoney(f.user, command), result);
    const history = ledgerSupplierFinancialHistory(ledger, scope, opening().supplierId);
    assert.equal(history.sourceAvailable('manualBillSurplus', original.draft.id), 50);
    assert.equal(history.balance, 900); assert.equal((await f.root.collection('attempts').get()).size, 1);
  } finally {await f.close();}
});
function sdkCreditCommand(f: Awaited<ReturnType<typeof sdkCreditHistoryFixture>>) {
  return resign({scope, operation: 'recordStoreSupplierCreditNote' as const, supplierId: opening().supplierId,
    expectedRevision: 5, expectedSupplierRevision: 5, expectedPurchaseRevision: f.book.revision,
    expectedPurchaseFingerprint: ledgerHash(f.book), idempotencyKey: 'HOST-original-credit-request', fingerprint: '',
    intent: {...ledgerSupplierCreditInput(f.sample.proof), requestedAt: '2026-10-29T03:30:00.000Z'}, confirmedUtcOffsetMinutes: 330});
}
for (const kind of ['goodsReturned', 'arrivalDamage', 'shortage'] as const) for (const treatment of ['gst', 'commercial'] as const)
  test('AGG05 SDK credit AI preparation keeps original document, selectors and native confirmation: ' + kind + ' ' + treatment,
    {skip: !ledgerEmulator}, async () => {
      const f = await sdkCreditHistoryFixture(false, kind, treatment);
      try {
        const authority = {async read() {return {revision: 'HOST-credit-paid-approved-port',
          validUntil: new Date(f.clock().getTime() + 120000).toISOString(), modelContext: {audience: 'workspace', current: {id: scope.store}},
          tools: [{name: 'HOST-original-credit-owner', actionId: 'AI-ACT-317', entityId: scope.store,
            sourceRevision: 'HOST-approved-owner', description: 'Isolated host authority only',
            parameters: {type: 'object', properties: {}, required: [], additionalProperties: false}, validate: () => true}]};}};
        const calls: string[] = [], service = new WorkspaceLedgerService(f.repo(), f.clock);
        const source = new OriginalStoreLedgerPreparationContext({realm: 'evaluation', authority, now: f.clock,
          purchase: new WorkspacePurchaseEntryService(f.original.repository, f.clock),
          ledger: {async handle(who, operation, input) {
            calls.push(operation); assert.equal(operation, 'readStoreLedgerSource'); return service.handle(who, operation, input);
          }}});
        const action = treatment === 'gst' ? 'AI-ACT-375' : 'AI-ACT-376', copy = f.sample.bill.copy;
        const input: PreparationRequest = {scope: {audience: 'workspace', storeId: scope.store}, requestId: 'HOST-credit-ai-prepare',
          requestRevision: 1, message: 'Review the credit note printed on the original copy', language: 'Hindi', history: [],
          actionId: action, entityId: copy.id, expectedEntitlementRevision: 'HOST-credit-paid-approved-port'};
        const before = ledgerHash((await f.root.get()).data());
        const context = await source.read(f.user, input), tool = context.tools.find(tool => tool.actionId === action)!;
        assert(tool); assertStrictSchema(tool.parameters);
        const available = ledgerSupplierAvailableCreditSupports(f.sample.ledger, scope, opening().supplierId, copy.draft.id, f.sample.bills);
        const support = available.find(row => row.support.kind === kind)!; assert(support);
        const printed = {supplierName: 'HOST printed supplier', invoiceReferences: copy.draft.invoiceReference};
        const document = {...f.sample.proof.documentInput, version: 2, particulars: printed};
        const fields = {supplierId: opening().supplierId, copyId: copy.id, billId: copy.draft.id, copyRevision: copy.revision,
          openingId: opening().id, openingRevision: opening().revision, reference: 'HOST-CN-ગુજરાતી', amount: '1.00',
          reason: 'HOST original reason', occurredOn: '2026-10-29', documentInput: document,
          supports: [{id: support.id, quantity: '0.250'}]};
        assert(tool.validate(fields));
        const modelFields = {...fields, documentInput: {...document,
          particulars: {...Object.fromEntries(Object.keys(ledgerSupplierCreditParticularLimits).map(key => [key, null])), ...printed}}};
        const target = tool.resolveTarget!(modelFields);
        assert.deepEqual(target.fields, fields);
        assert.equal(target.sourceRevision, 'store-original-ledger-v1:' + ledgerHash([
          scope.account, scope.store, scope.realm, 5, f.book.revision, action, copy.id]));
        const capture = (actionId: string, request: PreparationRequest, context: Awaited<ReturnType<typeof source.read>>,
          target: ReturnType<NonNullable<typeof tool.resolveTarget>>) => {
          if (!process.env.AGG05_CREDIT_CONTEXT_CAPTURE_PATH) return;
          writeFileSync(process.env.AGG05_CREDIT_CONTEXT_CAPTURE_PATH + '.' + kind + '.' + treatment + '.' + actionId + '.json',
            JSON.stringify({label: 'ISOLATED SDK ORIGINAL CREDIT PREPARATION; NO MODEL REQUEST ID OR FINANCIAL EFFECT',
              actor: f.user, request, metadata: {ok: true, data: canonicalContextProjection(f.user, request.scope, context, 1)},
              proposal: {actionId, entityId: target.entityId, sourceRevision: target.sourceRevision, fields: target.fields}}),
            {encoding: 'utf8', flag: 'wx'});
        };
        capture(action, input, context, target);
        const genericRequest = {...input, actionId: 'AI-ACT-264'}, generic = await source.read(f.user, genericRequest);
        const genericTool = generic.tools.find(tool => tool.actionId === 'AI-ACT-264')!; assert(genericTool);
        assertStrictSchema(genericTool.parameters); assert(genericTool.validate(fields));
        capture('AI-ACT-264', genericRequest, generic, genericTool.resolveTarget!(modelFields));
        for (const invalid of [
          {...fields, copyId: 'HOST-foreign-copy'}, {...fields, copyRevision: 999}, {...fields, operationId: 'HOST-model-nonce'},
          {...fields, occurredOn: '2026-02-30'}, {...fields, supports: [{id: 'HOST-guessed-source', quantity: '0.25'}]},
          {...fields, supports: [{id: support.id, quantity: '0.501'}]},
          {...fields, supports: [...fields.supports, ...fields.supports]},
          {...fields, documentInput: {...document, particulars: {inventedAuthority: 'approved'}}},
          {...fields, documentInput: {...document, treatment: treatment === 'gst' ? 'commercial' : 'gst'}},
        ]) assert.equal(tool.validate(invalid), false);
        const draft = {...fields, supports: [], documentInput: {...document, reasonCode: 'price'}};
        assert(tool.validate(draft), 'Original nonphysical printed input may prepare a draft; no money is posted.');
        for (const recovery of ['AI-ACT-265', 'AI-ACT-379']) {
          const result = await source.read(f.user, {...input, actionId: recovery});
          const recover = result.tools.find(tool => tool.actionId === recovery)!; assert(recover);
          assertStrictSchema(recover.parameters); assert(recover.validate({})); assert(!recover.validate({operationId: 'HOST-model-nonce'}));
          const target = recover.resolveTarget!({}); assert.deepEqual(target.fields, {});
          capture(recovery, {...input, actionId: recovery}, result, target);
        }
        assert.equal(ledgerHash((await f.root.get()).data()), before);
        assert.equal((await f.root.collection('attempts').get()).size, 0);
        assert(calls.length > 0); assert(calls.every(operation => operation === 'readStoreLedgerSource'));
      } finally {await f.close();}
    });
for (const kind of ['goodsReturned', 'arrivalDamage', 'shortage'] as const) for (const treatment of ['gst', 'commercial'] as const)
  test('AGG05 SDK credit original command records exact document once and recovers original status: ' + kind + ' ' + treatment,
    {skip: !ledgerEmulator}, async () => {
      const f = await sdkCreditHistoryFixture(false, kind, treatment);
      try {
        const command = sdkCreditCommand(f), bookBefore = ledgerHash((await f.original.root.get()).data());
        assert.deepEqual(checkedLedgerCommand(command), command);
        const service = new WorkspaceLedgerService(f.repo(), f.clock), response = await service.handle(f.user, command.operation, body(command));
        const receipt = (response as {attempt: LedgerReceipt}).attempt, current = JSON.parse((response as {current: LedgerRow}).current.json);
        assert.equal(receipt.status, 'saved'); assert.equal(receipt.changed, true); assert.equal(receipt.inputFingerprint, ledgerHash(command.intent));
        const proof = checkedLedgerSupplierCreditProof(current.creditNotes[command.intent.operationId], scope);
        assert.deepEqual(proof, {...command.intent, committedRevision: 6, recordedAt: f.clock().toISOString()});
        assert.deepEqual(current.entries, [...f.sample.ledger.entries as unknown[], ledgerSupplierCreditEntry(proof)]);
        for (const field of ['purchaseBills', 'goodsReceipts', 'goodsReturns', 'billGoodsAllocations', 'shortageClaims']) {
          assert.deepEqual(current[field], f.sample.ledger[field]);
        }
        assert.equal(ledgerHash((await f.original.root.get()).data()), bookBefore);
        assert.equal(ledgerSupplierFinancialHistory(current, scope, command.supplierId).balance, -100);
        if (process.env.AGG05_CREDIT_COMMAND_CAPTURE_PATH) writeFileSync(process.env.AGG05_CREDIT_COMMAND_CAPTURE_PATH + '.' + kind + '-' + treatment + '.json',
          JSON.stringify({label: 'ISOLATED ACTUAL SDK CREDIT COMMAND; NO RUNTIME FINANCIAL AUTHORITY', command, status: response,
            now: f.clock().toISOString()}), {encoding: 'utf8', flag: 'wx'});
        const restarted = new WorkspaceLedgerService(f.repo(), f.clock);
        assert.deepEqual(await restarted.handle(f.user, command.operation, body(command)), response);
        assert.deepEqual(await restarted.handle(f.user, 'readStoreLedgerAttempt', {schemaVersion: 1, ledgerVersion: 1,
          operation: 'readStoreLedgerAttempt', scope, idempotencyKey: command.idempotencyKey, fingerprint: command.fingerprint}), response);
        const noOp = await f.repo().recordSupplierCredit(f.user, resign({...command, idempotencyKey: 'HOST-credit-fact-recheck'}));
        assert.equal(noOp.receipt?.changed, false); assert.equal(noOp.receipt?.status, 'saved');
        const conflict = await f.repo().recordSupplierCredit(f.user, resign({...command, idempotencyKey: 'HOST-credit-divergent',
          intent: {...command.intent, amountMinor: 101}}));
        assert.equal(conflict.receipt?.reason, 'record_identity_conflict');
      } finally {await f.close();}
    });
for (const [name, mutate, reason] of [
  ['global revision', (command: ReturnType<typeof sdkCreditCommand>) => {command.expectedRevision = 4;}, 'stale_ledger'],
  ['supplier revision', (command: ReturnType<typeof sdkCreditCommand>) => {command.expectedSupplierRevision = 4;}, 'stale_supplier'],
  ['purchase revision', (command: ReturnType<typeof sdkCreditCommand>) => {command.expectedPurchaseRevision = 4;}, 'stale_evidence'],
  ['opening revision', (command: ReturnType<typeof sdkCreditCommand>) => {command.intent.openingRevision += 1;}, 'opening_evidence_changed'],
  ['copy revision', (command: ReturnType<typeof sdkCreditCommand>) => {command.intent.copyRevision += 1;}, 'credit_source_changed'],
  ['source quantity', (command: ReturnType<typeof sdkCreditCommand>) => {command.intent.supports[0]!.quantityMilli = 501;}, 'credit_source_changed'],
  ['bill amount cap', (command: ReturnType<typeof sdkCreditCommand>) => {command.intent.amountMinor = 1001;}, 'credit_capacity_changed'],
  ['future printed day', (command: ReturnType<typeof sdkCreditCommand>) => {command.intent.occurredOn = '2026-10-30';}, 'credit_confirmation_invalid'],
  ['future request', (command: ReturnType<typeof sdkCreditCommand>) => {command.intent.requestedAt = '2026-10-29T05:00:00.000Z';}, 'credit_confirmation_invalid'],
  ['price-only contract', (command: ReturnType<typeof sdkCreditCommand>) => {command.intent.documentInput.reasonCode = 'price';}, 'credit_source_changed'],
  ['tax-only contract', (command: ReturnType<typeof sdkCreditCommand>) => {command.intent.documentInput.reasonCode = 'tax';}, 'credit_source_changed'],
  ['discount-only contract', (command: ReturnType<typeof sdkCreditCommand>) => {command.intent.documentInput.reasonCode = 'discount';}, 'credit_source_changed'],
  ['unspecified contract', (command: ReturnType<typeof sdkCreditCommand>) => {command.intent.documentInput.reasonCode = 'other';}, 'credit_source_changed'],
  ['incomplete GST rows', (command: ReturnType<typeof sdkCreditCommand>) => {command.intent.documentInput.treatment = 'gst'; command.intent.documentInput.taxRows = [];}, 'credit_confirmation_invalid'],
  ['GST printed amount mismatch', (command: ReturnType<typeof sdkCreditCommand>) => {command.intent.documentInput.treatment = 'gst';
    command.intent.documentInput.taxRows = [{rate: '0', taxable: '2.00', cgst: '0', sgst: '0', igst: '0', cess: '0'}];}, 'credit_confirmation_invalid'],
] as const) test('AGG05 SDK credit original command refuses changed reviewed evidence: ' + name, {skip: !ledgerEmulator}, async () => {
  const f = await sdkCreditHistoryFixture(false);
  try {
    const before = ledgerHash((await f.repo().list(f.user, scope, 'supplierLedger', null, null)).rows);
    const command = sdkCreditCommand(f); mutate(command);
    const result = await f.repo().recordSupplierCredit(f.user, resign(command));
    assert.equal(result.receipt?.status, 'not_saved'); assert.equal(result.receipt?.reason, reason);
    assert.equal(ledgerHash((await f.repo().list(f.user, scope, 'supplierLedger', null, null)).rows), before);
    if (name === 'copy revision' && process.env.AGG05_CREDIT_COMMAND_CAPTURE_PATH) {
      const status = await new WorkspaceLedgerService(f.repo(), f.clock).handle(f.user, 'readStoreLedgerAttempt', {
        schemaVersion: 1, ledgerVersion: 1, operation: 'readStoreLedgerAttempt', scope,
        idempotencyKey: command.idempotencyKey, fingerprint: resign(command).fingerprint});
      writeFileSync(process.env.AGG05_CREDIT_COMMAND_CAPTURE_PATH + '.refused-copy-revision.json',
        JSON.stringify({label: 'ISOLATED ACTUAL SDK CREDIT COMMAND; NO RUNTIME FINANCIAL AUTHORITY', command: resign(command), status,
          now: f.clock().toISOString()}), {encoding: 'utf8', flag: 'wx'});
    }
  } finally {await f.close();}
});
test('AGG05 SDK credit original command recovers lost committed acknowledgement without another effect', {skip: !ledgerEmulator}, async () => {
  const f = await sdkCreditHistoryFixture(false), command = sdkCreditCommand(f);
  const run = f.db.runTransaction.bind(f.db); let lost = false;
  try {
    const attempt = f.root.collection('attempts').doc(ledgerHash({key: command.idempotencyKey}));
    f.db.runTransaction = (async (...args: Parameters<typeof f.db.runTransaction>) => {
      const result = await run(...args);
      if (!lost && (await attempt.get()).exists) {lost = true; throw new Error('HOST lost credit commit acknowledgement');}
      return result;
    }) as typeof f.db.runTransaction;
    const result = await f.repo().recordSupplierCredit(f.user, command);
    assert.equal(lost, true); assert.equal(result.receipt?.status, 'saved'); assert.equal(result.receipt?.changed, true);
    f.db.runTransaction = run;
    assert.deepEqual(await f.repo().status(f.user, scope, command.idempotencyKey, command.fingerprint), result);
    const ledger = JSON.parse(result.current!.json);
    assert.equal(Object.keys(ledger.creditNotes).length, 1);
    assert.equal(ledger.entries.filter((entry: {operationId: string}) => entry.operationId === command.intent.operationId).length, 1);
    assert.deepEqual(ledgerSupplierCreditInput(checkedLedgerSupplierCreditProof(ledger.creditNotes[command.intent.operationId], scope)), command.intent);
  } finally {f.db.runTransaction = run; await f.close();}
});
test('AGG05 SDK credit original command refuses revoked owner before creating any attempt', {skip: !ledgerEmulator}, async () => {
  const f = await sdkCreditHistoryFixture(false), command = sdkCreditCommand(f);
  try {
    const before = ledgerHash((await f.root.get()).data()); await f.grant.update({active: false});
    await assert.rejects(f.repo().recordSupplierCredit(f.user, command), code('permission_denied'));
    assert.equal(ledgerHash((await f.root.get()).data()), before);
    assert.equal((await f.root.collection('attempts').get()).size, 0);
  } finally {await f.close();}
});
for (const variant of ['plain', 'lot', 'restock', 'legacy calendar'] as const)
  test('AGG05 credit original goods-source validator preserves native relationships: ' + variant, () => {
    const f = agg05CreditGoodsFixture(variant), before = ledgerCanonical(f.ledger);
    const source = ledgerSupplierCreditGoodsSource(f.ledger, scope, opening().supplierId, f.bills);
    assert.equal(source.receipts.size, 1); assert.equal(source.links.size, 1);
    assert.equal(source.legacyCalendar, variant === 'legacy calendar');
    assert.deepEqual(source.receipts.get('HOST-credit-receipt'), f.receipt);
    assert.deepEqual(source.links.get('HOST-credit-goods-link'), f.link);
    assert.equal(ledgerCanonical(f.ledger), before);
    if (process.env.AGG05_CREDIT_GOODS_CAPTURE_PATH) writeFileSync(process.env.AGG05_CREDIT_GOODS_CAPTURE_PATH + '.' + variant.replaceAll(' ', '-') + '.json',
      JSON.stringify({label: 'ISOLATED HOST GOODS SOURCE FORMAT; NO RUNTIME RECEIPT OR STOCK AUTHORITY', scope, ledger: f.ledger,
        receiptCount: source.receipts.size, linkCount: source.links.size, legacyCalendar: source.legacyCalendar}),
      {encoding: 'utf8', flag: 'wx'});
  });
for (const [name, mutate] of [
  ['foreign owner', (f: ReturnType<typeof agg05CreditGoodsFixture>) => {f.ledger.accountScope = 'HOST-other';}],
  ['incomplete history', (f: ReturnType<typeof agg05CreditGoodsFixture>) => {f.ledger.historyComplete = false;}],
  ['receipt identity mismatch', (f: ReturnType<typeof agg05CreditGoodsFixture>) => {f.receipt.id = 'HOST-other';}],
  ['future receipt', (f: ReturnType<typeof agg05CreditGoodsFixture>) => {f.receipt.recordedAt = '2026-10-30T01:00:00.000Z';}],
  ['invalid calendar', (f: ReturnType<typeof agg05CreditGoodsFixture>) => {f.receipt.recordedUtcOffsetMinutes = 841;}],
  ['future delivered day', (f: ReturnType<typeof agg05CreditGoodsFixture>) => {f.receipt.deliveredOn = '2026-10-30';}],
  ['missing product', (f: ReturnType<typeof agg05CreditGoodsFixture>) => {f.line.productId = '';}],
  ['zero conversion', (f: ReturnType<typeof agg05CreditGoodsFixture>) => {f.line.unitsPerPack = 0;}],
  ['delivered totals', (f: ReturnType<typeof agg05CreditGoodsFixture>) => {f.line.deliveredMilli = 999;}],
  ['exceeded expected quantity', (f: ReturnType<typeof agg05CreditGoodsFixture>) => {f.line.expectedMilli = 999;}],
  ['fractional stock units', (f: ReturnType<typeof agg05CreditGoodsFixture>) => {f.line.acceptedMilli = 501; f.line.damagedMilli = 499;}],
  ['prior Stock exceeds goods', (f: ReturnType<typeof agg05CreditGoodsFixture>) => {f.line.priorStockUnits = {'HOST-movement': 2};}],
  ['duplicate line', (f: ReturnType<typeof agg05CreditGoodsFixture>) => {(f.receipt.lines as unknown[]).push(ledgerClone(f.line));}],
  ['duplicate expected delivery', (f: ReturnType<typeof agg05CreditGoodsFixture>) => {(f.ledger.goodsReceipts as Record<string, unknown>)['HOST-second'] = {...ledgerClone(f.receipt), id: 'HOST-second'};}],
  ['unreviewed conversion', (f: ReturnType<typeof agg05CreditGoodsFixture>) => {f.link.conversionReviewed = false;}],
  ['wrong copy', (f: ReturnType<typeof agg05CreditGoodsFixture>) => {f.link.copyId = 'HOST-other-copy';}],
  ['wrong copy revision', (f: ReturnType<typeof agg05CreditGoodsFixture>) => {f.link.copyRevision = 999;}],
  ['wrong product', (f: ReturnType<typeof agg05CreditGoodsFixture>) => {f.link.productId = 'HOST-other-product';}],
  ['wrong pack', (f: ReturnType<typeof agg05CreditGoodsFixture>) => {f.link.billUnit = 'HOST-other-unit';}],
  ['wrong conversion', (f: ReturnType<typeof agg05CreditGoodsFixture>) => {f.link.stockUnitsNumerator = 1;}],
  ['nonreduced conversion', (f: ReturnType<typeof agg05CreditGoodsFixture>) => {f.link.stockUnitsNumerator = 4; f.link.stockUnitsDenominator = 2;}],
  ['wrong free quantity', (f: ReturnType<typeof agg05CreditGoodsFixture>) => {f.link.billQuantityMilli = 0; Object.assign(f.link, {freeBillQuantityMilli: 1000});}],
  ['over-attributed damage', (f: ReturnType<typeof agg05CreditGoodsFixture>) => {f.link.acceptedReceiptMilli = 0; f.link.damagedReceiptMilli = 1000;}],
  ['duplicate attribution', (f: ReturnType<typeof agg05CreditGoodsFixture>) => {(f.ledger.billGoodsAllocations as Record<string, unknown>)['HOST-second-link'] = {...ledgerClone(f.link), operationId: 'HOST-second-link'};}],
  ['link before receipt', (f: ReturnType<typeof agg05CreditGoodsFixture>) => {f.link.linkedAt = '2026-10-29T02:05:00.000Z';}],
  ['link after source', (f: ReturnType<typeof agg05CreditGoodsFixture>) => {f.link.linkedAt = '2026-10-29T04:00:00.000Z';}],
  ['invoice quantity precision', (f: ReturnType<typeof agg05CreditGoodsFixture>) => {const [id, bill] = [...f.bills][0]!; f.bills.set(id, {...bill, copy: {...bill.copy, draft: {...bill.copy.draft, goods: bill.copy.draft.goods.map((line, index) => index === 0 ? {...line, quantity: '1.0001'} : line)}}});}],
] as const) test('AGG05 credit original goods-source refuses changed evidence: ' + name, () => {
  const f = agg05CreditGoodsFixture(); mutate(f);
  assert.throws(() => ledgerSupplierCreditGoodsSource(f.ledger, scope, opening().supplierId, f.bills), code('service_unavailable'));
});
for (const property of ['realm', 'accountScope', 'buyingStoreId'] as const) test('AGG05 credit original Restock evidence refuses foreign ' + property, () => {
  const f = agg05CreditGoodsFixture('restock'); (f.receipt.restockOriginal as Record<string, unknown>)[property] = 'HOST-foreign';
  assert.throws(() => ledgerSupplierCreditGoodsSource(f.ledger, scope, opening().supplierId, f.bills), code('service_unavailable'));
});
async function sdkRefundFixture(kind: 'openingAdvance' | 'accountAdvance' = 'openingAdvance') {
  const f = await sdkManualSupplierFixture(kind === 'openingAdvance' ? -1000 : 0);
  try {
    if (kind === 'accountAdvance') {
      const funding = supplierMoneyCommand({entry: {...supplierMoneyCommand().entry, amountMinor: 1000, kind: 'advance'}});
      assert.equal((await f.repo().recordSupplierMoney(f.user, funding)).receipt?.status, 'saved');
    }
    return {...f, command: refundCommand(kind)};
  } catch (error) {await f.close(); throw error;}
}
for (const kind of ['openingAdvance', 'accountAdvance'] as const) test('AGG05 SDK AI refund preparation binds original source with no model request identity: ' + kind,
  {skip: !ledgerEmulator}, async () => {
    const f = await sdkRefundFixture(kind);
    try {
      const prep = await sdkPreparation(f, {existing: {book: f.book, purchase: f.original}}), basis = f.command.intent;
      const entity = 'ledger-refund:' + ledgerHash([basis.supplierId, kind, basis.sourceId, null]);
      const before = ledgerHash((await f.root.get()).data()), bookBefore = ledgerHash((await f.original.root.get()).data()),
        attempts = (await f.root.collection('attempts').get()).size;
      let selected: Extract<PreparationReply['outcome'], {kind: 'proposal'}> | null = null;
      for (const actionId of ['AI-ACT-266', 'AI-ACT-267', 'AI-ACT-378']) {
        const input = {...prep.input, actionId, entityId: entity};
        const wire = checkedModelCommand({operation: 'prepare', payload: {...input, nativeTargets: [{actionId, entityId: entity}]}});
        assert.equal(wire.operation, 'prepare'); assert.equal((wire.payload as PreparationRequest).entityId, entity);
        assert.throws(() => checkedModelCommand({operation: 'prepare', payload: {...input,
          entityId: JSON.stringify([basis.supplierId, kind, basis.sourceId, null])}}), /invalid_request/u);
        const context = await prep.source.read(f.user, input);
        assert.equal(context.tools.length, 1); const tool = context.tools[0]!; assertStrictSchema(tool.parameters);
        const fields = actionId === 'AI-ACT-266' ? {supplierId: basis.supplierId, openingId: basis.openingId,
          openingRevision: basis.openingRevision, sourceKind: kind, sourceId: basis.sourceId,
          copyId: null, copyRevision: null, amount: '2.50', reference: basis.reference,
          channel: 'Cash', occurredOn: basis.occurredOn} : {};
        assert(tool.validate(fields)); const resolved = tool.resolveTarget!(fields);
        assert.deepEqual(resolved.fields, fields); assert.equal(resolved.entityId, entity);
        assert.equal(resolved.sourceRevision, 'store-original-ledger-v1:' + ledgerHash([
          scope.account, scope.store, scope.realm, f.command.expectedRevision, f.book.revision, actionId, entity]));
        for (const extra of [{operationId: 'HOST-invented-event'}, {idempotencyKey: 'HOST-invented-nonce'},
          {committedRevision: 999}, {approved: true}]) {
          assert(!tool.validate({...fields, ...extra}));
          assert.throws(() => tool.resolveTarget!({...fields, ...extra}), /invalid_model_result/u);
        }
        if (actionId === 'AI-ACT-266') {
          for (const patch of [{supplierId: 'HOST-other'}, {openingRevision: 999}, {sourceId: 'HOST-other'},
            {sourceKind: 'accountPayment'}, {sourceKind: 'manualBillSurplus'}, {copyId: 'HOST-copy'}, {copyRevision: 1},
            {amount: '10.01'}, {amount: '0'}, {amount: 250}, {channel: 'Cheque'}, {occurredOn: '2026-02-30'},
            {reference: ''}]) assert(!tool.validate({...fields, ...patch}), JSON.stringify(patch));
          for (const channel of ['Cash', 'UPI', 'Bank transfer']) assert(tool.validate({...fields, channel}));
        } else assert(!tool.validate({operationId: basis.operationId}));
        const proposal = {kind: 'proposal' as const, id: 'HOST-original-refund-proposal', actionId, ...resolved,
          title: 'Review original supplier refund', summary: 'HOST native final confirmation only'};
        assert.equal((await prep.source.readPrepared(f.user, input, proposal)).tools[0]!.sourceRevision, resolved.sourceRevision);
        if (actionId === 'AI-ACT-266') selected = proposal;
        if (process.env.AGG05_REFUND_CONTEXT_CAPTURE_PATH) writeFileSync(process.env.AGG05_REFUND_CONTEXT_CAPTURE_PATH + '.' + kind + '.' + actionId + '.json',
          JSON.stringify({label: 'ISOLATED SDK ORIGINAL REFUND PREPARATION; NO MODEL REQUEST ID OR FINANCIAL EFFECT',
            actor: f.user, request: input, metadata: {ok: true, data: canonicalContextProjection(f.user, input.scope, context, 1)}, proposal}),
          {encoding: 'utf8', flag: 'wx'});
      }
      assert.equal(ledgerHash((await f.root.get()).data()), before);
      assert.equal(ledgerHash((await f.original.root.get()).data()), bookBefore);
      assert.equal((await f.root.collection('attempts').get()).size, attempts);
      await assert.rejects(prep.source.read(f.user, {...prep.input, actionId: 'AI-ACT-266', entityId: 'HOST-other'}), /context_unavailable/u);
      assert.equal((await f.repo().recordSupplierRefund(f.user, f.command)).receipt?.status, 'saved');
      assert(selected);
      await assert.rejects(prep.source.readPrepared(f.user, {...prep.input, actionId: selected.actionId, entityId: entity}, selected), /stale_preparation/u);
      prep.changeOwner();
      await assert.rejects(prep.source.read(f.user, {...prep.input, actionId: 'AI-ACT-267', entityId: entity}), /stale_preparation/u);
    } finally {await f.close();}
  });
for (const kind of ['openingAdvance', 'accountAdvance'] as const) for (const exhausted of [false, true])
  test('AGG05 SDK AI refund recovery survives source consumption: ' + kind + ' exhausted=' + exhausted,
    {skip: !ledgerEmulator}, async () => {
      const f = await sdkRefundFixture(kind);
      try {
        const command = resign({...f.command, intent: {...f.command.intent, amountMinor: exhausted ? 1000 : 250}});
        assert.equal((await f.repo().recordSupplierRefund(f.user, command)).receipt?.status, 'saved');
        const prep = await sdkPreparation(f, {existing: {book: f.book, purchase: f.original}}), basis = command.intent,
          entity = 'ledger-refund:' + ledgerHash([basis.supplierId, kind, basis.sourceId, null]);
        const before = ledgerHash((await f.root.get()).data()), attempts = (await f.root.collection('attempts').get()).size;
        for (const actionId of ['AI-ACT-267', 'AI-ACT-378']) {
          const current = await prep.source.read(f.user, {...prep.input, actionId, entityId: entity});
          assert.equal(current.tools.length, 1); assert(current.tools[0]!.validate({}));
          assert(!current.tools[0]!.validate({operationId: basis.operationId}));
        }
        const input = {...prep.input, actionId: 'AI-ACT-266', entityId: entity};
        if (exhausted) await assert.rejects(prep.source.read(f.user, input), /context_unavailable/u);
        else {
          const current = await prep.source.read(f.user, input), tool = current.tools[0]!;
          const fields = {supplierId: basis.supplierId, openingId: basis.openingId, openingRevision: basis.openingRevision,
            sourceKind: kind, sourceId: basis.sourceId, copyId: null, copyRevision: null,
            amount: '7.50', reference: 'HOST-second-refund', channel: 'Cash', occurredOn: basis.occurredOn};
          assert(tool.validate(fields)); assert(!tool.validate({...fields, amount: '7.51'}));
        }
        assert.equal(ledgerHash((await f.root.get()).data()), before);
        assert.equal((await f.root.collection('attempts').get()).size, attempts);
      } finally {await f.close();}
    });
for (const kind of ['openingAdvance', 'accountAdvance'] as const) test('AGG05 SDK refund original record/status/restart preserves exact incoming fact: ' + kind,
  {skip: !ledgerEmulator}, async () => {
    const f = await sdkRefundFixture(kind);
    try {
      const command = f.command, book = ledgerHash((await f.original.root.get()).data()), service = new WorkspaceLedgerService(f.repo(), now);
      const before = JSON.parse((await f.repo().list(f.user, scope, 'supplierLedger', null, null)).rows[0]!.json);
      const response = await service.handle(f.user, command.operation, body(command)) as Record<string, unknown>,
        receipt = response.attempt as LedgerReceipt, current = response.current as LedgerRow, value = JSON.parse(current.json);
      assert.equal(receipt.status, 'saved'); assert.equal(receipt.changed, true); assert.equal(receipt.inputFingerprint, ledgerHash(command.intent));
      const proof = checkedLedgerSupplierRefundProof(value.refunds[command.intent.operationId], scope);
      assert.deepEqual(proof, {intent: command.intent, committedRevision: before.revision + 1, recordedAt: confirmedAt});
      assert.deepEqual(value.entries, [...before.entries, ledgerSupplierRefundEntry(proof)]);
      assert.deepEqual(value.purchaseBills, before.purchaseBills); assert.deepEqual(value.billMoneyAllocations, before.billMoneyAllocations);
      const history = ledgerSupplierFinancialHistory(value, scope, command.supplierId);
      assert.equal(history.balance, -750); assert.equal(history.used.get(history.sourceKey(kind, command.intent.sourceId)), 250);
      assert.deepEqual(await new WorkspaceLedgerService(f.repo(), now).handle(f.user, command.operation, body(command)), response);
      assert.deepEqual(await new WorkspaceLedgerService(f.repo(), now).handle(f.user, 'readStoreLedgerAttempt', {
        schemaVersion: 1, ledgerVersion: 1, operation: 'readStoreLedgerAttempt', scope, idempotencyKey: command.idempotencyKey, fingerprint: command.fingerprint}), response);
      const noOp = await f.repo().recordSupplierRefund(f.user, resign({...command, idempotencyKey: 'HOST-refund-fact-recheck'}));
      assert.equal(noOp.receipt?.changed, false); assert.equal(noOp.revision, response.sourceRevision);
      const conflict = await f.repo().recordSupplierRefund(f.user, resign({...command, idempotencyKey: 'HOST-refund-divergent', intent: {...command.intent, amountMinor: 249}}));
      assert.equal(conflict.receipt?.reason, 'record_identity_conflict');
      assert.equal(ledgerHash((await f.original.root.get()).data()), book);
      if (process.env.AGG05_REFUND_NATIVE_CAPTURE_PATH) writeFileSync(process.env.AGG05_REFUND_NATIVE_CAPTURE_PATH + '.' + kind + '.json',
        JSON.stringify({label: 'ISOLATED ACTUAL SDK ORIGINAL REFUND RECORD; NOT PROVIDER CONFIRMATION OR RUNTIME AUTHORITY',
          scope, now: confirmedAt, command, response}), {encoding: 'utf8', flag: 'wx'});
    } finally {await f.close();}
  });
for (const scenario of ['source capacity', 'wrong source', 'wrong opening', 'wrong qa', 'future day', 'prior day', 'future request', 'stale ledger', 'stale supplier'] as const)
  test('AGG05 SDK refund rejects stale or changed original evidence: ' + scenario, {skip: !ledgerEmulator}, async () => {
    const f = await sdkRefundFixture();
    try {
      let command = f.command, reason = 'refund_source_changed';
      if (scenario === 'source capacity') {command = resign({...command, intent: {...command.intent, amountMinor: 1001}}); reason = 'refund_capacity_changed';}
      if (scenario === 'wrong source') command = resign({...command, intent: {...command.intent, sourceId: 'HOST-unknown-source'}});
      if (scenario === 'wrong opening') {command = resign({...command, intent: {...command.intent, openingRevision: 999}}); reason = 'opening_evidence_changed';}
      if (scenario === 'wrong qa') {command = resign({...command, intent: {...command.intent, qa: true}}); reason = 'opening_evidence_changed';}
      if (scenario === 'future day') {command = resign({...command, intent: {...command.intent, occurredOn: '2026-10-30'}}); reason = 'refund_confirmation_invalid';}
      if (scenario === 'prior day') {command = resign({...command, intent: {...command.intent, occurredOn: '2026-10-28'}}); reason = 'refund_confirmation_invalid';}
      if (scenario === 'future request') {command = resign({...command, intent: {...command.intent, requestedAt: '2026-10-29T02:00:00.001Z'}}); reason = 'refund_confirmation_invalid';}
      if (scenario === 'stale ledger') {command = resign({...command, expectedRevision: null}); reason = 'stale_ledger';}
      if (scenario === 'stale supplier') {command = resign({...command, expectedSupplierRevision: 2}); reason = 'stale_supplier';}
      const result = await f.repo().recordSupplierRefund(f.user, command);
      assert.equal(result.receipt?.status, 'not_saved'); assert.equal(result.receipt?.reason, reason);
      assert.deepEqual(JSON.parse(result.current!.json).entries, []); assert.equal(result.revision, 1);
    } finally {await f.close();}
  });
test('AGG05 SDK refund and allocation share original source capacity without double consumption', {skip: !ledgerEmulator}, async () => {
  const f = await sdkReviewedBillFixture('excluded', -2000);
  try {
    assert.equal((await f.repo().confirmSupplierBill(f.user, f.billCommand)).receipt?.status, 'saved');
    const intent = checkedLedgerSupplierAllocationIntent({...agg05AllocationInput('openingAdvance'), sourceId: opening().id, billId: f.billCommand.bill.copy.draft.id,
      copyId: f.billCommand.bill.copy.id, copyRevision: f.billCommand.bill.copy.revision, amountMinor: 500, requestedAt: confirmedAt}, scope);
    const allocation: LedgerSupplierAllocationCommand = resign({scope, operation: 'recordStoreSupplierMoneyAllocation',
      supplierId: f.billCommand.supplierId, expectedRevision: 2, expectedSupplierRevision: 2,
      idempotencyKey: 'HOST-refund-existing-allocation', fingerprint: '', intent});
    assert.equal((await f.repo().allocateSupplierMoney(f.user, allocation)).receipt?.status, 'saved');
    const refund = refundCommand('openingAdvance', {expectedRevision: 3, expectedSupplierRevision: 3,
      intent: {...refundCommand().intent, amountMinor: 1100}});
    assert.equal((await f.repo().recordSupplierRefund(f.user, refund)).receipt?.reason, 'refund_capacity_changed', 'Source capacity alone does not prove net supplier credit.');
    const exact = resign({...refund, idempotencyKey: 'HOST-refund-net-credit', intent: {...refund.intent, amountMinor: 1000}});
    assert.equal((await f.repo().recordSupplierRefund(f.user, exact)).receipt?.status, 'saved');
    const after = resign({...allocation, expectedRevision: 4, expectedSupplierRevision: 4, idempotencyKey: 'HOST-allocation-after-refund',
      intent: {...allocation.intent, operationId: 'HOST-later-attribution', amountMinor: 501}});
    assert.equal((await f.repo().allocateSupplierMoney(f.user, after)).receipt?.reason, 'allocation_capacity_changed');
    const last = await f.repo().allocateSupplierMoney(f.user, resign({...after, idempotencyKey: 'HOST-exact-remaining-attribution', intent: {...after.intent, amountMinor: 500}}));
    assert.equal(last.receipt?.status, 'saved');
    const history = ledgerSupplierFinancialHistory(JSON.parse(last.current!.json), scope, f.billCommand.supplierId);
    assert.equal(history.balance, 0); assert.equal(history.used.get(history.sourceKey('openingAdvance', opening().id)), 2000);
    assert.equal(history.refunds.size, 1); assert.equal(history.allocations.size, 2);
  } finally {await f.close();}
});
test('AGG05 SDK refund concurrent same request records only one original fact', {skip: !ledgerEmulator}, async () => {
  const f = await sdkRefundFixture();
  try {
    const service = () => new WorkspaceLedgerService(f.repo(), now);
    const responses = await Promise.all([service().handle(f.user, f.command.operation, body(f.command)), service().handle(f.user, f.command.operation, body(f.command))]);
    assert.deepEqual(responses[0], responses[1]);
    const result = await f.repo().status(f.user, scope, f.command.idempotencyKey, f.command.fingerprint);
    assert.equal(JSON.parse(result.current!.json).entries.length, 1);
    assert.equal(Object.keys(JSON.parse(result.current!.json).refunds).length, 1);
    assert.equal((await f.root.collection('supplierEntryIdentities').get()).size, 1);
  } finally {await f.close();}
});
test('AGG05 SDK refund concurrent different requests cannot overconsume original credit', {skip: !ledgerEmulator}, async () => {
  const f = await sdkRefundFixture();
  try {
    const a = resign({...f.command, intent: {...f.command.intent, amountMinor: 600}}),
      b = resign({...f.command, idempotencyKey: 'HOST-competing-refund-request', intent: {...f.command.intent,
        operationId: 'HOST-competing-refund', reference: 'HOST distinct competing receipt', amountMinor: 600}});
    const results = await Promise.all([f.repo().recordSupplierRefund(f.user, a), f.repo().recordSupplierRefund(f.user, b)]);
    assert.equal(results.filter(value => value.receipt?.status === 'saved').length, 1);
    assert.equal(results.filter(value => value.receipt?.reason === 'stale_ledger').length, 1);
    assert.equal(JSON.parse((await f.repo().list(f.user, scope, 'supplierLedger', null, null)).rows[0]!.json).entries.length, 1);
  } finally {await f.close();}
});
test('AGG05 SDK refund lost reply reopens exact original status without another record', {skip: !ledgerEmulator}, async () => {
  const f = await sdkRefundFixture();
  try {
    const repository = f.repo(), save = repository.recordSupplierRefund.bind(repository);
    let writes = 0;
    repository.recordSupplierRefund = async (actor, command) => {writes++; await save(actor, command); throw new Error('HOST lost original response');};
    await assert.rejects(new WorkspaceLedgerService(repository, now).handle(f.user, f.command.operation, body(f.command)), /HOST lost original response/u);
    const result = await new WorkspaceLedgerService(f.repo(), now).handle(f.user, 'readStoreLedgerAttempt', {
      schemaVersion: 1, ledgerVersion: 1, operation: 'readStoreLedgerAttempt', scope,
      idempotencyKey: f.command.idempotencyKey, fingerprint: f.command.fingerprint}) as Record<string, unknown>;
    assert.equal((result.attempt as LedgerReceipt).status, 'saved'); assert.equal(writes, 1);
    assert.equal(JSON.parse((result.current as LedgerRow).json).entries.length, 1);
  } finally {await f.close();}
});
test('AGG05 SDK refund source exhaustion is independent of net supplier credit', {skip: !ledgerEmulator}, async () => {
  const f = await sdkRefundFixture('accountAdvance');
  try {
    const extra = supplierMoneyCommand({expectedRevision: 2, expectedSupplierRevision: 2, idempotencyKey: 'HOST-second-advance-request',
      entry: {...supplierMoneyCommand().entry, operationId: 'HOST-second-advance', kind: 'advance', amountMinor: 1000}});
    assert.equal((await f.repo().recordSupplierMoney(f.user, extra)).receipt?.status, 'saved');
    const tooMuch = resign({...f.command, expectedRevision: 3, expectedSupplierRevision: 3, intent: {...f.command.intent, amountMinor: 1100}});
    assert.equal((await f.repo().recordSupplierRefund(f.user, tooMuch)).receipt?.reason, 'refund_capacity_changed');
    const exact = resign({...tooMuch, idempotencyKey: 'HOST-refund-first-advance-exact', intent: {...tooMuch.intent, amountMinor: 1000}});
    const saved = await f.repo().recordSupplierRefund(f.user, exact);
    assert.equal(saved.receipt?.status, 'saved');
    assert.equal(ledgerSupplierFinancialHistory(JSON.parse(saved.current!.json), scope, exact.supplierId).balance, -1000);
    const exhausted = resign({...exact, expectedRevision: 4, expectedSupplierRevision: 4, idempotencyKey: 'HOST-exhausted-first-advance',
      intent: {...exact.intent, operationId: 'HOST-exhausted-refund', reference: 'HOST exhausted source receipt', amountMinor: 1}});
    assert.equal((await f.repo().recordSupplierRefund(f.user, exhausted)).receipt?.reason, 'refund_capacity_changed');
  } finally {await f.close();}
});
test('AGG05 SDK refund exact proof survives later original bill and payment', {skip: !ledgerEmulator}, async () => {
  const f = await sdkRefundFixture();
  try {
    const saved = await f.repo().recordSupplierRefund(f.user, f.command);
    const originalProof = JSON.parse(saved.current!.json).refunds[f.command.intent.operationId];
    const copy = checkedPurchaseEntryCopy({...agg05BillInput().copy, supplier: f.book.profiles[0]!}, true);
    const book = await publishReviewedBillCopy(f, copy, null);
    const bill: LedgerSupplierBillCommand = resign({scope, operation: 'confirmStoreSupplierBill', supplierId: f.command.supplierId,
      expectedRevision: 2, expectedSupplierRevision: 2, expectedPurchaseRevision: book.revision, expectedPurchaseFingerprint: ledgerHash(book),
      idempotencyKey: 'HOST-bill-after-original-refund', fingerprint: '', confirmedUtcOffsetMinutes: 330,
      bill: checkedLedgerSupplierBillAcceptance({copy, acceptedAt: confirmedAt, openingTreatment: 'excluded',
        openingReview: {openingId: opening().id, openingRevision: opening().revision, treatment: 'excluded'}})});
    assert.equal((await f.repo().confirmSupplierBill(f.user, bill)).receipt?.status, 'saved');
    const payment = billMoneyCommand(bill, {expectedRevision: 3, expectedSupplierRevision: 3}); payment.entry.amountMinor = 250;
    assert.equal((await f.repo().recordSupplierMoney(f.user, resign(payment))).receipt?.status, 'saved');
    const result = await f.repo().status(f.user, scope, f.command.idempotencyKey, f.command.fingerprint);
    assert.deepEqual(JSON.parse(result.current!.json).refunds[f.command.intent.operationId], originalProof);
    assert.equal(ledgerSupplierFinancialHistory(JSON.parse(result.current!.json), scope, f.command.supplierId).balance, 0);
    assert.equal(result.receipt?.changed, true); assert.equal(result.revision, 4);
  } finally {await f.close();}
});
test('AGG05 SDK refund foreign account Store realm and revoked membership cannot publish', {skip: !ledgerEmulator}, async () => {
  const f = await sdkRefundFixture();
  try {
    const before = ledgerHash((await f.root.get()).data()), count = (await f.root.collection('attempts').get()).size;
    await assert.rejects(f.repo().recordSupplierRefund({...f.user, uid: 'HOST-foreign-account'}, f.command), code('permission_denied'));
    await assert.rejects(f.repo().recordSupplierRefund({...f.user, projectId: 'demo-foreign-project'}, f.command), code('permission_denied'));
    const foreign = resign({...f.command, scope: {...scope, store: 'HOST-foreign-store'}, intent: {...f.command.intent, workspaceId: 'HOST-foreign-store'}});
    await assert.rejects(f.repo().recordSupplierRefund(f.user, foreign), code('permission_denied'));
    await assert.rejects(f.repo().recordSupplierRefund(f.user, resign({...f.command, scope: {...scope, realm: 'production'}})), code('permission_denied'));
    await f.grant.update({active: false});
    await assert.rejects(f.repo().recordSupplierRefund(f.user, f.command), code('permission_denied'));
    assert.equal(ledgerHash((await f.root.get()).data()), before); assert.equal((await f.root.collection('attempts').get()).size, count);
  } finally {await f.close();}
});
test('AGG05 SDK refund operation identity cannot be reused across original suppliers', {skip: !ledgerEmulator}, async () => {
  const f = await sdkManualSupplierFixture(-1000, true);
  try {
    const first = refundCommand('openingAdvance', {expectedRevision: 2});
    assert.equal((await f.repo().recordSupplierRefund(f.user, first)).receipt?.status, 'saved');
    const second = resign({...first, supplierId: 'HOST-supplier-second', expectedRevision: 3, expectedSupplierRevision: 1,
      idempotencyKey: 'HOST-cross-supplier-refund', intent: {...first.intent, supplierId: 'HOST-supplier-second',
        openingId: 'HOST-opening-second', openingRevision: 3, sourceId: 'HOST-opening-second'}});
    const result = await f.repo().recordSupplierRefund(f.user, second);
    assert.equal(result.receipt?.reason, 'record_identity_conflict');
    assert.deepEqual(JSON.parse(result.current!.json).entries, []);
    assert.equal((await f.root.collection('supplierEntryIdentities').get()).size, 1);
  } finally {await f.close();}
});
test('AGG05 SDK refund proof tampering cannot satisfy original status or later source validation', {skip: !ledgerEmulator}, async () => {
  const f = await sdkRefundFixture();
  try {
    const saved = await f.repo().recordSupplierRefund(f.user, f.command), ledger = JSON.parse(saved.current!.json);
    for (const patch of [{supplierId: 'HOST-other'}, {openingRevision: 999}, {amountMinor: 9999}, {sourceId: 'HOST-unknown'}, {qa: true}]) {
      const value = ledgerClone(ledger); Object.assign(value.refunds[f.command.intent.operationId].intent, patch);
      assert.throws(() => ledgerSupplierFinancialHistory(value, scope, f.command.supplierId), code('service_unavailable'));
    }
    for (const altered of ['amount', 'entry', 'missing proof'] as const) {
      const repository = f.repo(), original = repository.status.bind(repository);
      repository.status = async (...args) => {
        const value = ledgerClone(await original(...args)), body = JSON.parse(value.current!.json);
        if (altered === 'amount') body.refunds[f.command.intent.operationId].intent.amountMinor = 249;
        if (altered === 'entry') body.entries[0].amountMinor = 249;
        if (altered === 'missing proof') delete body.refunds[f.command.intent.operationId];
        value.current = {...value.current!, json: ledgerCanonical(body), fingerprint: ledgerHash(body)}; return value;
      };
      await assert.rejects(new WorkspaceLedgerService(repository, now).handle(f.user, 'readStoreLedgerAttempt', {
        schemaVersion: 1, ledgerVersion: 1, operation: 'readStoreLedgerAttempt', scope,
        idempotencyKey: f.command.idempotencyKey, fingerprint: f.command.fingerprint}), code('service_unavailable'));
    }
  } finally {await f.close();}
});
async function sdkAllocationFixture(sourceKind: 'openingAdvance' | 'accountPayment' | 'accountAdvance' = 'accountPayment') {
  const f = await sdkReviewedBillFixture('excluded', sourceKind === 'openingAdvance' ? -1000 : 10000);
  try {
    await f.repo().confirmSupplierBill(f.user, f.billCommand);
    const funding = supplierMoneyCommand({expectedRevision: 2, expectedSupplierRevision: 2,
      entry: {...supplierMoneyCommand().entry, amountMinor: 500, kind: sourceKind === 'accountAdvance' ? 'advance' : 'payment'}});
    if (sourceKind !== 'openingAdvance') assert.equal((await f.repo().recordSupplierMoney(f.user, funding)).receipt?.status, 'saved');
    const revision = sourceKind === 'openingAdvance' ? 2 : 3;
    const command: LedgerSupplierAllocationCommand = resign({scope, operation: 'recordStoreSupplierMoneyAllocation',
      supplierId: f.billCommand.supplierId, expectedRevision: revision, expectedSupplierRevision: revision,
      idempotencyKey: 'HOST-original-allocation-request', fingerprint: '',
      intent: checkedLedgerSupplierAllocationIntent({...agg05AllocationInput(sourceKind),
        sourceId: sourceKind === 'openingAdvance' ? opening().id : funding.entry.operationId,
        billId: f.billCommand.bill.copy.draft.id, copyId: f.billCommand.bill.copy.id,
        copyRevision: f.billCommand.bill.copy.revision, amountMinor: 250, requestedAt: confirmedAt}, scope)});
    return {...f, command, funding};
  } catch (error) {await f.close(); throw error;}
}
for (const kind of ['openingAdvance', 'accountPayment', 'accountAdvance'] as const) test('AGG05 SDK allocation original save/status/restart has no second payment: ' + kind,
  {skip: !ledgerEmulator}, async () => {
    const f = await sdkAllocationFixture(kind);
    try {
      const page = await f.repo().list(f.user, scope, 'supplierLedger', null, null);
      const before = JSON.parse(page.rows[0]!.json), bookBefore = ledgerHash((await f.original.root.get()).data());
      const service = new WorkspaceLedgerService(f.repo(), now), command = f.command;
      const response = await service.handle(f.user, command.operation, body(command)) as Record<string, unknown>;
      const receipt = response.attempt as LedgerReceipt, current = response.current as LedgerRow, value = JSON.parse(current.json), proof = value.billMoneyAllocations[command.intent.operationId];
      assert.equal(receipt.status, 'saved'); assert.equal(receipt.changed, true);
      assert.equal(receipt.entryId, command.intent.operationId); assert.equal(receipt.inputFingerprint, ledgerHash(command.intent));
      assert.deepEqual(value.entries, before.entries); assert.deepEqual(value.purchaseBills, before.purchaseBills);
      assert.equal(value.openingBalanceMinor, before.openingBalanceMinor); assert.equal(value.revision, before.revision + 1);
      assert.deepEqual(proof, {...command.intent, committedRevision: value.revision, recordedAt: confirmedAt});
      const statusBody = {schemaVersion: 1, ledgerVersion: 1, operation: 'readStoreLedgerAttempt', scope,
        idempotencyKey: command.idempotencyKey, fingerprint: command.fingerprint};
      assert.deepEqual(await new WorkspaceLedgerService(f.repo(), now).handle(f.user, 'readStoreLedgerAttempt', statusBody), response);
      assert.deepEqual(await service.handle(f.user, command.operation, body(command)), response);
      const noOp = await f.repo().allocateSupplierMoney(f.user, resign({...command, idempotencyKey: 'HOST-exact-allocation-recheck'}));
      assert.equal(noOp.receipt?.changed, false); assert.equal(noOp.revision, response.sourceRevision);
      const conflict = await f.repo().allocateSupplierMoney(f.user, resign({...command,
        idempotencyKey: 'HOST-divergent-allocation-recheck', intent: {...command.intent, amountMinor: 249}}));
      assert.equal(conflict.receipt?.reason, 'record_identity_conflict');
      assert.equal(ledgerHash((await f.original.root.get()).data()), bookBefore);
      assert.equal((await f.root.collection('supplierEntryIdentities').get()).size, kind === 'openingAdvance' ? 2 : 3);
      if (process.env.AGG05_ALLOCATION_NATIVE_CAPTURE_PATH) writeFileSync(process.env.AGG05_ALLOCATION_NATIVE_CAPTURE_PATH + '.' + kind + '.json',
        JSON.stringify({label: 'ISOLATED ACTUAL SDK ORIGINAL ALLOCATION; NO NEW PAYMENT OR RUNTIME AUTHORITY',
          scope, now: confirmedAt, command, response}), {encoding: 'utf8', flag: 'wx'});
      if (kind === 'accountPayment') {
        const over = billMoneyCommand(f.billCommand, {expectedRevision: value.revision, expectedSupplierRevision: value.revision});
        over.entry.amountMinor = 751;
        assert.equal((await f.repo().recordSupplierMoney(f.user, resign(over))).receipt?.reason, 'supplier_capacity_changed');
        const remaining = resign({...over, idempotencyKey: 'HOST-pay-remaining-after-allocation', entry: {...over.entry, amountMinor: 750}});
        assert.equal((await f.repo().recordSupplierMoney(f.user, remaining)).receipt?.status, 'saved');
        const latest = await service.handle(f.user, 'readStoreLedgerAttempt', statusBody) as Record<string, unknown>;
        assert.deepEqual((latest.attempt as LedgerReceipt), receipt);
        assert.deepEqual(JSON.parse((latest.current as LedgerRow).json).billMoneyAllocations[command.intent.operationId], proof);
      }
    } finally {await f.close();}
  });
for (const kind of ['openingAdvance', 'accountPayment', 'accountAdvance'] as const) test('AGG05 SDK AI allocation preparation binds original bill and funding without request identity: ' + kind,
  {skip: !ledgerEmulator}, async () => {
    const f = await sdkAllocationFixture(kind);
    try {
      const prep = await sdkPreparation(f, {existing: {book: f.billBook, purchase: f.original}});
      const before = ledgerHash((await f.root.get()).data()), bookBefore = ledgerHash((await f.original.root.get()).data()),
        attempts = (await f.root.collection('attempts').get()).size;
      let selected: PreparationReply['outcome'] | null = null;
      for (const actionId of ['AI-ACT-262', 'AI-ACT-263', 'AI-ACT-377']) {
        const input = {...prep.input, actionId, entityId: f.billCommand.bill.copy.id};
        const context = await prep.source.read(f.user, input);
        assert.equal(context.tools.length, 1); const tool = context.tools[0]!;
        assertStrictSchema(tool.parameters);
        const basis = f.command.intent;
        const fields = actionId === 'AI-ACT-262' ? {
          supplierId: basis.supplierId, copyId: basis.copyId, copyRevision: basis.copyRevision,
          openingId: basis.openingId, openingRevision: basis.openingRevision,
          sourceKind: basis.sourceKind, sourceId: basis.sourceId, amount: '2.50',
        } : {};
        assert(tool.validate(fields)); const resolved = tool.resolveTarget!(fields);
        assert.deepEqual(resolved.fields, fields); assert.equal(resolved.entityId, basis.copyId);
        assert.equal(resolved.sourceRevision, 'store-original-ledger-v1:' + ledgerHash([
          scope.account, scope.store, scope.realm, f.command.expectedRevision, f.billBook.revision, actionId, basis.copyId]));
        for (const extra of [{operationId: 'HOST-model-invented-event'}, {idempotencyKey: 'HOST-model-invented-nonce'},
          {committedRevision: 999}, {approved: true}]) assert(!tool.validate({...fields, ...extra}));
        if (actionId === 'AI-ACT-262') {
          for (const patch of [{supplierId: 'HOST-other-supplier'}, {copyId: 'HOST-other-copy'}, {copyRevision: 999},
            {openingRevision: 999}, {sourceId: 'HOST-other-source'}, {sourceKind: 'manualBillSurplus'},
            {amount: 250}, {amount: '0'}, {amount: ''}]) assert(!tool.validate({...fields, ...patch}));
        } else assert(!tool.validate({operationId: basis.operationId}), 'The model must never supply the encrypted native request identity.');
        const proposal = {kind: 'proposal' as const, id: 'HOST-original-allocation-proposal', actionId, ...resolved,
          title: 'Review original allocation', summary: 'HOST original native confirmation only'};
        assert.equal((await prep.source.readPrepared(f.user, input, proposal)).tools[0]!.sourceRevision, resolved.sourceRevision);
        if (actionId === 'AI-ACT-262') selected = proposal;
        if (process.env.AGG05_ALLOCATION_CONTEXT_CAPTURE_PATH) writeFileSync(process.env.AGG05_ALLOCATION_CONTEXT_CAPTURE_PATH + '.' + kind + '.' + actionId + '.json',
          JSON.stringify({label: 'ISOLATED SDK ORIGINAL ALLOCATION PREPARATION; NO MODEL REQUEST ID OR FINANCIAL EFFECT',
            actor: f.user, request: input, metadata: {ok: true, data: canonicalContextProjection(f.user, input.scope, context, 1)}, proposal}),
          {encoding: 'utf8', flag: 'wx'});
      }
      assert.equal(ledgerHash((await f.root.get()).data()), before);
      assert.equal(ledgerHash((await f.original.root.get()).data()), bookBefore);
      assert.equal((await f.root.collection('attempts').get()).size, attempts);
      await assert.rejects(prep.source.read(f.user, {...prep.input, actionId: 'AI-ACT-262', entityId: 'HOST-unrelated-copy'}), /context_unavailable/u);
      assert.equal((await f.repo().allocateSupplierMoney(f.user, f.command)).receipt?.status, 'saved');
      assert(selected?.kind === 'proposal');
      await assert.rejects(prep.source.readPrepared(f.user, {...prep.input, actionId: selected.actionId,
        entityId: selected.entityId}, selected), /stale_preparation/u);
    } finally {await f.close();}
  });
for (const kind of ['openingAdvance', 'accountPayment', 'accountAdvance'] as const) test('AGG05 SDK AI money preparation retains validated allocation history: ' + kind,
  {skip: !ledgerEmulator}, async () => {
    const f = await sdkAllocationFixture(kind);
    try {
      assert.equal((await f.repo().allocateSupplierMoney(f.user, f.command)).receipt?.status, 'saved');
      const before = ledgerHash((await f.root.get()).data()), bookBefore = ledgerHash((await f.original.root.get()).data()),
        attempts = (await f.root.collection('attempts').get()).size;
      const prep = await sdkPreparation(f, {existing: {book: f.billBook, purchase: f.original}});
      for (const actionId of ['AI-ACT-259', 'AI-ACT-260', 'AI-ACT-261']) {
        const entityId = actionId === 'AI-ACT-259' ? f.billCommand.bill.copy.id : opening().supplierId;
        const context = await prep.source.read(f.user, {...prep.input, actionId, entityId});
        assert.equal(context.tools.length, 1); assert.equal(context.tools[0]!.actionId, actionId);
      }
      for (const patch of [{amountMinor: 5001}, {openingRevision: 999}, {accountScope: 'HOST-other-account'}]) {
        prep.alter(frame => {
          if (frame.kind !== 'supplierLedger') return;
          const row = (frame.rows as LedgerRow[])[0]!;
          const value = JSON.parse(row.json);
          Object.assign(value.billMoneyAllocations[f.command.intent.operationId], patch);
          row.json = ledgerCanonical(value); row.fingerprint = ledgerHash(value);
        });
        await assert.rejects(prep.source.read(f.user, {...prep.input, actionId: 'AI-ACT-261', entityId: opening().supplierId}), /context_unavailable/u);
      }
      assert.equal(ledgerHash((await f.root.get()).data()), before);
      assert.equal(ledgerHash((await f.original.root.get()).data()), bookBefore);
      assert.equal((await f.root.collection('attempts').get()).size, attempts);
    } finally {await f.close();}
  });
for (const scenario of ['source spent', 'target spent', 'wrong source', 'wrong copy', 'wrong opening', 'future request', 'stale ledger', 'stale supplier', 'money identity collision'] as const) {
  test('AGG05 SDK allocation refuses changed original evidence/capacity: ' + scenario, {skip: !ledgerEmulator}, async () => {
    const f = await sdkAllocationFixture();
    try {
      let command = f.command, reason = 'allocation_source_changed';
      if (scenario === 'source spent') {command = resign({...command, intent: {...command.intent, amountMinor: 501}}); reason = 'allocation_capacity_changed';}
      if (scenario === 'target spent') {
        const paid = billMoneyCommand(f.billCommand, {expectedRevision: 3, expectedSupplierRevision: 3}); paid.entry.amountMinor = 750;
        assert.equal((await f.repo().recordSupplierMoney(f.user, resign(paid))).receipt?.status, 'saved');
        command = resign({...command, expectedRevision: 4, expectedSupplierRevision: 4, intent: {...command.intent, amountMinor: 300}});
        reason = 'allocation_capacity_changed';
      }
      if (scenario === 'wrong source') command = resign({...command, intent: {...command.intent, sourceId: 'HOST-unknown-money'}});
      if (scenario === 'wrong copy') command = resign({...command, intent: {...command.intent, copyId: 'HOST-other-copy'}});
      if (scenario === 'wrong opening') {command = resign({...command, intent: {...command.intent, openingRevision: 999}}); reason = 'opening_evidence_changed';}
      if (scenario === 'future request') {command = resign({...command, intent: {...command.intent, requestedAt: '2026-10-29T02:00:00.001Z'}}); reason = 'allocation_confirmation_invalid';}
      if (scenario === 'stale ledger') {command = resign({...command, expectedRevision: 2}); reason = 'stale_ledger';}
      if (scenario === 'stale supplier') {command = resign({...command, expectedSupplierRevision: 2}); reason = 'stale_supplier';}
      if (scenario === 'money identity collision') {command = resign({...command, intent: {...command.intent, operationId: f.funding.entry.operationId}}); reason = 'record_identity_conflict';}
      const result = await f.repo().allocateSupplierMoney(f.user, command);
      assert.equal(result.receipt?.status, 'not_saved'); assert.equal(result.receipt?.reason, reason);
      assert.deepEqual(JSON.parse(result.current!.json).billMoneyAllocations ?? {}, {});
      assert.equal(result.revision, scenario === 'target spent' ? 4 : 3);
    } finally {await f.close();}
  });
}
test('AGG05 SDK allocation concurrent attribution cannot consume the same source twice', {skip: !ledgerEmulator}, async () => {
  const f = await sdkAllocationFixture();
  try {
    const a = resign({...f.command, intent: {...f.command.intent, amountMinor: 300}}),
      b = resign({...f.command, idempotencyKey: 'HOST-other-concurrent-allocation', intent: {...f.command.intent, operationId: 'HOST-other-allocation', amountMinor: 300}});
    const results = await Promise.all([f.repo().allocateSupplierMoney(f.user, a), f.repo().allocateSupplierMoney(f.user, b)]);
    assert.equal(results.filter(value => value.receipt?.status === 'saved').length, 1);
    assert.equal(results.filter(value => value.receipt?.reason === 'stale_ledger').length, 1);
  } finally {await f.close();}
});
test('AGG05 SDK allocation preserves original attribution when another bill is confirmed later', {skip: !ledgerEmulator}, async () => {
  const f = await sdkAllocationFixture();
  try {
    const allocated = await f.repo().allocateSupplierMoney(f.user, f.command);
    assert.equal(allocated.receipt?.status, 'saved');
    const prior = JSON.parse(allocated.current!.json), first = f.billCommand.bill.copy;
    const copy = checkedPurchaseEntryCopy({...first, id: 'HOST-bill-after-allocation-copy', revision: 4,
      draft: {...first.draft, id: 'HOST-bill-after-allocation', invoiceReference: 'HOST-LATER-ALLOCATION-BILL'}}, true);
    const book = await publishReviewedBillCopy(f, copy, first.draft.id);
    const command = resign({...f.billCommand, expectedRevision: allocated.revision, expectedSupplierRevision: prior.revision,
      expectedPurchaseRevision: book.revision, expectedPurchaseFingerprint: ledgerHash(book),
      idempotencyKey: 'HOST-confirm-later-allocation-bill', bill: {...f.billCommand.bill, copy}});
    const response = await f.repo().confirmSupplierBill(f.user, command);
    assert.equal(response.receipt?.status, 'saved');
    const current = JSON.parse(response.current!.json);
    assert.deepEqual(current.billMoneyAllocations, prior.billMoneyAllocations);
    assert.deepEqual(current.entries.slice(0, prior.entries.length), prior.entries);
    assert.equal(current.entries.length, prior.entries.length + 1);
    assert.equal(current.entries.at(-1).kind, 'bill');
  } finally {await f.close();}
});
test('AGG05 SDK allocation foreign account and Store cannot read or publish attribution', {skip: !ledgerEmulator}, async () => {
  const f = await sdkAllocationFixture();
  try {
    const before = ledgerHash((await f.root.get()).data()), attempts = (await f.root.collection('attempts').get()).size;
    await assert.rejects(f.repo().allocateSupplierMoney({...f.user, uid: 'HOST-foreign-account'}, f.command), code('permission_denied'));
    const other = resign({...f.command, scope: {...scope, store: 'HOST-foreign-store'},
      intent: {...f.command.intent, workspaceId: 'HOST-foreign-store'}});
    await assert.rejects(f.repo().allocateSupplierMoney(f.user, other), code('permission_denied'));
    assert.equal(ledgerHash((await f.root.get()).data()), before);
    assert.equal((await f.root.collection('attempts').get()).size, attempts);
  } finally {await f.close();}
});
test('AGG05 SDK AI bill-money preparation joins originals without event identity or financial effects', {skip: !ledgerEmulator}, async () => {
  const f = await sdkReviewedBillFixture();
  try {
    await f.repo().confirmSupplierBill(f.user, f.billCommand);
    const before = ledgerHash((await f.root.get()).data()), bookBefore = ledgerHash((await f.original.root.get()).data()),
      attempts = (await f.root.collection('attempts').get()).size;
    const prep = await sdkPreparation(f, {existing: {book: f.billBook, purchase: f.original}});
    let selected: PreparationReply['outcome'] | null = null;
    for (const actionId of ['AI-ACT-259', 'AI-ACT-260', 'AI-ACT-261']) {
      const entityId = actionId === 'AI-ACT-259' ? f.billCommand.bill.copy.id : opening().supplierId;
      const input = {...prep.input, actionId, entityId};
      const context = await prep.source.read(f.user, input);
      assert.equal(context.tools.length, 1); const tool = context.tools[0]!;
      assertStrictSchema(tool.parameters);
      const fields = {supplierId: opening().supplierId, openingId: opening().id, openingRevision: opening().revision,
        ...(actionId === 'AI-ACT-259' ? {copyId: entityId} : {}), amount: '5.00',
        reference: 'HOST explicit bill money reference', channel: 'Cash', occurredOn: '2026-10-29'};
      assert(tool.validate(fields)); const resolved = tool.resolveTarget!(fields);
      assert.deepEqual(resolved.fields, fields); assert.equal(resolved.entityId, entityId);
      assert.equal(resolved.sourceRevision, 'store-original-ledger-v1:' + ledgerHash([
        scope.account, scope.store, scope.realm, 2, f.billBook.revision, actionId, entityId]));
      for (const patch of [{supplierId: 'HOST-other-supplier'}, {openingRevision: 999}, {copyId: 'HOST-another-copy'},
        {amount: 500}, {amount: '0'}, {occurredOn: '2026-02-30'}, {reference: ''},
        {operationId: 'HOST-invented-event'}, {idempotencyKey: 'HOST-invented-request'}, {notIncludedInOpening: true}]) {
        assert(!tool.validate({...fields, ...patch}));
      }
      const {occurredOn: _day, ...missingDate} = fields; assert(!tool.validate(missingDate));
      const proposal = {kind: 'proposal' as const, id: 'HOST-bill-money-preparation', actionId, ...resolved,
        title: 'Review original bill money', summary: 'HOST final native confirmation only'};
      assert.equal((await prep.source.readPrepared(f.user, input, proposal)).tools[0]!.sourceRevision, resolved.sourceRevision);
      if (actionId === 'AI-ACT-259') selected = proposal;
      if (process.env.AGG05_BILL_MONEY_CONTEXT_CAPTURE_PATH) writeFileSync(process.env.AGG05_BILL_MONEY_CONTEXT_CAPTURE_PATH + '.' + actionId + '.json',
        JSON.stringify({label: 'ISOLATED SDK ORIGINAL BILL MONEY PREPARATION; NO LIVE MODEL OR AUTHORITY', actor: f.user,
          request: input, metadata: {ok: true, data: canonicalContextProjection(f.user, input.scope, context, 1)}, proposal}),
        {encoding: 'utf8', flag: 'wx'});
    }
    assert.equal(ledgerHash((await f.root.get()).data()), before);
    assert.equal(ledgerHash((await f.original.root.get()).data()), bookBefore);
    assert.equal((await f.root.collection('attempts').get()).size, attempts);
    assert(prep.calls.every(operation => operation === 'readStoreLedgerSource'));
    assert.equal((await f.repo().recordSupplierMoney(f.user, billMoneyCommand(f.billCommand))).receipt?.status, 'saved');
    assert(selected?.kind === 'proposal');
    await assert.rejects(prep.source.readPrepared(f.user, {...prep.input, actionId: selected.actionId,
      entityId: selected.entityId}, selected), /stale_preparation/u);
  } finally {await f.close();}
});
test('AGG05 SDK AI bill-money preparation never exposes an opening-included bill as independently payable', {skip: !ledgerEmulator}, async () => {
  const f = await sdkReviewedBillFixture('included');
  try {
    await f.repo().confirmSupplierBill(f.user, f.billCommand);
    const prep = await sdkPreparation(f, {existing: {book: f.billBook, purchase: f.original}});
    await assert.rejects(prep.source.read(f.user, {...prep.input, actionId: 'AI-ACT-259', entityId: f.billCommand.bill.copy.id}), /context_unavailable/u);
    const context = await prep.source.read(f.user, {...prep.input, actionId: 'AI-ACT-261', entityId: opening().supplierId});
    assert.equal(context.tools.length, 1); assert.equal(context.tools[0]!.actionId, 'AI-ACT-261');
  } finally {await f.close();}
});
for (const variant of ['bill', 'account', 'advance'] as const) test('AGG05 actual SDK bill money exact save and restart: ' + variant,
  {skip: !ledgerEmulator}, async () => {
    const f = await sdkReviewedBillFixture();
    try {
      assert.equal((await f.repo().confirmSupplierBill(f.user, f.billCommand)).receipt?.status, 'saved');
      const originalBook = ledgerHash((await f.original.root.get()).data());
      const command = variant === 'bill' ? billMoneyCommand(f.billCommand) : supplierMoneyCommand({
        expectedRevision: 2, expectedSupplierRevision: 2,
        entry: {...supplierMoneyCommand().entry, amountMinor: 500, kind: variant === 'advance' ? 'advance' : 'payment'}});
      const service = new WorkspaceLedgerService(f.repo(), now);
      const response = await service.handle(f.user, command.operation, body(command)) as Record<string, unknown>;
      const row = response.current as LedgerRow, ledger = JSON.parse(row.json);
      assert.equal((response.attempt as LedgerReceipt).status, 'saved'); assert.equal(response.sourceRevision, 3);
      assert.equal(ledger.entries.length, 2); assert.deepEqual(ledger.entries[1], command.entry);
      assert.deepEqual(ledger.purchaseBills[f.billCommand.bill.copy.draft.id], f.billCommand.bill);
      const reopened = await new WorkspaceLedgerService(f.repo(), now).handle(f.user, 'readStoreLedgerAttempt', {
        schemaVersion: 1, ledgerVersion: 1, operation: 'readStoreLedgerAttempt', scope,
        idempotencyKey: command.idempotencyKey, fingerprint: command.fingerprint});
      assert.deepEqual(reopened, response);
      assert.deepEqual(await service.handle(f.user, command.operation, body(command)), response);
      const exact = await f.repo().recordSupplierMoney(f.user, resign({...command, idempotencyKey: 'HOST-bill-payment-recheck'}));
      assert.equal(exact.receipt?.changed, false); assert.equal(exact.revision, 3);
      assert.equal(ledgerHash((await f.original.root.get()).data()), originalBook);
      if (process.env.AGG05_BILL_MONEY_NATIVE_CAPTURE_PATH) writeFileSync(process.env.AGG05_BILL_MONEY_NATIVE_CAPTURE_PATH + '.' + variant + '.json',
        JSON.stringify({label: 'ISOLATED ACTUAL SDK ORIGINAL BILL MONEY; NOT RUNTIME AUTHORITY OR PAYMENT',
          scope, now: confirmedAt, command, response}), {encoding: 'utf8', flag: 'wx'});
    } finally {await f.close();}
  });
for (const variant of ['bill overpayment', 'wrong copy', 'wrong bill', 'predates acceptance', 'included bill', 'stale ledger', 'stale supplier'] as const) {
  test('AGG05 actual SDK bill money refuses invalid reviewed capacity: ' + variant, {skip: !ledgerEmulator}, async () => {
    const f = await sdkReviewedBillFixture(variant === 'included bill' ? 'included' : 'excluded');
    try {
      await f.repo().confirmSupplierBill(f.user, f.billCommand);
      let command = billMoneyCommand(f.billCommand);
      const entry = {...command.entry};
      if (variant === 'bill overpayment') entry.amountMinor = 1001;
      if (variant === 'wrong copy') entry.purchaseId = 'HOST-another-copy';
      if (variant === 'wrong bill') entry.billId = 'HOST-another-bill';
      if (variant === 'predates acceptance') entry.postedAt = '2026-10-29T01:59:59.999Z';
      command = resign({...command, entry,
        expectedRevision: variant === 'stale ledger' ? 1 : 2,
        expectedSupplierRevision: variant === 'stale supplier' ? 1 : 2});
      const result = await f.repo().recordSupplierMoney(f.user, command);
      assert.equal(result.receipt?.status, 'not_saved');
      assert.equal(result.receipt?.reason, variant === 'bill overpayment' ? 'supplier_capacity_changed'
        : variant === 'stale ledger' ? 'stale_ledger' : variant === 'stale supplier' ? 'stale_supplier' : 'supplier_money_evidence_invalid');
      assert.equal(result.revision, 2); assert.equal(JSON.parse(result.current!.json).entries.length, variant === 'included bill' ? 0 : 1);
    } finally {await f.close();}
  });
}
test('AGG05 actual SDK bill money partial payments preserve exact remaining capacity and account separation', {skip: !ledgerEmulator}, async () => {
  const f = await sdkReviewedBillFixture();
  try {
    await f.repo().confirmSupplierBill(f.user, f.billCommand);
    const first = billMoneyCommand(f.billCommand);
    assert.equal((await f.repo().recordSupplierMoney(f.user, first)).receipt?.status, 'saved');
    const second = resign({...first, expectedRevision: 3, expectedSupplierRevision: 3,
      idempotencyKey: 'HOST-second-partial-bill-payment', entry: {...first.entry, operationId: 'HOST-second-payment'}});
    assert.equal((await f.repo().recordSupplierMoney(f.user, second)).receipt?.status, 'saved');
    const third = resign({...second, expectedRevision: 4, expectedSupplierRevision: 4,
      idempotencyKey: 'HOST-third-partial-bill-payment', entry: {...second.entry, operationId: 'HOST-third-payment', amountMinor: 1}});
    const refused = await f.repo().recordSupplierMoney(f.user, third);
    assert.equal(refused.receipt?.reason, 'supplier_capacity_changed'); assert.equal(refused.revision, 4);
    const account = supplierMoneyCommand({expectedRevision: 4, expectedSupplierRevision: 4,
      entry: {...supplierMoneyCommand().entry, amountMinor: 10000}});
    assert.equal((await f.repo().recordSupplierMoney(f.user, account)).receipt?.status, 'saved');
    const overAccount = resign({...account, expectedRevision: 5, expectedSupplierRevision: 5,
      idempotencyKey: 'HOST-no-account-dues', entry: {...account.entry, operationId: 'HOST-extra-account-payment', amountMinor: 1}});
    assert.equal((await f.repo().recordSupplierMoney(f.user, overAccount)).receipt?.reason, 'supplier_capacity_changed');
  } finally {await f.close();}
});
test('AGG05 actual SDK bill money concurrent reviewed requests cannot overspend the same bill', {skip: !ledgerEmulator}, async () => {
  const f = await sdkReviewedBillFixture();
  try {
    await f.repo().confirmSupplierBill(f.user, f.billCommand);
    const first = billMoneyCommand(f.billCommand);
    first.entry.amountMinor = 700;
    const a = resign(first), b = resign({...first, idempotencyKey: 'HOST-other-concurrent-bill-payment',
      entry: {...first.entry, operationId: 'HOST-other-concurrent-payment'}});
    const replies = await Promise.all([f.repo().recordSupplierMoney(f.user, a), f.repo().recordSupplierMoney(f.user, b)]);
    assert.equal(replies.filter(value => value.receipt?.status === 'saved').length, 1);
    assert.equal(replies.filter(value => value.receipt?.reason === 'stale_ledger').length, 1);
  } finally {await f.close();}
});
for (const treatment of ['included', 'excluded'] as const) test('AGG05 actual SDK original bill confirmation and exact recovery: ' + treatment,
  {skip: !ledgerEmulator}, async () => {
    const f = await sdkReviewedBillFixture(treatment);
    try {
      const service = new WorkspaceLedgerService(f.repo(), now), command = f.billCommand;
      const originalBook = ledgerHash((await f.original.root.get()).data());
      const reply = await service.handle(f.user, command.operation, body(command)) as Record<string, unknown>;
      const receipt = reply.attempt as Record<string, unknown>, row = reply.current as LedgerRow, value = JSON.parse(row.json);
      assert.equal(receipt.status, 'saved'); assert.equal(reply.sourceRevision, 2);
      assert.equal(receipt.entryId, command.bill.copy.draft.id); assert.equal(receipt.inputFingerprint, ledgerHash(command.bill));
      assert.deepEqual(value.purchaseBills[command.bill.copy.draft.id], command.bill);
      assert.equal(value.entries.length, treatment === 'excluded' ? 1 : 0);
      if (treatment === 'excluded') {
        assert.equal(value.entries[0].operationId, 'manual-bill:' + command.bill.copy.draft.id);
        assert.equal(value.entries[0].amountMinor, 1000); assert.equal(value.entries[0].kind, 'bill');
      }
      const after = ledgerHash((await f.root.get()).data());
      const duplicate = await new WorkspaceLedgerService(f.repo(), now).handle(f.user, command.operation, body(command));
      assert.deepEqual(duplicate, reply); assert.equal(ledgerHash((await f.root.get()).data()), after);
      const status = await service.handle(f.user, 'readStoreLedgerAttempt', {schemaVersion: 1, ledgerVersion: 1,
        operation: 'readStoreLedgerAttempt', scope, idempotencyKey: command.idempotencyKey, fingerprint: command.fingerprint});
      assert.deepEqual(status, reply); assert.equal(ledgerHash((await f.original.root.get()).data()), originalBook);
      if (process.env.AGG05_BILL_NATIVE_CAPTURE_PATH) writeFileSync(process.env.AGG05_BILL_NATIVE_CAPTURE_PATH + '.' + treatment + '.json',
        JSON.stringify({label: 'ISOLATED ACTUAL SDK ORIGINAL BILL; NOT RUNTIME AUTHORITY OR PAYMENT',
          scope, now: confirmedAt, command, requestBody: body(command), response: reply}), {encoding: 'utf8', flag: 'wx'});
    } finally {await f.close();}
  });
for (const fault of ['stale global', 'stale supplier', 'stale original book', 'changed original copy',
  'missing opening review', 'different opening review', 'future confirmation'] as const) test('AGG05 actual SDK original bill refuses ' + fault,
  {skip: !ledgerEmulator}, async () => {
    const f = await sdkReviewedBillFixture();
    try {
      let command = f.billCommand;
      const expected = fault === 'stale global' ? 'stale_ledger' : fault === 'stale supplier' ? 'stale_supplier'
        : fault === 'stale original book' ? 'stale_evidence' : fault === 'changed original copy' ? 'bill_source_changed'
        : fault === 'future confirmation' ? 'bill_confirmation_invalid' : 'bill_opening_evidence_changed';
      if (fault === 'stale global') command = resign({...command, expectedRevision: 2});
      if (fault === 'stale supplier') command = resign({...command, expectedSupplierRevision: 2});
      if (fault === 'stale original book') command = resign({...command, expectedPurchaseRevision: 2});
      if (fault === 'changed original copy') command = resign({...command, bill: {...command.bill,
        copy: {...command.bill.copy, draft: {...command.bill.copy.draft, invoiceReference: 'HOST-DIFFERENT'}}}});
      if (fault === 'missing opening review') {const {openingReview: _review, ...bill} = command.bill; command = resign({...command, bill});}
      if (fault === 'different opening review') command = resign({...command, bill: {...command.bill,
        openingReview: {...command.bill.openingReview!, openingRevision: 3}}});
      if (fault === 'future confirmation') command = resign({...command, bill: {...command.bill, acceptedAt: '2026-10-29T03:00:00.000Z'}});
      const before = ledgerHash((await f.root.get()).data()), bookBefore = ledgerHash((await f.original.root.get()).data());
      const service = new WorkspaceLedgerService(f.repo(), now);
      const reply = await service.handle(f.user, command.operation, body(command)) as Record<string, unknown>;
      assert.equal((reply.attempt as Record<string, unknown>).status, 'not_saved');
      assert.equal((reply.attempt as Record<string, unknown>).reason, expected);
      assert.equal(ledgerHash((await f.root.get()).data()), before); assert.equal(ledgerHash((await f.original.root.get()).data()), bookBefore);
      assert.deepEqual(await service.handle(f.user, command.operation, body(command)), reply);
    } finally {await f.close();}
  });
test('AGG05 actual SDK concurrent original bill confirmation has one liability and immutable request identity',
  {skip: !ledgerEmulator}, async () => {
    const f = await sdkReviewedBillFixture();
    try {
      const command = f.billCommand, service = () => new WorkspaceLedgerService(f.repo(), now);
      const replies = await Promise.all([service().handle(f.user, command.operation, body(command)), service().handle(f.user, command.operation, body(command))]);
      assert.deepEqual(replies[0], replies[1]);
      const value = JSON.parse(((replies[0] as Record<string, unknown>).current as LedgerRow).json);
      assert.equal(value.entries.length, 1); assert.equal(Object.keys(value.purchaseBills).length, 1);
      await assert.rejects(service().handle(f.user, command.operation, body(resign({...command, expectedRevision: 2}))), code('idempotency_conflict'));
      const duplicateFact = resign({...command, expectedRevision: 2, expectedSupplierRevision: 2,
        idempotencyKey: 'HOST-second-bill-fact', bill: {...command.bill, acceptedAt: '2026-10-29T01:59:59.999999Z'}});
      const refused = await service().handle(f.user, command.operation, body(duplicateFact)) as Record<string, unknown>;
      assert.equal((refused.attempt as Record<string, unknown>).reason, 'record_identity_conflict');
    } finally {await f.close();}
  });

async function publishReviewedBillCopy(f: Pick<Awaited<ReturnType<typeof sdkManualSupplierFixture>>, 'original' | 'user'>,
  copy: ReturnType<typeof checkedPurchaseEntryCopy>, replaceReviewedDraftId: string | null) {
  const current = (await f.original.repository.read(f.user, scope))!;
  const input = {scope, expectedRevision: current.revision, idempotencyKey: 'HOST-source-copy-' + copy.id,
    profile: copy.supplier, draft: copy.draft, reviewedCopy: copy, replaceReviewedDraftId};
  await f.original.repository.savePurchaseDraft(f.user, {...input, fingerprint: purchaseEntryDraftCommandFingerprint(input)});
  const book = (await f.original.repository.read(f.user, scope))!;
  assert.equal(book.revision, copy.revision); return book;
}
test('AGG05 actual SDK bill latest-copy invoice history preserves corrected originals', {skip: !ledgerEmulator}, async () => {
  const f = await sdkReviewedBillFixture();
  try {
    const first = f.billCommand.bill.copy;
    const old = checkedPurchaseEntryCopy({...first, id: 'HOST-bill-history-4', revision: 4,
      draft: {...first.draft, id: 'HOST-bill-history-B', invoiceReference: 'HOST-HISTORY-OLD'}}, true);
    await publishReviewedBillCopy(f, old, first.draft.id);
    const corrected = checkedPurchaseEntryCopy({...old, id: 'HOST-bill-history-5', revision: 5,
      draft: {...old.draft, invoiceReference: 'HOST-HISTORY-NEW'}}, true);
    await publishReviewedBillCopy(f, corrected, null);
    const target = checkedPurchaseEntryCopy({...first, id: 'HOST-bill-history-6', revision: 6,
      draft: {...first.draft, id: 'HOST-bill-history-C', invoiceReference: 'HOST-HISTORY-OLD'}}, true);
    const book = await publishReviewedBillCopy(f, target, corrected.draft.id);
    const command = resign({...f.billCommand, expectedPurchaseRevision: book.revision,
      expectedPurchaseFingerprint: ledgerHash(book), bill: {...f.billCommand.bill, copy: target}});
    const result = await f.repo().confirmSupplierBill(f.user, command);
    assert.equal(result.receipt?.status, 'saved', result.receipt?.reason ?? 'missing receipt');
    assert.equal((await f.original.repository.read(f.user, scope))?.copies?.length, 4);
  } finally {await f.close();}
});
test('AGG05 actual SDK bill internal timestamp normalisation never changes printed document fields', {skip: !ledgerEmulator}, async () => {
  const f = await sdkReviewedBillFixture();
  try {
    const source = checkedPurchaseEntryCopy({...f.billCommand.bill.copy, id: 'HOST-bill-utc-4', revision: 4,
      savedAt: '2026-10-29T01:00:01.000000Z'}, true);
    const book = await publishReviewedBillCopy(f, source, null);
    const copy = {...source, savedAt: '2026-10-29T01:00:01.000Z'};
    const command = resign({...f.billCommand, expectedPurchaseRevision: book.revision,
      expectedPurchaseFingerprint: ledgerHash(book), bill: {...f.billCommand.bill, copy}});
    const changedPrint = resign({...command, idempotencyKey: 'HOST-bill-changed-print', bill: {...command.bill,
      copy: {...copy, draft: {...copy.draft, invoiceDate: '2026-10-29'}}}});
    assert.equal((await f.repo().confirmSupplierBill(f.user, changedPrint)).receipt?.reason, 'bill_source_changed');
    const result = await f.repo().confirmSupplierBill(f.user, command);
    assert.equal(result.receipt?.status, 'saved', result.receipt?.reason ?? 'missing receipt');
    assert.equal((await f.original.repository.read(f.user, scope))?.copies?.length, 2);
  } finally {await f.close();}
});

for (const change of ['source changed', 'membership revoked'] as const) test('AGG05 actual SDK bill publication rechecks ' + change,
  {skip: !ledgerEmulator}, async () => {
    const f = await sdkReviewedBillFixture();
    try {
      const anchor = f.original.repository.ledgerAnchor(); let changed = false;
      const guarded: LedgerPurchaseAnchor = {capture: anchor.capture, assertCurrent: async (tx, actor, requested, book) => {
        if (!changed) {
          changed = true;
          if (change === 'membership revoked') await f.grant.update({active: false});
          else {
            const input = {scope, expectedRevision: f.billBook.revision, idempotencyKey: 'HOST-bill-source-race',
              profile: {...f.billBook.profiles[0]!, name: 'HOST independently changed supplier'}};
            await f.original.repository.saveSupplier(f.user, {...input, fingerprint: purchaseEntryCommandFingerprint(input)});
          }
        }
        await anchor.assertCurrent(tx, actor, requested, book);
      }};
      const repo = new FirestoreWorkspaceLedgerRepository(f.db, 'evaluation', f.user.projectId, f.authority, guarded, now);
      const before = ledgerHash((await f.root.get()).data());
      if (change === 'source changed') {
        const result = await repo.confirmSupplierBill(f.user, f.billCommand);
        assert.equal(result.receipt?.status, 'not_saved'); assert.equal(result.receipt?.reason, 'stale_evidence');
        assert.equal((await f.original.repository.read(f.user, scope))?.revision, 4);
      } else {
        await assert.rejects(repo.confirmSupplierBill(f.user, f.billCommand), code('permission_denied'));
        await f.grant.update({active: true});
        assert.equal((await repo.status(f.user, scope, f.billCommand.idempotencyKey, f.billCommand.fingerprint)).receipt, null);
      }
      assert.equal(changed, true); assert.equal(ledgerHash((await f.root.get()).data()), before);
      assert.equal((await f.root.collection('supplierBillIdentities').get()).size, 0);
      assert.equal((await f.root.collection('supplierEntryIdentities').get()).size, 0);
    } finally {await f.close();}
  });
test('AGG05 actual SDK bill identity cannot become liability for another supplier', {skip: !ledgerEmulator}, async () => {
  const f = await sdkManualSupplierFixture(10000, true);
  try {
    const first = checkedPurchaseEntryCopy({...agg05BillInput().copy, revision: 4, supplier: f.book.profiles[0]!}, true);
    let book = await publishReviewedBillCopy(f, first, null);
    const command: LedgerSupplierBillCommand = resign({scope, operation: 'confirmStoreSupplierBill', supplierId: first.supplier.id,
      expectedRevision: 2, expectedSupplierRevision: 1, expectedPurchaseRevision: book.revision, expectedPurchaseFingerprint: ledgerHash(book),
      bill: checkedLedgerSupplierBillAcceptance({copy: first, acceptedAt: confirmedAt, openingTreatment: 'excluded',
        openingReview: {openingId: opening().id, openingRevision: 2, treatment: 'excluded'}}),
      confirmedUtcOffsetMinutes: 330, idempotencyKey: 'HOST-first-supplier-bill', fingerprint: ''});
    assert.equal((await f.repo().confirmSupplierBill(f.user, command)).receipt?.status, 'saved');
    const second = checkedPurchaseEntryCopy({...first, id: 'HOST-other-supplier-copy', revision: 5, supplier: f.book.profiles[1]!,
      draft: {...first.draft, supplierId: f.book.profiles[1]!.id}}, true);
    book = await publishReviewedBillCopy(f, second, null);
    const other = resign({...command, supplierId: second.supplier.id, expectedRevision: 3,
      expectedPurchaseRevision: book.revision, expectedPurchaseFingerprint: ledgerHash(book), idempotencyKey: 'HOST-other-supplier-bill',
      bill: checkedLedgerSupplierBillAcceptance({...command.bill, copy: second,
        openingReview: {openingId: 'HOST-opening-second', openingRevision: 3, treatment: 'excluded'}})});
    const before = ledgerHash((await f.root.get()).data()), rejected = await f.repo().confirmSupplierBill(f.user, other);
    assert.equal(rejected.receipt?.status, 'not_saved'); assert.equal(rejected.receipt?.reason, 'record_identity_conflict');
    assert.equal(ledgerHash((await f.root.get()).data()), before);
    assert.equal((await f.root.collection('supplierBillIdentities').get()).size, 1);
  } finally {await f.close();}
});

async function sdkManualSupplierFixture(balance = 10000, secondSupplier = false) {
  const f = await sdkLedger();
  try {
    const record = {...opening(), amountMinor: Math.abs(balance), supplierCredit: balance < 0}, firstBook = originalOpeningBook(record);
    const second = {...record, id: 'HOST-opening-second', supplierId: 'HOST-supplier-second', revision: 3};
    const book: PurchaseEntryBook = secondSupplier ? {...firstBook, revision: 3,
      profiles: [...firstBook.profiles, {...firstBook.profiles[0]!, id: second.supplierId}], openingRecords: [record, second]} : firstBook;
    const original = await seedOriginalPurchase(f, book);
    const repo = () => new FirestoreWorkspaceLedgerRepository(f.db, 'evaluation', f.user.projectId,
      f.authority, original.repository.ledgerAnchor(), now);
    const source = await repo().confirmOpening(f.user, resign({...openingCommand(), opening: record,
      expectedPurchaseRevision: book.revision, expectedPurchaseFingerprint: ledgerHash(book)}));
    assert.equal(source.receipt?.status, 'saved');
    if (secondSupplier) assert.equal((await repo().confirmOpening(f.user, resign({...openingCommand(),
      opening: second, expectedRevision: 1, expectedPurchaseRevision: book.revision,
      expectedPurchaseFingerprint: ledgerHash(book), idempotencyKey: 'HOST-opening-second-attempt'}))).receipt?.status, 'saved');
    return {...f, repo, original, book};
  } catch (error) {await f.close(); throw error;}
}
for (const kind of ['payment', 'advance'] as const) test('AGG05 actual SDK original supplier ' + kind + ' records once and reopens exact status',
  {skip: !ledgerEmulator}, async () => {
    const f = await sdkManualSupplierFixture();
    try {
      const command = supplierMoneyCommand({entry: {...supplierMoneyCommand().entry, kind}});
      const bookBefore = (await f.original.root.get()).data(), service = new WorkspaceLedgerService(f.repo(), now);
      const reply = await service.handle(f.user, command.operation, body(command)) as Record<string, unknown>;
      if (process.env.AGG05_NATIVE_CAPTURE_PATH) writeFileSync(process.env.AGG05_NATIVE_CAPTURE_PATH + '.' + kind + '.json',
        JSON.stringify({label: 'ISOLATED ACTUAL SDK MANUAL MONEY; NOT BANK OR RUNTIME AUTHORITY',
          scope, now: confirmedAt, command, requestBody: body(command), response: reply}), {encoding: 'utf8', flag: 'wx'});
      const receipt = reply.attempt as LedgerReceipt, current = reply.current as LedgerRow;
      assert.equal(receipt.status, 'saved'); assert.equal(receipt.changed, true); assert.equal(receipt.entryId, command.entry.operationId);
      assert.deepEqual(JSON.parse(current.json).entries, [command.entry]);
      assert.equal(JSON.parse(current.json).revision, 2); assert.equal(reply.sourceRevision, 2);
      const reopened = await new WorkspaceLedgerService(f.repo(), now).handle(f.user, 'readStoreLedgerAttempt', {
        schemaVersion: 1, ledgerVersion: 1, scope, operation: 'readStoreLedgerAttempt',
        idempotencyKey: command.idempotencyKey, fingerprint: command.fingerprint}) as Record<string, unknown>;
      assert.deepEqual(reopened.attempt, receipt); assert.deepEqual(reopened.current, current);
      assert.deepEqual((await service.handle(f.user, command.operation, body(command)) as Record<string, unknown>).attempt, receipt);
      const noOp = await f.repo().recordSupplierMoney(f.user, resign({...command, idempotencyKey: 'HOST-exact-entry-recheck'}));
      assert.equal(noOp.receipt?.status, 'saved'); assert.equal(noOp.receipt?.changed, false); assert.equal(noOp.revision, 2);
      const conflict = await f.repo().recordSupplierMoney(f.user, resign({...command, idempotencyKey: 'HOST-divergent-entry',
        entry: {...command.entry, amountMinor: command.entry.amountMinor + 1}}));
      assert.equal(conflict.receipt?.reason, 'record_identity_conflict'); assert.equal(conflict.revision, 2);
      assert.deepEqual((await f.original.root.get()).data(), bookBefore, 'Recording manual money cannot rewrite original purchase evidence.');
      assert.deepEqual((await f.root.get()).get('counts'), {supplierLedger: 1, expense: 0, moneyRegister: 0, moneyEntry: 0});
      assert.equal((await f.root.collection('supplierEntryIdentities').get()).size, 1);
    } finally {await f.close();}
  });
test('AGG05 actual SDK concurrent exact supplier money never duplicates its accounting effect', {skip: !ledgerEmulator}, async () => {
  const f = await sdkManualSupplierFixture();
  try {
    const command = supplierMoneyCommand(), replies = await Promise.all([
      f.repo().recordSupplierMoney(f.user, command), f.repo().recordSupplierMoney(f.user, command)]);
    assert.ok(replies.every(reply => reply.receipt?.status === 'saved'));
    const saved = await f.repo().status(f.user, scope, command.idempotencyKey, command.fingerprint);
    assert.equal(saved.revision, 2); assert.deepEqual(JSON.parse(saved.current!.json).entries, [command.entry]);
    assert.equal((await f.root.collection('supplierEntryIdentities').get()).size, 1);
  } finally {await f.close();}
});
test('AGG05 actual SDK stale global and supplier revisions never silently rebase money', {skip: !ledgerEmulator}, async () => {
  const f = await sdkManualSupplierFixture();
  try {
    await f.repo().recordExpense(f.user, resign({...expenseCommand(), expectedRevision: 1}));
    const stale = await f.repo().recordSupplierMoney(f.user, supplierMoneyCommand());
    assert.equal(stale.receipt?.reason, 'stale_ledger'); assert.equal(stale.revision, 2);
    const wrongSupplierRevision = await f.repo().recordSupplierMoney(f.user, supplierMoneyCommand({expectedRevision: 2,
      expectedSupplierRevision: 2, idempotencyKey: 'HOST-stale-supplier'}));
    assert.equal(wrongSupplierRevision.receipt?.reason, 'stale_supplier');
    assert.deepEqual(JSON.parse(wrongSupplierRevision.current!.json).entries, []);
  } finally {await f.close();}
});
test('AGG05 actual SDK overpayment remains refused unless explicitly reviewed as an advance', {skip: !ledgerEmulator}, async () => {
  const f = await sdkManualSupplierFixture(1000);
  try {
    const payment = supplierMoneyCommand(), refused = await f.repo().recordSupplierMoney(f.user, payment);
    assert.equal(refused.receipt?.reason, 'supplier_capacity_changed'); assert.equal(refused.revision, 1);
    if (process.env.AGG05_NATIVE_CAPTURE_PATH) {
      const response = await new WorkspaceLedgerService(f.repo(), now).handle(f.user, payment.operation, body(payment));
      writeFileSync(process.env.AGG05_NATIVE_CAPTURE_PATH + '.refused.json', JSON.stringify({
        label: 'ISOLATED ACTUAL SDK REFUSAL; NO MONEY RECORDED', scope, now: confirmedAt,
        command: payment, requestBody: body(payment), response}), {encoding: 'utf8', flag: 'wx'});
    }
    const advance = supplierMoneyCommand({idempotencyKey: 'HOST-explicit-advance',
      entry: {...payment.entry, operationId: 'HOST-explicit-advance-entry', kind: 'advance'}});
    assert.equal((await f.repo().recordSupplierMoney(f.user, advance)).receipt?.status, 'saved');
    const after = supplierMoneyCommand({expectedRevision: 2, expectedSupplierRevision: 2, idempotencyKey: 'HOST-no-due',
      entry: {...payment.entry, operationId: 'HOST-no-due-entry', amountMinor: 1}});
    assert.equal((await f.repo().recordSupplierMoney(f.user, after)).receipt?.reason, 'supplier_capacity_changed');
    assert.equal((await f.repo().status(f.user, scope, advance.idempotencyKey, advance.fingerprint)).revision, 2);
  } finally {await f.close();}
});
test('AGG05 actual SDK opening evidence and local occurrence date are checked before publication', {skip: !ledgerEmulator}, async () => {
  const f = await sdkManualSupplierFixture();
  try {
    const base = supplierMoneyCommand();
    const wrong = supplierMoneyCommand({idempotencyKey: 'HOST-wrong-opening', entry: {...base.entry,
      moneyReview: {...base.entry.moneyReview, openingId: 'HOST-other-opening'}}});
    assert.equal((await f.repo().recordSupplierMoney(f.user, wrong)).receipt?.reason, 'opening_evidence_changed');
    const future = supplierMoneyCommand({idempotencyKey: 'HOST-future-occurrence', entry: {...base.entry,
      moneyReview: {...base.entry.moneyReview, occurredOn: '2026-10-30'}}});
    assert.equal((await f.repo().recordSupplierMoney(f.user, future)).receipt?.reason, 'supplier_money_evidence_invalid');
    const futureClock = supplierMoneyCommand({idempotencyKey: 'HOST-future-recording', entry: {...base.entry,
      postedAt: '2026-10-29T02:00:01.000Z'}});
    assert.equal((await f.repo().recordSupplierMoney(f.user, futureClock)).receipt?.reason, 'supplier_money_evidence_invalid');
    const previousUtcDay = {...base.entry, postedAt: '2026-10-28T23:30:00.000Z'};
    const wrongZone = supplierMoneyCommand({idempotencyKey: 'HOST-wrong-local-date', confirmedUtcOffsetMinutes: -480, entry: previousUtcDay});
    assert.equal((await f.repo().recordSupplierMoney(f.user, wrongZone)).receipt?.reason, 'supplier_money_evidence_invalid');
    const localDate = supplierMoneyCommand({idempotencyKey: 'HOST-explicit-local-date', entry: previousUtcDay});
    assert.equal((await f.repo().recordSupplierMoney(f.user, localDate)).receipt?.status, 'saved');
  } finally {await f.close();}
});
test('AGG05 actual SDK account/Store/realm membership and missing suppliers cannot create records', {skip: !ledgerEmulator}, async () => {
  const f = await sdkManualSupplierFixture();
  try {
    const command = supplierMoneyCommand();
    await assert.rejects(f.repo().recordSupplierMoney({...f.user, uid: 'HOST-other-account'}, command), code('permission_denied'));
    await assert.rejects(f.repo().recordSupplierMoney({...f.user, projectId: 'demo-foreign'}, command), code('permission_denied'));
    await assert.rejects(f.repo().recordSupplierMoney(f.user, resign({...command, scope: {...scope, realm: 'production'}})), code('permission_denied'));
    const missing = supplierMoneyCommand({supplierId: 'HOST-missing-supplier', idempotencyKey: 'HOST-missing-supplier-request'});
    assert.equal((await f.repo().recordSupplierMoney(f.user, missing)).receipt?.reason, 'supplier_unavailable');
    await f.grant.update({active: false});
    await assert.rejects(f.repo().recordSupplierMoney(f.user, command), code('permission_denied'));
    assert.equal((await f.root.get()).get('revision'), 1);
    assert.equal((await f.root.collection('supplierEntryIdentities').get()).size, 0);
  } finally {await f.close();}
});
test('AGG05 actual SDK supplier fact identity cannot be reused against another supplier', {skip: !ledgerEmulator}, async () => {
  const f = await sdkManualSupplierFixture(10000, true);
  try {
    const first = supplierMoneyCommand({expectedRevision: 2});
    assert.equal((await f.repo().recordSupplierMoney(f.user, first)).receipt?.status, 'saved');
    const second = supplierMoneyCommand({expectedRevision: 3, supplierId: 'HOST-supplier-second', idempotencyKey: 'HOST-cross-supplier',
      entry: {...first.entry, moneyReview: {...first.entry.moneyReview, openingId: 'HOST-opening-second', openingRevision: 3}}});
    const refused = await f.repo().recordSupplierMoney(f.user, second);
    assert.equal(refused.receipt?.reason, 'record_identity_conflict'); assert.equal(refused.revision, 3);
    assert.deepEqual(JSON.parse(refused.current!.json).entries, []);
    assert.equal((await f.root.collection('supplierEntryIdentities').get()).size, 1);
  } finally {await f.close();}
});
