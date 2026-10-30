/** Isolated HOST contract inputs; never injected into OPPO or live Store data. */
import test, {after} from 'node:test';
import assert from 'node:assert/strict';
import {writeFileSync} from 'node:fs';
import {initializeApp, deleteApp} from 'firebase-admin/app';
import {getFirestore, type Firestore} from 'firebase-admin/firestore';
import {checkedStorePrivatePreferenceFields as fields, checkedStorePrivatePreferenceCommand as command,
  checkedStorePrivatePreferenceRecord as record, storePreferenceInteger,
  storePrivatePreferenceCommandFingerprint, FirestoreStorePrivatePreferenceRepository,
  WorkspaceStorePrivatePreferenceService, storePrivatePreferenceRecoveryWire, storePrivatePreferenceRequestBodyLimit,
  checkedStorePrivatePreferenceProposalFields,
  type StorePrivatePreferenceKind, type StorePrivatePreferenceCommand, type StorePrivatePreferenceFields,
  type StorePrivatePreferenceRepository} from './workspace_store_preferences_service.js';
import type {PurchaseEntryTransactionAuthority} from './workspace_purchase_entry_repository.js';
import {purchaseEntryHash} from './workspace_purchase_entry_service.js';
const scope = {account: 'HOST-private-preference-owner', store: 'HOST-private-preference-store', realm: 'evaluation' as const};
const projectId = 'host-private-pref-agg10';
const actor = {uid: scope.account, projectId};
const status = () => ({acceptingOrders: true, visibleToCustomers: false, fulfilmentMode: 'Delivery and pickup',
  busyMinutes: '0', reopensAt: '', openingTime: '9:00 AM', closingTime: '21:30', maximumActiveOrders: '0', alertSound: true, alertVibration: false});
