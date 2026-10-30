/** Existing native customer record validation only. Parsing and capacity
 * calculations are not financial/source authority. Original receiver/transaction
 * and native confirmation must separately establish every posted event.
 * No whole finance snapshot, initial opening, bank verification or Stock fact
 * is inferred here. Unknown original opening/history remains unavailable.
 */
import {
  type PurchaseEntryScope, type PurchaseEntryActor, type PurchaseEntryRealm,
  checkedPurchaseEntryScope, purchaseEntryExact,
  purchaseEntryId, purchaseEntryRevision, purchaseEntryMicros,
  purchaseEntryClone, purchaseEntryCanonical, purchaseEntryHash, purchaseEntryFingerprint,
} from './workspace_purchase_entry_service.js';
import {WorkspaceProfileError} from './workspace_profile_service.js';

export type CustomerScope = PurchaseEntryScope;
export type CustomerChannel = 'platform' | 'cash' | 'directUpi' | 'credit' | 'unknown' | 'bankTransfer';
export type CustomerKind = 'invoice' | 'collection' | 'creditNote' | 'refund' | 'creditUsed' | 'creditReceived';
export type CustomerState = 'pending' | 'posted' | 'failed';
export interface CustomerCollection {
  accountScope: string; workspaceId: string; customerId: string; invoiceId: string;
  orderId: string; operationId: string; expectedRevision: number; amountMinor: number;
  channel: CustomerChannel; reference: string | null;
}
export interface CustomerRefund extends CustomerCollection { sourceCollectionId?: string }
export interface CustomerReturn {
  accountScope: string; workspaceId: string; customerId: string; invoiceId: string;
  orderId: string; operationId: string; expectedRevision: number; reason: string;
  reasonCode?: string;
  lines: {productId: string; quantity: number; restockQuantity: number}[];
}
export interface CustomerEntry {
  id: string; operationId: string; invoiceId: string; orderId: string; sequence: number;
  occurredAt: string; kind: CustomerKind; state: CustomerState; amountMinor: number;
  channel: CustomerChannel; paymentReference: string | null;
  customerReturn?: CustomerReturn; customerRefund?: CustomerRefund;
}
export interface CustomerLedger {
  accountScope: string; workspaceId: string; customerId: string; customerName: string;
  revision: number; asOf: string; openingBalanceMinor: number | null;
  historyComplete: boolean; entries: CustomerEntry[];
}
const limit = 9007199254740991n;
const channels: readonly string[] = ['platform', 'cash', 'directUpi', 'credit', 'unknown', 'bankTransfer'];
const kinds: readonly string[] = ['invoice', 'collection', 'creditNote', 'refund', 'creditUsed', 'creditReceived'];
function invalid(code = 'invalid_input'): never {
  throw new WorkspaceProfileError(code, 'Check the original customer records and account/Store context.', 400);
}
function text(value: unknown): string { if (typeof value !== 'string' || !value.trim()) invalid(); return value; }
function nullableText(value: unknown): string | null { if (value !== null && typeof value !== 'string') invalid(); return value as string | null; }
function money(value: unknown, signed = false): number {
  if (!Number.isSafeInteger(value) || (!signed && (value as number) < 0)) invalid();
  return value as number;
}
function exactNumber(value: bigint): number { if (value < -limit || value > limit) invalid(); return Number(value); }
function channel(value: unknown): CustomerChannel { if (!channels.includes(value as string)) invalid(); return value as CustomerChannel; }
function context(v: Record<string, unknown>, rawScope: CustomerScope): void {
  const scope = checkedPurchaseEntryScope(rawScope);
  if (v.accountScope !== scope.account || v.workspaceId !== scope.store) invalid();
  for (const key of ['accountScope', 'workspaceId', 'customerId']) purchaseEntryId(v[key]);
}
const requestKeys = ['accountScope', 'workspaceId', 'customerId', 'invoiceId', 'orderId', 'operationId', 'expectedRevision', 'amountMinor', 'channel', 'reference'];
function checkedTender(v: Record<string, unknown>, scope: CustomerScope): CustomerCollection {
  context(v, scope);
  for (const key of ['invoiceId', 'orderId', 'operationId']) purchaseEntryId(v[key]);
  purchaseEntryRevision(v.expectedRevision);
  if (money(v.amountMinor) <= 0) invalid();
  const c = channel(v.channel), ref = nullableText(v.reference);
  if (c !== 'cash' && !((c === 'directUpi' || c === 'bankTransfer') && ref?.trim())) invalid();
  return purchaseEntryClone(v) as unknown as CustomerCollection;
}
export function checkedCustomerCollection(raw: unknown, scope: CustomerScope): CustomerCollection {
  return checkedTender(purchaseEntryExact(raw, requestKeys), scope);
}
export function checkedCustomerRefund(raw: unknown, scope: CustomerScope): CustomerRefund {
  const v = purchaseEntryExact(raw, requestKeys, ['sourceCollectionId']);
  checkedTender(v, scope);
  if (Object.hasOwn(v, 'sourceCollectionId')) text(v.sourceCollectionId);
  return purchaseEntryClone(v) as unknown as CustomerRefund;
}
export function checkedCustomerReturn(raw: unknown, scope: CustomerScope): CustomerReturn {
  const v = purchaseEntryExact(raw, ['accountScope', 'workspaceId', 'customerId', 'invoiceId', 'orderId', 'operationId', 'expectedRevision', 'reason', 'lines'], ['reasonCode']);
  context(v, scope);
  for (const key of ['invoiceId', 'orderId', 'operationId']) purchaseEntryId(v[key]);
  text(v.reason); purchaseEntryRevision(v.expectedRevision);
  if (Object.hasOwn(v, 'reasonCode') && !['damaged', 'expired', 'wrong_item', 'quality_issue', 'changed_mind', 'other'].includes(v.reasonCode as string)) invalid();
  if (!Array.isArray(v.lines) || !v.lines.length) invalid();
  const ids = new Set<string>();
  for (const rawLine of v.lines) {
    const line = purchaseEntryExact(rawLine, ['productId', 'quantity', 'restockQuantity']);
    const id = purchaseEntryId(line.productId), q = purchaseEntryRevision(line.quantity);
    const restock = purchaseEntryRevision(line.restockQuantity, 0);
    if (q > 2147483647 || restock > q || ids.has(id)) invalid(); ids.add(id);
  }
  return purchaseEntryClone(v) as unknown as CustomerReturn;
}
function checkedEntry(raw: unknown, scope: CustomerScope): CustomerEntry {
  const v = purchaseEntryExact(raw, ['id', 'operationId', 'invoiceId', 'orderId', 'sequence', 'occurredAt', 'kind', 'state', 'amountMinor', 'channel', 'paymentReference'], ['customerReturn', 'customerRefund']);
  for (const key of ['id', 'operationId', 'invoiceId', 'orderId']) purchaseEntryId(v[key]);
  purchaseEntryRevision(v.sequence); purchaseEntryMicros(v.occurredAt);
  if (!kinds.includes(v.kind as string) || !['pending', 'posted', 'failed'].includes(v.state as string) || money(v.amountMinor) <= 0) invalid();
  channel(v.channel); nullableText(v.paymentReference);
  if (Object.hasOwn(v, 'customerReturn')) {
    const r = checkedCustomerReturn(v.customerReturn, scope);
    if (v.kind !== 'creditNote' || r.operationId !== v.operationId || r.invoiceId !== v.invoiceId || r.orderId !== v.orderId) invalid();
  }
  if (Object.hasOwn(v, 'customerRefund')) {
    const r = checkedCustomerRefund(v.customerRefund, scope);
    if (v.kind !== 'refund' || r.operationId !== v.operationId || r.invoiceId !== v.invoiceId || r.orderId !== v.orderId || r.amountMinor !== v.amountMinor || r.channel !== v.channel || r.reference !== v.paymentReference) invalid();
  }
  return purchaseEntryClone(v) as unknown as CustomerEntry;
}
function delta(e: CustomerEntry): bigint {
  if (e.state !== 'posted') return 0n;
  return BigInt(e.amountMinor) * (['invoice', 'refund', 'creditUsed'].includes(e.kind) ? 1n : -1n);
}
export function checkedCustomerLedger(raw: unknown, scope: CustomerScope): CustomerLedger {
  const v = purchaseEntryExact(raw, ['accountScope', 'workspaceId', 'customerId', 'customerName', 'revision', 'asOf', 'openingBalanceMinor', 'historyComplete', 'entries']);
  context(v, scope); text(v.customerName); purchaseEntryRevision(v.revision);
  const asOf = purchaseEntryMicros(v.asOf);
  if (typeof v.historyComplete !== 'boolean' || v.historyComplete && v.openingBalanceMinor === null || !Array.isArray(v.entries)) invalid();
  if (v.openingBalanceMinor !== null) money(v.openingBalanceMinor, true);
  const entries = v.entries.map(e => checkedEntry(e, scope));
  const ids = new Set<string>(), ops = new Set<string>(), invoices = new Set<string>();
  const running = new Map<string, bigint>(), pairs = new Map<string, CustomerEntry[]>();
  let sequence = 0, previousTime: bigint | undefined, balance = BigInt((v.openingBalanceMinor as number | null) ?? 0);
  for (const e of entries) {
    const time = purchaseEntryMicros(e.occurredAt), op = purchaseEntryCanonical([e.kind, e.operationId, e.invoiceId]);
    if (time > asOf || previousTime !== undefined && time < previousTime || e.sequence <= sequence || ids.has(e.id) || ops.has(op) || e.kind === 'invoice' && invoices.has(e.invoiceId)) invalid();
    for (const r of [e.customerReturn, e.customerRefund]) if (r && r.customerId !== v.customerId) invalid();
    ids.add(e.id); ops.add(op); if (e.kind === 'invoice') invoices.add(e.invoiceId);
    balance += delta(e); exactNumber(balance);
    if (e.kind === 'creditUsed' || e.kind === 'creditReceived') {
      const available = running.get(e.invoiceId);
      if (e.state !== 'posted' || e.channel !== 'credit' || e.customerReturn || e.customerRefund || available === undefined || !invoices.has(e.invoiceId) || BigInt(e.amountMinor) > (e.kind === 'creditUsed' ? -available : available)) invalid();
      pairs.set(e.operationId, [...(pairs.get(e.operationId) ?? []), e]);
    }
    running.set(e.invoiceId, (running.get(e.invoiceId) ?? 0n) + delta(e));
    sequence = e.sequence; previousTime = time;
  }
  for (const pair of pairs.values()) {
    if (pair.length !== 2) invalid();
    const a = pair[0]!, b = pair[1]!;
    if (a.kind !== 'creditUsed' || b.kind !== 'creditReceived' || a.amountMinor !== b.amountMinor || a.invoiceId === b.invoiceId || a.orderId === b.orderId || BigInt(b.sequence) !== BigInt(a.sequence) + 1n || purchaseEntryMicros(a.occurredAt) !== purchaseEntryMicros(b.occurredAt)) invalid();
  }
  return {...purchaseEntryClone(v), entries} as unknown as CustomerLedger;
}
function validated(ledger: CustomerLedger, scope: CustomerScope): CustomerLedger | null {
  try { return checkedCustomerLedger(ledger, scope); }
  catch { return null; } // Caller supplies the original source scope; this still conveys no authority.
}
export interface CustomerInvoiceBalance {
  billedMinor: number; creditedMinor: number; collectedMinor: number; refundedMinor: number;
  dueMinor: number; refundableMinor: number; availableCreditMinor: number;
}
export function customerInvoiceBalance(ledger: CustomerLedger, id: string, scope: CustomerScope): CustomerInvoiceBalance | null {
  if (!validated(ledger, scope) || !ledger.historyComplete || typeof id !== 'string' || !id.trim()) return null;
  let billed = 0n, credited = 0n, collected = 0n, refunded = 0n, used = 0n, received = 0n;
  let order: string | undefined;
  for (const e of ledger.entries.filter(e => e.invoiceId === id)) {
    if (order !== undefined && order !== e.orderId) return null; order = e.orderId;
    if (e.state !== 'posted') continue;
    const amount = BigInt(e.amountMinor), balance = billed - credited - collected + refunded + used - received;
    switch (e.kind) {
      case 'invoice': if (billed !== 0n) return null; billed = amount; break;
      case 'collection': if (!billed || amount > balance) return null; collected += amount; break;
      case 'creditNote': if (!billed || amount > billed - credited) return null; credited += amount; break;
      case 'refund': if (!billed || amount > -balance || amount > collected - refunded) return null; refunded += amount; break;
      case 'creditUsed': if (!billed || amount > -balance) return null; used += amount; break;
      case 'creditReceived': if (!billed || amount > balance) return null; received += amount; break;
    }
  }
  if (!billed) return null;
  const balance = billed - credited - collected + refunded + used - received;
  const available = balance < 0n ? -balance : 0n, cash = collected - refunded;
  try {return {billedMinor: exactNumber(billed), creditedMinor: exactNumber(credited), collectedMinor: exactNumber(collected), refundedMinor: exactNumber(refunded), dueMinor: exactNumber(balance > 0n ? balance : 0n), refundableMinor: exactNumber(available < cash ? available : cash), availableCreditMinor: exactNumber(available)};} catch {return null;}
}
export function customerReceiptRemaining(ledger: CustomerLedger, invoice: string, receipt: string, scope: CustomerScope): number | null {
  if (!validated(ledger, scope) || !ledger.historyComplete) return null;
  const originals = ledger.entries.filter(e => e.id === receipt && e.invoiceId === invoice && e.kind === 'collection' && e.state === 'posted');
  if (originals.length !== 1) return null;
  const original = originals[0]!; let remaining = BigInt(original.amountMinor);
  for (const e of ledger.entries.filter(e => e.invoiceId === invoice && e.kind === 'refund' && e.state === 'posted')) {
    const source = e.customerRefund?.sourceCollectionId;
    if (source === undefined) return null;
    const matches = ledger.entries.filter(r => r.id === source && r.invoiceId === invoice && r.orderId === e.orderId && r.kind === 'collection' && r.state === 'posted' && r.channel === e.channel);
    if (matches.length !== 1) return null;
    if (source === receipt) {
      if (e.orderId !== original.orderId || e.channel !== original.channel) return null;
      remaining -= BigInt(e.amountMinor);
    }
  }
  return remaining < 0n ? null : exactNumber(remaining);
}
export interface CustomerCreditArgs {
  sourceInvoiceId: string; targetInvoiceId: string; amountMinor: number;
  expectedRevision: number; operationId: string; at: string;
}
export function planCustomerCreditAllocation(ledger: CustomerLedger, args: CustomerCreditArgs, scope: CustomerScope): CustomerLedger {
  const current = checkedCustomerLedger(ledger, scope);
  const replay = current.entries.filter(e => e.operationId === args.operationId);
  if (replay.length) {
    if (replay.length === 2 && replay[0]!.kind === 'creditUsed' && replay[1]!.kind === 'creditReceived' && replay[0]!.invoiceId === args.sourceInvoiceId && replay[1]!.invoiceId === args.targetInvoiceId && replay.every(e => e.amountMinor === args.amountMinor)) return current;
    invalid('idempotency_conflict');
  }
  const source = customerInvoiceBalance(current, args.sourceInvoiceId, scope), target = customerInvoiceBalance(current, args.targetInvoiceId, scope);
  purchaseEntryId(args.operationId); purchaseEntryMicros(args.at); money(args.amountMinor);
  if (!current.historyComplete || current.revision !== args.expectedRevision || purchaseEntryMicros(args.at) < purchaseEntryMicros(current.asOf) || args.sourceInvoiceId === args.targetInvoiceId || !source || !target || args.amountMinor <= 0 || args.amountMinor > source.availableCreditMinor || args.amountMinor > target.dueMinor) invalid('stale_book');
  const base = current.entries.at(-1)?.sequence ?? 0;
  const entries: CustomerEntry[] = [0, 1].map((i): CustomerEntry => ({id: `CREDIT-${args.operationId}-${i}`, operationId: args.operationId,
    invoiceId: i === 0 ? args.sourceInvoiceId : args.targetInvoiceId,
    orderId: current.entries.find(e => e.invoiceId === (i === 0 ? args.sourceInvoiceId : args.targetInvoiceId))!.orderId,
    sequence: exactNumber(BigInt(base) + BigInt(i + 1)), occurredAt: args.at,
    kind: i === 0 ? 'creditUsed' : 'creditReceived', state: 'posted', amountMinor: args.amountMinor, channel: 'credit', paymentReference: null}));
  return checkedCustomerLedger({...current, revision: exactNumber(BigInt(current.revision) + 1n), asOf: args.at, entries: [...current.entries, ...entries]}, scope);
}
/** Optional identity helpers; no operation ID is generated and no effect is posted. */
export function customerRecordFingerprint(value: CustomerLedger | CustomerCollection | CustomerRefund | CustomerReturn): string {return purchaseEntryHash(value);}


