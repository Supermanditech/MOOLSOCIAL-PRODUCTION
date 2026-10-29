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
import {assertStrictSchema, type PreparationRequest} from '../assistant/model_contract.js';
import {purchaseEntryCommandFingerprint, purchaseEntryOpeningCommandFingerprint, planPurchaseEntryOpening, workspaceOriginalRequestBodyLimit, WorkspacePurchaseEntryService,
  type PurchaseEntryBook} from './workspace_purchase_entry_service.js';
import {WorkspaceProfileError} from './workspace_profile_service.js';
import {
  WorkspaceLedgerService, checkedLedgerCommand, checkedLedgerExpense, checkedLedgerOpening,
  checkedLedgerRegisterHeader, checkedLedgerRegisterEntry, ledgerCanonical, ledgerHash, ledgerClone,
  ledgerCommandFingerprint, ledgerCommandInput, ledgerCommandTarget, ledgerConfirmedOpening,
  type LedgerActor, type LedgerScope, type LedgerCommand, type LedgerExpenseCommand,
  type LedgerOpeningCommand, type LedgerRegisterCommand, type LedgerExpense, type LedgerOpeningRecord,
  type LedgerRegisterHeader, type LedgerRepository, type LedgerPage, type LedgerRow, type LedgerStatus,
  type LedgerReceipt,
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

async function sdkPreparation(f: Awaited<ReturnType<typeof sdkLedger>>, options: {posted?: boolean; newOpening?: boolean; unavailable?: boolean} = {}) {
  await seedSdkRegister(f);
  const book = options.newOpening ? {...originalOpeningBook(), openingRecords: []} : originalOpeningBook();
  const purchase = await seedOriginalPurchase(f, book);
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
  for (const operation of ['saveStorePurchaseDraft', 'saveStoreSupplierOpeningEvidence', 'confirmStoreSupplierOpening']) {
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