const pickup = () => ({city: 'HOST city', area: 'HOST area', pincode: '560001', pickupEnabled: false});
const draft = (kind: StorePrivatePreferenceKind = 'status', value: StorePrivatePreferenceFields = status(), expectedRevision = '0', key = 'HOST-save-1'): StorePrivatePreferenceCommand => {
  const base = {version: 1 as const, projectId, scope, kind, fields: value, expectedRevision, idempotencyKey: key};
  return {...base, fingerprint: storePrivatePreferenceCommandFingerprint(base)};
};
for (const value of ['0', '9007199254740993', '9223372036854775807']) {
  test(`HOST exact native integer ${value}`, () => assert.equal(storePreferenceInteger(value), value));
}
for (const value of ['-1', '00', '+1', ' 1', '1 ', '1.0', '1e3', '9223372036854775808', 1, 9007199254740992, null, true]) {
  test(`HOST rejects rounded/noncanonical integer ${String(value)}`, () => assert.throws(() => storePreferenceInteger(value)));
}
test('HOST all four groups preserve literal native inputs', () => {
  const values = {status: status(), pickup: pickup(), invoice: {mode: 'moolSocialChat'}, staff: {staffAccessEnabled: true, counterCount: '20'}};
  for (const [kind, value] of Object.entries(values)) assert.deepEqual(fields(kind as StorePrivatePreferenceKind, value), value);
});
test('HOST full signed-native maximum is not capped at JS safe range', () => {
  const s = {...status(), busyMinutes: '9223372036854775807', maximumActiveOrders: '9007199254740993'};
  assert.deepEqual(fields('status', s), s);
});
test('HOST text validation preserves Dart NEL edges and original spelling', () => {
  const s = {...status(), openingTime: '\u0085 9:00 am\u0085', reopensAt: '  unchanged \ufeff interior  '};
  assert.deepEqual(fields('status', s), s);
  assert.throws(() => fields('status', {...s, openingTime: '\u180e9:00 AM'}));
  assert.throws(() => fields('status', {...s, openingTime: '9:\ufeff00 AM'}));
});
test('HOST source text is not limited to model proposal length', () => {
  const value = {...pickup(), area: 'अ'.repeat(3000)}; assert.deepEqual(fields('pickup', value), value);
});
test('HOST malformed Unicode/controls rejected rather than silently replaced', () => {
  for (const area of ['\ud800', 'a\u0000b', 'a\u007fb']) assert.throws(() => fields('pickup', {...pickup(), area}));
});
test('HOST closed group rejects omissions, extra fields and other group fields', () => {
  assert.throws(() => fields('status', {...status(), publicApproved: true}));
  const s: Record<string, unknown> = status(); delete s.alertSound; assert.throws(() => fields('status', s));
  assert.throws(() => fields('invoice', {mode: 'automatic', staffAccessEnabled: true}));
});
test('HOST existing native count/time/fulfilment/PIN/mode boundaries', () => {
  for (const counterCount of ['0', '21']) assert.throws(() => fields('staff', {staffAccessEnabled: false, counterCount}));
  for (const openingTime of ['24:00', '13:00 PM', '9:60 AM', '']) assert.throws(() => fields('status', {...status(), openingTime}));
  assert.throws(() => fields('status', {...status(), fulfilmentMode: 'Anywhere'}));
  for (const pincode of ['012345', '560001 ', '56000', 'abcdef']) assert.throws(() => fields('pickup', {...pickup(), pincode}));
  assert.throws(() => fields('pickup', {...pickup(), area: '\u0085'}));
  assert.throws(() => fields('invoice', {mode: 'send_now'}));
});
test('HOST frozen identity covers project, scope, group, expected revision and literal fields', () => {
  const original = draft(); assert.deepEqual(command(original), original);
  for (const patch of [{projectId: 'other'}, {scope: {...scope, store: 'other'}}, {expectedRevision: '1'},
    {idempotencyKey: 'other'}, {fields: {...status(), reopensAt: 'different'}}]) assert.throws(() => command({...original, ...patch}));
});
test('HOST records require positive revision and do not accept client authority fields', () => {
  const original = {version: 1, projectId, scope, kind: 'status', revision: '1', fields: status()};
  assert.deepEqual(record(original), original);
  assert.throws(() => record({...original, revision: '0'}));
  assert.throws(() => record({...original, membershipApproved: true}));
});
test('HOST missing original membership authority performs no Firestore IO', async () => {
  const forbidden = new Proxy({}, {get: () => {throw new Error('private IO must not happen');}}) as Firestore;
  const repository = new FirestoreStorePrivatePreferenceRepository(forbidden, 'evaluation', projectId);
  for (const action of [() => repository.read(actor, scope, 'status'), () => repository.save(actor, draft()),
    () => repository.status(actor, scope, 'status', 'HOST-save-1', draft().fingerprint)]) {
    await assert.rejects(action, error => (error as {code: string}).code === 'service_unavailable');
  }
});
const apiBody = (kind: StorePrivatePreferenceKind = 'status') => ({schemaVersion: 1, storePrivatePreferencesVersion: 1,
  actorAccountId: scope.account, projectId, realm: scope.realm, storeId: scope.store, kind});