/** Lossless native Counter draft format only; no Stock or financial authority. */
export interface CustomerCounterDraftWire {
  encoding: 'native-counter-int64-v1';
  draft: {
    version: 1; purpose: 'counter-bill-draft'; account: string; store: string;
    id: string; revision: string;
    stage: 'editing' | 'submitting' | 'reviewRequired' | 'retired';
    customer: string;
    billingDetails: {business: boolean; name: string; businessName: string; gst: string; address: string};
    billingCustomer: string;
    discount: {kind: 'none' | 'fixed' | 'percentage'; value: string};
    source: 'Counter' | 'Phone' | 'Chat';
    fulfilment: 'At the shop' | 'Own delivery' | 'Mool delivery';
    payment: 'Cash' | 'UPI' | 'Bank Transfer' | 'Pay request' | 'On delivery' | 'Customer due';
    address: string; submissionOrderId: string | null;
    lines: {productId: string; name: string; pack: string; quantity: string; unitPricePaise: string; lineTotalPaise: string}[];
  };
}
const customerCounterInt64Max = 9223372036854775807n;
function customerCounterInteger(raw: unknown): bigint {
  if (typeof raw !== 'string' || raw.trim() !== raw || !/^(0|[1-9][0-9]{0,18})$/u.test(raw)) invalid();
  const value = BigInt(raw);
  if (value > customerCounterInt64Max) invalid();
  return value;
}
export function checkedCustomerCounterDraftWire(raw: unknown, scope: CustomerScope): CustomerCounterDraftWire {
  const originalScope = checkedPurchaseEntryScope(scope);
  const envelope = purchaseEntryExact(raw, ['encoding', 'draft']);
  if (envelope.encoding !== 'native-counter-int64-v1') invalid();
  const d = purchaseEntryExact(envelope.draft, [
    'version', 'purpose', 'account', 'store', 'id', 'revision', 'stage', 'customer',
    'billingDetails', 'billingCustomer', 'discount', 'source', 'fulfilment',
    'payment', 'address', 'submissionOrderId', 'lines',
  ]);
  if (d.version !== 1 || d.purpose !== 'counter-bill-draft' ||
      d.account !== originalScope.account || d.store !== originalScope.store) invalid();
  text(d.account); text(d.store); text(d.id);
  if (customerCounterInteger(d.revision) === 0n) invalid();
  if (!['editing', 'submitting', 'reviewRequired', 'retired'].includes(d.stage as string)) invalid();
  for (const field of ['customer', 'billingCustomer', 'address']) if (typeof d[field] !== 'string') invalid();
  if (typeof d.billingCustomer !== 'string' || d.billingCustomer !== '' &&
      !/^(?:\+?91[ -]?)?[6-9]\d(?:[ -]?\d){8}$/u.test(d.billingCustomer.trim())) invalid();
  if (d.submissionOrderId !== null && typeof d.submissionOrderId !== 'string') invalid();
  if (d.stage === 'editing' && d.submissionOrderId !== null) invalid();
  if (!['Counter', 'Phone', 'Chat'].includes(d.source as string) ||
      !['At the shop', 'Own delivery', 'Mool delivery'].includes(d.fulfilment as string) ||
      !['Cash', 'UPI', 'Bank Transfer', 'Pay request', 'On delivery', 'Customer due'].includes(d.payment as string)) invalid();
  const billing = purchaseEntryExact(d.billingDetails, ['business', 'name', 'businessName', 'gst', 'address']);
  if (typeof billing.business !== 'boolean') invalid();
  for (const field of ['name', 'businessName', 'gst', 'address']) if (typeof billing[field] !== 'string') invalid();
  const discount = purchaseEntryExact(d.discount, ['kind', 'value']);
  const discountValue = customerCounterInteger(discount.value);
  switch (discount.kind) {
    case 'none': if (discountValue !== 0n) invalid(); break;
    case 'fixed': if (discountValue === 0n || discountValue > limit) invalid(); break;
    case 'percentage': if (discountValue === 0n || discountValue > 10000n) invalid(); break;
    default: invalid();
  }
  if (!Array.isArray(d.lines)) invalid();
  if (d.stage === 'submitting' || d.stage === 'reviewRequired') {
    text(d.submissionOrderId); text(d.customer);
    if (!d.lines.length) invalid();
  }
  const products = new Set<string>();
  for (const rawLine of d.lines) {
    const line = purchaseEntryExact(rawLine, ['productId', 'name', 'pack', 'quantity', 'unitPricePaise', 'lineTotalPaise']);
    const productId = text(line.productId); text(line.name); text(line.pack);
    const quantity = customerCounterInteger(line.quantity);
    const unitPrice = customerCounterInteger(line.unitPricePaise);
    const total = customerCounterInteger(line.lineTotalPaise);
    if (quantity === 0n || quantity * unitPrice !== total || products.has(productId)) invalid();
    products.add(productId);
  }
  // Keep the original decimal strings and text; no numeric JSON conversion.
  return purchaseEntryClone(envelope) as unknown as CustomerCounterDraftWire;
}

