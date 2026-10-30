import assert from 'node:assert/strict';
import test from 'node:test';
import {existsSync, readFileSync, writeFileSync} from 'node:fs';
import {dirname, isAbsolute} from 'node:path';
import {randomUUID} from 'node:crypto';
import {initializeApp, deleteApp} from 'firebase-admin/app';
import {getFirestore, type Firestore, type Transaction} from 'firebase-admin/firestore';
import {FirestoreCustomerCounterDraftRepository} from './workspace_customer_repository.js';
import {purchaseEntryError, purchaseEntryHash, type PurchaseEntryActor} from './workspace_purchase_entry_service.js';
import type {PurchaseEntryTransactionAuthority} from './workspace_purchase_entry_repository.js';
import {WorkspaceProfileError} from './workspace_profile_service.js';
import {checkedCustomerLedger, checkedCustomerCollection, checkedCustomerRefund,
  checkedCustomerReturn, customerInvoiceBalance, customerReceiptRemaining,
  planCustomerCreditAllocation, checkedCustomerCounterDraftWire, checkedCustomerCounterDraftCommand,
  customerCounterDraftFingerprint, planCustomerCounterDraftSave, checkedCustomerCounterDraftReceipt,
  WorkspaceCustomerService, workspaceCustomerOperation,
  type CustomerCounterDraftWire, type CustomerScope, type CustomerLedger,
  type CustomerEntry} from './workspace_customer_service.js';

// ISOLATED HOST FORMAT/FUNCTION FIXTURES. These do not issue authenticated
// customer originals, establish money receipt or install records on a phone.
const scope: CustomerScope = {account: 'HOST-customer-account', store: 'HOST-customer-store', realm: 'evaluation'};
const at = '2026-10-30T01:00:00.999999Z';
const clone = <T>(value: T): T => structuredClone(value);
function entry(sequence: number, kind: CustomerEntry['kind'], amountMinor: number,
  invoiceId = 'HOST-invoice-one'): CustomerEntry {
  return {id: `HOST-entry-${sequence}`, operationId: `HOST-operation-${sequence}`,
    invoiceId, orderId: invoiceId === 'HOST-invoice-one' ? 'HOST-order-one' : 'HOST-order-two',
    sequence, occurredAt: `2026-10-30T01:00:00.${String(sequence).padStart(6, '0')}Z`,
    kind, state: 'posted', amountMinor, channel: kind === 'collection' ? 'cash' : 'unknown',
    paymentReference: kind === 'collection' ? 'HOST cash record' : null};
}
function ledger(entries = [entry(1, 'invoice', 250), entry(2, 'collection', 100)]): CustomerLedger {
  return {accountScope: scope.account, workspaceId: scope.store, customerId: 'HOST-customer-one',
    customerName: 'HOST ग्राहक', revision: Math.max(entries.length, 1), asOf: at,
    openingBalanceMinor: 0, historyComplete: true, entries};
}
function creditLedger(): CustomerLedger {
  return ledger([entry(1, 'invoice', 10005), entry(2, 'collection', 10005),
    entry(3, 'creditNote', 3333), entry(4, 'invoice', 20000, 'HOST-invoice-two')]);
}
function collection() {
  return {accountScope: scope.account, workspaceId: scope.store, customerId: 'HOST-customer-one',
    invoiceId: 'HOST-invoice-one', orderId: 'HOST-order-one', operationId: 'HOST-new-collection',
    expectedRevision: 2, amountMinor: 25, channel: 'cash', reference: null};
}
const creditArgs = {sourceInvoiceId: 'HOST-invoice-one', targetInvoiceId: 'HOST-invoice-two',
  amountMinor: 1234, expectedRevision: 4, operationId: 'HOST-credit-allocation', at};

function counterWire(): CustomerCounterDraftWire {
  return {encoding: 'native-counter-int64-v1', draft: {
    version: 1, purpose: 'counter-bill-draft', account: scope.account, store: scope.store,
    id: 'HOST-counter-bill', revision: '9223372036854775807', stage: 'editing',
    customer: '', billingDetails: {business: true, name: 'HOST ग्राहक', businessName: 'HOST વેપાર', gst: '', address: ''},
    billingCustomer: '', discount: {kind: 'none', value: '0'}, source: 'Counter',
    fulfilment: 'At the shop', payment: 'Customer due', address: '', submissionOrderId: null,
    lines: [{productId: '0000000000001', name: 'HOST private product', pack: 'HOST pack',
      quantity: '2147483647', unitPricePaise: '1000000000', lineTotalPaise: '2147483647000000000'}],
  }};
}

function rawCounter(stage: string, revision: string, id = 'HOST-counter-bill'): CustomerCounterDraftWire {
  const wire = counterWire();
  Object.assign(wire.draft, {stage, revision, id,
    customer: stage === 'editing' ? '' : 'HOST entered customer',
    submissionOrderId: stage === 'editing' ? null : 'HOST-submission'});
  return wire;
}
function rawCommand(wire: CustomerCounterDraftWire, expectedRevision: string | null,
  idempotencyKey = 'HOST-native-save') {
  const input = {operation: 'saveStoreCounterDraft' as const, scope, expectedRevision, idempotencyKey, wire};
  return {...input, fingerprint: customerCounterDraftFingerprint(input)};
}
function customerCommonBody() {
  return {schemaVersion: 1, customerOriginalVersion: 1, actorAccountId: scope.account,
    realm: scope.realm, storeId: scope.store};
}
function counterSaveBody(command = rawCommand(rawCounter('editing', '1'), null)) {
  return {...customerCommonBody(), expectedRevision: command.expectedRevision,
    idempotencyKey: command.idempotencyKey, fingerprint: command.fingerprint, wire: command.wire};
}