for (const [action, supplied] of Object.entries({
  'AI-ACT-318': {busyMinutes: '9223372036854775807'},
  'AI-ACT-319': {preparationMinutes: '9007199254740993', openingTime: '\u0085 9:00 am\u0085'},
  'AI-ACT-322': {city: '  HOST supplied city  ', pincode: '56'},
  'AI-ACT-323': {mode: 'moolSocialChat'},
  'AI-ACT-326': {staffAccessEnabled: false, counterCount: '20'},
  'AI-ACT-327': {visibleToCustomers: false},
})) {
  test(`HOST ${action} partial prefill keeps only supplied literal fields`, () => {
    assert.deepEqual(checkedStorePrivatePreferenceProposalFields(action, supplied), supplied);
  });
}
test('HOST private proposal excludes payment, public details, alerts and invented keys', () => {
  for (const action of ['AI-ACT-320', 'AI-ACT-324', 'AI-ACT-328']) assert.throws(() => checkedStorePrivatePreferenceProposalFields(action, {mode: 'off'}));
  assert.throws(() => checkedStorePrivatePreferenceProposalFields('AI-ACT-318', {busyMinutes: '1', membershipApproved: true}));
  assert.throws(() => checkedStorePrivatePreferenceProposalFields('AI-ACT-326', {counterCount: '21'}));
  assert.throws(() => checkedStorePrivatePreferenceProposalFields('AI-ACT-319', {preparationMinutes: 1}));
  assert.throws(() => checkedStorePrivatePreferenceProposalFields('AI-ACT-318', {}));
});
test('HOST partial native text limit/format matches original prefill without imposing it on complete saved sources', () => {
  assert.throws(() => checkedStorePrivatePreferenceProposalFields('AI-ACT-322', {area: 'x'.repeat(2001)}));
  assert.throws(() => checkedStorePrivatePreferenceProposalFields('AI-ACT-319', {openingTime: '25:00'}));
  assert.throws(() => checkedStorePrivatePreferenceProposalFields('AI-ACT-318', {fulfilmentMode: 'Anywhere'}));
  assert.throws(() => checkedStorePrivatePreferenceProposalFields('AI-ACT-323', {mode: 'send_now'}));
  assert.deepEqual(fields('pickup', {...pickup(), area: 'x'.repeat(2001)}).area, 'x'.repeat(2001));
});
test('HOST extended transport allowance applies only to matching private preference operations/version', () => {
  for (const op of ['readStorePrivatePreferences', 'saveStorePrivatePreferences', 'checkStorePrivatePreferencesSave']) {
    assert.equal(storePrivatePreferenceRequestBodyLimit(op, 1), 8 * 1024 * 1024);
    for (const version of [undefined, '1', 0, 2]) assert.equal(storePrivatePreferenceRequestBodyLimit(op, version), undefined);
  }
  assert.equal(storePrivatePreferenceRequestBodyLimit('saveStorePublicDetails', 1), undefined);
});
test('HOST matching HTTP contract is default off, with no source IO', async () => {
  const forbidden = new Proxy({}, {get: () => {throw new Error('private IO must not happen');}}) as StorePrivatePreferenceRepository;
  await assert.rejects(() => new WorkspaceStorePrivatePreferenceService(forbidden).handle(actor, 'readStorePrivatePreferences', apiBody()),
    error => (error as {code: string}).code === 'service_unavailable');
});
test('HOST HTTP contract rejects client authority, wrong identity and unsupported versions before source IO', async () => {
  let reads = 0;
  const repository: StorePrivatePreferenceRepository = {realm: 'evaluation', projectId,
    async read() {reads++; return null;}, async save() {throw new Error('unexpected Save');}, async status() {throw new Error('unexpected status');}};
  const service = new WorkspaceStorePrivatePreferenceService(repository, true);
  for (const body of [{...apiBody(), membershipApproved: true}, {...apiBody(), actorAccountId: 'foreign'},
    {...apiBody(), projectId: 'foreign'}, {...apiBody(), storePrivatePreferencesVersion: 2},
    {...apiBody(), realm: 'production'}, {...apiBody(), kind: 'upi'}]) {
    await assert.rejects(() => service.handle(actor, 'readStorePrivatePreferences', body));
  }
  assert.equal(reads, 0);
  assert.deepEqual(await service.handle(actor, 'readStorePrivatePreferences', apiBody()), {...apiBody(), record: null});
  assert.equal(reads, 1);
});