/** Raw Counter recovery input only. Saving/retiring it is never an order,
 * Stock, invoice, collection or cancellation-of-financial-outcome receipt. */
export interface CustomerCounterDraftInput {
  operation: 'saveStoreCounterDraft'; scope: CustomerScope;
  expectedRevision: string | null; idempotencyKey: string;
  wire: CustomerCounterDraftWire;
}
export interface CustomerCounterDraftCommand extends CustomerCounterDraftInput {fingerprint: string}
export function customerCounterDraftFingerprint(input: CustomerCounterDraftInput): string {
  return purchaseEntryHash({operation: input.operation, scope: input.scope,
    expectedRevision: input.expectedRevision, idempotencyKey: input.idempotencyKey, wire: input.wire});
}
export function checkedCustomerCounterDraftCommand(raw: unknown): CustomerCounterDraftCommand {
  const v = purchaseEntryExact(raw, ['operation', 'scope', 'expectedRevision', 'idempotencyKey', 'wire', 'fingerprint']);
  if (v.operation !== 'saveStoreCounterDraft') invalid();
  const scope = checkedPurchaseEntryScope(v.scope);
  const wire = checkedCustomerCounterDraftWire(v.wire, scope);
  const expected = v.expectedRevision === null ? 0n : customerCounterInteger(v.expectedRevision);
  if (v.expectedRevision !== null && expected === 0n || customerCounterInteger(wire.draft.revision) !== expected + 1n) invalid();
  const idempotencyKey = purchaseEntryId(v.idempotencyKey);
  const fingerprint = purchaseEntryFingerprint(v.fingerprint);
  const input: CustomerCounterDraftInput = {operation: 'saveStoreCounterDraft', scope,
    expectedRevision: v.expectedRevision as string | null, idempotencyKey, wire};
  if (fingerprint !== customerCounterDraftFingerprint(input)) invalid('input_changed');
  return {...input, fingerprint};
}
export interface CustomerCounterDraftPlan {
  state: 'save' | 'same' | 'refused'; reason: 'stale_draft' | 'recovery_input_changed' | null;
  next: CustomerCounterDraftWire | null;
}