test('AGG06 original customer service keeps unrelated actions and absent sources unavailable', async () => {
  assert.equal(workspaceCustomerOperation('recordStoreCounterSale'), undefined);
  assert.equal(workspaceCustomerOperation('saveStoreCounterDraft'), 'save');
  const service = new WorkspaceCustomerService(), actor = {uid: scope.account, projectId: 'demo-host'};
  await assert.rejects(service.handle(actor, 'readStoreCounterDraft', customerCommonBody()), customerCode('service_unavailable'));
});

test('AGG06 original customer service validates actor, closed body and exact input before repository dispatch', async () => {
  let calls = 0;
  const service = new WorkspaceCustomerService({realm: 'evaluation', projectId: 'demo-host',
    read: async () => {calls++; return null;},
    save: async () => {calls++; throw new Error('Unexpected save');},
    status: async () => {calls++; throw new Error('Unexpected status');}});
  const actor = {uid: scope.account, projectId: 'demo-host'}, common = customerCommonBody();
  for (const change of [{actorAccountId: 'HOST-other'}, {realm: 'production'}, {schemaVersion: 2}, {customerOriginalVersion: 2}]) {
    await assert.rejects(service.handle(actor, 'readStoreCounterDraft', {...common, ...change}), customerCode('permission_denied'));
  }
  await assert.rejects(service.handle({...actor, tenantId: 'HOST-tenant'}, 'readStoreCounterDraft', common), customerCode('permission_denied'));
  await assert.rejects(service.handle(actor, 'readStoreCounterDraft', {...common, draftJson: '{}'}));
  const body = counterSaveBody(); body.fingerprint = '0'.repeat(64);
  await assert.rejects(service.handle(actor, 'saveStoreCounterDraft', body), customerCode('input_changed'));
  assert.equal(calls, 0);
  const empty = await service.handle(actor, 'readStoreCounterDraft', common) as Record<string, unknown>;
  assert.equal(empty.state, 'empty'); assert.equal(empty.draftJson, null); assert.equal(empty.attempt, null); assert.equal(calls, 1);
});

test('AGG06 original Counter service rejects a same-revision acknowledgement with different input', async () => {
  const command = rawCommand(rawCounter('editing', '1'), null), wrong = clone(command.wire);
  wrong.draft.address = 'HOST different same-version input';
  const receipt = checkedCustomerCounterDraftReceipt({schemaVersion: 1, scope, operation: command.operation,
    idempotencyKey: command.idempotencyKey, fingerprint: command.fingerprint, status: 'saved',
    reason: null, changed: true, resultRevision: '1', recordedAt: at}, scope, command.idempotencyKey, command.fingerprint);
  const service = new WorkspaceCustomerService({realm: 'evaluation', projectId: 'demo-host',
    read: async () => wrong, status: async () => ({receipt, currentDraft: wrong}),
    save: async () => ({receipt, currentDraft: wrong})});
  await assert.rejects(service.handle({uid: scope.account, projectId: 'demo-host'},
    'saveStoreCounterDraft', counterSaveBody(command)), customerCode('service_unavailable'));
});

for (const [from, to, accepted] of [
  ['editing', 'editing', true], ['editing', 'submitting', true], ['editing', 'retired', true],
  ['editing', 'reviewRequired', false], ['submitting', 'submitting', false],
  ['submitting', 'editing', false], ['submitting', 'retired', true],
  ['reviewRequired', 'editing', true], ['reviewRequired', 'retired', true],
  ['reviewRequired', 'submitting', false], ['reviewRequired', 'reviewRequired', false],
  ...['editing', 'submitting', 'reviewRequired', 'retired'].map(to => ['retired', to, false]),
] as [string, string, boolean][]) {
  test(`AGG06 raw Counter planner native transition ${from} to ${to}`, () => {
    const current = rawCounter(from, '4'), command = rawCommand(rawCounter(to, '5'), '4');
    const preserved = clone({current, command}), plan = planCustomerCounterDraftSave(current, command);
    assert.equal(plan.state, accepted ? 'save' : 'refused');
    assert.equal(plan.reason, accepted ? null : 'stale_draft');
    assert.deepEqual({current, command}, preserved);
    if (accepted) {assert.deepEqual(plan.next, command.wire); assert.notEqual(plan.next, command.wire);}
    else assert.equal(plan.next, null);
  });
}

test('AGG06 raw Counter planner creates editing only and continues revisions across retired IDs', () => {
  for (const stage of ['editing', 'submitting', 'reviewRequired', 'retired']) {
    assert.equal(planCustomerCounterDraftSave(null, rawCommand(rawCounter(stage, '1'), null)).state,
      stage === 'editing' ? 'save' : 'refused');
    assert.equal(planCustomerCounterDraftSave(rawCounter('retired', '4'),
      rawCommand(rawCounter(stage, '5', 'HOST-next-draft'), '4')).state,
      stage === 'editing' ? 'save' : 'refused');
  }
  for (const stage of ['editing', 'submitting', 'reviewRequired']) {
    assert.equal(planCustomerCounterDraftSave(rawCounter(stage, '4'),
      rawCommand(rawCounter('editing', '5', 'HOST-next-draft'), '4')).state, 'refused');
  }
});