// Actual SDK cases run only in a separately owned loopback emulator. They do
// not establish an available production membership issuer or deployed service.
if (process.env.AGG10_PRIVATE_PREFERENCE_SDK === 'true') {
  assert.equal(process.env.FIRESTORE_EMULATOR_HOST, '127.0.0.1:19189');
  const app = initializeApp({projectId}, `agg10-${process.pid}`), db = getFirestore(app);
  const membership = db.collection('HOST_ONLY_membership_fixture').doc(scope.account);
  const authority: PurchaseEntryTransactionAuthority = {async assertCurrent(tx, principal, requested) {
    const original = await tx.get(membership);
    if (principal.uid !== scope.account || requested.store !== scope.store || original.get('active') !== true) {
      throw Object.assign(new Error('HOST authority revoked'), {code: 'permission_denied'});
    }
  }};
  const repository = new FirestoreStorePrivatePreferenceRepository(db, 'evaluation', projectId, authority);
  after(async () => {await db.terminate(); await deleteApp(app);});
  test('HOST actual SDK original CAS, exact duplicates, conflict, original status and revocation', async () => {
    await membership.set({active: true});
    assert.equal(await repository.read(actor, scope, 'status'), null);
    const first = draft(), saved = await repository.save(actor, first);
    assert.equal(saved.receipt?.status, 'saved'); assert.equal(saved.current?.revision, '1');
    assert.deepEqual(saved.original?.fields, status());
    const exportPath = process.env.AGG10_BACKEND_PRIVATE_PREFERENCE_WIRE;
    if (exportPath) writeFileSync(exportPath, JSON.stringify({label: 'ISOLATED HOST actual Firestore SDK original',
      command: first, result: saved}), {flag: 'wx'});
    assert.deepEqual(await repository.save(actor, first), saved);
    const second = draft('status', {...status(), busyMinutes: '9007199254740993'}, '1', 'HOST-save-2');
    assert.equal((await repository.save(actor, second)).current?.revision, '2');
    const recovered = await repository.status(actor, scope, 'status', first.idempotencyKey, first.fingerprint);
    assert.equal(recovered.original?.revision, '1'); assert.deepEqual(recovered.original?.fields, status());
    assert.equal(recovered.current?.revision, '2');
    const stale = draft('status', {...status(), busyMinutes: '7'}, '0', 'HOST-stale');
    const refused = await repository.save(actor, stale); assert.equal(refused.receipt?.status, 'not_saved');
    assert.equal(refused.original?.fields.busyMinutes, '7'); assert.equal(refused.current?.revision, '2');
    assert.deepEqual(await repository.status(actor, scope, 'status', stale.idempotencyKey, stale.fingerprint), refused);
    const changed = draft('status', {...status(), reopensAt: 'changed'}, '0', first.idempotencyKey);
    await assert.rejects(() => repository.save(actor, changed), error => (error as {code: string}).code === 'idempotency_conflict');
    assert.equal((await repository.read(actor, scope, 'status'))?.revision, '2');
    assert.equal((await repository.status(actor, scope, 'status', 'HOST-absent', first.fingerprint)).receipt, null);
    assert.equal(await repository.read(actor, scope, 'staff'), null);
    await assert.rejects(() => repository.read({...actor, uid: 'foreign'}, scope, 'status'));
    await assert.rejects(() => repository.read({...actor, projectId: 'foreign'}, scope, 'status'));
    await assert.rejects(() => repository.read(actor, {...scope, realm: 'production'}, 'status'));
    await membership.set({active: false});
    await assert.rejects(() => repository.read(actor, scope, 'status'));
    await assert.rejects(() => repository.status(actor, scope, 'status', first.idempotencyKey, first.fingerprint));
    await assert.rejects(() => repository.save(actor, first));
  });
  test('HOST actual SDK concurrent native saves publish one revision and retain both originals across repository restart', async () => {
    await membership.set({active: true});
    const left = draft('staff', {staffAccessEnabled: true, counterCount: '2'}, '0', 'HOST-staff-left');
    const right = draft('staff', {staffAccessEnabled: false, counterCount: '3'}, '0', 'HOST-staff-right');
    const results = await Promise.all([repository.save(actor, left), repository.save(actor, right)]);
    assert.equal(results.filter(r => r.receipt?.status === 'saved').length, 1);
    assert.equal(results.filter(r => r.receipt?.status === 'not_saved').length, 1);
    const restarted = new FirestoreStorePrivatePreferenceRepository(db, 'evaluation', projectId, authority);
    assert.equal((await restarted.read(actor, scope, 'staff'))?.revision, '1');
    for (const original of [left, right]) {
      const result = await restarted.status(actor, scope, 'staff', original.idempotencyKey, original.fingerprint);
      assert.deepEqual(result.original?.fields, original.fields);
      assert.equal(result.current?.revision, '1');
      assert.deepEqual((await restarted.save(actor, original)).receipt, result.receipt);
    }
    assert.equal((await restarted.read(actor, scope, 'staff'))?.revision, '1');
  });
  test('HOST actual SDK multipart source integrity rejects damaged data and missing head instead of empty/default state', async () => {
    await membership.set({active: true});
    const original = draft('pickup', {...pickup(), area: 'अ'.repeat(100000)}, '0', 'HOST-large-pickup');
    const saved = await repository.save(actor, original); assert.equal(saved.receipt?.status, 'saved');
    assert.deepEqual((await repository.read(actor, scope, 'pickup'))?.fields, original.fields);
    const root = db.collection('privateWorkspacePreferencesV1').doc(purchaseEntryHash({projectId, scope, kind: 'pickup'}));
    const head = await root.get(), pointer = head.get('original') as {id: string};
    const part = root.collection('originals').doc(pointer.id).collection('parts').doc('00000');
    const before = await part.get();
    await part.update({data: Buffer.from('HOST damaged source').toString('base64')});
    await assert.rejects(() => repository.read(actor, scope, 'pickup'));
    await assert.rejects(() => repository.status(actor, scope, 'pickup', original.idempotencyKey, original.fingerprint));
    await part.set(before.data()!);
    assert.deepEqual((await repository.read(actor, scope, 'pickup'))?.fields, original.fields);
    await root.delete();
    await assert.rejects(() => repository.read(actor, scope, 'pickup'));
    await root.set(head.data()!);
    assert.equal((await repository.read(actor, scope, 'pickup'))?.revision, '1');
  });
  test('HOST actual SDK HTTP read/save/status use the same original and compact current reference', async () => {
    await membership.set({active: true});
    const service = new WorkspaceStorePrivatePreferenceService(repository, true), body = apiBody('invoice');
    const empty = await service.handle(actor, 'readStorePrivatePreferences', body);
    assert.deepEqual(empty, {...body, record: null});
    const original = draft('invoice', {mode: 'automatic'}, '0', 'HOST-invoice-native-save');
    const saved = await service.handle(actor, 'saveStorePrivatePreferences', {...body, command: original});
    const direct = await repository.status(actor, scope, 'invoice', original.idempotencyKey, original.fingerprint);
    assert.deepEqual(saved, {...body, result: storePrivatePreferenceRecoveryWire(direct)});
    const status = await service.handle(actor, 'checkStorePrivatePreferencesSave', {...body,
      idempotencyKey: original.idempotencyKey, fingerprint: original.fingerprint});
    assert.deepEqual(status, saved);
    const read = await service.handle(actor, 'readStorePrivatePreferences', body);
    assert.deepEqual(read, {...body, record: direct.current});
    assert.equal(Object.hasOwn((saved as {result: object}).result, 'current'), false);
    await assert.rejects(() => service.handle(actor, 'saveStorePrivatePreferences', {...body,
      command: draft('staff', {staffAccessEnabled: true, counterCount: '1'}, '0', 'HOST-mixed-group')}));
    const path = process.env.AGG10_BACKEND_PRIVATE_PREFERENCE_HTTP_WIRE;
    if (path) writeFileSync(path, JSON.stringify({label: 'ISOLATED HOST actual SDK HTTP contract', command: original,
      empty: {ok: true, data: empty}, saved: {ok: true, data: saved}, status: {ok: true, data: status}, read: {ok: true, data: read}}), {flag: 'wx'});
  });
}