export interface CustomerCounterDraftReceipt {
  schemaVersion: 1; scope: CustomerScope; operation: 'saveStoreCounterDraft';
  idempotencyKey: string; fingerprint: string; status: 'saved' | 'not_saved';
  reason: 'stale_draft' | 'recovery_input_changed' | null;
  changed: boolean; resultRevision: string | null; recordedAt: string;
}
export interface CustomerCounterDraftResult {
  receipt: CustomerCounterDraftReceipt | null;
  currentDraft: CustomerCounterDraftWire | null;
}
export function checkedCustomerCounterDraftReceipt(raw: unknown, scope: CustomerScope,
  key: string, fingerprint: string): CustomerCounterDraftReceipt {
  const v = purchaseEntryExact(raw, ['schemaVersion', 'scope', 'operation', 'idempotencyKey',
    'fingerprint', 'status', 'reason', 'changed', 'resultRevision', 'recordedAt']);
  if (v.schemaVersion !== 1 || v.operation !== 'saveStoreCounterDraft' ||
      purchaseEntryCanonical(checkedPurchaseEntryScope(v.scope)) !== purchaseEntryCanonical(checkedPurchaseEntryScope(scope)) ||
      v.idempotencyKey !== purchaseEntryId(key) || v.fingerprint !== purchaseEntryFingerprint(fingerprint) ||
      !['saved', 'not_saved'].includes(v.status as string) || typeof v.changed !== 'boolean' ||
      ![null, 'stale_draft', 'recovery_input_changed'].includes(v.reason as null | string)) invalid();
  if (v.resultRevision !== null && customerCounterInteger(v.resultRevision) === 0n) invalid();
  purchaseEntryMicros(v.recordedAt);
  if (v.status === 'saved' && (v.reason !== null || v.resultRevision === null) ||
      v.status === 'not_saved' && (v.reason === null || v.changed)) invalid();
  return purchaseEntryClone(v) as unknown as CustomerCounterDraftReceipt;
}
/** Exact SecureWorkCounterDraftStore.save transition rules, without storage or
 * any financial inference. The original repository supplies/locks current. */