test('AGG06 raw Counter recovery freezes exact input and does not treat retirement as financial cancellation', () => {
  const current = rawCounter('submitting', '4'), next = clone(current);
  Object.assign(next.draft, {revision: '5', stage: 'reviewRequired'});
  assert.equal(planCustomerCounterDraftSave(current, rawCommand(next, '4')).state, 'save');
  for (const change of [{address: 'HOST changed address'}, {id: 'HOST-other'}, {submissionOrderId: 'HOST-other-order'}]) {
    const changed = clone(next); Object.assign(changed.draft, change);
    assert.deepEqual(planCustomerCounterDraftSave(current, rawCommand(changed, '4')),
      {state: 'refused', reason: 'recovery_input_changed', next: null});
  }
  const retired = rawCounter('retired', '5'); retired.draft.submissionOrderId = 'HOST-other-order';
  assert.equal(planCustomerCounterDraftSave(current, rawCommand(retired, '4')).state, 'refused');
  const result = planCustomerCounterDraftSave(current, rawCommand(rawCounter('retired', '5'), '4'));
  assert.deepEqual(Object.keys(result).sort(), ['next', 'reason', 'state']);
});

test('AGG06 raw Counter exact replay, stale CAS and lossless int64 boundaries', () => {
  for (const stage of ['editing', 'submitting', 'retired']) {
    const current = rawCounter(stage, '4');
    assert.equal(planCustomerCounterDraftSave(current, rawCommand(clone(current), '3')).state, 'same');
    assert.equal(planCustomerCounterDraftSave(current, rawCommand(clone(current), '3', 'HOST-other-key')).state, 'same');
  }
  assert.equal(planCustomerCounterDraftSave(rawCounter('editing', '4'), rawCommand(rawCounter('editing', '3'), '2')).state, 'refused');
  assert.equal(planCustomerCounterDraftSave(rawCounter('editing', '9223372036854775806'),
    rawCommand(rawCounter('editing', '9223372036854775807'), '9223372036854775806')).state, 'save');
  assert.throws(() => checkedCustomerCounterDraftCommand(rawCommand(rawCounter('editing', '9223372036854775808'), '9223372036854775807')));
  const large = rawCounter('editing', '1');
  Object.assign(large.draft.lines[0]!, {quantity: '9223372036854775807', unitPricePaise: '1', lineTotalPaise: '9223372036854775807'});
  assert.equal(planCustomerCounterDraftSave(null, rawCommand(large, null)).state, 'save');
});

test('AGG06 raw Counter commands bind source scope, revision and every byte of the native input', () => {
  const command = rawCommand(rawCounter('editing', '1'), null);
  assert.deepEqual(checkedCustomerCounterDraftCommand(command), command);
  for (const revision of ['0', '2', '01', '+1', '1.0', '1e0', '1 ', '-1']) {
    assert.throws(() => checkedCustomerCounterDraftCommand(rawCommand(rawCounter('editing', revision), null)));
  }
  for (const change of [{idempotencyKey: 'HOST-changed-key'}, {scope: {...scope, store: 'HOST-other'}},
    {wire: {...command.wire, draft: {...command.wire.draft, address: 'HOST changed'}}}]) {
    assert.throws(() => checkedCustomerCounterDraftCommand({...command, ...change}));
  }
  assert.throws(() => planCustomerCounterDraftSave({...command.wire,
    draft: {...command.wire.draft, account: 'HOST-foreign'}}, command));
});

test('AGG06 raw Counter receipts do not accept an invented save or discard result', () => {
  const command = rawCommand(rawCounter('editing', '1'), null);
  const receipt = {schemaVersion: 1, scope, operation: command.operation,
    idempotencyKey: command.idempotencyKey, fingerprint: command.fingerprint,
    status: 'saved', reason: null, changed: true, resultRevision: '1', recordedAt: at};
  assert.deepEqual(checkedCustomerCounterDraftReceipt(receipt, scope, command.idempotencyKey, command.fingerprint), receipt);
  for (const change of [{status: 'posted'}, {resultRevision: null}, {reason: 'stale_draft'},
    {status: 'not_saved', reason: null}, {status: 'not_saved', reason: 'stale_draft', changed: true}]) {
    assert.throws(() => checkedCustomerCounterDraftReceipt({...receipt, ...change}, scope, command.idempotencyKey, command.fingerprint));
  }
});

test('AGG06 Counter wire keeps int64 decimals, leading SKU zeros and incomplete entered text', () => {
  const wire = counterWire(), transported = JSON.parse(JSON.stringify(wire));
  assert.deepEqual(checkedCustomerCounterDraftWire(transported, scope), wire);
  assert.equal(transported.draft.lines[0].lineTotalPaise, '2147483647000000000');
  assert.equal(transported.draft.lines[0].productId, '0000000000001');
  assert.equal(transported.draft.billingDetails.gst, '');
  assert.deepEqual(checkedCustomerCounterDraftWire({...wire, draft: {...wire.draft, lines: []}}, scope).draft.lines, []);
});

