import assert from 'node:assert/strict';
import test from 'node:test';
import {createHash, randomUUID} from 'node:crypto';
import {writeFileSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
import {resolve} from 'node:path';
import {initializeApp, deleteApp} from 'firebase-admin/app';
import {getFirestore, type Firestore, type Transaction} from 'firebase-admin/firestore';
import {
  WorkspacePurchaseEntryService, checkedPurchaseEntryBook, planPurchaseEntrySupplier,
  purchaseEntryCanonical, purchaseEntryClone, purchaseEntryCommandFingerprint,
  purchaseEntryError, purchaseEntryHash, purchaseEntryMicros, purchaseEntryOperation,
  checkedPurchaseEntryDraft, checkedPurchaseEntryCopy, planPurchaseEntryDraft, purchaseEntryDraftCommandFingerprint, purchaseEntryInvoiceFinancialYear,
  type PurchaseEntryActor, type PurchaseEntryBook, type PurchaseEntryScope,
  type PurchaseEntrySupplier, type PurchaseEntrySupplierCommand, type PurchaseEntryRepository,
  type PurchaseEntryDraft, type PurchaseEntryCopy, type PurchaseEntryDraftCommand,
} from './workspace_purchase_entry_service.js';
import {FirestorePurchaseEntryRepository, type PurchaseEntryTransactionAuthority} from './workspace_purchase_entry_repository.js';

const at = '2026-10-29T00:00:00.123456Z';
const scope: PurchaseEntryScope = {account: 'HOST-account', store: 'HOST-store', realm: 'evaluation'};
const actor: PurchaseEntryActor = {uid: scope.account, projectId: 'demo-agg03-host'};
function profile(id = 'HOST-manual-supplier'): PurchaseEntrySupplier {
  return {id, name: 'HOST भारतीय વેપારી', phone: '', address: 'HOST billing address', gstin: '',
    source: 'manual', createdAt: at, updatedAt: at};
}
function command(p = profile(), expectedRevision: number | null = null, key = 'HOST-original-save'): PurchaseEntrySupplierCommand {
  const input = {scope: purchaseEntryClone(scope), expectedRevision, idempotencyKey: key, profile: purchaseEntryClone(p)};
  return {...input, fingerprint: purchaseEntryCommandFingerprint(input)};
}
function common() {return {schemaVersion: 1, purchaseEntryVersion: 1, actorAccountId: scope.account, realm: scope.realm, storeId: scope.store};}
function saveBody(c = command()): Record<string, unknown> {
  return {...common(), expectedRevision: c.expectedRevision, idempotencyKey: c.idempotencyKey,
    fingerprint: c.fingerprint, profile: purchaseEntryClone(c.profile)};
}
function code(expected: string) {return (error: unknown) => !!error && typeof error === 'object' && 'code' in error && error.code === expected;}
function book(p = profile()): PurchaseEntryBook {return planPurchaseEntrySupplier(command(p), null).book;}
function draft(id = 'HOST-manual-draft'): PurchaseEntryDraft {
  return {id, supplierId: profile().id, invoiceReference: 'HOST-BILL-1', invoiceDate: '29/10/2026',
    createdAt: at, updatedAt: at, source: 'manual', stage: 'draft',
    goods: [{productId: '', name: 'HOST printed item', pack: 'HOST pack', quantity: '1', cost: ''}]};
}
function reviewedCopy(d = draft(), revision = 1): PurchaseEntryCopy {
  return {id: `${d.id}-reviewed-r${revision}`, storeName: 'HOST Store', revision, savedAt: '2026-10-29T00:00:00.223456Z',
    supplier: profile(), draft: purchaseEntryClone(d), labels: {name: 'HOST printed product label'}};
}
function draftCommand(d = draft(), expectedRevision: number | null = null, copy: PurchaseEntryCopy | null = null,
  replaceReviewedDraftId: string | null = null, key = 'HOST-original-draft-save'): PurchaseEntryDraftCommand {
  const input = {scope: purchaseEntryClone(scope), profile: profile(), draft: purchaseEntryClone(d), reviewedCopy: purchaseEntryClone(copy),
    replaceReviewedDraftId, expectedRevision, idempotencyKey: key};
  return {...input, fingerprint: purchaseEntryDraftCommandFingerprint(input)};
}
function draftBody(c = draftCommand()): Record<string, unknown> {
  const {scope: _, ...fields} = c; return {...common(), ...fields};
}

test('AGG03 manual draft command preserves raw partial fields, all rows and unrelated original records', () => {
  const original = {...book(), openingRecords: [{HOST: 'keep opening evidence'}], goodsReceiptDrafts: [{HOST: 'keep receiving draft'}]},
    raw = {...draft(), invoiceReference: '', invoiceDate: '', details: {invoiceTotal: '', notes: 'HOST owner note'},
      goods: Array.from({length: 205}, (_, i) => ({productId: '', name: `HOST line ${i + 1}`, pack: '', quantity: '', cost: ''}))},
    next = planPurchaseEntryDraft(draftCommand(raw, 1), original);
  assert.equal(next.book.revision, 2); assert.equal(next.changed, true); assert.deepEqual(next.book.draft, raw);
  assert.deepEqual(next.book.openingRecords, original.openingRecords); assert.deepEqual(next.book.goodsReceiptDrafts, original.goodsReceiptDrafts);
  assert.equal(Object.hasOwn(next.book, 'copies'), false); assert.equal((next.book.draft as PurchaseEntryDraft).goods.length, 205);
  assert.equal((next.book.draft as PurchaseEntryDraft).goods[0]!.cost, '', 'Unknown cost must not become zero.');
});

test('AGG03 manual draft and reviewed copy preserve native identity, revision and duplicate financial-year rules', () => {
  const d = draft(), first = planPurchaseEntryDraft(draftCommand(d, null, reviewedCopy(d)), null).book,
    emptyNext = {...draft('HOST-next-draft'), invoiceReference: '  host-bill-1  '};
  assert.equal((first.copies![0] as PurchaseEntryCopy).revision, 1);
  assert.throws(() => planPurchaseEntryDraft(draftCommand({...d, id: 'HOST-wrong-draft'}, 1), first), code('stale_draft'));
  assert.throws(() => planPurchaseEntryDraft(draftCommand({...d, createdAt: '2026-10-29T00:00:00.123455Z'}, 1), first), code('stale_draft'));
  assert.throws(() => planPurchaseEntryDraft(draftCommand(emptyNext, 1, reviewedCopy(emptyNext, 2), d.id), first), code('duplicate_invoice'));
  const followingYear = {...emptyNext, invoiceDate: '01/04/2027'}, accepted = planPurchaseEntryDraft(
    draftCommand(followingYear, 1, reviewedCopy(followingYear, 2), d.id), first);
  assert.equal(accepted.book.revision, 2); assert.equal(accepted.book.copies!.length, 2);
  assert.deepEqual(accepted.book.copies![0], first.copies![0]);
  assert.throws(() => planPurchaseEntryDraft(draftCommand(d, 2, null, followingYear.id), accepted.book), code('stale_draft'));
  const repeat = planPurchaseEntryDraft(draftCommand(followingYear, 2, reviewedCopy(followingYear, 3)), accepted.book);
  assert.equal(repeat.book.copies!.length, 3, 'A later review of this same draft must not be classified as another duplicate invoice.');
  assert.equal(purchaseEntryInvoiceFinancialYear('31/03/2027'), 2026); assert.equal(purchaseEntryInvoiceFinancialYear('01/04/2027'), 2027);
  assert.equal(purchaseEntryInvoiceFinancialYear('29/02/2026'), null); assert.equal(purchaseEntryInvoiceFinancialYear('2024-02-29'), 2023);
});

test('AGG03 exact immutable copy acknowledgement never rolls current supplier or draft back', () => {
  const d = draft(), copy = reviewedCopy(d), original = planPurchaseEntryDraft(draftCommand(d, null, copy), null).book,
    p = {...profile(), name: 'HOST later contact', updatedAt: '2026-10-29T00:00:00.323456Z'},
    later = planPurchaseEntrySupplier(command(p, 1, 'HOST-later-contact'), original).book,
    replay = planPurchaseEntryDraft(draftCommand(d, null, copy), later);
  assert.equal(replay.changed, false); assert.deepEqual(replay.book, later); assert.equal(replay.profile.name, copy.supplier.name);
  assert.throws(() => planPurchaseEntryDraft(draftCommand(d, 2, {...copy, labels: {name: 'HOST changed copy'}}), later), code('immutable_copy_conflict'));
});

test('AGG03 unreviewed or ambiguous draft cannot be silently replaced', () => {
  const d = draft(), unreviewed = planPurchaseEntryDraft(draftCommand(d), null).book, next = draft('HOST-new-draft');
  assert.throws(() => planPurchaseEntryDraft(draftCommand(next, 1, null, d.id), unreviewed), code('stale_draft'));
  const copy = reviewedCopy(d), ambiguous = {...unreviewed, copies: [copy, {...copy, id: 'HOST-second-ambiguous-copy'}]};
  assert.throws(() => planPurchaseEntryDraft(draftCommand(next, 1, null, d.id), ambiguous), code('stale_draft'));
});

test('AGG03 manual draft rejects invented accounting fields, invalid printed references and timezone-less fresh copies', () => {
  for (const invalid of [
    {...draft(), ledgerPosted: true}, {...draft(), details: {inventedTaxDecision: 'approved'}},
    {...draft(), goods: [{productId: '', name: 'HOST', pack: '', quantity: '', cost: '', stockPosted: 'yes'}]},
    {...draft(), additionalFields: [{version: 1, id: 'HOST-field', label: 'HOST', value: '', section: 'items', reviewed: true, itemIndex: 9}]},
  ]) assert.throws(() => checkedPurchaseEntryDraft(invalid));
  assert.throws(() => checkedPurchaseEntryCopy({...reviewedCopy(), savedAt: '2026-10-29T00:00:00.223456'}, true));
  const retained = {...reviewedCopy(), savedAt: '2026-10-29T00:00:00.223456'};
  assert.deepEqual(checkedPurchaseEntryCopy(retained, false), retained, 'Historical bytes remain untouched.');
});

test('AGG03 a local file declaration cannot become a saved remote original', () => {
  const d = {...draft(), attachments: [{owner: 'HOST-local-private-path', digest: '1'.repeat(64), byteLength: 8}]};
  assert.throws(() => planPurchaseEntryDraft(draftCommand(d), null), code('private_original_unavailable'));
});

test('AGG03 authenticated endpoint dispatch admits only the original read Save and status operations', async () => {
  assert.deepEqual(['readStorePurchaseEntryBook', 'saveStoreSupplierProfile', 'readStorePurchaseEntryAttempt'].map(purchaseEntryOperation),
    ['read', 'saveSupplier', 'status']);
  assert.equal(purchaseEntryOperation('replaceStorePurchaseBook'), undefined);
  const service = new WorkspacePurchaseEntryService();
  await assert.rejects(service.handle(actor, 'replaceStorePurchaseBook', common()), code('invalid_input'));
  await assert.rejects(service.handle(actor, 'readStorePurchaseEntryBook', common()), code('service_unavailable'));
});

test('AGG03 native UTC capture microseconds are preserved and compared without rounding', () => {
  assert.equal(purchaseEntryMicros(at) - purchaseEntryMicros('2026-10-29T00:00:00.123455Z'), 1n);
  assert.equal(purchaseEntryMicros('2026-10-29T00:00:00.123Z'), purchaseEntryMicros('2026-10-29T00:00:00.123000Z'));
  assert.throws(() => purchaseEntryMicros('2026-02-30T00:00:00.123Z'), code('invalid_input'));
  const saved = book();
  assert.equal(saved.profiles[0]!.createdAt, at);
  assert.throws(() => planPurchaseEntrySupplier(command({...profile(), updatedAt: '2026-10-29T00:00:00.123455Z'}, 1), saved), code('invalid_input'));
});
test('AGG03 contact command preserves every unrelated original section and optional omissions', () => {
  const original: PurchaseEntryBook = {...book(), draft: {HOST_opaque_private_draft: 'unchanged'},
    copies: [{HOST_retained_copy: [1, 2]}], openingRecords: [{HOST_opening: 'unposted'}],
    goodsReceiptDrafts: [{HOST_review: 'not physical receipt'}], goodsReceiptCancellations: [{HOST_cancel: 'retained'}],
    billGoodsReviews: [{HOST_match: 'retained'}], billGoodsCancellations: [{HOST_cancel: 'retained'}],
    restockGoodsAttempts: [{HOST_attempt: 'retained'}]};
  const before = purchaseEntryCanonical(original), next = planPurchaseEntrySupplier(command({...profile(), name: 'HOST updated'}, 1), original).book;
  assert.equal(purchaseEntryCanonical(original), before);
  for (const key of ['draft', 'copies', 'openingRecords', 'goodsReceiptDrafts', 'goodsReceiptCancellations',
    'billGoodsReviews', 'billGoodsCancellations', 'restockGoodsAttempts'] as const) assert.deepEqual(next[key], original[key]);
  assert.equal(next.revision, 2);
  const fresh = book();
  assert.equal(Object.hasOwn(fresh, 'copies'), false);
  assert.equal(Object.hasOwn(planPurchaseEntrySupplier(command({...profile(), name: 'HOST changed'}, 1), fresh).book, 'copies'), false);
});
test('AGG03 unchanged Save is a no-op only after current original CAS', () => {
  const original = book(), result = planPurchaseEntrySupplier(command(profile(), 1), original);
  assert.equal(result.changed, false); assert.equal(result.book.revision, 1);
  assert.throws(() => planPurchaseEntrySupplier(command(profile(), null), original), code('stale_book'));
  assert.throws(() => planPurchaseEntrySupplier(command(profile(), 2), original), code('stale_book'));
  assert.throws(() => planPurchaseEntrySupplier(command(profile(), 1), {...original, account: 'HOST-foreign'}), code('service_unavailable'));
});

test('AGG03 native timestamp precision normalisation keeps unchanged supplier and book bytes intact', () => {
  const stored = {...profile(), createdAt: '2026-10-29T00:00:00.123000Z', updatedAt: '2026-10-29T00:00:00.123000Z'},
    native = {...stored, createdAt: '2026-10-29T00:00:00.123Z', updatedAt: '2026-10-29T00:00:00.123Z'}, original = book(stored),
    before = purchaseEntryCanonical(original), planned = planPurchaseEntrySupplier(command(native, 1), original);
  assert.equal(planned.changed, false); assert.equal(planned.book.revision, 1);
  assert.equal(purchaseEntryCanonical(planned.book), before); assert.deepEqual(planned.profile, native);
  const changed = planPurchaseEntrySupplier(command({...native, name: 'HOST explicit edit', updatedAt: '2026-10-29T00:00:01.000Z'}, 1), original);
  assert.equal(changed.changed, true); assert.equal(changed.book.revision, 2);
});
test('AGG03 native legacy duplicate no-op is preserved while a new conflicting contact is rejected', () => {
  const p = {...profile(), phone: '+919999999999'}, original = {...book(p), profiles: [p, {...p, id: 'HOST-legacy-second'}]};
  assert.equal(planPurchaseEntrySupplier(command(p, 1), original).changed, false);
  assert.throws(() => planPurchaseEntrySupplier(command({...profile('HOST-new'), phone: p.phone}, 1), original), code('duplicate_supplier'));
  const gst = '00HOST0000A0Z00';
  const old = {...book(), profiles: [{...profile(), gstin: gst}]};
  assert.throws(() => planPurchaseEntrySupplier(command({...profile('HOST-other'), gstin: gst}, 1), old), code('duplicate_supplier'));
});
test('AGG03 original identity and captured dates cannot be reassigned or regressed', () => {
  const original = book({...profile(), updatedAt: '2026-10-29T00:00:00.123457Z'});
  assert.throws(() => planPurchaseEntrySupplier(command({...profile(), createdAt: '2026-10-29T00:00:00.123455Z'}, 1), original), code('stale_book'));
  assert.throws(() => planPurchaseEntrySupplier(command({...profile(), name: 'HOST edit'}, 1), original), code('stale_book'));
  assert.throws(() => checkedPurchaseEntryBook({...original, profiles: [profile(), profile()]}, scope), code('service_unavailable'));
  assert.throws(() => checkedPurchaseEntryBook({...original, unexpectedLedgerAuthority: true}, scope), code('invalid_input'));
});
for (const [field, value] of [['name', ''], ['name', 'x'.repeat(121)], ['address', 'x'.repeat(501)],
  ['phone', 'verified by platform'], ['gstin', 'VERIFIED'], ['source', 'restock'], ['updatedAt', 'not a date']] as const) {
  test(`AGG03 supplier input rejects unsupported ${field} without creating original facts`, () => {
    assert.throws(() => planPurchaseEntrySupplier(command({...profile(), [field]: value} as PurchaseEntrySupplier), null), code('invalid_input'));
  });
}
test('AGG03 protocol rejects tenant, wrong project, actor echoes and unknown body fields before source IO', async () => {
  let reads = 0;
  const repo: PurchaseEntryRepository = {realm: 'evaluation', projectId: actor.projectId,
    read: async () => {reads++; return null;}, saveSupplier: async () => {throw new Error('no write expected');},
    status: async () => {throw new Error('no status expected');}};
  const service = new WorkspacePurchaseEntryService(repo);
  for (const other of [{...actor, tenantId: 'HOST-tenant'}, {...actor, projectId: 'HOST-other-project'}]) {
    await assert.rejects(service.read(other, common()), code('permission_denied'));
  }
  await assert.rejects(service.read(actor, {...common(), actorAccountId: 'HOST-other'}), code('permission_denied'));
  await assert.rejects(service.read(actor, {...common(), force: true}), code('invalid_input'));
  await assert.rejects(service.read(actor, {...common(), realm: 'production'}), code('permission_denied'));
  assert.equal(reads, 0);
  await assert.rejects(new WorkspacePurchaseEntryService().read(actor, common()), code('service_unavailable'));
});
test('AGG03 backend evaluation realm never promotes a local review-QA book', () => {
  const original = book();
  assert.equal(original.qa, false);
  assert.throws(() => checkedPurchaseEntryBook({...original, qa: true}, scope), code('service_unavailable'));
});
test('AGG03 protocol fingerprint pins original fields and never accepts a whole-book PUT', async () => {
  const service = new WorkspacePurchaseEntryService({realm: 'evaluation', projectId: actor.projectId,
    read: async () => null, saveSupplier: async () => {throw new Error('No invalid input may reach the writer');},
    status: async () => ({receipt: null, currentBook: null})});
  await assert.rejects(service.saveSupplier(actor, {...saveBody(), fingerprint: '0'.repeat(64)}), code('invalid_input'));
  await assert.rejects(service.saveSupplier(actor, {...saveBody(), book: book()}), code('invalid_input'));
  const result = await service.status(actor, {...common(), idempotencyKey: 'HOST-not-recorded', fingerprint: command().fingerprint}) as Record<string, unknown>;
  assert.equal(result.state, 'empty'); assert.equal(result.attempt, null); assert.equal(result.bookJson, null);
});

const emulator = process.env.FIRESTORE_EMULATOR_HOST;
interface Fixture {
  db: Firestore; actor: PurchaseEntryActor; repo: () => FirestorePurchaseEntryRepository;
  authority: PurchaseEntryTransactionAuthority; scope: PurchaseEntryScope;
  grant: ReturnType<Firestore['doc']>; root: ReturnType<Firestore['doc']>;
  setBarrier: (callback: (transaction: Transaction) => Promise<void>) => void;
  close: () => Promise<void>;
}
async function fixture(): Promise<Fixture> {
  assert.match(emulator!, /^127\.0\.0\.1:\d+$/u, 'Actual repository tests are loopback-only, never cloud.');
  const projectId = 'demo-agg03-' + randomUUID().slice(0, 8), app = initializeApp({projectId}, 'agg03-' + randomUUID()),
    db = getFirestore(app), currentActor = {...actor, projectId}, grant = db.doc('HOST_ONLY_TEST_AUTHORITY/' + randomUUID());
  await grant.set({label: 'ISOLATED HOST AUTHORITY FIXTURE; NOT A MEMBERSHIP ISSUER', active: true, account: scope.account, store: scope.store});
  let barrier: ((transaction: Transaction) => Promise<void>) | undefined;
  const authority: PurchaseEntryTransactionAuthority = {assertCurrent: async (transaction, user, requested) => {
    // A committed revocation must win before this transaction reads/locks its
    // authority source. Waiting for a conflicting write while holding that lock
    // would test a fixture deadlock, not rejected stale authority.
    if (barrier) await barrier(transaction);
    const source = await transaction.get(grant);
    if (user.uid !== source.get('account') || requested.store !== source.get('store') || !source.get('active')) purchaseEntryError('permission_denied', 403);
  }};
  const root = db.collection('privateWorkspacePurchaseEntriesV1').doc(purchaseEntryHash({projectId, scope}));
  return {db, actor: currentActor, authority, scope, grant, root,
    repo: () => new FirestorePurchaseEntryRepository(db, 'evaluation', projectId, authority, () => new Date('2026-10-29T00:00:01.000Z')),
    setBarrier: value => {barrier = value;}, close: async () => {await db.terminate(); await deleteApp(app);}};
}
test('AGG03 actual SDK duplicate Save, backend restart and original receipt recovery', {skip: !emulator}, async () => {
  const f = await fixture();
  try {
    const c = command(), results = await Promise.all([f.repo().saveSupplier(f.actor, c), f.repo().saveSupplier(f.actor, c)]);
    assert.equal(results[0]!.currentBook!.revision, 1); assert.deepEqual(results[0], results[1]);
    const recovered = await f.repo().status(f.actor, scope, c.idempotencyKey, c.fingerprint);
    if (process.env.AGG03_CAPTURE_PATH) {
      const service = new WorkspacePurchaseEntryService(f.repo());
      const response = await service.handle(f.actor, 'readStorePurchaseEntryAttempt', {...common(), idempotencyKey: c.idempotencyKey, fingerprint: c.fingerprint});
      const readResponse = await service.handle(f.actor, 'readStorePurchaseEntryBook', common());
      writeFileSync(process.env.AGG03_CAPTURE_PATH, JSON.stringify({label: 'ISOLATED HOST SDK RESPONSE; NOT PHONE OR LIVE AUTHORITY', command: c, request: saveBody(c), response, readResponse}, null, 2)+'\n', {encoding: 'utf8', flag: 'wx'});
    }
    assert.equal(recovered.receipt!.resultRevision, 1); assert.equal((await f.root.collection('attempts').get()).size, 1);
    const second = command({...profile(), name: 'HOST current contact', updatedAt: '2026-10-29T00:00:02.000Z'}, 1, 'HOST-next-save');
    await f.repo().saveSupplier(f.actor, second);
    const old = await new WorkspacePurchaseEntryService(f.repo()).saveSupplier(f.actor, saveBody(c)) as Record<string, unknown>;
    assert.equal((old.attempt as {resultRevision: number}).resultRevision, 1);
    const currentBook = JSON.parse(old.bookJson as string) as PurchaseEntryBook;
    assert.equal(currentBook.revision, 2);
    assert.equal(currentBook.profiles[0]!.name, second.profile.name);
    assert.equal(createHash('sha256').update(old.bookJson as string, 'utf8').digest('hex'), old.bookFingerprint);
    await assert.rejects(f.repo().saveSupplier(f.actor, command({...profile(), name: 'HOST conflicting payload'}, null, c.idempotencyKey)), code('idempotency_conflict'));
    const stale = await f.repo().saveSupplier(f.actor, command(profile('HOST-stale'), 1, 'HOST-stale-save'));
    assert.equal(stale.receipt!.status, 'not_saved'); assert.equal(stale.receipt!.reason, 'stale_book');
    assert.equal(stale.receipt!.changed, false);
    assert.equal((await f.repo().read(f.actor, scope))!.revision, 2);
  } finally {await f.close();}
});

test('AGG03 actual SDK terminal duplicate refusal survives restart and prevents a late same-key write', {skip: !emulator}, async () => {
  const f = await fixture();
  try {
    const first = command({...profile(), phone: '9876543210'});
    await f.repo().saveSupplier(f.actor, first);
    const duplicate = command({...profile('HOST-duplicate'), phone: first.profile.phone}, 1, 'HOST-duplicate-save');
    const declined = await f.repo().saveSupplier(f.actor, duplicate);
    assert.equal(declined.receipt!.status, 'not_saved'); assert.equal(declined.receipt!.reason, 'duplicate_supplier');
    assert.equal(declined.currentBook!.revision, 1);
    await f.repo().saveSupplier(f.actor, command({...first.profile, phone: '', updatedAt: '2026-10-29T00:00:02.000Z'}, 1, 'HOST-edit-after-refusal'));
    const replay = await f.repo().saveSupplier(f.actor, duplicate);
    assert.deepEqual(replay.receipt, declined.receipt); assert.equal(replay.currentBook!.revision, 2);
    assert.equal(replay.currentBook!.profiles.length, 1);
    const fresh = await f.repo().saveSupplier(f.actor, command(duplicate.profile, 2, 'HOST-explicit-new-review'));
    assert.equal(fresh.receipt!.status, 'saved'); assert.equal(fresh.currentBook!.revision, 3);
  } finally {await f.close();}
});

test('AGG03 actual SDK lost head with a saved receipt is corruption rather than a fresh empty original', {skip: !emulator}, async () => {
  const f = await fixture();
  try {
    await f.repo().saveSupplier(f.actor, command()); await f.root.delete();
    await assert.rejects(f.repo().read(f.actor, scope), code('service_unavailable'));
    await assert.rejects(f.repo().saveSupplier(f.actor, command(profile('HOST-new'), null, 'HOST-new-key')), code('service_unavailable'));
    assert.equal((await f.root.get()).exists, false);
  } finally {await f.close();}
});
test('AGG03 actual transaction rejects revoked original authority before head publication', {skip: !emulator}, async () => {
  const f = await fixture();
  let entered!: () => void, release!: () => void;
  const held = new Promise<void>(resolve => {entered = resolve;}), resume = new Promise<void>(resolve => {release = resolve;});
  let blocked = false;
  try {
    f.setBarrier(async () => {
      if (!blocked && !(await f.root.get()).exists && !(await f.root.collection('originals').limit(1).get()).empty) {
        blocked = true; entered(); await resume;
      }
    });
    const operation = f.repo().saveSupplier(f.actor, command());
    const terminal = operation.then(value => ({value}), error => ({error}));
    let timer: ReturnType<typeof setTimeout> | undefined;
    try {await Promise.race([held, new Promise<never>((_, reject) => {
      timer = setTimeout(() => reject(new Error('Publish boundary was not reached')), 15000); timer.unref();
    })]);} finally {if (timer) clearTimeout(timer);}
    await f.grant.update({active: false}); release();
    const result = await terminal; assert.ok('error' in result && code('permission_denied')(result.error));
    assert.equal((await f.root.get()).exists, false); assert.equal((await f.root.collection('attempts').get()).size, 0);
    assert.equal((await f.root.collection('originals').get()).empty, false, 'Unpublished staging must not count as Save.');
    await assert.rejects(f.repo().read(f.actor, scope), code('permission_denied'));
  } finally {release(); await f.close();}
});
test('AGG03 actual SDK absent authority, foreign actors and damaged originals never become empty success', {skip: !emulator}, async () => {
  const f = await fixture();
  try {
    const unavailable = new FirestorePurchaseEntryRepository(f.db, 'evaluation', f.actor.projectId);
    await assert.rejects(unavailable.read(f.actor, scope), code('service_unavailable'));
    await assert.rejects(f.repo().read({...f.actor, uid: 'HOST-other'}, scope), code('permission_denied'));
    await assert.rejects(f.repo().read({...f.actor, tenantId: 'HOST-tenant'}, scope), code('permission_denied'));
    const saved = await f.repo().saveSupplier(f.actor, command()); assert.equal(saved.currentBook!.revision, 1);
    const head = (await f.root.get()).data()!, pointer = head.original as {id: string};
    const first = f.root.collection('originals').doc(pointer.id).collection('parts').doc('00000');
    await first.update({data: Buffer.from('HOST damaged original').toString('base64')});
    await assert.rejects(f.repo().read(f.actor, scope), code('service_unavailable'));
    assert.deepEqual((await f.root.get()).data(), head, 'Recovery must not rewrite or clear the original head.');
  } finally {await f.close();}
});

/** An already-owned original seeded only inside the volatile host emulator.
 * This is not an adoption API and does not qualify legacy phone migration. */
async function seedOwnedBook(f: Fixture, original: PurchaseEntryBook): Promise<void> {
  const data = Buffer.from(purchaseEntryCanonical(original), 'utf8'), size = 192 * 1024,
    fingerprint = createHash('sha256').update(data).digest('hex'),
    pointer = {id: purchaseEntryHash({scope, revision: original.revision, fingerprint}), fingerprint,
      byteLength: data.length, parts: Math.ceil(data.length / size), revision: original.revision};
  const ref = f.root.collection('originals').doc(pointer.id);
  for (let index = 0; index < pointer.parts; index++) {
    const bytes = data.subarray(index * size, Math.min((index + 1) * size, data.length));
    await ref.collection('parts').doc(String(index).padStart(5, '0')).create({schemaVersion: 1, index,
      data: bytes.toString('base64'), fingerprint: createHash('sha256').update(bytes).digest('hex')});
  }
  await ref.create({schemaVersion: 1, projectId: f.actor.projectId, scope, ...pointer});
  await f.root.create({schemaVersion: 1, projectId: f.actor.projectId, scope, original: pointer});
}

test('AGG03 actual SDK native-normalised no-op receipt retains the original stored head and bytes', {skip: !emulator}, async () => {
  const f = await fixture();
  try {
    const stored = {...profile(), createdAt: '2026-10-29T00:00:00.123000Z', updatedAt: '2026-10-29T00:00:00.123000Z'},
      native = {...stored, createdAt: '2026-10-29T00:00:00.123Z', updatedAt: '2026-10-29T00:00:00.123Z'}, original = book(stored);
    await seedOwnedBook(f, original); const head = (await f.root.get()).data();
    const result = await new WorkspacePurchaseEntryService(f.repo()).saveSupplier(f.actor, saveBody(command(native, 1)));
    assert.deepEqual((await f.root.get()).data(), head);
    assert.equal((result as {bookJson: string}).bookJson, purchaseEntryCanonical(original));
    const recovered = await f.repo().status(f.actor, scope, command(native, 1).idempotencyKey, command(native, 1).fingerprint);
    assert.equal(recovered.receipt!.status, 'saved'); assert.equal(recovered.receipt!.changed, false);
    assert.equal(recovered.receipt!.profile.createdAt, native.createdAt);
  } finally {await f.close();}
});

test('AGG03 actual SDK manual purchase Save is exactly once and recovers in an independent backend process', {skip: !emulator}, async () => {
  const f = await fixture();
  try {
    const d = draft(), c = draftCommand(d, null, reviewedCopy(d)), saved = await Promise.all([
      f.repo().savePurchaseDraft(f.actor, c), f.repo().savePurchaseDraft(f.actor, c)]);
    assert.deepEqual(saved[0], saved[1]); assert.equal(saved[0]!.receipt!.operation, 'savePurchaseDraft');
    assert.equal(saved[0]!.currentBook!.revision, 1); assert.equal(saved[0]!.currentBook!.copies!.length, 1);
    assert.equal((await f.root.collection('attempts').get()).size, 1);
    assert.ok(Buffer.byteLength(JSON.stringify(saved[0]!.receipt), 'utf8') < 4096, 'Receipt must not embed a large draft or file declaration.');
    const service = new WorkspacePurchaseEntryService(f.repo());
    const response = await service.handle(f.actor, 'saveStorePurchaseDraft', draftBody(c)), readResponse = await service.read(f.actor, common());
    if (process.env.AGG03_DRAFT_CAPTURE_PATH) writeFileSync(process.env.AGG03_DRAFT_CAPTURE_PATH,
      JSON.stringify({label: 'ISOLATED HOST ORIGINAL SDK DATA; NOT PHONE OR LIVE AUTHORITY', command: c, response, readResponse}, null, 2)+'\n', {encoding: 'utf8', flag: 'wx'});
    const restart = spawnSync(process.execPath, ['--input-type=module', '-e', `
      import {initializeApp,deleteApp} from 'firebase-admin/app';import {getFirestore} from 'firebase-admin/firestore';
      import {FirestorePurchaseEntryRepository} from './lib/workspace/workspace_purchase_entry_repository.js';
      if(!/^127\\.0\\.0\\.1:\\d+$/.test(process.env.FIRESTORE_EMULATOR_HOST??''))throw Error('Loopback SDK only');
      const f=JSON.parse(process.env.AGG03_RESTART_FIXTURE),app=initializeApp({projectId:f.actor.projectId}),db=getFirestore(app);
      try{const repo=new FirestorePurchaseEntryRepository(db,'evaluation',f.actor.projectId,{assertCurrent:async(tx,actor,scope)=>{
        const grant=await tx.get(db.doc(f.grant));if(!grant.get('active')||grant.get('account')!==actor.uid||grant.get('store')!==scope.store)throw Error('HOST authority denied');
      }});const result=await repo.status(f.actor,f.scope,f.key,f.fingerprint);process.stdout.write(JSON.stringify({status:result.receipt.status,revision:result.currentBook.revision,copyId:result.receipt.copyId}));}
      finally{await db.terminate();await deleteApp(app);}`],
    {cwd: resolve(__dirname, '../..'), env: {...process.env, AGG03_RESTART_FIXTURE: JSON.stringify({actor: f.actor, scope, grant: f.grant.path,
      key: c.idempotencyKey, fingerprint: c.fingerprint})}, encoding: 'utf8', timeout: 30000, maxBuffer: 1024 * 1024});
    assert.equal(restart.error, undefined); assert.equal(restart.status, 0, restart.stderr);
    assert.deepEqual(JSON.parse(restart.stdout), {status: 'saved', revision: 1, copyId: c.reviewedCopy!.id});
    const later = command({...profile(), name: 'HOST newer contact', updatedAt: '2026-10-29T00:00:02.000Z'}, 1, 'HOST-after-purchase-contact');
    await f.repo().saveSupplier(f.actor, later);
    const recovered = await f.repo().savePurchaseDraft(f.actor, c);
    assert.deepEqual(recovered.receipt, saved[0]!.receipt); assert.equal(recovered.currentBook!.profiles[0]!.name, later.profile.name);
    assert.equal(recovered.currentBook!.revision, 2); assert.equal(recovered.currentBook!.copies!.length, 1);
  } finally {await f.close();}
});

test('AGG03 actual committed draft with lost transaction acknowledgement recovers only its original receipt', {skip: !emulator}, async () => {
  const f = await fixture(), actual = f.db.runTransaction.bind(f.db); let lost = false, commits = 0;
  // HOST transport fault only. The real SDK transaction still commits its
  // original book and receipt before its acknowledgement is deliberately lost.
  f.db.runTransaction = (async (update: (tx: Transaction) => Promise<unknown>, options?: object) => {
    let createsReceipt = false;
    const result = await actual(async tx => update(new Proxy(tx, {get(target, key) {
      if (key === 'create') return ((...args: Parameters<Transaction['create']>) => {
        if (args[0].path.startsWith(f.root.path + '/attempts/')) createsReceipt = true;
        return target.create(...args);
      });
      const value = Reflect.get(target, key, target);
      return typeof value === 'function' ? value.bind(target) : value;
    }})), options);
    if (createsReceipt) {commits++; if (!lost) {lost = true; throw new Error('HOST lost committed transaction acknowledgement');}}
    return result;
  }) as Firestore['runTransaction'];
  try {
    const d = draft(), c = draftCommand(d, null, reviewedCopy(d));
    const result = await f.repo().savePurchaseDraft(f.actor, c);
    assert.equal(lost, true); assert.equal(commits, 1); assert.equal(result.receipt!.status, 'saved');
    assert.equal(result.currentBook!.revision, 1); assert.equal((await f.root.collection('attempts').get()).size, 1);
    assert.deepEqual((await f.repo().status(f.actor, scope, c.idempotencyKey, c.fingerprint)).receipt, result.receipt);
  } finally {f.db.runTransaction = actual; await f.close();}
});

test('AGG03 actual SDK duplicate-bill refusal is durable and a corrected explicit review uses a new nonce', {skip: !emulator}, async () => {
  const f = await fixture();
  try {
    const first = draft(); await f.repo().savePurchaseDraft(f.actor, draftCommand(first, null, reviewedCopy(first)));
    const next = draft('HOST-next-bill'), duplicate = draftCommand(next, 1, reviewedCopy(next, 2), first.id, 'HOST-duplicate-bill');
    const declined = await f.repo().savePurchaseDraft(f.actor, duplicate);
    assert.equal(declined.receipt!.status, 'not_saved'); assert.equal(declined.receipt!.reason, 'duplicate_invoice');
    assert.equal(declined.currentBook!.revision, 1); assert.equal((await f.root.collection('attempts').get()).size, 2);
    assert.deepEqual((await f.repo().status(f.actor, scope, duplicate.idempotencyKey, duplicate.fingerprint)).receipt, declined.receipt);
    const corrected = {...next, invoiceReference: 'HOST-CORRECTED-2'};
    await assert.rejects(f.repo().savePurchaseDraft(f.actor, draftCommand(corrected, 1, reviewedCopy(corrected, 2), first.id, duplicate.idempotencyKey)), code('idempotency_conflict'));
    const saved = await f.repo().savePurchaseDraft(f.actor, draftCommand(corrected, 1, reviewedCopy(corrected, 2), first.id, 'HOST-explicit-corrected-review'));
    assert.equal(saved.receipt!.status, 'saved'); assert.equal(saved.currentBook!.revision, 2); assert.equal(saved.currentBook!.copies!.length, 2);
  } finally {await f.close();}
});

test('AGG03 actual SDK unsupported private file refuses before publishing any book or uploaded original', {skip: !emulator}, async () => {
  const f = await fixture();
  try {
    const d = {...draft(), attachments: [{owner: 'HOST-local-private-file', digest: '2'.repeat(64), byteLength: 16}]},
      c = draftCommand(d), result = await new WorkspacePurchaseEntryService(f.repo()).handle(f.actor, 'saveStorePurchaseDraft', draftBody(c)) as Record<string, unknown>;
    assert.equal(result.state, 'empty'); assert.equal(result.bookJson, null);
    assert.equal((result.attempt as {status: string}).status, 'not_saved');
    assert.equal((result.attempt as {reason: string}).reason, 'private_original_unavailable');
    assert.equal((await f.root.get()).exists, false); assert.equal((await f.root.collection('originals').get()).size, 0);
    assert.equal((await f.root.collection('attempts').get()).size, 1);
    assert.equal((await f.repo().savePurchaseDraft(f.actor, c)).receipt!.status, 'not_saved');
  } finally {await f.close();}
});
test('AGG03 actual SDK preserves a larger-than-document owned book across native contact Save and restart', {skip: !emulator}, async () => {
  const f = await fixture();
  try {
    const original: PurchaseEntryBook = {...book(), revision: 7, profiles: Array.from({length: 2100}, (_, n) =>
      ({...profile('HOST-owned-'+n), name: 'HOST original supplier '+n, address: 'HOST supplied address '+ 'x'.repeat(470)}))};
    assert.ok(Buffer.byteLength(purchaseEntryCanonical(original), 'utf8') > 1024 * 1024);
    await seedOwnedBook(f, original);
    const next = command(profile('HOST-confirmed-new'), 7, 'HOST-large-book-save');
    const saved = await f.repo().saveSupplier(f.actor, next);
    assert.equal(saved.currentBook!.revision, 8); assert.equal(saved.currentBook!.profiles.length, 2101);
    assert.deepEqual(saved.currentBook!.profiles.slice(0, 2100), original.profiles);
    assert.equal(Object.hasOwn(saved.currentBook!, 'copies'), false);
    assert.deepEqual((await f.repo().status(f.actor, scope, next.idempotencyKey, next.fingerprint)).currentBook, saved.currentBook);
    const head = (await f.root.get()).data()!;
    assert.ok(head.original.parts > 1); assert.equal(Object.hasOwn(head, 'book'), false);
  } finally {await f.close();}
});

for (const kind of ['status', 'save'] as const) {
  test(`AGG03 actual SDK ${kind} recovers a commit between its receipt and book reads`, {skip: !emulator}, async () => {
    const f = await fixture();
    let enter!: () => void, release!: () => void;
    const entered = new Promise<void>(resolve => {enter = resolve;}), resumed = new Promise<void>(resolve => {release = resolve;});
    let calls = 0;
    try {
      // The first authority call belongs to the receipt read; pause before the
      // following book-read transaction takes any locks, then commit the exact
      // original through an independent repository instance.
      f.setBarrier(async () => {if (++calls === 2) {enter(); await resumed;}});
      const c = command(), operation = kind === 'status'
        ? f.repo().status(f.actor, scope, c.idempotencyKey, c.fingerprint)
        : f.repo().saveSupplier(f.actor, c);
      const terminal = operation.then(value => ({value}), error => ({error}));
      let timer: ReturnType<typeof setTimeout> | undefined;
      try {await Promise.race([entered, new Promise<never>((_, reject) => {
        timer = setTimeout(() => reject(new Error('Receipt/book boundary was not reached')), 15000); timer.unref();
      })]);} finally {if (timer) clearTimeout(timer);}
      const committed = await f.repo().saveSupplier(f.actor, c); release();
      const result = await terminal;
      assert.ok('value' in result, 'A matching committed request must recover, not report a stale CAS.');
      assert.equal(result.value.receipt!.fingerprint, committed.receipt!.fingerprint);
      assert.equal(result.value.currentBook!.revision, 1);
      assert.equal((await f.root.collection('attempts').get()).size, 1);
    } finally {release(); await f.close();}
  });
}