export function planCustomerCounterDraftSave(current: CustomerCounterDraftWire | null,
  raw: CustomerCounterDraftCommand): CustomerCounterDraftPlan {
  const command = checkedCustomerCounterDraftCommand(raw), next = command.wire.draft;
  const previous = current === null ? null : checkedCustomerCounterDraftWire(current, command.scope).draft;
  if (current !== null && purchaseEntryCanonical(current) === purchaseEntryCanonical(command.wire)) {
    return {state: 'same', reason: null, next: purchaseEntryClone(current)};
  }
  if (previous?.stage === 'submitting' && next.stage === 'reviewRequired' &&
      purchaseEntryCanonical({...previous, revision: next.revision, stage: next.stage}) !== purchaseEntryCanonical(next)) {
    return {state: 'refused', reason: 'recovery_input_changed', next: null};
  }
  if ((previous?.revision ?? null) !== command.expectedRevision ||
      next.stage === 'reviewRequired' && previous?.stage !== 'submitting' ||
      previous === null && next.stage !== 'editing' ||
      previous !== null && (previous.id === next.id
        ? previous.stage === 'retired' ||
          previous.stage === 'submitting' && (!['retired', 'reviewRequired'].includes(next.stage) ||
            next.submissionOrderId !== previous.submissionOrderId) ||
          previous.stage === 'reviewRequired' && !['editing', 'retired'].includes(next.stage)
        : previous.stage !== 'retired' || next.stage !== 'editing')) {
    return {state: 'refused', reason: 'stale_draft', next: null};
  }
  return {state: 'save', reason: null, next: purchaseEntryClone(command.wire)};
}