test('AGG06 Counter wire closes exact fields and preserves native stage and integer guards', () => {
  const wire = counterWire(), draft = wire.draft, line = draft.lines[0]!;
  const invalidDrafts = [{...draft, revision: 1}, {...draft, revision: '01'},
    {...draft, revision: '0'}, {...draft, revision: '9223372036854775808'},
    {...draft, store: 'HOST-foreign'}, {...draft, source: 'App'},
    {...draft, submissionOrderId: 'HOST-proposed-order'}, {...draft, stage: 'submitting'},
    {...draft, billingDetails: {...draft.billingDetails, fee: 0}},
    {...draft, lines: [line, line]}, {...draft, lines: [{...line, quantity: '0'}]},
    {...draft, lines: [{...line, quantity: '2147483648'}]},
    {...draft, lines: [{...line, lineTotalPaise: 2147483647000000000}]},
    {...draft, lines: [{...line, lineTotalPaise: '9223372036854775808'}]}];
  for (const bad of invalidDrafts) assert.throws(() => checkedCustomerCounterDraftWire({...wire, draft: bad}, scope));
  const submitted = {...wire, draft: {...draft, stage: 'submitting', customer: 'HOST entered buyer', submissionOrderId: 'HOST-order'}};
  assert.equal(checkedCustomerCounterDraftWire(submitted, scope).draft.stage, 'submitting');
  assert.equal(checkedCustomerCounterDraftWire({...wire, draft: {...draft, stage: 'retired'}}, scope).draft.stage, 'retired');
  assert.equal(checkedCustomerCounterDraftWire({...wire, draft: {...draft, billingCustomer: '+91 98765-43210'}}, scope).draft.billingCustomer, '+91 98765-43210');
  assert.throws(() => checkedCustomerCounterDraftWire({...wire, draft: {...draft, billingCustomer: 'not a mobile'}}, scope));
});

test('AGG06 Counter wire keeps native discount bounds without introducing draft subtotal decisions', () => {
  const wire = counterWire();
  for (const discount of [{kind: 'fixed', value: '9007199254740991'}, {kind: 'percentage', value: '10000'}]) {
    assert.deepEqual(checkedCustomerCounterDraftWire({...wire, draft: {...wire.draft, discount}}, scope).draft.discount, discount);
  }
  for (const discount of [{kind: 'none', value: '1'}, {kind: 'fixed', value: '0'},
    {kind: 'fixed', value: '9007199254740992'}, {kind: 'percentage', value: '10001'}]) {
    assert.throws(() => checkedCustomerCounterDraftWire({...wire, draft: {...wire.draft, discount}}, scope));
  }
});

const nativeCounterPrefix = process.env.AGG06_COUNTER_WIRE_NATIVE_EXPORT_PATH;
for (const variant of ['plain', 'int64', 'revision64']) {
  test('AGG06 actual native Counter wire crosses backend without numeric rounding: ' + variant,
    {skip: !nativeCounterPrefix}, () => {
      const input = JSON.parse(readFileSync(`${nativeCounterPrefix}.${variant}.json`, 'utf8'));
      assert.equal(input.label, 'ISOLATED HOST NATIVE COUNTER FORMAT; NO ORIGINAL AUTHORITY');
      assert.deepEqual(input.scope, scope);
      const checked = checkedCustomerCounterDraftWire(input.wire, scope);
      assert.deepEqual(checked, input.wire);
      if (variant !== 'plain') {
        assert.equal(checked.draft.lines[0]!.lineTotalPaise, '2147483647000000000');
        assert.ok(input.nativeJson.includes('2147483647000000000'));
      }
      if (variant === 'revision64') assert.equal(checked.draft.revision, '9223372036854775807');
      const outputPrefix = process.env.AGG06_COUNTER_WIRE_BACKEND_EXPORT_PATH;
      if (outputPrefix) {
        assert.ok(isAbsolute(outputPrefix) && existsSync(dirname(outputPrefix)));
        const path = `${outputPrefix}.${variant}.json`; assert.ok(!existsSync(path), 'Preserve prior format evidence.');
        writeFileSync(path, JSON.stringify({label: 'ISOLATED HOST VALIDATED COUNTER FORMAT; NO ORIGINAL AUTHORITY',
          scope, wire: checked, nativeJson: input.nativeJson}) + '\n');
      }
    });
}

test('AGG06 customer pure codec preserves original fields and requires explicit matching scope', () => {
  const original = ledger();
  assert.deepEqual(checkedCustomerLedger(original, scope), original);
  assert.throws(() => checkedCustomerLedger(original, {...scope, account: 'HOST-other-account'}));
  assert.throws(() => checkedCustomerLedger(original, {...scope, store: 'HOST-other-store'}));
  assert.throws(() => checkedCustomerLedger({...original, availableSettlementMinor: 0}, scope));
  assert.equal(customerInvoiceBalance(original, 'HOST-invoice-one', undefined as unknown as CustomerScope), null);
  assert.deepEqual(customerInvoiceBalance(original, 'HOST-invoice-one', scope), {
    billedMinor: 250, creditedMinor: 0, collectedMinor: 100, refundedMinor: 0,
    dueMinor: 150, refundableMinor: 0, availableCreditMinor: 0});
  assert.equal(customerInvoiceBalance(original, 'HOST-absent-invoice', scope), null);
});

test('AGG06 customer pure unknown opening and incomplete history never create zero or capacity', () => {
  const partial = {...ledger(), openingBalanceMinor: null, historyComplete: false};
  assert.equal(checkedCustomerLedger(partial, scope).openingBalanceMinor, null);
  assert.equal(customerInvoiceBalance(partial, 'HOST-invoice-one', scope), null);
  assert.equal(customerReceiptRemaining(partial, 'HOST-invoice-one', 'HOST-entry-2', scope), null);
  assert.throws(() => checkedCustomerLedger({...partial, historyComplete: true}, scope));
});

test('AGG06 customer pure requests retain manual evidence and reject provider/foreign/duplicate input', () => {
  assert.deepEqual(checkedCustomerCollection(collection(), scope), collection());
  for (const change of [{channel: 'platform'}, {amountMinor: 0}, {expectedRevision: 0},
    {accountScope: 'HOST-foreign'}, {channel: 'directUpi', reference: null}, {nonce: 'model-minted'}]) {
    assert.throws(() => checkedCustomerCollection({...collection(), ...change}, scope));
  }
  const refund = {...collection(), operationId: 'HOST-refund', sourceCollectionId: 'HOST-entry-2'};
  assert.deepEqual(checkedCustomerRefund(refund, scope), refund);
  assert.throws(() => checkedCustomerRefund({...refund, sourceCollectionId: ''}, scope));
  const returned = {accountScope: scope.account, workspaceId: scope.store, customerId: 'HOST-customer-one',
    invoiceId: 'HOST-invoice-one', orderId: 'HOST-order-one', operationId: 'HOST-return',
    expectedRevision: 2, reason: 'HOST original damaged item', reasonCode: 'damaged',
    lines: [{productId: 'HOST-sku', quantity: 2147483647, restockQuantity: 0}]};
  assert.deepEqual(checkedCustomerReturn(returned, scope), returned);
  assert.throws(() => checkedCustomerReturn({...returned, reasonCode: 'invented'}, scope));
  assert.throws(() => checkedCustomerReturn({...returned, lines: [...returned.lines, ...returned.lines]}, scope));
  assert.throws(() => checkedCustomerReturn({...returned, lines: [{...returned.lines[0]!, quantity: 2147483648}]}, scope));
  assert.throws(() => checkedCustomerReturn({...returned, lines: [{productId: 'HOST-sku', quantity: 1, restockQuantity: 2}]}, scope));
});

test('AGG06 customer pure balances use exact source invoice credit and conserve paired allocation', () => {
  const original = creditLedger();
  const before = customerInvoiceBalance(original, 'HOST-invoice-one', scope)!;
  assert.equal(before.availableCreditMinor, 3333); assert.equal(before.refundableMinor, 3333);
  const allocated = planCustomerCreditAllocation(original, creditArgs, scope);
  assert.equal(allocated.revision, 5); assert.equal(allocated.entries.length, original.entries.length + 2);
  assert.deepEqual(allocated.entries.slice(0, original.entries.length), original.entries);
  assert.equal(customerInvoiceBalance(allocated, 'HOST-invoice-one', scope)!.availableCreditMinor, 2099);
  assert.equal(customerInvoiceBalance(allocated, 'HOST-invoice-two', scope)!.dueMinor, 18766);
  assert.deepEqual(planCustomerCreditAllocation(allocated, creditArgs, scope), allocated);
  assert.throws(() => planCustomerCreditAllocation(allocated, {...creditArgs, amountMinor: 1235}, scope));
  for (const change of [{expectedRevision: 3}, {sourceInvoiceId: 'HOST-unknown'},
    {targetInvoiceId: creditArgs.sourceInvoiceId}, {amountMinor: 3334}]) {
    assert.throws(() => planCustomerCreditAllocation(original, {...creditArgs, ...change}, scope));
  }
});

test('AGG06 customer pure receipt capacity keeps exact original tender and legacy ambiguity', () => {
  const original = creditLedger();
  const refund = {...collection(), expectedRevision: 4, operationId: 'HOST-refund', amountMinor: 1000,
    sourceCollectionId: 'HOST-entry-2', reference: 'HOST actual cash returned'};
  const posted = {...entry(5, 'refund', 1000), operationId: refund.operationId,
    channel: 'cash' as const, paymentReference: refund.reference, customerRefund: checkedCustomerRefund(refund, scope)};
  const next = {...original, revision: 5, entries: [...original.entries, posted]};
  assert.equal(customerReceiptRemaining(original, 'HOST-invoice-one', 'HOST-entry-2', scope), 10005);
  assert.equal(customerReceiptRemaining(next, 'HOST-invoice-one', 'HOST-entry-2', scope), 9005);
  assert.equal(customerInvoiceBalance(next, 'HOST-invoice-one', scope)!.refundableMinor, 2333);
  const legacy = clone(next); delete legacy.entries.at(-1)!.customerRefund!.sourceCollectionId;
  assert.equal(customerReceiptRemaining(legacy, 'HOST-invoice-one', 'HOST-entry-2', scope), null);
  const wrong = clone(next); wrong.entries.at(-1)!.customerRefund!.sourceCollectionId = 'HOST-other-receipt';
  assert.equal(customerReceiptRemaining(wrong, 'HOST-invoice-one', 'HOST-entry-2', scope), null);
});

test('AGG06 customer pure validates microsecond chronology and exact posted pair time', () => {
  const original = ledger();
  assert.throws(() => checkedCustomerLedger({...original, asOf: '2026-10-30T01:00:00.000001Z'}, scope));
  const allocated = planCustomerCreditAllocation(creditLedger(), creditArgs, scope);
  const changed = clone(allocated); changed.entries.at(-2)!.occurredAt = '2026-10-30T01:00:00.999998Z';
  assert.throws(() => checkedCustomerLedger(changed, scope));
});

test('AGG06 customer pure safe-integer limits and long histories are not silently rounded or trimmed', () => {
  const near = ledger([entry(1, 'invoice', Number.MAX_SAFE_INTEGER), entry(2, 'collection', Number.MAX_SAFE_INTEGER - 1)]);
  assert.equal(customerInvoiceBalance(near, 'HOST-invoice-one', scope)!.dueMinor, 1);
  const overflow = clone(near); overflow.entries[0]!.amountMinor = Number.MAX_SAFE_INTEGER + 1;
  assert.throws(() => checkedCustomerLedger(overflow, scope));
  const long = ledger(Array.from({length: 1001}, (_, i) => entry(i + 1, 'invoice', 1, `HOST-invoice-${i + 1}`)));
  assert.equal(checkedCustomerLedger(long, scope).entries.length, 1001);
  assert.equal(customerInvoiceBalance(long, 'HOST-invoice-1001', scope)!.dueMinor, 1);
});