export interface CustomerCounterDraftRepository {
  readonly realm: PurchaseEntryRealm; readonly projectId: string;
  read(actor: PurchaseEntryActor, scope: CustomerScope): Promise<CustomerCounterDraftWire | null>;
  save(actor: PurchaseEntryActor, command: CustomerCounterDraftCommand): Promise<CustomerCounterDraftResult>;
  status(actor: PurchaseEntryActor, scope: CustomerScope, key: string, fingerprint: string): Promise<CustomerCounterDraftResult>;
}
export function workspaceCustomerOperation(operation: string): 'read' | 'save' | 'status' | undefined {
  if (operation === 'readStoreCounterDraft') return 'read';
  if (operation === 'saveStoreCounterDraft') return 'save';
  if (operation === 'readStoreCounterDraftAttempt') return 'status';
  return undefined;
}
const customerCommon = ['schemaVersion', 'customerOriginalVersion', 'actorAccountId', 'realm', 'storeId'];
export class WorkspaceCustomerService {
  constructor(private readonly repository?: CustomerCounterDraftRepository,
    private readonly now: () => Date = () => new Date()) {}
  private scope(actor: PurchaseEntryActor, body: Readonly<Record<string, unknown>>): CustomerScope {
    if (!this.repository) throw new WorkspaceProfileError('service_unavailable', 'Original customer records are unavailable.', 503);
    if (!actor || actor.tenantId !== undefined || !actor.uid || actor.projectId !== this.repository.projectId ||
        body.actorAccountId !== actor.uid || body.realm !== this.repository.realm ||
        body.schemaVersion !== 1 || body.customerOriginalVersion !== 1) {
      throw new WorkspaceProfileError('permission_denied', 'Original customer context changed.', 403);
    }
    return checkedPurchaseEntryScope({account: actor.uid, store: body.storeId, realm: this.repository.realm});
  }
  private response(scope: CustomerScope, result: CustomerCounterDraftResult, key?: string, fingerprint?: string): object {
    const current = result.currentDraft === null ? null : checkedCustomerCounterDraftWire(result.currentDraft, scope);
    const receipt = result.receipt === null ? null : checkedCustomerCounterDraftReceipt(result.receipt, scope, key!, fingerprint!);
    if (receipt?.resultRevision !== null && receipt?.resultRevision !== undefined &&
        (!current || BigInt(current.draft.revision) < BigInt(receipt.resultRevision))) {
      throw new WorkspaceProfileError('service_unavailable', 'Original Counter recovery could not be verified.', 503);
    }
    return {schemaVersion: 1, customerOriginalVersion: 1, actorAccountId: scope.account,
      realm: scope.realm, storeId: scope.store, observedAt: this.now().toISOString(),
      state: current === null ? 'empty' : 'ready',
      draftJson: current === null ? null : purchaseEntryCanonical(current),
      draftFingerprint: current === null ? null : purchaseEntryHash(current), attempt: receipt};
  }
  async handle(actor: PurchaseEntryActor, operation: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    const method = workspaceCustomerOperation(operation);
    if (!method) invalid();
    purchaseEntryExact(body, [...customerCommon, ...(method === 'read' ? [] : method === 'status'
      ? ['idempotencyKey', 'fingerprint'] : ['expectedRevision', 'idempotencyKey', 'fingerprint', 'wire'])]);
    const scope = this.scope(actor, body);
    if (method === 'read') return this.response(scope, {receipt: null, currentDraft: await this.repository!.read(actor, scope)});
    const key = purchaseEntryId(body.idempotencyKey), fingerprint = purchaseEntryFingerprint(body.fingerprint);
    if (method === 'status') return this.response(scope, await this.repository!.status(actor, scope, key, fingerprint), key, fingerprint);
    const command = checkedCustomerCounterDraftCommand({operation: 'saveStoreCounterDraft', scope,
      expectedRevision: body.expectedRevision, idempotencyKey: key, fingerprint, wire: body.wire});
    const result = await this.repository!.save(actor, command);
    if (!result.receipt || result.receipt.status === 'saved' &&
        (result.receipt.resultRevision !== command.wire.draft.revision ||
          result.currentDraft?.draft.revision === command.wire.draft.revision &&
            purchaseEntryCanonical(result.currentDraft) !== purchaseEntryCanonical(command.wire))) {
      throw new WorkspaceProfileError('service_unavailable', 'Original Counter save could not be verified.', 503);
    }
    return this.response(scope, result, key, fingerprint);
  }
}