test('AGG06 customer pure format vectors cross the native codec without claiming source authority', () => {
  const cases: Record<string, CustomerLedger> = {baseline: ledger(), credit: creditLedger(),
    allocated: planCustomerCreditAllocation(creditLedger(), creditArgs, scope),
    partial: {...ledger(), openingBalanceMinor: null, historyComplete: false},
    'near-limit': ledger([entry(1, 'invoice', Number.MAX_SAFE_INTEGER), entry(2, 'collection', Number.MAX_SAFE_INTEGER - 1)])};
  const prefix = process.env.AGG06_CUSTOMER_FORMAT_EXPORT_PATH;
  if (prefix) assert.ok(isAbsolute(prefix) && existsSync(dirname(prefix)), 'Use an existing isolated absolute evidence directory.');
  for (const [name, raw] of Object.entries(cases)) {
    const original = checkedCustomerLedger(raw, scope);
    const invoiceIds = [...new Set(original.entries.map(e => e.invoiceId))];
    const value = {label: 'ISOLATED HOST CUSTOMER FORMAT; NO ORIGINAL AUTHORITY', scope, ledger: original,
      balances: Object.fromEntries(invoiceIds.map(id => [id, customerInvoiceBalance(original, id, scope)])),
      receiptRemaining: customerReceiptRemaining(original, 'HOST-invoice-one', 'HOST-entry-2', scope)};
    if (prefix) {
      const path = `${prefix}.${name}.json`; assert.ok(!existsSync(path), 'Preserve prior format evidence.');
      writeFileSync(path, JSON.stringify(value) + '\n');
    }
  }
});

const customerEmulator = process.env.FIRESTORE_EMULATOR_HOST;
const customerCode = (code: string) => (error: unknown) => error instanceof WorkspaceProfileError && error.code === code;
async function customerFixture() {
  assert.match(customerEmulator!, /^127\.0\.0\.1:\d+$/, 'Isolated loopback SDK only; no cloud.');
  const projectId = 'demo-agg06-' + randomUUID().slice(0, 8);
  const app = initializeApp({projectId}, 'agg06-' + randomUUID()), db: Firestore = getFirestore(app);
  const actor: PurchaseEntryActor = {uid: scope.account, projectId};
  const grant = db.doc('HOST_ONLY_TEST_AUTHORITY/' + randomUUID());
  await grant.set({active: true, account: scope.account, store: scope.store,
    label: 'ISOLATED HOST FIXTURE; NOT A RUNTIME MEMBERSHIP ISSUER'});
  let barrier: (() => Promise<void>) | undefined;
  const authority: PurchaseEntryTransactionAuthority = {assertCurrent: async (tx: Transaction, user, requested) => {
    if (barrier) await barrier();
    const original = await tx.get(grant);
    if (!original.get('active') || original.get('account') !== user.uid || original.get('store') !== requested.store) {
      purchaseEntryError('permission_denied', 403);
    }
  }};
  const root = db.collection('privateWorkspaceCounterDraftsV1').doc(purchaseEntryHash({projectId, scope}));
  return {db, actor, grant, root,
    repo: () => new FirestoreCustomerCounterDraftRepository(db, 'evaluation', projectId, authority,
      () => new Date('2026-10-30T01:00:01.000Z')),
    barrier: (callback: () => Promise<void>) => {barrier = callback;},
    close: async () => {await db.terminate(); await deleteApp(app);}};
}

test('AGG06 actual SDK Counter original empty read, save, restart, later edit and immutable replay', {skip: !customerEmulator}, async () => {
  const f = await customerFixture();
  try {
    assert.equal(await f.repo().read(f.actor, scope), null);
    const first = rawCommand(rawCounter('editing', '1'), null);
    const saved = await f.repo().save(f.actor, first);
    assert.equal(saved.receipt!.status, 'saved'); assert.equal(saved.receipt!.changed, true);
    const next = rawCounter('editing', '2'); next.draft.address = 'HOST newer entered address';
    await f.repo().save(f.actor, rawCommand(next, '1', 'HOST-next-save'));
    const recovered = await f.repo().save(f.actor, first);
    assert.deepEqual(recovered.receipt, saved.receipt);
    assert.deepEqual(recovered.currentDraft, next);
    assert.equal((await f.root.collection('attempts').get()).size, 2);
    const prefix = process.env.AGG06_COUNTER_SERVICE_CAPTURE_PATH;
    if (prefix) {
      assert.ok(isAbsolute(prefix) && existsSync(dirname(prefix)));
      const service = new WorkspaceCustomerService(f.repo(), () => new Date('2026-10-30T01:00:02.000Z'));
      const response = await service.handle(f.actor, 'readStoreCounterDraftAttempt', {...customerCommonBody(),
        idempotencyKey: first.idempotencyKey, fingerprint: first.fingerprint});
      const readResponse = await service.handle(f.actor, 'readStoreCounterDraft', customerCommonBody());
      writeFileSync(prefix + '.json', JSON.stringify({label: 'ISOLATED HOST ACTUAL SDK COUNTER SERVICE; NO PHONE AUTHORITY',
        scope, command: first, request: counterSaveBody(first), response, readResponse}) + '\n', {flag: 'wx'});
    }
    const changed = clone(first); changed.wire.draft.address = 'HOST different same-key input';
    changed.fingerprint = customerCounterDraftFingerprint(changed);
    await assert.rejects(f.repo().save(f.actor, changed), customerCode('idempotency_conflict'));
  } finally {await f.close();}
});

test('AGG06 actual SDK Counter identical concurrent requests publish one immutable receipt', {skip: !customerEmulator}, async () => {
  const f = await customerFixture();
  try {
    const command = rawCommand(rawCounter('editing', '1'), null);
    const results = await Promise.all([f.repo().save(f.actor, command), f.repo().save(f.actor, command)]);
    assert.deepEqual(results[0], results[1]);
    assert.equal((await f.root.collection('attempts').get()).size, 1);
    assert.equal((await f.root.collection('originals').get()).size, 1);
  } finally {await f.close();}
});

test('AGG06 actual SDK Counter stale refusal persists after newer source and cannot become a late save', {skip: !customerEmulator}, async () => {
  const f = await customerFixture();
  try {
    await f.repo().save(f.actor, rawCommand(rawCounter('editing', '1'), null));
    const stale = rawCommand(rawCounter('editing', '1', 'HOST-stale-id'), null, 'HOST-stale-save');
    const declined = await f.repo().save(f.actor, stale);
    assert.equal(declined.receipt!.status, 'not_saved'); assert.equal(declined.receipt!.reason, 'stale_draft');
    await f.repo().save(f.actor, rawCommand(rawCounter('editing', '2'), '1', 'HOST-next-save'));
    const replay = await f.repo().save(f.actor, stale);
    assert.deepEqual(replay.receipt, declined.receipt); assert.equal(replay.currentDraft!.draft.revision, '2');
  } finally {await f.close();}
});

test('AGG06 actual SDK Counter recovery freezes input, retains retirement and continues new draft revision', {skip: !customerEmulator}, async () => {
  const f = await customerFixture();
  try {
    await f.repo().save(f.actor, rawCommand(rawCounter('editing', '1'), null));
    const submitting = rawCounter('submitting', '2');
    await f.repo().save(f.actor, rawCommand(submitting, '1', 'HOST-submit-input'));
    const recovery = clone(submitting); Object.assign(recovery.draft, {revision: '3', stage: 'reviewRequired'});
    const bad = clone(recovery); bad.draft.address = 'HOST changed during unknown';
    const rejected = await f.repo().save(f.actor, rawCommand(bad, '2', 'HOST-bad-recovery'));
    assert.equal(rejected.receipt!.reason, 'recovery_input_changed');
    await f.repo().save(f.actor, rawCommand(recovery, '2', 'HOST-recovery'));
    const retired = clone(recovery); Object.assign(retired.draft, {revision: '4', stage: 'retired'});
    await f.repo().save(f.actor, rawCommand(retired, '3', 'HOST-retire-input'));
    const next = rawCounter('editing', '5', 'HOST-next-draft');
    assert.deepEqual((await f.repo().save(f.actor, rawCommand(next, '4', 'HOST-next-draft-save'))).currentDraft, next);
    assert.equal((await f.root.collection('originals').get()).size, 5);
    // There is no financial receipt, order or reservation API in this source.
    assert.deepEqual(Object.keys((await f.repo().status(f.actor, scope, 'HOST-retire-input',
      rawCommand(retired, '3', 'HOST-retire-input').fingerprint))).sort(), ['currentDraft', 'receipt']);
  } finally {await f.close();}
});

test('AGG06 actual SDK Counter long bill spans immutable parts without an item-count limit', {skip: !customerEmulator}, async () => {
  const f = await customerFixture();
  try {
    const wire = rawCounter('editing', '1'), line = wire.draft.lines[0]!;
    wire.draft.lines = Array.from({length: 1601}, (_, i) => ({...line, productId: 'HOST-SKU-' + i,
      name: 'HOST entered original description '.repeat(4) + i}));
    const saved = await f.repo().save(f.actor, rawCommand(wire, null));
    assert.deepEqual(saved.currentDraft, wire); assert.equal(saved.currentDraft!.draft.lines.length, 1601);
    const head = (await f.root.get()).data()!;
    assert.ok(head.original.parts > 1);
    assert.deepEqual(await f.repo().read(f.actor, scope), wire);
  } finally {await f.close();}
});

test('AGG06 actual SDK Counter absent authority, foreign actor/project/tenant/realm never produce empty success', {skip: !customerEmulator}, async () => {
  const f = await customerFixture();
  try {
    const unavailable = new FirestoreCustomerCounterDraftRepository(f.db, 'evaluation', f.actor.projectId);
    await assert.rejects(unavailable.read(f.actor, scope), customerCode('service_unavailable'));
    for (const user of [{...f.actor, uid: 'HOST-foreign'}, {...f.actor, projectId: 'HOST-foreign'},
      {...f.actor, tenantId: 'HOST-tenant'}]) await assert.rejects(f.repo().read(user, scope), customerCode('permission_denied'));
    await assert.rejects(f.repo().read(f.actor, {...scope, realm: 'production'}), customerCode('permission_denied'));
    assert.equal((await f.root.get()).exists, false);
  } finally {await f.close();}
});

test('AGG06 actual SDK Counter missing head after saved receipt is corruption, never a fresh draft', {skip: !customerEmulator}, async () => {
  const f = await customerFixture();
  try {
    await f.repo().save(f.actor, rawCommand(rawCounter('editing', '1'), null));
    await f.root.delete();
    await assert.rejects(f.repo().read(f.actor, scope), customerCode('service_unavailable'));
    await assert.rejects(f.repo().save(f.actor, rawCommand(rawCounter('editing', '1'), null, 'HOST-fresh-key')),
      customerCode('service_unavailable'));
    assert.equal((await f.root.get()).exists, false);
  } finally {await f.close();}
});

test('AGG06 actual SDK Counter corrupted payload never rewrites or clears original recovery input', {skip: !customerEmulator}, async () => {
  const f = await customerFixture();
  try {
    await f.repo().save(f.actor, rawCommand(rawCounter('editing', '1'), null));
    const original = (await f.root.get()).data()!;
    await f.root.collection('originals').doc(original.original.id).collection('parts').doc('00000')
      .update({data: Buffer.from('HOST corrupted original').toString('base64')});
    await assert.rejects(f.repo().read(f.actor, scope), customerCode('service_unavailable'));
    assert.deepEqual((await f.root.get()).data(), original);
  } finally {await f.close();}
});

test('AGG06 actual SDK Counter authority revoked after staging prevents head and receipt publication', {skip: !customerEmulator}, async () => {
  const f = await customerFixture();
  let entered!: () => void, release!: () => void;
  const held = new Promise<void>(resolve => {entered = resolve;}), resume = new Promise<void>(resolve => {release = resolve;});
  let blocked = false;
  try {
    f.barrier(async () => {
      if (!blocked && !(await f.root.get()).exists && !(await f.root.collection('originals').limit(1).get()).empty) {
        blocked = true; entered(); await resume;
      }
    });
    const terminal = f.repo().save(f.actor, rawCommand(rawCounter('editing', '1'), null))
      .then(value => ({value}), error => ({error}));
    let timer: ReturnType<typeof setTimeout> | undefined;
    try {await Promise.race([held, new Promise<never>((_, reject) => {
      timer = setTimeout(() => reject(new Error('Counter publication boundary not reached')), 15000); timer.unref();
    })]);} finally {if (timer) clearTimeout(timer);}
    await f.grant.update({active: false}); release();
    const result = await terminal;
    assert.ok('error' in result && customerCode('permission_denied')(result.error));
    assert.equal((await f.root.get()).exists, false); assert.equal((await f.root.collection('attempts').get()).size, 0);
    assert.equal((await f.root.collection('originals').get()).empty, false, 'Staged payload is not a saved original.');
  } finally {release(); await f.close();}
});

test('AGG06 actual SDK Counter concurrent different edits publish one CAS winner and durable stale refusal', {skip: !customerEmulator}, async () => {
  const f = await customerFixture();
  try {
    const a = rawCommand(rawCounter('editing', '1'), null, 'HOST-concurrent-a');
    const changed = rawCounter('editing', '1'); changed.draft.address = 'HOST competing edit';
    const b = rawCommand(changed, null, 'HOST-concurrent-b');
    const results = await Promise.all([f.repo().save(f.actor, a), f.repo().save(f.actor, b)]);
    assert.deepEqual(results.map(value => value.receipt!.status).sort(), ['not_saved', 'saved']);
    assert.equal(results.find(value => value.receipt!.status === 'not_saved')!.receipt!.reason, 'stale_draft');
    const current = await f.repo().read(f.actor, scope);
    for (const command of [a, b]) {
      const replay = await f.repo().save(f.actor, command);
      assert.deepEqual(replay.receipt, results[[a, b].indexOf(command)]!.receipt);
      assert.deepEqual(replay.currentDraft, current);
    }
    assert.equal((await f.root.collection('attempts').get()).size, 2);
  } finally {await f.close();}
});

test('AGG06 actual SDK Counter lost committed acknowledgement recovers only the original receipt', {skip: !customerEmulator}, async () => {
  const f = await customerFixture(), actual = f.db.runTransaction.bind(f.db);
  let lost = false, commits = 0;
  // HOST transport fault only. The original SDK commit happens first.
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
    if (createsReceipt) {commits++; if (!lost) {lost = true; throw new Error('HOST lost committed acknowledgement');}}
    return result;
  }) as Firestore['runTransaction'];
  try {
    const command = rawCommand(rawCounter('editing', '1'), null);
    const result = await f.repo().save(f.actor, command);
    assert.equal(lost, true); assert.equal(commits, 1); assert.equal(result.receipt!.status, 'saved');
    assert.equal(result.currentDraft!.draft.revision, '1');
    assert.equal((await f.root.collection('attempts').get()).size, 1);
    assert.deepEqual((await f.repo().status(f.actor, scope, command.idempotencyKey, command.fingerprint)).receipt, result.receipt);
  } finally {f.db.runTransaction = actual; await f.close();}
});

test('AGG06 actual SDK Counter revoked access prevents disclosure without losing confirmed recovery', {skip: !customerEmulator}, async () => {
  const f = await customerFixture();
  try {
    const command = rawCommand(rawCounter('editing', '1'), null), result = await f.repo().save(f.actor, command);
    await f.grant.update({active: false});
    await assert.rejects(f.repo().status(f.actor, scope, command.idempotencyKey, command.fingerprint), customerCode('permission_denied'));
    await f.grant.update({active: true});
    assert.deepEqual((await f.repo().status(f.actor, scope, command.idempotencyKey, command.fingerprint)).receipt, result.receipt);
    assert.equal((await f.root.collection('attempts').get()).size, 1);
  } finally {await f.close();}
});
