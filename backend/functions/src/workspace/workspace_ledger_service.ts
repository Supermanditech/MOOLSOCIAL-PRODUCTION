import {
  checkedPurchaseEntryScope, checkedPurchaseEntryOpening, checkedPurchaseEntryCopy, purchaseEntryInvoiceFinancialYear,
  purchaseEntryCanonical, purchaseEntryClone,
  purchaseEntryExact, purchaseEntryFingerprint,
  purchaseEntryHash, purchaseEntryId, purchaseEntryMicros, purchaseEntryRevision,
  type PurchaseEntryActor, type PurchaseEntryScope, type PurchaseEntryOpeningRecord, type PurchaseEntryOpeningBill, type PurchaseEntryCopy,
} from './workspace_purchase_entry_service.js';
import {WorkspaceProfileError} from './workspace_profile_service.js';

/** Original owner-recorded sections only; never a replacement finance snapshot. */
export type LedgerScope = PurchaseEntryScope;
export type LedgerActor = PurchaseEntryActor;
export type LedgerKind = 'supplierLedger' | 'expense' | 'moneyRegister' | 'moneyEntry';
export type LedgerOperation = 'recordStoreExpense' | 'confirmStoreSupplierOpening' | 'recordStoreMoneyRegisterEntry' | 'recordStoreSupplierMoney' | 'confirmStoreSupplierBill' | 'recordStoreSupplierMoneyAllocation' | 'recordStoreSupplierRefund' | 'recordStoreSupplierCreditNote';
export interface LedgerExpense {
  account: string; store: string; operationId: string; amountMinor: number;
  category: string; method: string; reference: string; note: string; occurredAt: string;
}
export type LedgerOpeningBill = PurchaseEntryOpeningBill;
export type LedgerOpeningRecord = PurchaseEntryOpeningRecord;
export interface LedgerRegisterEntry {id: string; reference: string; occurredAt: string; deltaMinor: number}
/** Existing native manual-money input only. Parsing is not proof of payment,
 * source ownership, available capacity or permission to publish a record. */
export interface LedgerSupplierMoneyEntry {
  operationId: string; orderId: null; reference: string; billId: string | null;
  origin: 'supplierAccount' | 'manualPurchase'; purchaseId?: string;
  paymentMethod: string; kind: 'payment' | 'advance'; amountMinor: number; postedAt: string;
  moneyReview: {occurredOn: string; openingId: string; openingRevision: number; notIncludedInOpening: true};
}
export const ledgerSupplierMoneyMethods = ['UPI', 'Cheque', 'Bank transfer', 'NEFT', 'RTGS', 'Cash'] as const;
export interface LedgerSupplierBillAcceptance {
  copy: PurchaseEntryCopy; acceptedAt: string; openingTreatment: 'included' | 'excluded';
  openingReview?: {openingId: string; openingRevision: number; treatment: 'included' | 'excluded'};
}
export type LedgerSupplierMoneySourceKind = 'openingAdvance' | 'accountPayment' | 'accountAdvance' | 'manualBillSurplus';
/** Existing native attribution request; never another payment or Stock fact. */
export interface LedgerSupplierAllocationIntent {
  operationId: string; accountScope: string; workspaceId: string; supplierId: string;
  sourceKind: LedgerSupplierMoneySourceKind; sourceId: string; openingId: string;
  openingRevision: number; billId: string; copyId: string; copyRevision: number;
  amountMinor: number; requestedAt: string; sourceCopyId?: string; sourceCopyRevision?: number;
}
export interface LedgerSupplierAllocationProof extends LedgerSupplierAllocationIntent {
  committedRevision: number; recordedAt: string; sourceEntryCount?: number;
}
/** Printed supplier credit-note input, not a GST return or posting authority.
 * Keep classification, rows and particulars together; never infer missing tax. */
export interface LedgerSupplierCreditDocumentInput {
  version: 1 | 2; treatment: '' | 'gst' | 'commercial'; reasonCode: string;
  taxRows: Array<Record<'rate' | 'taxable' | 'cgst' | 'sgst' | 'igst' | 'cess', string>>;
  particulars?: Record<string, string>;
}
export const ledgerSupplierCreditParticularLimits: Readonly<Record<string, number>> = Object.freeze({
  documentTitle: 128, supplierName: 256, supplierAddress: 2000, supplierGstin: 32,
  buyerName: 256, buyerAddress: 2000, buyerGstinUin: 32, deliveryAddress: 2000,
  recipientState: 128, recipientStateCode: 2, invoiceReferences: 4000,
  signatureDetails: 512, irn: 128, qrReference: 8000,
});
export function checkedLedgerSupplierCreditDocumentInput(raw: unknown): LedgerSupplierCreditDocumentInput {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) ledgerError();
  const value = raw as Record<string, unknown>, version = value.version;
  if (version !== 1 && version !== 2) ledgerError();
  ledgerExact(value, ['version', 'treatment', 'reasonCode', 'taxRows', ...(version === 2 ? ['particulars'] : [])]);
  if (typeof value.treatment !== 'string' || !['', 'gst', 'commercial'].includes(value.treatment) ||
      typeof value.reasonCode !== 'string' || !['', 'return', 'shortage', 'damage', 'price', 'tax', 'discount', 'other'].includes(value.reasonCode) ||
      !Array.isArray(value.taxRows) || value.taxRows.length > 100) ledgerError();
  const taxFields = ['rate', 'taxable', 'cgst', 'sgst', 'igst', 'cess'];
  for (const row of value.taxRows) {
    const fields = ledgerExact(row, taxFields);
    if (Object.values(fields).some(text => typeof text !== 'string' || text.length > 100)) ledgerError();
  }
  if (version === 2) {
    const printed = value.particulars;
    if (!printed || typeof printed !== 'object' || Array.isArray(printed) ||
        Object.keys(printed).length > Object.keys(ledgerSupplierCreditParticularLimits).length) ledgerError();
    for (const [key, text] of Object.entries(printed)) {
      if (!Object.hasOwn(ledgerSupplierCreditParticularLimits, key) || typeof text !== 'string' ||
          text.length > ledgerSupplierCreditParticularLimits[key]!) ledgerError();
    }
  }
  if (JSON.stringify(value).length > 65536) ledgerError();
  return ledgerClone(value) as unknown as LedgerSupplierCreditDocumentInput;
}
/** Sum explicitly printed values only, matching the native review comparison.
 * Null means incomplete/unreadable; it never means zero tax or zero credit. */
export function ledgerSupplierCreditPrintedTotal(document: LedgerSupplierCreditDocumentInput): number | null {
  const value = checkedLedgerSupplierCreditDocumentInput(document);
  if (value.treatment !== 'gst' || value.taxRows.length === 0) return null;
  let total = 0;
  for (const row of value.taxRows) for (const field of ['taxable', 'cgst', 'sgst', 'igst', 'cess'] as const) {
    const printed = ledgerPrintedPaise(row[field]);
    if (printed === null) return null;
    total += printed;
    if (!Number.isSafeInteger(total)) return null;
  }
  return total;
}
export interface LedgerSupplierCreditSupport {
  kind: 'goodsReturned' | 'arrivalDamage' | 'shortage'; receiptId: string; receiptLineId: string;
  billLineIndex: number; quantityMilli: number; returnOperationId?: string; shortageClaimId?: string;
}
/** Reviewed supplier document only; source and cumulative capacity are not
 * established by decoding it. Legacy unclassified notes are not new commands. */
export interface LedgerSupplierCreditIntent {
  operationId: string; accountScope: string; workspaceId: string; supplierId: string;
  billId: string; copyId: string; copyRevision: number; openingId: string; openingRevision: number;
  reference: string; occurredOn: string; reason: string; amountMinor: number; requestedAt: string;
  supports: LedgerSupplierCreditSupport[]; documentInput: LedgerSupplierCreditDocumentInput;
}
export interface LedgerSupplierCreditProof extends LedgerSupplierCreditIntent {committedRevision: number; recordedAt: string}
const supplierCreditIntentKeys = ['operationId', 'accountScope', 'workspaceId', 'supplierId', 'billId', 'copyId',
  'copyRevision', 'openingId', 'openingRevision', 'reference', 'occurredOn', 'reason', 'amountMinor', 'requestedAt',
  'supports', 'documentInput'];
export function checkedLedgerSupplierCreditIntent(raw: unknown, scope: LedgerScope): LedgerSupplierCreditIntent {
  const value = ledgerExact(raw, supplierCreditIntentKeys);
  for (const key of ['operationId', 'accountScope', 'workspaceId', 'supplierId', 'billId', 'copyId', 'openingId', 'reference']) {
    const text = ledgerText(value[key], 512); if (text !== text.trim()) ledgerError();
  }
  const reason = ledgerText(value.reason, 2000);
  if (reason !== reason.trim() || value.accountScope !== scope.account || value.workspaceId !== scope.store ||
      ledgerAmount(value.amountMinor) <= 0) ledgerError();
  purchaseEntryRevision(value.copyRevision); purchaseEntryRevision(value.openingRevision);
  ledgerDay(value.occurredOn); ledgerTime(value.requestedAt);
  const document = checkedLedgerSupplierCreditDocumentInput(value.documentInput);
  if (document.treatment === '' || document.reasonCode === '' || !Array.isArray(value.supports) || value.supports.length === 0 ||
      JSON.stringify(value).length > 262144) ledgerError();
  const identities = new Set<string>();
  for (const rawSupport of value.supports) {
    if (!rawSupport || typeof rawSupport !== 'object' || Array.isArray(rawSupport)) ledgerError();
    const kind = (rawSupport as Record<string, unknown>).kind;
    if (kind !== 'goodsReturned' && kind !== 'arrivalDamage' && kind !== 'shortage') ledgerError();
    const support = ledgerExact(rawSupport, ['kind', 'receiptId', 'receiptLineId', 'billLineIndex', 'quantityMilli',
      ...(kind === 'goodsReturned' ? ['returnOperationId'] : []), ...(kind === 'shortage' ? ['shortageClaimId'] : [])]);
    for (const key of ['receiptId', 'receiptLineId', ...(kind === 'goodsReturned' ? ['returnOperationId'] : []),
      ...(kind === 'shortage' ? ['shortageClaimId'] : [])]) {
      const text = ledgerText(support[key], 512); if (text !== text.trim()) ledgerError();
    }
    if (!Number.isSafeInteger(support.billLineIndex) || Number(support.billLineIndex) < 0 ||
        !Number.isSafeInteger(support.quantityMilli) || Number(support.quantityMilli) <= 0 || Number(support.quantityMilli) > 2147483647) ledgerError();
    const identity = ledgerCanonical(kind === 'shortage' ? [kind, support.shortageClaimId]
      : [kind, support.receiptId, support.receiptLineId, support.returnOperationId ?? null]);
    if (identities.has(identity)) ledgerError(); identities.add(identity);
  }
  return ledgerClone(value) as unknown as LedgerSupplierCreditIntent;
}
export function checkedLedgerSupplierCreditProof(raw: unknown, scope: LedgerScope): LedgerSupplierCreditProof {
  const value = ledgerExact(raw, [...supplierCreditIntentKeys, 'recordedAt', 'committedRevision']);
  checkedLedgerSupplierCreditIntent(Object.fromEntries(supplierCreditIntentKeys.map(key => [key, value[key]])), scope);
  purchaseEntryRevision(value.committedRevision);
  if (Number(value.committedRevision) <= 1 || ledgerMicros(value.recordedAt) < ledgerMicros(value.requestedAt)) ledgerError();
  return ledgerClone(value) as unknown as LedgerSupplierCreditProof;
}
export function ledgerSupplierCreditEntry(proof: LedgerSupplierCreditProof): Record<string, unknown> {
  return {operationId: proof.operationId, orderId: null, reference: proof.reference,
    billId: proof.billId, origin: 'manualPurchase', purchaseId: proof.copyId,
    kind: 'creditNote', amountMinor: proof.amountMinor, postedAt: proof.recordedAt};
}
export function ledgerSupplierCreditInput(proof: LedgerSupplierCreditProof): LedgerSupplierCreditIntent {
  const {committedRevision: _revision, recordedAt: _at, ...intent} = proof;
  return ledgerClone(intent);
}
/** Existing native incoming-money record. This is not provider verification. */
export interface LedgerSupplierRefundIntent {
  operationId: string; accountScope: string; workspaceId: string; supplierId: string; qa: boolean;
  sourceKind: 'openingAdvance' | 'accountAdvance' | 'manualBillSurplus'; sourceId: string;
  openingId: string; openingRevision: number; reference: string; occurredOn: string;
  paymentMethod: 'Cash' | 'UPI' | 'Bank transfer'; amountMinor: number; requestedAt: string;
  copyId: string | null; copyRevision: number | null;
}
export interface LedgerSupplierRefundProof {
  intent: LedgerSupplierRefundIntent; committedRevision: number; recordedAt: string;
}
/** Entry history is paged separately; its absence here is not an empty history. */
export interface LedgerRegisterHeader {
  accountScope: string; workspaceId: string; registerId: string; label: string;
  revision: number; openingAt: string; asOf: string; openingMinor: number | null;
  historyComplete: boolean; entryCount: number; lastEntryAt: string | null;
  /** Native sequential overflow guard, not an available cash/bank balance. */
  sequenceValidationMinor: number;
}
export interface LedgerCommandBase {
  scope: LedgerScope; expectedRevision: number | null; idempotencyKey: string; fingerprint: string;
}
export interface LedgerExpenseCommand extends LedgerCommandBase {
  operation: 'recordStoreExpense'; expense: LedgerExpense;
}
export interface LedgerOpeningCommand extends LedgerCommandBase {
  operation: 'confirmStoreSupplierOpening'; opening: LedgerOpeningRecord;
  expectedPurchaseRevision: number; expectedPurchaseFingerprint: string;
  confirmedAt: string; confirmedUtcOffsetMinutes: number;
}
export interface LedgerRegisterCommand extends LedgerCommandBase {
  operation: 'recordStoreMoneyRegisterEntry'; registerId: string;
  expectedRegisterRevision: number; entry: LedgerRegisterEntry; capturedAt: string;
}
export interface LedgerSupplierMoneyCommand extends LedgerCommandBase {
  operation: 'recordStoreSupplierMoney'; supplierId: string; expectedSupplierRevision: number;
  entry: LedgerSupplierMoneyEntry; confirmedUtcOffsetMinutes: number;
}
export interface LedgerSupplierBillCommand extends LedgerCommandBase {
  operation: 'confirmStoreSupplierBill'; supplierId: string; expectedSupplierRevision: number;
  expectedPurchaseRevision: number; expectedPurchaseFingerprint: string;
  bill: LedgerSupplierBillAcceptance; confirmedUtcOffsetMinutes: number;
}
export interface LedgerSupplierAllocationCommand extends LedgerCommandBase {
  operation: 'recordStoreSupplierMoneyAllocation'; supplierId: string; expectedSupplierRevision: number;
  intent: LedgerSupplierAllocationIntent;
}
export interface LedgerSupplierRefundCommand extends LedgerCommandBase {
  operation: 'recordStoreSupplierRefund'; supplierId: string; expectedSupplierRevision: number;
  intent: LedgerSupplierRefundIntent; confirmedUtcOffsetMinutes: number;
}
export interface LedgerSupplierCreditCommand extends LedgerCommandBase {
  operation: 'recordStoreSupplierCreditNote'; supplierId: string; expectedSupplierRevision: number;
  expectedPurchaseRevision: number; expectedPurchaseFingerprint: string;
  intent: LedgerSupplierCreditIntent; confirmedUtcOffsetMinutes: number;
}
export type LedgerCommand = LedgerExpenseCommand | LedgerOpeningCommand | LedgerRegisterCommand | LedgerSupplierMoneyCommand | LedgerSupplierBillCommand | LedgerSupplierAllocationCommand | LedgerSupplierRefundCommand | LedgerSupplierCreditCommand;
export interface LedgerReceipt {
  schemaVersion: 1; scope: LedgerScope; operation: LedgerOperation; idempotencyKey: string;
  fingerprint: string; inputFingerprint: string; status: 'saved' | 'not_saved'; reason: string | null;
  changed: boolean; resultRevision: number | null; targetKind: Exclude<LedgerKind, 'moneyEntry'>;
  targetId: string; entryId: string | null; recordedAt: string;
}
export interface LedgerRow {
  kind: LedgerKind; id: string; parentId: string | null; revision: number;
  json: string; fingerprint: string; ordinal: number | null;
}
export interface LedgerPage {
  revision: number | null; kind: LedgerKind; parentId: string | null;
  totalCount: number; startsSource: boolean; rows: readonly LedgerRow[]; nextCursor: string | null;
}
export interface LedgerStatus {revision: number | null; receipt: LedgerReceipt | null; current: LedgerRow | null}
export interface LedgerRepository {
  readonly realm: 'evaluation' | 'production'; readonly projectId: string; readonly configured: boolean;
  list(actor: LedgerActor, scope: LedgerScope, kind: LedgerKind, parentId: string | null, cursor: string | null): Promise<LedgerPage>;
  status(actor: LedgerActor, scope: LedgerScope, key: string, fingerprint: string): Promise<LedgerStatus>;
  recordExpense(actor: LedgerActor, command: LedgerExpenseCommand): Promise<LedgerStatus>;
  confirmOpening(actor: LedgerActor, command: LedgerOpeningCommand): Promise<LedgerStatus>;
  recordRegisterEntry(actor: LedgerActor, command: LedgerRegisterCommand): Promise<LedgerStatus>;
  recordSupplierMoney?(actor: LedgerActor, command: LedgerSupplierMoneyCommand): Promise<LedgerStatus>;
  confirmSupplierBill?(actor: LedgerActor, command: LedgerSupplierBillCommand): Promise<LedgerStatus>;
  allocateSupplierMoney?(actor: LedgerActor, command: LedgerSupplierAllocationCommand): Promise<LedgerStatus>;
  recordSupplierRefund?(actor: LedgerActor, command: LedgerSupplierRefundCommand): Promise<LedgerStatus>;
  recordSupplierCredit?(actor: LedgerActor, command: LedgerSupplierCreditCommand): Promise<LedgerStatus>;
}

const kinds: readonly LedgerKind[] = ['supplierLedger', 'expense', 'moneyRegister', 'moneyEntry'];
const operations: readonly LedgerOperation[] = ['recordStoreExpense', 'confirmStoreSupplierOpening', 'recordStoreMoneyRegisterEntry', 'recordStoreSupplierMoney', 'confirmStoreSupplierBill', 'recordStoreSupplierMoneyAllocation', 'recordStoreSupplierRefund', 'recordStoreSupplierCreditNote'];
const supplierBillFields = ['supplierId', 'expectedSupplierRevision', 'expectedPurchaseRevision', 'expectedPurchaseFingerprint', 'bill', 'confirmedUtcOffsetMinutes'];
const supplierAllocationFields = ['supplierId', 'expectedSupplierRevision', 'intent'];
const supplierRefundFields = ['supplierId', 'expectedSupplierRevision', 'intent', 'confirmedUtcOffsetMinutes'];
const supplierCreditFields = [...supplierRefundFields, 'expectedPurchaseRevision', 'expectedPurchaseFingerprint'];
/** Closed HTTP routing table also distinguishes readonly status from mutation. */
export function workspaceLedgerOperation(operation: string): 'read' | 'status' | 'mutation' | undefined {
  if (operation === 'readStoreLedgerSource') return 'read';
  if (operation === 'readStoreLedgerAttempt') return 'status';
  if (operations.includes(operation as LedgerOperation)) return 'mutation';
  return undefined;
}
const common = ['operation', 'schemaVersion', 'ledgerVersion', 'scope'];
const saveKeys = [...common, 'expectedRevision', 'idempotencyKey', 'fingerprint'];
export const ledgerCanonical = purchaseEntryCanonical;
export const ledgerHash = purchaseEntryHash;
export const ledgerClone = purchaseEntryClone;
export const ledgerExact = purchaseEntryExact;
export function ledgerError(code = 'invalid_input', status = 400): never {
  const message = code === 'service_unavailable' ? 'Store account records could not be verified. Saved records are kept.'
    : code === 'permission_denied' ? 'Reopen the approved Store to continue.'
    : code === 'idempotency_conflict' ? 'Check the original saved status before changing these entries.'
    : code.startsWith('stale_') ? 'Records changed. Review the current details before saving again.'
    : 'Check the account entries and try again.';
  throw new WorkspaceProfileError(code, message, status, status >= 500);
}
export const ledgerMicros = purchaseEntryMicros;
export function ledgerText(value: unknown, maximum?: number, blank = false): string {
  if (typeof value !== 'string' || !blank && !value.trim() || maximum !== undefined && value.length > maximum ||
      /[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/.test(value) || Buffer.from(value, 'utf8').toString('utf8') !== value) ledgerError();
  return value;
}
export function ledgerAmount(value: unknown, signed = false): number {
  if (!Number.isSafeInteger(value) || !signed && (value as number) < 0) ledgerError();
  return value as number;
}
export function ledgerCount(value: unknown): number {
  if (!Number.isSafeInteger(value) || (value as number) < 0) ledgerError('service_unavailable', 503);
  return value as number;
}
export function ledgerTime(value: unknown): string {
  ledgerMicros(value); return value as string;
}
/** Compare known internal timestamps by exact instant; printed fields and
 * original source-byte fingerprints stay exact and are never rewritten. */
export function ledgerReviewedCopyMatches(left: ReturnType<typeof checkedPurchaseEntryCopy>, right: ReturnType<typeof checkedPurchaseEntryCopy>): boolean {
  const adjusted = ledgerClone(left) as unknown as Record<string, unknown>, target = right as unknown as Record<string, unknown>;
  for (const [a, b, keys] of [
    [adjusted, target, ['savedAt']],
    [adjusted.supplier as Record<string, unknown>, target.supplier as Record<string, unknown>, ['createdAt', 'updatedAt']],
    [adjusted.draft as Record<string, unknown>, target.draft as Record<string, unknown>, ['createdAt', 'updatedAt']],
  ] as const) for (const key of keys) {
    if (ledgerMicros(a[key]) !== ledgerMicros(b[key])) return false;
    a[key] = b[key];
  }
  return ledgerCanonical(adjusted) === ledgerCanonical(target);
}
export function checkedLedgerSupplierAllocationIntent(raw: unknown, scope: LedgerScope): LedgerSupplierAllocationIntent {
  const surplus = (raw as Record<string, unknown> | null)?.sourceKind === 'manualBillSurplus';
  const value = ledgerExact(raw, ['operationId', 'accountScope', 'workspaceId', 'supplierId', 'sourceKind',
    'sourceId', 'openingId', 'openingRevision', 'billId', 'copyId', 'copyRevision', 'amountMinor', 'requestedAt',
    ...(surplus ? ['sourceCopyId', 'sourceCopyRevision'] : [])]);
  for (const key of ['operationId', 'accountScope', 'workspaceId', 'supplierId', 'sourceId', 'openingId', 'billId', 'copyId']) ledgerText(value[key], 512);
  if (typeof value.sourceKind !== 'string' || !['openingAdvance', 'accountPayment', 'accountAdvance', 'manualBillSurplus'].includes(value.sourceKind) ||
      value.accountScope !== scope.account || value.workspaceId !== scope.store || ledgerAmount(value.amountMinor) <= 0) ledgerError();
  purchaseEntryRevision(value.openingRevision); purchaseEntryRevision(value.copyRevision); ledgerTime(value.requestedAt);
  if (surplus) {
    ledgerText(value.sourceCopyId, 512); purchaseEntryRevision(value.sourceCopyRevision);
    if (value.sourceId === value.billId) ledgerError();
  }
  return ledgerClone(value) as unknown as LedgerSupplierAllocationIntent;
}
/** Closed original commit proof, not proof of available source/bill capacity.
 * Capacity and membership still require the original publication transaction. */
export function checkedLedgerSupplierAllocationProof(raw: unknown, scope: LedgerScope): LedgerSupplierAllocationProof {
  const value = raw as Record<string, unknown>;
  if (!value || typeof value !== 'object' || Array.isArray(value)) ledgerError();
  const {committedRevision, recordedAt, sourceEntryCount, ...input} = value;
  const surplus = value.sourceKind === 'manualBillSurplus';
  if (!Object.hasOwn(value, 'committedRevision') || !Object.hasOwn(value, 'recordedAt') ||
      Object.hasOwn(value, 'sourceEntryCount') !== surplus) ledgerError();
  const intent = checkedLedgerSupplierAllocationIntent(input, scope);
  if (purchaseEntryRevision(committedRevision) <= 1 || ledgerMicros(recordedAt) < ledgerMicros(intent.requestedAt) ||
      surplus && ledgerCount(sourceEntryCount) > 10000) ledgerError();
  return ledgerClone(value) as unknown as LedgerSupplierAllocationProof;
}
export function ledgerSupplierAllocationInput(proof: LedgerSupplierAllocationProof): LedgerSupplierAllocationIntent {
  const {committedRevision: _revision, recordedAt: _at, sourceEntryCount: _count, ...intent} = proof;
  return ledgerClone(intent);
}
export function checkedLedgerSupplierRefundIntent(raw: unknown, scope: LedgerScope): LedgerSupplierRefundIntent {
  const value = ledgerExact(raw, ['operationId', 'accountScope', 'workspaceId', 'supplierId', 'qa', 'sourceKind',
    'sourceId', 'openingId', 'openingRevision', 'reference', 'occurredOn', 'paymentMethod', 'amountMinor', 'requestedAt', 'copyId', 'copyRevision']);
  for (const key of ['operationId', 'accountScope', 'workspaceId', 'supplierId', 'sourceId', 'openingId', 'reference']) {
    const text = ledgerText(value[key], 512); if (text !== text.trim()) ledgerError();
  }
  if (value.accountScope !== scope.account || value.workspaceId !== scope.store || typeof value.qa !== 'boolean' ||
      typeof value.sourceKind !== 'string' || !['openingAdvance', 'accountAdvance', 'manualBillSurplus'].includes(value.sourceKind) ||
      typeof value.paymentMethod !== 'string' || !['Cash', 'UPI', 'Bank transfer'].includes(value.paymentMethod) || ledgerAmount(value.amountMinor) <= 0) ledgerError();
  purchaseEntryRevision(value.openingRevision); ledgerDay(value.occurredOn); ledgerTime(value.requestedAt);
  if (value.sourceKind === 'manualBillSurplus') {
    const id = ledgerText(value.copyId, 512); if (id !== id.trim()) ledgerError();
    purchaseEntryRevision(value.copyRevision);
  } else if (value.copyId !== null || value.copyRevision !== null) ledgerError();
  return ledgerClone(value) as unknown as LedgerSupplierRefundIntent;
}
export function checkedLedgerSupplierRefundProof(raw: unknown, scope: LedgerScope): LedgerSupplierRefundProof {
  const value = ledgerExact(raw, ['intent', 'committedRevision', 'recordedAt']);
  const intent = checkedLedgerSupplierRefundIntent(value.intent, scope);
  if (purchaseEntryRevision(value.committedRevision) <= 1 || ledgerMicros(value.recordedAt) < ledgerMicros(intent.requestedAt)) ledgerError();
  return ledgerClone(value) as unknown as LedgerSupplierRefundProof;
}
export function ledgerSupplierRefundEntry(proof: LedgerSupplierRefundProof): Record<string, unknown> {
  const {intent, recordedAt} = proof, surplus = intent.sourceKind === 'manualBillSurplus';
  return {operationId: intent.operationId, orderId: null, reference: intent.reference,
    origin: surplus ? 'manualPurchase' : 'supplierAccount', ...(surplus ? {purchaseId: intent.copyId} : {}),
    billId: surplus ? intent.sourceId : null, kind: 'refund', amountMinor: intent.amountMinor,
    paymentMethod: intent.paymentMethod, postedAt: recordedAt};
}
/** Exact native printed-rupee input conversion. Missing/invalid is not zero;
 * no rounding, tax calculation or accounting authority is supplied here. */
export function ledgerPrintedPaise(input: unknown): number | null {
  if (typeof input !== 'string' || !/^-?\d+(\.\d{1,2})?$/u.test(input.trim())) return null;
  const value = input.trim(), parts = value.replace(/^-/, '').split('.'), whole = BigInt(parts[0]!);
  if (whole > 999999999999n) return null;
  const paise = Number(whole * 100n + BigInt((parts[1] ?? '').padEnd(2, '0')));
  return value.startsWith('-') && paise !== 0 ? -paise : paise;
}
/** Closed counterpart of the existing native reviewed bill. This validates
 * the frozen input only; the original-copy/opening/revision transaction must
 * still prove that the bill may be accepted and liability recorded. */
export function checkedLedgerSupplierBillAcceptance(raw: unknown): LedgerSupplierBillAcceptance {
  const v = ledgerExact(raw, ['copy', 'acceptedAt', 'openingTreatment'], ['openingReview']);
  const copy = checkedPurchaseEntryCopy(v.copy, true), draft = copy.draft, details = draft.details ?? {};
  ledgerTime(v.acceptedAt);
  if (!['included', 'excluded'].includes(String(v.openingTreatment)) || typeof v.openingTreatment !== 'string' ||
      ledgerMicros(v.acceptedAt) < ledgerMicros(copy.savedAt) || !draft.invoiceReference.trim() ||
      purchaseEntryInvoiceFinancialYear(draft.invoiceDate) === null || !draft.goods.length) ledgerError();
  const total = ledgerPrintedPaise(details.invoiceTotal);
  if (total === null || total < 0) ledgerError();
  for (const line of draft.goods) {
    const quantity = line.quantity ?? '', free = line.freeQuantity ?? '', cost = ledgerPrintedPaise(line.cost);
    const validQuantity = /^\d+(\.\d{1,3})?$/u;
    if (!line.name?.trim() || !line.pack?.trim() || !validQuantity.test(quantity) ||
        !/[1-9]/u.test(quantity) && !(validQuantity.test(free) && /[1-9]/u.test(free)) ||
        cost === null || cost < 0) ledgerError();
  }
  for (const key of ['invoiceTotal', 'totalTax', 'amountPayable', 'paidAmount', 'taxableValue', 'supplyValue',
    'cgst', 'sgstAmount', 'utgst', 'igst', 'cess', 'billDiscount', 'freight', 'otherCharges', 'roundOff', 'exemptValue']) {
    if (details[key]?.trim() && ledgerPrintedPaise(details[key]) === null) ledgerError();
  }
  const components = details.taxTreatment === 'CGST + SGST' ? ['cgst', 'sgstAmount', 'cess']
    : details.taxTreatment === 'CGST + UTGST' ? ['cgst', 'utgst', 'cess'] : details.taxTreatment === 'IGST' ? ['igst', 'cess'] : [];
  const tax = ledgerPrintedPaise(details.totalTax);
  if (tax !== null && components.length && components.every(key => ledgerPrintedPaise(details[key]) !== null) &&
      components.reduce((sum, key) => sum + ledgerPrintedPaise(details[key])!, 0) !== tax) ledgerError();
  if (Object.hasOwn(v, 'openingReview')) {
    const review = ledgerExact(v.openingReview, ['openingId', 'openingRevision', 'treatment']);
    ledgerText(review.openingId, 240); purchaseEntryRevision(review.openingRevision);
    if (review.treatment !== v.openingTreatment) ledgerError();
  }
  return ledgerClone(v) as unknown as LedgerSupplierBillAcceptance;
}
interface CreditReceiptLine {
  sourceLineId: string; productId: string; productLabel: string; purchaseUnit: string; stockUnit: string;
  unitsPerPack: number; deliveredMilli: number; acceptedMilli: number; damagedMilli: number; shortMilli: number;
  expectedMilli: number | null; priorStockUnits: Record<string, number>;
}
interface CreditReceipt {
  id: string; expectedDeliveryId: string; reference: string; deliveredOn: string; recordedAt: string;
  recordedUtcOffsetMinutes?: number; lines: CreditReceiptLine[]; restockOriginal?: Record<string, unknown>;
}
interface CreditGoodsLink {
  operationId: string; receiptId: string; receiptLineId: string; billId: string; copyId: string; copyRevision: number;
  billLineIndex: number; productId: string; billUnit: string; stockUnit: string; stockUnitsNumerator: number;
  stockUnitsDenominator: number; billQuantityMilli: number; freeBillQuantityMilli?: number;
  acceptedReceiptMilli: number; damagedReceiptMilli: number; conversionReviewed: true; linkedAt: string;
}
interface CreditGoodsReturn {
  operationId: string; accountScope: string; workspaceId: string; supplierId: string; receiptId: string;
  reference: string; reason: string; returnedOn: string; recordedAt: string; committedRevision: number;
  requestedAt?: string; lines: Array<Omit<CreditReceiptLine, 'sourceLineId' | 'deliveredMilli' | 'shortMilli' |
    'expectedMilli' | 'priorStockUnits'> & {receiptLineId: string}>;
}
interface CreditShortageClaim {
  operationId: string; accountScope: string; workspaceId: string; supplierId: string; billId: string;
  copyId: string; copyRevision: number; billLineIndex: number; expectedDeliveryId: string; receiptLineId: string;
  productId: string; purchaseUnit: string; quantityMilli: number; outstandingMilli: number; priorClaimedMilli: number;
  recordedAt: string; committedRevision: number; receiptIds: string[]; priorClaimIds: string[]; billAllocationIds: string[];
  requestedAt?: string; openingId?: string; openingRevision?: number;
}
/** Existing native receiving/bill attribution invariants only. This reader
 * creates no receipt, allocation, Stock movement or financial authority. */
export function ledgerSupplierCreditGoodsSource(ledger: Record<string, unknown>, scope: LedgerScope,
  supplierId: string, bills: ReadonlyMap<string, LedgerSupplierBillAcceptance>) {
  try {
    if (ledger.accountScope !== scope.account || ledger.workspaceId !== scope.store || ledger.supplierId !== supplierId ||
        ledger.historyComplete !== true || checkedLedgerOpening(ledger.openingRecord, scope).supplierId !== supplierId) ledgerError();
    const asOf = ledgerMicros(ledger.asOf), receipts = new Map<string, CreditReceipt>(), links = new Map<string, CreditGoodsLink>();
    const map = (raw: unknown, maximum: number): Record<string, unknown> => {
      if (!raw || typeof raw !== 'object' || Array.isArray(raw) || Object.keys(raw).length > maximum) ledgerError();
      return raw as Record<string, unknown>;
    };
    const count = (value: unknown, maximum = 2147483647, positive = false): number => {
      if (!Number.isSafeInteger(value) || Number(value) < (positive ? 1 : 0) || Number(value) > maximum) ledgerError();
      return value as number;
    };
    const quantity = (raw: unknown): bigint => {
      if (typeof raw !== 'string' || !/^\d+(\.\d{1,3})?$/u.test(raw)) ledgerError();
      const [whole, fraction = ''] = raw.split('.');
      const value = BigInt(whole!) * 1000n + BigInt(fraction.padEnd(3, '0') || '0');
      if (value > 2147483647n) ledgerError(); return value;
    };
    const mappings = new Map<string, {identity: string; delivered: number}>(), originals = new Map<string, string>();
    let legacyCalendar = false;
    for (const [id, raw] of Object.entries(map(ledger.goodsReceipts ?? {}, 1000))) {
      const candidate = map(raw, 8), row = ledgerExact(raw, ['id', 'expectedDeliveryId', 'reference', 'deliveredOn', 'recordedAt', 'lines',
        ...(Object.hasOwn(candidate, 'recordedUtcOffsetMinutes') ? ['recordedUtcOffsetMinutes'] : []),
        ...(Object.hasOwn(candidate, 'restockOriginal') ? ['restockOriginal'] : [])]);
      for (const key of ['id', 'expectedDeliveryId', 'reference']) ledgerText(row[key], 240);
      if (row.id !== id || ledgerMicros(row.recordedAt) > asOf || !Array.isArray(row.lines) || row.lines.length === 0) ledgerError();
      const day = ledgerDay(row.deliveredOn), offset = row.recordedUtcOffsetMinutes;
      if (offset !== undefined) {
        if (!Number.isInteger(offset) || Number(offset) < -720 || Number(offset) > 840) ledgerError();
        const local = new Date(Number(ledgerMicros(row.recordedAt) / 1000n) + Number(offset) * 60000).toISOString().slice(0, 10);
        if (day > local) ledgerError();
      } else legacyCalendar = true; // Retain, but do not invent its original calendar basis.
      const lines = new Set<string>();
      for (const rawLine of row.lines) {
        const candidateLine = map(rawLine, 14), line = ledgerExact(rawLine, ['sourceLineId', 'productId', 'productLabel', 'purchaseUnit',
          'stockUnit', 'unitsPerPack', 'deliveredMilli', 'acceptedMilli', 'damagedMilli', 'shortMilli', 'expectedMilli', 'priorStockUnits',
          ...(Object.hasOwn(candidateLine, 'lotDetails') ? ['lotDetails'] : [])]);
        for (const key of ['sourceLineId', 'productId', 'productLabel', 'purchaseUnit', 'stockUnit']) ledgerText(line[key], 240);
        if (lines.has(String(line.sourceLineId))) ledgerError(); lines.add(String(line.sourceLineId));
        const units = count(line.unitsPerPack, 1000000, true), delivered = count(line.deliveredMilli, 2147483647, true),
          accepted = count(line.acceptedMilli), damaged = count(line.damagedMilli), short = count(line.shortMilli);
        if (delivered !== accepted + damaged || accepted * units % 1000 !== 0 || accepted * units / 1000 > 2147483647) ledgerError();
        if (line.expectedMilli !== null && delivered + short > count(line.expectedMilli, 2147483647, true)) ledgerError();
        let prior = 0;
        for (const [key, amount] of Object.entries(map(line.priorStockUnits, 200))) {ledgerText(key, 512); prior += count(amount, 2147483647, true);}
        if (prior > accepted * units / 1000) ledgerError();
        if (Object.hasOwn(line, 'lotDetails')) {
          const lot = ledgerExact(line.lotDetails, ['schemaVersion', 'batch', 'manufacturedLabel', 'expiryLabel', 'mrpMinor']);
          if (lot.schemaVersion !== 1) ledgerError();
          for (const key of ['batch', 'manufacturedLabel', 'expiryLabel']) {
            const text = ledgerText(lot[key], 240, true); if (text !== text.trim() || /[\x00-\x1f\x7f]/u.test(text)) ledgerError();
          }
          if (lot.mrpMinor !== null) ledgerAmount(lot.mrpMinor);
          if (lot.batch === '' && lot.manufacturedLabel === '' && lot.expiryLabel === '' && lot.mrpMinor === null) ledgerError();
        }
        const group = ledgerCanonical([row.expectedDeliveryId, line.sourceLineId]), previous = mappings.get(group),
          identity = ledgerCanonical([line.productId, line.productLabel, line.purchaseUnit, line.stockUnit, units, line.expectedMilli]);
        const total = (previous?.delivered ?? 0) + delivered;
        if (previous && previous.identity !== identity || total > 2147483647 || line.expectedMilli !== null && total > Number(line.expectedMilli)) ledgerError();
        mappings.set(group, {identity, delivered: total});
      }
      const original = row.restockOriginal;
      if (original !== undefined) {
        const source = ledgerExact(original, ['schemaVersion', 'realm', 'accountScope', 'buyingStoreId', 'reference', 'lines']);
        const validId = (value: unknown) => typeof value === 'string' && /^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$/u.test(value);
        const reference = ledgerExact(source.reference, ['purchaseId', 'storeId', 'orderId', 'originalFingerprint', 'sourceRevision']);
        if (source.schemaVersion !== 1 || source.realm !== scope.realm || source.accountScope !== scope.account || source.buyingStoreId !== scope.store ||
            !validId(source.accountScope) || !validId(source.buyingStoreId) ||
            ['purchaseId', 'storeId', 'orderId', 'sourceRevision'].some(key => !validId(reference[key])) ||
            typeof reference.originalFingerprint !== 'string' || !/^[a-f0-9]{64}$/u.test(reference.originalFingerprint) ||
            !Array.isArray(source.lines) || source.lines.length === 0 || source.lines.length > 100) ledgerError();
        const sourceLines = new Map<string, {quantity: number; unit: string}>();
        for (const rawSourceLine of source.lines) {
          const sourceLine = ledgerExact(rawSourceLine, ['lineId', 'quantityMilli', 'quantityUnit']);
          if (!validId(sourceLine.lineId) || sourceLines.has(String(sourceLine.lineId))) ledgerError();
          sourceLines.set(String(sourceLine.lineId), {quantity: count(sourceLine.quantityMilli, 2147483647, true), unit: ledgerText(sourceLine.quantityUnit, 240)});
        }
        if (row.expectedDeliveryId !== 'restock-' + ledgerHash([source.realm, source.buyingStoreId, reference.purchaseId, reference.storeId, reference.orderId]) ||
            (row.lines as CreditReceiptLine[]).some(line => sourceLines.get(line.sourceLineId)?.quantity !== line.expectedMilli ||
              sourceLines.get(line.sourceLineId)?.unit !== line.purchaseUnit)) ledgerError();
      }
      const originalIdentity = ledgerCanonical(original ?? null), priorOriginal = originals.get(String(row.expectedDeliveryId));
      if (priorOriginal !== undefined && priorOriginal !== originalIdentity) ledgerError();
      originals.set(String(row.expectedDeliveryId), originalIdentity); receipts.set(id, ledgerClone(row) as unknown as CreditReceipt);
    }
    const receiptTotals = new Map<string, {accepted: number; damaged: number}>(), billTotals = new Map<string, {paid: bigint; free: bigint; binding: string}>();
    for (const [id, raw] of Object.entries(map(ledger.billGoodsAllocations ?? {}, 10000))) {
      const candidate = map(raw, 18), row = ledgerExact(raw, ['operationId', 'receiptId', 'receiptLineId', 'billId', 'copyId', 'copyRevision',
        'billLineIndex', 'productId', 'billUnit', 'stockUnit', 'stockUnitsNumerator', 'stockUnitsDenominator', 'billQuantityMilli',
        'acceptedReceiptMilli', 'damagedReceiptMilli', 'conversionReviewed', 'linkedAt', ...(Object.hasOwn(candidate, 'freeBillQuantityMilli') ? ['freeBillQuantityMilli'] : [])]);
      for (const key of ['operationId', 'receiptId', 'receiptLineId', 'billId', 'copyId', 'productId', 'billUnit', 'stockUnit']) ledgerText(row[key], 512);
      const receipt = receipts.get(String(row.receiptId)), bill = bills.get(String(row.billId));
      const index = count(row.billLineIndex, Number.MAX_SAFE_INTEGER), line = receipt?.lines.find(line => line.sourceLineId === row.receiptLineId);
      if (row.operationId !== id || !receipt || !line || !bill || bill.copy.supplier.id !== supplierId || row.copyId !== bill.copy.id ||
          row.copyRevision !== bill.copy.revision || index >= bill.copy.draft.goods.length || row.conversionReviewed !== true ||
          ledgerMicros(row.linkedAt) > asOf || ledgerMicros(row.linkedAt) < ledgerMicros(receipt.recordedAt) || ledgerMicros(row.linkedAt) < ledgerMicros(bill.acceptedAt)) ledgerError();
      const numerator = count(row.stockUnitsNumerator, 1000000, true), denominator = count(row.stockUnitsDenominator, 1000000, true);
      let x = numerator, y = denominator; while (y !== 0) {[x, y] = [y, x % y];} if (x !== 1) ledgerError();
      const paid = count(row.billQuantityMilli), free = count(row.freeBillQuantityMilli ?? 0), accepted = count(row.acceptedReceiptMilli), damaged = count(row.damagedReceiptMilli);
      if (paid + free <= 0 || paid + free > 2147483647 || accepted + damaged <= 0 || accepted + damaged > 2147483647) ledgerError();
      const printed = bill.copy.draft.goods[index]!;
      if (printed.productId !== row.productId || line.productId !== row.productId || printed.pack?.trim() !== row.billUnit || line.stockUnit !== row.stockUnit ||
          row.billUnit === row.stockUnit && (numerator !== 1 || denominator !== 1) ||
          row.billUnit === line.purchaseUnit && (numerator !== line.unitsPerPack || denominator !== 1) ||
          BigInt(paid + free) * BigInt(numerator) !== BigInt(accepted + damaged) * BigInt(line.unitsPerPack) * BigInt(denominator)) ledgerError();
      const invoiced = quantity(printed.quantity ?? ''), freePrinted = quantity((printed.freeQuantity ?? '').trim() || '0');
      if (invoiced + freePrinted <= 0n) ledgerError();
      const receiptKey = ledgerCanonical([receipt.id, line.sourceLineId]), previousReceipt = receiptTotals.get(receiptKey) ?? {accepted: 0, damaged: 0};
      previousReceipt.accepted += accepted; previousReceipt.damaged += damaged;
      if (previousReceipt.accepted > line.acceptedMilli || previousReceipt.damaged > line.damagedMilli) ledgerError();
      receiptTotals.set(receiptKey, previousReceipt);
      const billKey = ledgerCanonical([row.billId, index]), binding = ledgerCanonical([row.copyId, row.copyRevision, row.productId, row.billUnit, row.stockUnit, numerator, denominator]);
      const previousBill = billTotals.get(billKey) ?? {paid: 0n, free: 0n, binding};
      previousBill.paid += BigInt(paid); previousBill.free += BigInt(free);
      if (previousBill.binding !== binding || previousBill.paid > invoiced || previousBill.free > freePrinted) ledgerError();
      billTotals.set(billKey, previousBill); links.set(id, ledgerClone(row) as unknown as CreditGoodsLink);
    }
    const returns = new Map<string, CreditGoodsReturn>(), returnRevisions = new Set<number>();
    const returnedQuantities = new Map<string, {accepted: number; damaged: number}>();
    for (const [id, raw] of Object.entries(map(ledger.goodsReturns ?? {}, 10000))) {
      const candidate = map(raw, 12), row = ledgerExact(raw, ['operationId', 'accountScope', 'workspaceId', 'supplierId',
        'receiptId', 'reference', 'reason', 'returnedOn', 'recordedAt', 'committedRevision', 'lines',
        ...(Object.hasOwn(candidate, 'requestedAt') ? ['requestedAt'] : [])]);
      for (const key of ['operationId', 'accountScope', 'workspaceId', 'supplierId', 'receiptId', 'reference']) ledgerText(row[key], 240);
      ledgerText(row.reason, 500);
      const receipt = receipts.get(String(row.receiptId)), revision = count(row.committedRevision);
      const recordedAt = ledgerMicros(row.recordedAt), returnedOn = ledgerDay(row.returnedOn);
      if (row.operationId !== id || row.accountScope !== scope.account || row.workspaceId !== scope.store ||
          row.supplierId !== supplierId || !receipt || revision <= 1 || revision > count(ledger.revision) ||
          returnRevisions.has(revision) || recordedAt > asOf || recordedAt < ledgerMicros(receipt.recordedAt) ||
          returnedOn < ledgerDay(receipt.deliveredOn) ||
          (row.requestedAt !== undefined && ledgerMicros(row.requestedAt) > recordedAt) ||
          !Array.isArray(row.lines) || row.lines.length === 0) ledgerError();
      // Native historical returns did not retain their local calendar offset.
      // Preserve that qualification boundary; never invent an original timezone.
      legacyCalendar = true;
      const seen = new Set<string>();
      for (const rawLine of row.lines) {
        const line = ledgerExact(rawLine, ['receiptLineId', 'productId', 'productLabel', 'purchaseUnit', 'stockUnit',
          'unitsPerPack', 'acceptedMilli', 'damagedMilli']);
        for (const key of ['receiptLineId', 'productId', 'productLabel', 'purchaseUnit', 'stockUnit']) ledgerText(line[key], 240);
        const source = receipt.lines.find(value => value.sourceLineId === line.receiptLineId);
        const accepted = count(line.acceptedMilli), damaged = count(line.damagedMilli), units = count(line.unitsPerPack, 1000000, true);
        if (!source || seen.has(String(line.receiptLineId)) || accepted + damaged <= 0 ||
            line.productId !== source.productId || line.productLabel !== source.productLabel ||
            line.purchaseUnit !== source.purchaseUnit || line.stockUnit !== source.stockUnit || units !== source.unitsPerPack ||
            accepted * units % 1000 !== 0 || accepted * units / 1000 > 2147483647) ledgerError();
        seen.add(String(line.receiptLineId));
        const key = ledgerCanonical([receipt.id, line.receiptLineId]), used = returnedQuantities.get(key) ?? {accepted: 0, damaged: 0};
        used.accepted += accepted; used.damaged += damaged;
        if (used.accepted > source.acceptedMilli || used.damaged > source.damagedMilli) ledgerError();
        returnedQuantities.set(key, used);
      }
      returnRevisions.add(revision); returns.set(id, ledgerClone(row) as unknown as CreditGoodsReturn);
    }
    const claims = new Map<string, CreditShortageClaim>(), claimRevisions = new Set<number>();
    const orderedClaims = Object.entries(map(ledger.shortageClaims ?? {}, 10000))
      .sort((a, b) => Number((a[1] as Record<string, unknown>)?.committedRevision) - Number((b[1] as Record<string, unknown>)?.committedRevision));
    const sameIds = (actual: unknown, expected: string[], maximum: number, nonempty = false): string[] => {
      if (!Array.isArray(actual) || actual.length > maximum || nonempty && actual.length === 0 ||
          actual.some(id => typeof id !== 'string' || id.length > 512 || !id.trim() || id !== id.trim()) ||
          new Set(actual).size !== actual.length || ledgerCanonical(actual) !== ledgerCanonical([...new Set(expected)].sort())) ledgerError();
      return actual as string[];
    };
    for (const [id, raw] of orderedClaims) {
      const candidate = map(raw, 23), reviewed = Object.hasOwn(candidate, 'requestedAt');
      const row = ledgerExact(raw, ['operationId', 'accountScope', 'workspaceId', 'supplierId', 'billId', 'copyId', 'copyRevision',
        'billLineIndex', 'expectedDeliveryId', 'receiptLineId', 'productId', 'purchaseUnit', 'quantityMilli', 'outstandingMilli',
        'priorClaimedMilli', 'recordedAt', 'committedRevision', 'receiptIds', 'priorClaimIds', 'billAllocationIds',
        ...(reviewed ? ['requestedAt', 'openingId', 'openingRevision'] : [])]);
      for (const key of ['operationId', 'accountScope', 'workspaceId', 'supplierId', 'billId', 'copyId',
        'expectedDeliveryId', 'receiptLineId', 'productId', 'purchaseUnit']) {
        ledgerText(row[key], 512); if (row[key] !== String(row[key]).trim()) ledgerError();
      }
      const bill = bills.get(String(row.billId)), revision = count(row.committedRevision), index = count(row.billLineIndex);
      const at = ledgerMicros(row.recordedAt), requestedAt = reviewed ? ledgerMicros(row.requestedAt) : undefined;
      const claimed = count(row.quantityMilli, 2147483647, true);
      if (row.operationId !== id || row.accountScope !== scope.account || row.workspaceId !== scope.store || row.supplierId !== supplierId ||
          !bill || bill.openingTreatment !== 'excluded' || row.copyId !== bill.copy.id || row.copyRevision !== bill.copy.revision ||
          revision <= 1 || revision > count(ledger.revision) || claimRevisions.has(revision) || returnRevisions.has(revision) ||
          at > asOf || at < ledgerMicros(bill.acceptedAt) || index >= bill.copy.draft.goods.length ||
          (requestedAt !== undefined && (requestedAt > at || requestedAt < ledgerMicros(bill.acceptedAt)))) ledgerError();
      if (reviewed) {
        const opening = checkedLedgerOpening(ledger.openingRecord, scope);
        if (row.openingId !== opening.id || row.openingRevision !== opening.revision) ledgerError();
      }
      if ((Array.isArray(ledger.entries) && ledger.entries.some(entry => (entry as Record<string, unknown>)?.operationId === id)) ||
          returns.has(id) || Object.hasOwn(map(ledger.billMoneyAllocations ?? {}, 10000), id) || links.has(id)) ledgerError();
      for (const name of ['creditNotes', 'billMoneyAllocations']) {
        if (Object.values(map(ledger[name] ?? {}, 10000)).some(value =>
          (value as Record<string, unknown>)?.committedRevision === revision)) ledgerError();
      }
      const group = [...receipts.values()].filter(receipt => receipt.expectedDeliveryId === row.expectedDeliveryId &&
        receipt.lines.some(line => line.sourceLineId === row.receiptLineId));
      if (!Array.isArray(row.receiptIds) || row.receiptIds.length === 0 || row.receiptIds.length > 1000 ||
          new Set(row.receiptIds).size !== row.receiptIds.length) ledgerError();
      const receiptIds = row.receiptIds;
      const selected = receiptIds.map(receiptId => group.find(receipt => receipt.id === receiptId));
      if (selected.some(receipt => !receipt || ledgerMicros(receipt.recordedAt) > at ||
          requestedAt !== undefined && ledgerMicros(receipt.recordedAt) > requestedAt) ||
          group.some(receipt => ledgerMicros(receipt.recordedAt) < at && !receiptIds.includes(receipt.id))) ledgerError();
      sameIds(row.receiptIds, selected.map(receipt => receipt!.id), 1000, true);
      const lines = selected.map(receipt => receipt!.lines.find(line => line.sourceLineId === row.receiptLineId)!);
      const source = lines[0]!, printed = bill.copy.draft.goods[index]!;
      if (source.expectedMilli === null || printed.productId !== source.productId || printed.pack?.trim() !== source.purchaseUnit ||
          row.productId !== source.productId || row.purchaseUnit !== source.purchaseUnit) ledgerError();
      const outstanding = source.expectedMilli - lines.reduce((sum, line) => sum + line.deliveredMilli, 0);
      const previous = [...claims.values()], priorGroup = previous.filter(claim => claim.expectedDeliveryId === row.expectedDeliveryId &&
        claim.receiptLineId === row.receiptLineId), priorBill = previous.filter(claim => claim.billId === row.billId && claim.billLineIndex === index);
      const priorTotal = priorGroup.reduce((sum, claim) => sum + claim.quantityMilli, 0);
      const relevant = reviewed ? [...priorGroup, ...priorBill] : priorGroup;
      if (requestedAt !== undefined && relevant.some(claim => ledgerMicros(claim.recordedAt) > requestedAt)) ledgerError();
      sameIds(row.priorClaimIds, relevant.map(claim => claim.operationId), 10000);
      const allocations = [...links.values()].filter(link => link.billId === row.billId && link.billLineIndex === index);
      if (!Array.isArray(row.billAllocationIds) || row.billAllocationIds.length > 10000 ||
          new Set(row.billAllocationIds).size !== row.billAllocationIds.length) ledgerError();
      const allocationIds = row.billAllocationIds;
      const allocated = allocationIds.map(linkId => allocations.find(link => link.operationId === linkId));
      if (allocated.some(link => !link || ledgerMicros(link.linkedAt) > at ||
          requestedAt !== undefined && ledgerMicros(link.linkedAt) > requestedAt) ||
          allocations.some(link => ledgerMicros(link.linkedAt) < at && !allocationIds.includes(link.operationId))) ledgerError();
      sameIds(row.billAllocationIds, allocated.map(link => link!.operationId), 10000);
      const billQuantity = quantity(printed.quantity ?? '') + quantity((printed.freeQuantity ?? '').trim() || '0');
      const attributed = allocated.reduce((sum, link) => sum + BigInt(link!.billQuantityMilli) + BigInt(link!.freeBillQuantityMilli ?? 0), 0n);
      if (row.outstandingMilli !== outstanding || row.priorClaimedMilli !== priorTotal ||
          claimed + priorTotal > outstanding || BigInt(claimed) + BigInt(priorBill.reduce((sum, claim) => sum + claim.quantityMilli, 0)) +
          attributed > billQuantity) ledgerError();
      claims.set(id, ledgerClone(row) as unknown as CreditShortageClaim); claimRevisions.add(revision);
    }
    return {receipts, links, returns, claims, legacyCalendar};
  } catch {ledgerError('service_unavailable', 503);}
}
/** Reconcile typed original credit notes with their retained bill and physical
 * evidence. This is not a posting command or proof of GST filing/verification. */
export function ledgerSupplierCreditHistory(ledger: Record<string, unknown>, scope: LedgerScope,
  supplierId: string, bills: ReadonlyMap<string, LedgerSupplierBillAcceptance>) {
  try {
    const opening = checkedLedgerOpening(ledger.openingRecord, scope);
    const goods = ledgerSupplierCreditGoodsSource(ledger, scope, supplierId, bills);
    const raw = ledger.creditNotes ?? {};
    if (!raw || typeof raw !== 'object' || Array.isArray(raw) || Object.keys(raw).length > 10000 || !Array.isArray(ledger.entries)) ledgerError();
    const credits = new Map<string, LedgerSupplierCreditProof>(), amounts = new Map<string, number>();
    const quantities = new Map<string, number>(), billQuantities = new Map<string, number>(), references = new Set<string>();
    const entries = new Map<string, {value: unknown; index: number; count: number}>();
    ledger.entries.forEach((value, index) => {
      if (value && typeof value === 'object' && typeof (value as Record<string, unknown>).operationId === 'string') {
        const id = (value as Record<string, unknown>).operationId as string;
        entries.set(id, {value, index, count: (entries.get(id)?.count ?? 0) + 1});
      }
    });
    const notes = Object.entries(raw).map(([id, value]) => [id, checkedLedgerSupplierCreditProof(value, scope)] as const)
      .sort((a, b) => a[1].committedRevision - b[1].committedRevision);
    let lastRevision = 0, lastEntry = -1, lastAt: bigint | undefined;
    const consume = (map: Map<string, number>, key: string, quantity: number, capacity: number) => {
      const total = (map.get(key) ?? 0) + quantity;
      if (!Number.isSafeInteger(total) || total > capacity) ledgerError(); map.set(key, total);
    };
    for (const [id, note] of notes) {
      const bill = bills.get(note.billId), at = ledgerMicros(note.recordedAt);
      const entry = entries.get(id), printedDate = bill?.copy.draft.invoiceDate.trim() ?? '', dateParts = printedDate.split('/');
      const invoiceDay = dateParts.length === 3 ? `${dateParts[2]}-${dateParts[1]}-${dateParts[0]}` : printedDate;
      if (id !== note.operationId || note.supplierId !== supplierId || !bill || bill.openingTreatment !== 'excluded' ||
          note.copyId !== bill.copy.id || note.copyRevision !== bill.copy.revision ||
          note.openingId !== opening.id || note.openingRevision !== opening.revision ||
          note.committedRevision > Number(ledger.revision) || note.committedRevision <= lastRevision ||
          at > ledgerMicros(ledger.asOf) || at < ledgerMicros(bill.acceptedAt) ||
          lastAt !== undefined && at < lastAt || note.occurredOn < ledgerDay(invoiceDay) ||
          references.has(note.reference.toUpperCase()) || !entry || entry.count !== 1 || entry.index <= lastEntry ||
          ledgerCanonical(entry.value) !== ledgerCanonical(ledgerSupplierCreditEntry(note))) ledgerError();
      lastRevision = note.committedRevision; lastEntry = entry.index; lastAt = at;
      references.add(note.reference.toUpperCase());
      consume(amounts, note.billId, note.amountMinor, ledgerPrintedPaise(bill.copy.draft.details?.invoiceTotal)!);
      for (const support of note.supports) {
        const receipt = goods.receipts.get(support.receiptId), line = receipt?.lines.find(line => line.sourceLineId === support.receiptLineId);
        const printed = bill.copy.draft.goods[support.billLineIndex];
        if (!receipt || !line || !printed || at < ledgerMicros(receipt.recordedAt) ||
            note.occurredOn < receipt.deliveredOn || printed.productId !== line.productId) ledgerError();
        const sourceKey = ledgerCanonical(support.kind === 'shortage' ? [support.kind, support.shortageClaimId]
          : [support.kind, receipt.id, line.sourceLineId, support.returnOperationId ?? null]);
        if (support.kind === 'shortage') {
          const claim = goods.claims.get(support.shortageClaimId!);
          if (printed.pack?.trim() !== line.purchaseUnit || !claim || claim.billId !== note.billId ||
              claim.billLineIndex !== support.billLineIndex || claim.copyId !== note.copyId || claim.copyRevision !== note.copyRevision ||
              claim.receiptLineId !== support.receiptLineId || !claim.receiptIds.includes(receipt.id) ||
              claim.committedRevision >= note.committedRevision || ledgerMicros(claim.recordedAt) > at) ledgerError();
          consume(quantities, sourceKey, support.quantityMilli, claim.quantityMilli); continue;
        }
        const links = [...goods.links.values()].filter(link => link.receiptId === receipt.id &&
          link.receiptLineId === line.sourceLineId && link.billId === note.billId && link.billLineIndex === support.billLineIndex);
        if (!links.length || links.some(link => ledgerMicros(link.linkedAt) > at)) ledgerError();
        const attributed = links.reduce((sum, link) => sum + (support.kind === 'goodsReturned' ? link.acceptedReceiptMilli : link.damagedReceiptMilli), 0);
        consume(billQuantities, ledgerCanonical([note.billId, support.billLineIndex, receipt.id, line.sourceLineId, support.kind]),
          support.quantityMilli, attributed);
        let capacity = line.damagedMilli;
        if (support.kind === 'goodsReturned') {
          const returned = goods.returns.get(support.returnOperationId!), returnedLine = returned?.lines.find(value => value.receiptLineId === support.receiptLineId);
          if (!returned || returned.receiptId !== receipt.id || !returnedLine || returned.committedRevision >= note.committedRevision ||
              at < ledgerMicros(returned.recordedAt) || note.occurredOn < returned.returnedOn) ledgerError();
          capacity = returnedLine.acceptedMilli;
        }
        consume(quantities, sourceKey, support.quantityMilli, capacity);
      }
      credits.set(id, note);
    }
    return {credits, amounts, quantities, billQuantities, goods};
  } catch {ledgerError('service_unavailable', 503);}
}
/** Read-only counterpart of the existing native availableCreditSupports.
 * IDs identify printed-goods sources, never a new receipt or posting grant. */
export function ledgerSupplierAvailableCreditSupports(ledger: Record<string, unknown>, scope: LedgerScope,
  supplierId: string, billId: string, bills: ReadonlyMap<string, LedgerSupplierBillAcceptance>) {
  const history = ledgerSupplierCreditHistory(ledger, scope, supplierId, bills), bill = bills.get(billId);
  const result: Array<{id: string; support: LedgerSupplierCreditSupport; label: string; unit: string}> = [];
  if (!bill || bill.openingTreatment !== 'excluded') return result;
  const add = (support: LedgerSupplierCreditSupport, label: string, unit: string) => {
    if (support.quantityMilli <= 0) return;
    result.push({id: JSON.stringify([support.kind, support.receiptId, support.receiptLineId,
      support.billLineIndex, support.returnOperationId ?? null, support.shortageClaimId ?? null]), support, label, unit});
  };
  const links = [...history.goods.links.values()].filter(link => link.billId === billId);
  const groups = new Map<string, CreditGoodsLink[]>();
  for (const link of links) {
    const key = ledgerCanonical([link.receiptId, link.receiptLineId, link.billLineIndex]);
    groups.set(key, [...(groups.get(key) ?? []), link]);
  }
  for (const group of groups.values()) {
    const first = group[0]!, receipt = history.goods.receipts.get(first.receiptId)!;
    const line = receipt.lines.find(value => value.sourceLineId === first.receiptLineId)!;
    const damagedGlobal = line.damagedMilli - (history.quantities.get(ledgerCanonical(['arrivalDamage', receipt.id, line.sourceLineId, null])) ?? 0);
    const damagedBill = group.reduce((sum, link) => sum + link.damagedReceiptMilli, 0) -
      (history.billQuantities.get(ledgerCanonical([billId, first.billLineIndex, receipt.id, line.sourceLineId, 'arrivalDamage'])) ?? 0);
    add({kind: 'arrivalDamage', receiptId: receipt.id, receiptLineId: line.sourceLineId,
      billLineIndex: first.billLineIndex, quantityMilli: Math.min(damagedGlobal, damagedBill)},
      `${line.productLabel} · Damaged on arrival`, line.purchaseUnit);
    const returnedBill = group.reduce((sum, link) => sum + link.acceptedReceiptMilli, 0) -
      (history.billQuantities.get(ledgerCanonical([billId, first.billLineIndex, receipt.id, line.sourceLineId, 'goodsReturned'])) ?? 0);
    for (const returned of history.goods.returns.values()) {
      if (returned.receiptId !== receipt.id) continue;
      const returnedLine = returned.lines.find(value => value.receiptLineId === line.sourceLineId);
      if (!returnedLine) continue;
      const global = returnedLine.acceptedMilli - (history.quantities.get(
        ledgerCanonical(['goodsReturned', receipt.id, line.sourceLineId, returned.operationId])) ?? 0);
      add({kind: 'goodsReturned', receiptId: receipt.id, receiptLineId: line.sourceLineId,
        billLineIndex: first.billLineIndex, returnOperationId: returned.operationId,
        quantityMilli: Math.min(global, returnedBill)}, `${line.productLabel} · Returned · ${returned.reference}`, line.purchaseUnit);
    }
  }
  for (const claim of history.goods.claims.values()) {
    if (claim.billId !== billId) continue;
    const quantityMilli = claim.quantityMilli - (history.quantities.get(ledgerCanonical(['shortage', claim.operationId])) ?? 0);
    const receipt = history.goods.receipts.get(claim.receiptIds[0]!)!;
    const line = receipt.lines.find(value => value.sourceLineId === claim.receiptLineId)!;
    add({kind: 'shortage', receiptId: receipt.id, receiptLineId: line.sourceLineId,
      billLineIndex: claim.billLineIndex, shortageClaimId: claim.operationId, quantityMilli},
      `${line.productLabel} · Short delivery`, claim.purchaseUnit);
  }
  return result;
}
/** Existing native bill-surplus prefix rule. Call only with the independently
 * validated original history; this calculation creates no spendable balance. */
export function ledgerSupplierBillSurplusAt(ledger: Record<string, unknown>, billId: string, entryLimit: number,
  revisionLimit: number, at: string, bills: ReadonlyMap<string, LedgerSupplierBillAcceptance>,
  credits: ReadonlyMap<string, LedgerSupplierCreditProof>, refunds: ReadonlyMap<string, LedgerSupplierRefundProof>,
  allocations: ReadonlyMap<string, LedgerSupplierAllocationProof>): number | null {
  try {
    const bill = bills.get(billId), time = ledgerMicros(at);
    if (!bill || bill.openingTreatment !== 'excluded' || !Array.isArray(ledger.entries) ||
        !Number.isSafeInteger(entryLimit) || entryLimit < 0 || entryLimit > ledger.entries.length ||
        !Number.isSafeInteger(revisionLimit) || revisionLimit <= 1 || ledgerMicros(bill.acceptedAt) > time) return null;
    const prior = ledger.entries.slice(0, entryLimit) as Record<string, unknown>[], ids = new Set(prior.map(entry => entry.operationId));
    if (prior.some(entry => !entry || typeof entry !== 'object' || Array.isArray(entry) || ledgerMicros(entry.postedAt) > time) ||
        !prior.some(entry => entry.kind === 'bill' && entry.billId === billId) ||
        [...credits.values()].some(note => (note.committedRevision < revisionLimit) !== ids.has(note.operationId)) ||
        [...refunds.values()].some(refund => (refund.committedRevision < revisionLimit) !== ids.has(refund.intent.operationId)) ||
        [...allocations.values()].some(link => link.committedRevision < revisionLimit && ledgerMicros(link.recordedAt) > time)) return null;
    if (prior.some(entry => entry.billId === billId &&
      (entry.kind === 'creditNote' && (!credits.has(String(entry.operationId)) || credits.get(String(entry.operationId))!.committedRevision >= revisionLimit) ||
       entry.kind === 'refund' && (!refunds.has(String(entry.operationId)) || refunds.get(String(entry.operationId))!.committedRevision >= revisionLimit) ||
       entry.kind === 'payment' && entry.moneyReview == null))) return null;
    const sum = <T>(values: T[], amount: (value: T) => number) => values.reduce((total, value) => {
      const next = total + amount(value); if (!Number.isSafeInteger(next)) ledgerError(); return next;
    }, 0);
    const paid = sum(prior.filter(entry => entry.billId === billId && entry.origin === 'manualPurchase' && entry.kind === 'payment'),
      entry => ledgerAmount(entry.amountMinor));
    const links = [...allocations.values()].filter(link => link.committedRevision < revisionLimit);
    const incoming = sum(links.filter(link => link.billId === billId), link => link.amountMinor);
    const outgoing = sum(links.filter(link => link.sourceKind === 'manualBillSurplus' && link.sourceId === billId), link => link.amountMinor);
    const credited = sum([...credits.values()].filter(note => note.billId === billId && note.committedRevision < revisionLimit && ids.has(note.operationId)),
      note => note.amountMinor);
    const refunded = sum([...refunds.values()].filter(refund => refund.committedRevision < revisionLimit &&
      refund.intent.sourceKind === 'manualBillSurplus' && refund.intent.sourceId === billId && ids.has(refund.intent.operationId)),
      refund => refund.intent.amountMinor);
    const residual = ledgerPrintedPaise(bill.copy.draft.details?.invoiceTotal)! - paid - incoming - credited + outgoing + refunded;
    return Number.isSafeInteger(residual) ? Math.max(-residual, 0) : null;
  } catch {return null;}
}
/** Shared validation of original supplier financial history; never a write. */
export function ledgerSupplierFinancialHistory(ledger: Record<string, unknown>, scope: LedgerScope, supplierId: string) {
  const equal = (a: unknown, b: unknown) => ledgerCanonical(a) === ledgerCanonical(b);
  const opening = checkedLedgerOpening(ledger.openingRecord, scope);
  const rawCredits = ledger.creditNotes ?? {};
  if (!rawCredits || typeof rawCredits !== 'object' || Array.isArray(rawCredits) || Object.keys(rawCredits).length > 10000) ledgerError('service_unavailable', 503);
  const bills = ledger.purchaseBills ?? {};
  if (!bills || typeof bills !== 'object' || Array.isArray(bills)) ledgerError('service_unavailable', 503);
  const parsed = new Map<string, LedgerSupplierBillAcceptance>(), references = new Set<string>(), paid = new Map<string, number>(),
    entryById = new Map<string, Record<string, unknown>>();
  const refunds = new Map<string, LedgerSupplierRefundProof>(), refundReferences = new Set<string>(),
    refundRevisions = new Set<number>(), refunded = new Map<string, number>();
  const credits = new Map<string, LedgerSupplierCreditProof>(), credited = new Map<string, number>(), creditRevisions = new Set<number>();
  const rawRefunds = ledger.refunds ?? {};
  if (!rawRefunds || typeof rawRefunds !== 'object' || Array.isArray(rawRefunds) || Object.keys(rawRefunds).length > 10000) ledgerError('service_unavailable', 503);
  const rawLinks = ledger.billMoneyAllocations ?? {};
  if (!rawLinks || typeof rawLinks !== 'object' || Array.isArray(rawLinks) || Object.keys(rawLinks).length > 10000) ledgerError('service_unavailable', 503);
  let checkedLinks: [string, LedgerSupplierAllocationProof][];
  try {checkedLinks = Object.entries(rawLinks).map(([id, value]) => [id, checkedLedgerSupplierAllocationProof(value, scope)]);
  } catch {ledgerError('service_unavailable', 503);}
  const chronologicalLinks = [...checkedLinks].sort((a, b) => a[1].committedRevision - b[1].committedRevision),
    priorAllocationUse = new Map<string, number>();
  const typedAllocations = new Map(checkedLinks);
  const refundSurplusCapacity = (intent: Pick<LedgerSupplierRefundIntent, 'sourceId' | 'copyId' | 'copyRevision' | 'occurredOn'>,
    entryLimit: number, revisionLimit: number, at: string): number | null => {
    const bill = parsed.get(intent.sourceId);
    if (!bill || bill.copy.id !== intent.copyId || bill.copy.revision !== intent.copyRevision) return null;
    const date = bill.copy.draft.invoiceDate.trim().split('/');
    const invoiceDay = date.length === 3 ? `${date[2]}-${date[1]}-${date[0]}` : bill.copy.draft.invoiceDate;
    if (intent.occurredOn < invoiceDay) return null;
    const prior = (ledger.entries as Record<string, unknown>[]).slice(0, entryLimit);
    const ids = new Set(prior.map(entry => entry.operationId));
    const funding = [...typedAllocations.values()].filter(link => link.billId === intent.sourceId && link.committedRevision < revisionLimit);
    // Historical surplus-funded links retain no original local calendar offset.
    // Their refund-date comparison needs that original evidence, not server UTC.
    if (funding.some(link => link.sourceKind === 'manualBillSurplus' || link.sourceKind !== 'openingAdvance' && (() => {
      const source = prior.find(entry => entry.operationId === link.sourceId);
      return !source?.moneyReview || intent.occurredOn < (source.moneyReview as {occurredOn: string}).occurredOn;
    })()) || [...credits.values()].some(note => note.billId === intent.sourceId && note.committedRevision < revisionLimit &&
      ids.has(note.operationId) && intent.occurredOn < note.occurredOn) || prior.some(entry => entry.billId === intent.sourceId &&
        entry.kind === 'payment' && (!entry.moneyReview || intent.occurredOn < (entry.moneyReview as {occurredOn: string}).occurredOn))) return null;
    return ledgerSupplierBillSurplusAt(ledger, intent.sourceId, entryLimit, revisionLimit, at, parsed, credits, refunds, typedAllocations);
  };
  let priorLinkIndex = 0;
  try {
    for (const [id, raw] of Object.entries(rawRefunds)) {
      const proof = checkedLedgerSupplierRefundProof(raw, scope), intent = proof.intent;
      if (id !== intent.operationId || intent.supplierId !== supplierId || intent.qa !== opening.qa ||
          intent.openingId !== opening.id || intent.openingRevision !== opening.revision || intent.occurredOn < opening.asOfDate ||
          proof.committedRevision > Number(ledger.revision) || refundRevisions.has(proof.committedRevision) ||
          refundReferences.has(intent.reference.toUpperCase()) || ledgerMicros(proof.recordedAt) > ledgerMicros(ledger.asOf) ||
          ledgerMicros(proof.recordedAt) < ledgerMicros(opening.savedAt)) ledgerError('service_unavailable', 503);
      refunds.set(id, proof); refundRevisions.add(proof.committedRevision); refundReferences.add(intent.reference.toUpperCase());
    }
  } catch {ledgerError('service_unavailable', 503);}
  let balance = ledger.openingBalanceMinor as number;
  try {
    for (const [id, raw] of Object.entries(bills)) {
      const bill = checkedLedgerSupplierBillAcceptance(raw);
      const reference = `${purchaseEntryInvoiceFinancialYear(bill.copy.draft.invoiceDate)}:${bill.copy.draft.invoiceReference.trim().toUpperCase()}`;
      if (id !== bill.copy.draft.id || bill.copy.supplier.id !== supplierId ||
          !ledgerBillOpeningMatches(bill, opening) || ledgerMicros(bill.acceptedAt) > ledgerMicros(ledger.asOf) || references.has(reference)) ledgerError('service_unavailable', 503);
      references.add(reference); parsed.set(id, bill);
    }
    if (Object.keys(rawCredits).length) {
      const history = ledgerSupplierCreditHistory(ledger, scope, supplierId, parsed);
      for (const [id, note] of history.credits) {credits.set(id, note); creditRevisions.add(note.committedRevision);}
      for (const [id, amount] of history.amounts) credited.set(id, amount);
      if ([...refundRevisions].some(revision => creditRevisions.has(revision))) ledgerError('service_unavailable', 503);
    }
    const seen = new Set<string>(), seenBills = new Set<string>();
    let lastRefundRevision = 0, foundRefunds = 0, previousAt = ledgerMicros(opening.savedAt);
    for (const raw of ledger.entries as unknown[]) {
      if (!raw || typeof raw !== 'object' || Array.isArray(raw)) ledgerError('service_unavailable', 503);
      const entry = raw as Record<string, unknown>, id = entry.operationId;
      if (typeof id !== 'string' || seen.has(id) || ledgerMicros(entry.postedAt) > ledgerMicros(ledger.asOf)) ledgerError('service_unavailable', 503);
      const refund = refunds.get(id), credit = credits.get(id);
      if (credit) {
        balance -= credit.amountMinor;
      } else if (refund) {
        const intent = refund.intent, key = ledgerCanonical([intent.sourceKind, intent.sourceId]);
        const source = entryById.get(intent.sourceId);
        const capacity = intent.sourceKind === 'manualBillSurplus'
          ? refundSurplusCapacity(intent, seen.size, refund.committedRevision, refund.recordedAt)
          : intent.sourceKind === 'openingAdvance' ? opening.supplierCredit && intent.sourceId === opening.id ? opening.amountMinor! : null
          : intent.sourceKind === 'accountAdvance' && source?.origin === 'supplierAccount' && source.kind === 'advance' && source.moneyReview != null
            ? source.amountMinor as number : null;
        if (capacity === null || !equal(entry, ledgerSupplierRefundEntry(refund)) || balance >= 0 || intent.amountMinor > -balance ||
            refund.committedRevision <= lastRefundRevision || ledgerMicros(refund.recordedAt) < previousAt ||
            intent.sourceKind === 'accountAdvance' && intent.occurredOn < (source!.moneyReview as {occurredOn: string}).occurredOn) ledgerError('service_unavailable', 503);
        while (priorLinkIndex < chronologicalLinks.length && chronologicalLinks[priorLinkIndex]![1].committedRevision < refund.committedRevision) {
          const link = chronologicalLinks[priorLinkIndex++]![1];
          if (ledgerMicros(link.recordedAt) > ledgerMicros(refund.recordedAt)) ledgerError('service_unavailable', 503);
          const sourceKey = ledgerCanonical([link.sourceKind, link.sourceId]), used = (priorAllocationUse.get(sourceKey) ?? 0) + link.amountMinor;
          if (!Number.isSafeInteger(used)) ledgerError('service_unavailable', 503);
          priorAllocationUse.set(sourceKey, used);
        }
        const assigned = priorAllocationUse.get(key) ?? 0;
        const total = (refunded.get(key) ?? 0) + intent.amountMinor;
        if (!Number.isSafeInteger(total + assigned) || (intent.sourceKind === 'manualBillSurplus'
          ? intent.amountMinor > capacity : total + assigned > capacity)) ledgerError('service_unavailable', 503);
        refunded.set(key, total); lastRefundRevision = refund.committedRevision; foundRefunds++;
        balance += intent.amountMinor;
      } else if (entry.kind === 'bill') {
        const bill = parsed.get(String(entry.billId));
        if (!bill || !equal(entry, ledgerBillLiabilityEntry(bill))) ledgerError('service_unavailable', 503);
        seenBills.add(bill.copy.draft.id); balance += ledgerPrintedPaise(bill.copy.draft.details?.invoiceTotal)!;
      } else {
        const money = checkedLedgerSupplierMoneyEntry(entry);
        if (money.moneyReview.openingId !== opening.id || money.moneyReview.openingRevision !== opening.revision ||
            money.kind === 'payment' && money.amountMinor > Math.max(balance, 0)) ledgerError('service_unavailable', 503);
        if (money.origin === 'manualPurchase') {
          const bill = parsed.get(money.billId!);
          const amount = (paid.get(money.billId!) ?? 0) + money.amountMinor;
          if (!bill || bill.openingTreatment !== 'excluded' || bill.copy.id !== money.purchaseId ||
              ledgerMicros(money.postedAt) < ledgerMicros(bill.acceptedAt) || amount > ledgerPrintedPaise(bill.copy.draft.details?.invoiceTotal)!) ledgerError('service_unavailable', 503);
          paid.set(money.billId!, amount);
        }
        balance -= money.amountMinor;
      }
      seen.add(id); entryById.set(id, entry);
      if (ledgerMicros(entry.postedAt) > previousAt) previousAt = ledgerMicros(entry.postedAt);
      if (!Number.isSafeInteger(balance)) ledgerError('service_unavailable', 503);
    }
    if (foundRefunds !== refunds.size) ledgerError('service_unavailable', 503);
    for (const [id, bill] of parsed) if ((ledgerBillLiabilityEntry(bill) !== null) !== seenBills.has(id)) ledgerError('service_unavailable', 503);
  } catch {ledgerError('service_unavailable', 503);}
  const sourceKey = (kind: LedgerSupplierMoneySourceKind, id: string) => ledgerCanonical([kind, id]);
  const sourceAmount = (kind: LedgerSupplierMoneySourceKind, id: string): number | null => {
    if (kind === 'openingAdvance') return opening.supplierCredit && id === opening.id ? opening.amountMinor : null;
    if (kind === 'manualBillSurplus') return ledgerSupplierBillSurplusAt(ledger, id, (ledger.entries as unknown[]).length,
      Number(ledger.revision) + 1, String(ledger.asOf), parsed, credits, refunds, typedAllocations);
    const entry = entryById.get(id);
    return entry?.origin === 'supplierAccount' && entry.moneyReview != null &&
      entry.kind === (kind === 'accountAdvance' ? 'advance' : 'payment') ? entry.amountMinor as number : null;
  };
  const allocations = new Map<string, LedgerSupplierAllocationProof>(), used = new Map<string, number>(refunded),
    allocated = new Map<string, number>(), revisions = new Set<number>();
  try {
    for (const [id, link] of chronologicalLinks) {
      const surplus = link.sourceKind === 'manualBillSurplus', sourceBill = surplus ? parsed.get(link.sourceId) : undefined;
      const bill = parsed.get(link.billId), capacity = surplus && link.sourceEntryCount !== undefined
        ? ledgerSupplierBillSurplusAt(ledger, link.sourceId, link.sourceEntryCount, link.committedRevision, link.recordedAt,
          parsed, credits, refunds, typedAllocations)
        : sourceAmount(link.sourceKind, link.sourceId), source = sourceKey(link.sourceKind, link.sourceId);
      const sourceEntry = entryById.get(link.sourceId);
      if (id !== link.operationId || link.supplierId !== supplierId || link.openingId !== opening.id ||
          link.openingRevision !== opening.revision || revisions.has(link.committedRevision) || refundRevisions.has(link.committedRevision) || creditRevisions.has(link.committedRevision) ||
          link.committedRevision > Number(ledger.revision) || ledgerMicros(link.recordedAt) > ledgerMicros(ledger.asOf) ||
          ledgerMicros(link.recordedAt) < ledgerMicros(opening.savedAt) ||
          entryById.has(id) ||
          !bill || bill.openingTreatment !== 'excluded' || link.copyId !== bill.copy.id || link.copyRevision !== bill.copy.revision ||
          ledgerMicros(link.recordedAt) < ledgerMicros(bill.acceptedAt) || capacity === null ||
          link.sourceKind !== 'openingAdvance' && !surplus && (sourceEntry === undefined || ledgerMicros(sourceEntry.postedAt) > ledgerMicros(link.recordedAt)) ||
          surplus && (!sourceBill || sourceBill.copy.id !== link.sourceCopyId || sourceBill.copy.revision !== link.sourceCopyRevision ||
            !(ledger.entries as Record<string, unknown>[]).slice(0, link.sourceEntryCount!).some(entry => entry.kind === 'bill' && entry.billId === link.billId))) {
        ledgerError('service_unavailable', 503);
      }
      const sourceUsed = (used.get(source) ?? 0) + link.amountMinor,
        billUsed = (allocated.get(link.billId) ?? 0) + link.amountMinor;
      if (!Number.isSafeInteger(sourceUsed) || !Number.isSafeInteger(billUsed) || (surplus ? link.amountMinor > capacity : sourceUsed > capacity) ||
          billUsed + (paid.get(link.billId) ?? 0) > ledgerPrintedPaise(bill.copy.draft.details?.invoiceTotal)!) ledgerError('service_unavailable', 503);
      used.set(source, sourceUsed); allocated.set(link.billId, billUsed);
      allocations.set(id, link); revisions.add(link.committedRevision);
    }
  } catch {ledgerError('service_unavailable', 503);}
  const sourceAvailable = (kind: LedgerSupplierMoneySourceKind, id: string): number | null => {
    const total = sourceAmount(kind, id);
    return total === null ? null : kind === 'manualBillSurplus' ? total : total - (used.get(sourceKey(kind, id)) ?? 0);
  };
  const billRemaining = (id: string): number | null => {
    const bill = parsed.get(id); if (!bill || bill.openingTreatment !== 'excluded') return null;
    const returned = [...refunds.values()].filter(refund => refund.intent.sourceKind === 'manualBillSurplus' && refund.intent.sourceId === id)
      .reduce((sum, refund) => sum + refund.intent.amountMinor, 0);
    const transferred = [...allocations.values()].filter(link => link.sourceKind === 'manualBillSurplus' && link.sourceId === id)
      .reduce((sum, link) => sum + link.amountMinor, 0);
    const remaining = ledgerPrintedPaise(bill.copy.draft.details?.invoiceTotal)! - (paid.get(id) ?? 0) -
      (allocated.get(id) ?? 0) - (credited.get(id) ?? 0) + returned + transferred;
    return Number.isSafeInteger(remaining) ? remaining : null;
  };
  return {opening, bills, parsed, balance, paid, allocations, allocated, used, sourceKey, sourceAmount, sourceAvailable,
    billRemaining, entryById, credits, credited, refunds, refunded, refundSurplusCapacity};
}

export function ledgerBillLiabilityEntry(bill: LedgerSupplierBillAcceptance): Record<string, unknown> | null {
  const amount = ledgerPrintedPaise(bill.copy.draft.details?.invoiceTotal)!;
  return bill.openingTreatment !== 'excluded' || amount === 0 ? null : {
    operationId: 'manual-bill:' + bill.copy.draft.id, orderId: null, origin: 'manualPurchase', purchaseId: bill.copy.id,
    reference: bill.copy.draft.invoiceReference, billId: bill.copy.draft.id, kind: 'bill', amountMinor: amount, postedAt: bill.acceptedAt};
}
export function ledgerBillOpeningMatches(bill: LedgerSupplierBillAcceptance, opening: LedgerOpeningRecord,
  confirmedUtcOffsetMinutes?: number): boolean {
  const text = bill.copy.draft.invoiceDate.trim(), parts = text.split('/');
  const day = parts.length === 3 ? `${parts[2]}-${parts[1]}-${parts[0]}` : text;
  const links = opening.bills.filter(link => link.draftId === bill.copy.draft.id);
  const exact = links.length === 1 && links[0]!.copyId === bill.copy.id && links[0]!.copyRevision === bill.copy.revision &&
    links[0]!.inclusion === bill.openingTreatment;
  const review = bill.openingReview, explicit = review?.openingId === opening.id &&
    review.openingRevision === opening.revision && review.treatment === bill.openingTreatment;
  if (review && !explicit || links.length && !exact || day <= opening.asOfDate && !exact && !explicit ||
      day > opening.asOfDate && bill.openingTreatment !== 'excluded') return false;
  if (confirmedUtcOffsetMinutes !== undefined) {
    const local = new Date(Number(ledgerMicros(bill.acceptedAt) / 1000n) + confirmedUtcOffsetMinutes * 60000);
    if (day > local.toISOString().slice(0, 10)) return false;
  }
  return true;
}
export function ledgerDay(value: unknown): string {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) ledgerError();
  const instant = new Date(value + 'T00:00:00.000Z');
  if (!Number.isFinite(instant.getTime()) || instant.toISOString().slice(0, 10) !== value) ledgerError();
  return value;
}
export function checkedLedgerExpense(raw: unknown, scope: LedgerScope): LedgerExpense {
  const v = ledgerExact(raw, ['account', 'store', 'operationId', 'amountMinor', 'category', 'method', 'reference', 'note', 'occurredAt']);
  for (const key of ['account', 'store', 'operationId', 'category', 'method', 'reference']) ledgerText(v[key], 512);
  ledgerText(v.note, 2000, true); ledgerTime(v.occurredAt);
  if (v.account !== scope.account || v.store !== scope.store || ledgerAmount(v.amountMinor) <= 0) ledgerError();
  return ledgerClone(v) as unknown as LedgerExpense;
}
/** Closed counterpart of WorkspaceSupplierMoneyAttempt's entry, preserving
 * printed inputs and opening evidence for the original receiver to verify. */
export function checkedLedgerSupplierMoneyEntry(raw: unknown): LedgerSupplierMoneyEntry {
  const candidate = raw as Record<string, unknown> | null;
  const value = ledgerExact(raw, ['operationId', 'orderId', 'reference', 'billId', 'origin',
    'paymentMethod', 'kind', 'amountMinor', 'postedAt', 'moneyReview',
    ...(candidate?.origin === 'manualPurchase' ? ['purchaseId'] : [])]);
  ledgerText(value.operationId); ledgerText(value.reference); ledgerTime(value.postedAt);
  if (value.orderId !== null || !['supplierAccount', 'manualPurchase'].includes(value.origin as string) ||
      !['payment', 'advance'].includes(value.kind as string) || ledgerAmount(value.amountMinor) <= 0 ||
      !(ledgerSupplierMoneyMethods as readonly string[]).includes(ledgerText(value.paymentMethod))) ledgerError();
  if (value.origin === 'supplierAccount') {
    if (value.billId !== null) ledgerError();
  } else {
    if (value.kind !== 'payment') ledgerError();
    ledgerText(value.purchaseId); ledgerText(value.billId);
  }
  const review = ledgerExact(value.moneyReview, ['occurredOn', 'openingId', 'openingRevision', 'notIncludedInOpening']);
  ledgerDay(review.occurredOn); ledgerText(review.openingId, 240); purchaseEntryRevision(review.openingRevision);
  if (review.notIncludedInOpening !== true) ledgerError();
  return ledgerClone(value) as unknown as LedgerSupplierMoneyEntry;
}
export function checkedLedgerOpening(raw: unknown, scope: LedgerScope): LedgerOpeningRecord {
  try {return checkedPurchaseEntryOpening(raw, scope);} catch (error) {
    if (error instanceof WorkspaceProfileError) ledgerError(error.code, error.httpStatus);
    throw error;
  }
}
export function checkedLedgerRegisterEntry(raw: unknown): LedgerRegisterEntry {
  const v = ledgerExact(raw, ['id', 'reference', 'occurredAt', 'deltaMinor']);
  ledgerText(v.id); ledgerText(v.reference); ledgerTime(v.occurredAt);
  if (ledgerAmount(v.deltaMinor, true) === 0) ledgerError();
  return ledgerClone(v) as unknown as LedgerRegisterEntry;
}
export function checkedLedgerRegisterHeader(raw: unknown, scope: LedgerScope): LedgerRegisterHeader {
  const v = ledgerExact(raw, ['accountScope', 'workspaceId', 'registerId', 'label', 'revision', 'openingAt', 'asOf',
    'openingMinor', 'historyComplete', 'entryCount', 'lastEntryAt', 'sequenceValidationMinor']);
  for (const key of ['accountScope', 'workspaceId', 'registerId', 'label']) ledgerText(v[key]);
  purchaseEntryRevision(v.revision); ledgerTime(v.openingAt); ledgerTime(v.asOf); ledgerCount(v.entryCount);
  ledgerAmount(v.sequenceValidationMinor, true);
  if (v.accountScope !== scope.account || v.workspaceId !== scope.store || typeof v.historyComplete !== 'boolean' ||
      v.openingMinor === null && v.historyComplete || v.openingMinor !== null &&
      !Number.isSafeInteger(v.openingMinor) || ledgerMicros(v.openingAt) > ledgerMicros(v.asOf)) ledgerError();
  if (v.entryCount === 0) {if (v.lastEntryAt !== null || v.sequenceValidationMinor !== (v.openingMinor ?? 0)) ledgerError();}
  else {
    ledgerTime(v.lastEntryAt);
    if (ledgerMicros(v.lastEntryAt) < ledgerMicros(v.openingAt) || ledgerMicros(v.lastEntryAt) >= ledgerMicros(v.asOf)) ledgerError();
  }
  return ledgerClone(v) as unknown as LedgerRegisterHeader;
}
export function ledgerCommandInput(command: LedgerCommand): unknown {
  switch (command.operation) {
    case 'recordStoreExpense': return command.expense;
    case 'confirmStoreSupplierOpening': return command.opening;
    case 'recordStoreMoneyRegisterEntry': return command.entry;
    case 'recordStoreSupplierMoney': return command.entry;
    case 'confirmStoreSupplierBill': return command.bill;
    case 'recordStoreSupplierMoneyAllocation': return command.intent;
    case 'recordStoreSupplierRefund': return command.intent;
    case 'recordStoreSupplierCreditNote': return command.intent;
  }
}
export function ledgerCommandTarget(command: LedgerCommand): {kind: Exclude<LedgerKind, 'moneyEntry'>; id: string; entryId: string | null} {
  switch (command.operation) {
    case 'recordStoreExpense': return {kind: 'expense', id: command.expense.operationId, entryId: null};
    case 'confirmStoreSupplierOpening': return {kind: 'supplierLedger', id: command.opening.supplierId, entryId: null};
    case 'recordStoreMoneyRegisterEntry': return {kind: 'moneyRegister', id: command.registerId, entryId: command.entry.id};
    case 'recordStoreSupplierMoney': return {kind: 'supplierLedger', id: command.supplierId, entryId: command.entry.operationId};
    case 'confirmStoreSupplierBill': return {kind: 'supplierLedger', id: command.supplierId, entryId: command.bill.copy.draft.id};
    case 'recordStoreSupplierMoneyAllocation': return {kind: 'supplierLedger', id: command.supplierId, entryId: command.intent.operationId};
    case 'recordStoreSupplierRefund': return {kind: 'supplierLedger', id: command.supplierId, entryId: command.intent.operationId};
    case 'recordStoreSupplierCreditNote': return {kind: 'supplierLedger', id: command.supplierId, entryId: command.intent.operationId};
  }
}
export function ledgerCommandFingerprint(command: Omit<LedgerExpenseCommand, 'fingerprint'> |
  Omit<LedgerOpeningCommand, 'fingerprint'> | Omit<LedgerRegisterCommand, 'fingerprint'> | Omit<LedgerSupplierMoneyCommand, 'fingerprint'> | Omit<LedgerSupplierBillCommand, 'fingerprint'> | Omit<LedgerSupplierAllocationCommand, 'fingerprint'> | Omit<LedgerSupplierRefundCommand, 'fingerprint'> | Omit<LedgerSupplierCreditCommand, 'fingerprint'>): string {
  return ledgerHash(command);
}
export function checkedLedgerCommand(raw: unknown): LedgerCommand {
  const value = raw as Record<string, unknown>;
  if (!value || !operations.includes(value.operation as LedgerOperation)) ledgerError();
  const fields = value.operation === 'recordStoreExpense' ? ['expense'] : value.operation === 'confirmStoreSupplierOpening'
    ? ['opening', 'expectedPurchaseRevision', 'expectedPurchaseFingerprint', 'confirmedAt', 'confirmedUtcOffsetMinutes']
    : value.operation === 'recordStoreSupplierMoney' ? ['supplierId', 'expectedSupplierRevision', 'entry', 'confirmedUtcOffsetMinutes']
    : value.operation === 'confirmStoreSupplierBill' ? supplierBillFields
    : value.operation === 'recordStoreSupplierMoneyAllocation' ? supplierAllocationFields
    : value.operation === 'recordStoreSupplierRefund' ? supplierRefundFields
    : value.operation === 'recordStoreSupplierCreditNote' ? supplierCreditFields
    : ['registerId', 'expectedRegisterRevision', 'entry', 'capturedAt'];
  const v = ledgerExact(raw, ['scope', 'operation', 'expectedRevision', 'idempotencyKey', 'fingerprint', ...fields]);
  const scope = checkedPurchaseEntryScope(v.scope), operation = v.operation as LedgerOperation;
  const expectedRevision = v.expectedRevision === null ? null : purchaseEntryRevision(v.expectedRevision),
    idempotencyKey = purchaseEntryId(v.idempotencyKey), fingerprint = purchaseEntryFingerprint(v.fingerprint);
  const base = {scope, operation, expectedRevision, idempotencyKey, fingerprint};
  let result: LedgerCommand;
  if (operation === 'recordStoreExpense') result = {...base, operation, expense: checkedLedgerExpense(v.expense, scope)};
  else if (operation === 'confirmStoreSupplierOpening') {
    const offset = v.confirmedUtcOffsetMinutes;
    if (!Number.isInteger(offset) || (offset as number) < -720 || (offset as number) > 840) ledgerError();
    result = {...base, operation, opening: checkedLedgerOpening(v.opening, scope),
      expectedPurchaseRevision: purchaseEntryRevision(v.expectedPurchaseRevision),
      expectedPurchaseFingerprint: purchaseEntryFingerprint(v.expectedPurchaseFingerprint),
      confirmedAt: ledgerTime(v.confirmedAt), confirmedUtcOffsetMinutes: offset as number};
  } else if (operation === 'recordStoreSupplierMoney') {
    const offset = v.confirmedUtcOffsetMinutes;
    if (!Number.isInteger(offset) || (offset as number) < -720 || (offset as number) > 840) ledgerError();
    result = {...base, operation, supplierId: ledgerText(v.supplierId),
      expectedSupplierRevision: purchaseEntryRevision(v.expectedSupplierRevision),
      entry: checkedLedgerSupplierMoneyEntry(v.entry), confirmedUtcOffsetMinutes: offset as number};
  } else if (operation === 'confirmStoreSupplierBill') {
    const offset = v.confirmedUtcOffsetMinutes, bill = checkedLedgerSupplierBillAcceptance(v.bill);
    if (!Number.isInteger(offset) || (offset as number) < -720 || (offset as number) > 840 || bill.copy.supplier.id !== v.supplierId) ledgerError();
    result = {...base, operation, supplierId: ledgerText(v.supplierId), expectedSupplierRevision: purchaseEntryRevision(v.expectedSupplierRevision),
      expectedPurchaseRevision: purchaseEntryRevision(v.expectedPurchaseRevision), expectedPurchaseFingerprint: purchaseEntryFingerprint(v.expectedPurchaseFingerprint),
      bill, confirmedUtcOffsetMinutes: offset as number};
  } else if (operation === 'recordStoreSupplierMoneyAllocation') {
    const intent = checkedLedgerSupplierAllocationIntent(v.intent, scope);
    if (intent.supplierId !== v.supplierId) ledgerError();
    result = {...base, operation, supplierId: ledgerText(v.supplierId),
      expectedSupplierRevision: purchaseEntryRevision(v.expectedSupplierRevision), intent};
  } else if (operation === 'recordStoreSupplierRefund') {
    const intent = checkedLedgerSupplierRefundIntent(v.intent, scope), offset = v.confirmedUtcOffsetMinutes;
    if (intent.supplierId !== v.supplierId || !Number.isInteger(offset) || (offset as number) < -720 || (offset as number) > 840) ledgerError();
    result = {...base, operation, supplierId: ledgerText(v.supplierId),
      expectedSupplierRevision: purchaseEntryRevision(v.expectedSupplierRevision), intent, confirmedUtcOffsetMinutes: offset as number};
  } else if (operation === 'recordStoreSupplierCreditNote') {
    const intent = checkedLedgerSupplierCreditIntent(v.intent, scope), offset = v.confirmedUtcOffsetMinutes;
    if (intent.supplierId !== v.supplierId || !Number.isInteger(offset) || (offset as number) < -720 || (offset as number) > 840) ledgerError();
    result = {...base, operation, supplierId: ledgerText(v.supplierId), expectedSupplierRevision: purchaseEntryRevision(v.expectedSupplierRevision),
      expectedPurchaseRevision: purchaseEntryRevision(v.expectedPurchaseRevision), expectedPurchaseFingerprint: purchaseEntryFingerprint(v.expectedPurchaseFingerprint),
      intent, confirmedUtcOffsetMinutes: offset as number};
  } else result = {...base, operation, registerId: ledgerText(v.registerId),
    expectedRegisterRevision: purchaseEntryRevision(v.expectedRegisterRevision), entry: checkedLedgerRegisterEntry(v.entry), capturedAt: ledgerTime(v.capturedAt)};
  const {fingerprint: _, ...input} = result;
  if (ledgerCommandFingerprint(input) !== fingerprint) ledgerError();
  return result;
}
export function ledgerTerminalReasons(operation: LedgerOperation): readonly string[] {
  const shared = ['stale_ledger', 'record_identity_conflict'];
  return operation === 'recordStoreExpense' ? shared : operation === 'confirmStoreSupplierOpening'
    ? [...shared, 'stale_evidence', 'supplier_has_records', 'opening_amount_unknown', 'opening_bill_inclusion_missing', 'opening_confirmation_invalid']
    : operation === 'recordStoreSupplierMoney' ? [...shared, 'supplier_unavailable', 'stale_supplier', 'opening_evidence_changed', 'supplier_capacity_changed', 'supplier_money_evidence_invalid']
    : operation === 'confirmStoreSupplierBill' ? [...shared, 'supplier_unavailable', 'stale_supplier', 'stale_evidence', 'bill_source_changed', 'bill_opening_evidence_changed', 'bill_confirmation_invalid']
    : operation === 'recordStoreSupplierMoneyAllocation' ? [...shared, 'supplier_unavailable', 'stale_supplier', 'opening_evidence_changed', 'allocation_source_changed', 'allocation_capacity_changed', 'allocation_confirmation_invalid']
    : operation === 'recordStoreSupplierRefund' ? [...shared, 'supplier_unavailable', 'stale_supplier', 'opening_evidence_changed', 'refund_source_changed', 'refund_capacity_changed', 'refund_confirmation_invalid', 'refund_reference_conflict']
    : operation === 'recordStoreSupplierCreditNote' ? [...shared, 'supplier_unavailable', 'stale_supplier', 'stale_evidence', 'opening_evidence_changed', 'credit_source_changed', 'credit_capacity_changed', 'credit_confirmation_invalid', 'credit_reference_conflict']
    : [...shared, 'register_unavailable', 'stale_register', 'register_history_changed'];
}
export function checkedLedgerReceipt(raw: unknown, scope: LedgerScope, key: string, fingerprint: string): LedgerReceipt {
  try {return ledgerReceipt(raw, scope, key, fingerprint);} catch {ledgerError('service_unavailable', 503);}
}
function ledgerReceipt(raw: unknown, scope: LedgerScope, key: string, fingerprint: string): LedgerReceipt {
  const v = ledgerExact(raw, ['schemaVersion', 'scope', 'operation', 'idempotencyKey', 'fingerprint', 'inputFingerprint',
    'status', 'reason', 'changed', 'resultRevision', 'targetKind', 'targetId', 'entryId', 'recordedAt']);
  const operation = v.operation as LedgerOperation;
  if (v.schemaVersion !== 1 || ledgerCanonical(checkedPurchaseEntryScope(v.scope)) !== ledgerCanonical(scope) ||
      v.idempotencyKey !== key || v.fingerprint !== fingerprint || !operations.includes(operation) ||
      typeof v.changed !== 'boolean' || !['saved', 'not_saved'].includes(v.status as string)) ledgerError('service_unavailable', 503);
  purchaseEntryFingerprint(v.inputFingerprint); ledgerText(v.targetId); ledgerTime(v.recordedAt);
  const kind = operation === 'recordStoreExpense' ? 'expense' : operation === 'confirmStoreSupplierOpening' || operation === 'recordStoreSupplierMoney' || operation === 'confirmStoreSupplierBill' || operation === 'recordStoreSupplierMoneyAllocation' || operation === 'recordStoreSupplierRefund' || operation === 'recordStoreSupplierCreditNote' ? 'supplierLedger' : 'moneyRegister';
  if (v.targetKind !== kind || (operation === 'recordStoreMoneyRegisterEntry' || operation === 'recordStoreSupplierMoney' || operation === 'confirmStoreSupplierBill' || operation === 'recordStoreSupplierMoneyAllocation' || operation === 'recordStoreSupplierRefund' || operation === 'recordStoreSupplierCreditNote' ? typeof v.entryId !== 'string' || !v.entryId.trim() : v.entryId !== null) ||
      v.status === 'saved' && (v.reason !== null || v.resultRevision === null) ||
      v.status === 'not_saved' && (v.changed || !ledgerTerminalReasons(operation).includes(v.reason as string))) ledgerError('service_unavailable', 503);
  if (v.resultRevision !== null) purchaseEntryRevision(v.resultRevision);
  return ledgerClone(v) as unknown as LedgerReceipt;
}
export function checkedLedgerRow(raw: unknown, scope: LedgerScope): LedgerRow {
  try {return ledgerRow(raw, scope);} catch {ledgerError('service_unavailable', 503);}
}
function ledgerRow(raw: unknown, scope: LedgerScope): LedgerRow {
  const v = ledgerExact(raw, ['kind', 'id', 'parentId', 'revision', 'json', 'fingerprint', 'ordinal']);
  if (!kinds.includes(v.kind as LedgerKind)) ledgerError('service_unavailable', 503);
  const id = ledgerText(v.id); purchaseEntryRevision(v.revision); purchaseEntryFingerprint(v.fingerprint);
  if (typeof v.json !== 'string') ledgerError('service_unavailable', 503);
  let value: unknown;
  try {value = JSON.parse(v.json);} catch {ledgerError('service_unavailable', 503);}
  if (ledgerCanonical(value) !== v.json || ledgerHash(value) !== v.fingerprint) ledgerError('service_unavailable', 503);
  if (v.kind === 'expense') {
    if (checkedLedgerExpense(value, scope).operationId !== id) ledgerError('service_unavailable', 503);
  } else if (v.kind === 'moneyRegister') {
    const header = checkedLedgerRegisterHeader(value, scope);
    if (header.registerId !== id || header.revision !== v.revision) ledgerError('service_unavailable', 503);
  } else if (v.kind === 'moneyEntry') {
    if (checkedLedgerRegisterEntry(value).id !== id || v.parentId === null) ledgerError('service_unavailable', 503);
    ledgerText(v.parentId); purchaseEntryRevision(v.ordinal);
  } else {
    if (!value || typeof value !== 'object' || Array.isArray(value)) ledgerError('service_unavailable', 503);
    const supplier = value as Record<string, unknown>;
    if (supplier.accountScope !== scope.account || supplier.workspaceId !== scope.store ||
        supplier.supplierId !== id || supplier.revision !== v.revision ||
        typeof supplier.historyComplete !== 'boolean' || !Array.isArray(supplier.entries) ||
        supplier.openingBalanceMinor !== null && !Number.isSafeInteger(supplier.openingBalanceMinor) ||
        supplier.historyComplete && supplier.openingBalanceMinor === null) ledgerError('service_unavailable', 503);
    ledgerText(supplier.supplierName); ledgerTime(supplier.asOf);
    if (supplier.openingRecord !== undefined) {
      const opening = checkedLedgerOpening(supplier.openingRecord, scope);
      const amount = opening.amountMinor;
      if (opening.supplierId !== id || amount === null ||
          supplier.openingBalanceMinor !== (opening.supplierCredit ? -amount : amount) ||
          ledgerMicros(supplier.asOf) < ledgerMicros(opening.savedAt)) ledgerError('service_unavailable', 503);
    }
  }
  if (v.kind !== 'moneyEntry' && (v.ordinal !== null || v.parentId !== null)) ledgerError('service_unavailable', 503);
  return ledgerClone(v) as unknown as LedgerRow;
}

/** Same native opening result, derived from the exact verified source evidence. */
export function ledgerConfirmedOpening(command: LedgerOpeningCommand, supplierName: string): Record<string, unknown> {
  const record = command.opening;
  if (record.amountMinor === null) ledgerError('opening_amount_unknown', 409);
  if (ledgerMicros(command.confirmedAt) < ledgerMicros(record.savedAt)) ledgerError('opening_confirmation_invalid', 409);
  const calendar = new Date(Number(ledgerMicros(command.confirmedAt) / 1000n) + command.confirmedUtcOffsetMinutes * 60000);
  calendar.setUTCHours(0, 0, 0, 0);
  if (new Date(record.asOfDate + 'T00:00:00.000Z').getTime() > calendar.getTime()) ledgerError('opening_confirmation_invalid', 409);
  return {accountScope: command.scope.account, workspaceId: command.scope.store, supplierId: record.supplierId,
    supplierName: ledgerText(supplierName), revision: 1, asOf: command.confirmedAt,
    openingBalanceMinor: record.supplierCredit && record.amountMinor !== 0 ? -record.amountMinor : record.amountMinor,
    openingRecord: ledgerClone(record), historyComplete: true, entries: []};
}

export class WorkspaceLedgerService {
  constructor(private readonly repository: LedgerRepository | null, private readonly now: () => Date = () => new Date()) {}
  private scope(actor: LedgerActor, body: Readonly<Record<string, unknown>>): LedgerScope {
    if (body.schemaVersion !== 1 || body.ledgerVersion !== 1) ledgerError();
    const scope = checkedPurchaseEntryScope(body.scope);
    if (actor.uid !== scope.account || actor.tenantId !== undefined) ledgerError('permission_denied', 403);
    if (!this.repository || !this.repository.configured) ledgerError('service_unavailable', 503);
    if (this.repository.projectId !== actor.projectId || this.repository.realm !== scope.realm) ledgerError('permission_denied', 403);
    return scope;
  }
  private frame(scope: LedgerScope): Record<string, unknown> {
    return {schemaVersion: 1, ledgerVersion: 1, actorAccountId: scope.account, storeId: scope.store,
      realm: scope.realm, observedAt: this.now().toISOString()};
  }
  private statusFrame(scope: LedgerScope, value: LedgerStatus, original?: LedgerCommand): object {
    if (value.revision !== null) purchaseEntryRevision(value.revision);
    const receipt = value.receipt;
    if (value.revision === null && value.current !== null) ledgerError('service_unavailable', 503);
    if (value.current) checkedLedgerRow(value.current, scope);
    if (original) {
      const target = ledgerCommandTarget(original);
      if (!receipt || receipt.operation !== original.operation || receipt.inputFingerprint !== ledgerHash(ledgerCommandInput(original)) ||
          receipt.targetKind !== target.kind || receipt.targetId !== target.id || receipt.entryId !== target.entryId) ledgerError('service_unavailable', 503);
    }
    if (receipt && (receipt.resultRevision !== null && (value.revision === null || value.revision < receipt.resultRevision) ||
        receipt.status === 'saved' && value.current === null || value.current !== null &&
        (value.current.id !== receipt.targetId || value.current.kind !== receipt.targetKind))) ledgerError('service_unavailable', 503);
    if (receipt?.operation === 'recordStoreSupplierMoney' && receipt.status === 'saved') {
      try {
        const rows = (JSON.parse(value.current!.json) as {entries: unknown[]}).entries;
        const matching = rows.filter(row => (row as {operationId?: unknown})?.operationId === receipt.entryId);
        if (matching.length !== 1 || ledgerHash(checkedLedgerSupplierMoneyEntry(matching[0])) !== receipt.inputFingerprint) {
          ledgerError('service_unavailable', 503);
        }
      } catch {ledgerError('service_unavailable', 503);}
    }
    if (receipt?.operation === 'confirmStoreSupplierBill' && receipt.status === 'saved') {
      try {
        const bill = checkedLedgerSupplierBillAcceptance(JSON.parse(value.current!.json).purchaseBills?.[receipt.entryId!]);
        if (bill.copy.draft.id !== receipt.entryId || ledgerHash(bill) !== receipt.inputFingerprint) ledgerError('service_unavailable', 503);
        const wanted = ledgerBillLiabilityEntry(bill), entries = JSON.parse(value.current!.json).entries as Record<string, unknown>[];
        const matching = entries.filter(entry => entry.kind === 'bill' && entry.billId === receipt.entryId);
        if (wanted ? matching.length !== 1 || ledgerHash(matching[0]) !== ledgerHash(wanted) : matching.length !== 0) ledgerError('service_unavailable', 503);
      } catch {ledgerError('service_unavailable', 503);}
    }
    if (receipt?.operation === 'recordStoreSupplierMoneyAllocation' && receipt.status === 'saved') {
      try {
        const ledger = JSON.parse(value.current!.json);
        const proof = checkedLedgerSupplierAllocationProof(ledger.billMoneyAllocations?.[receipt.entryId!], scope);
        if (proof.operationId !== receipt.entryId || proof.supplierId !== receipt.targetId || proof.committedRevision > value.current!.revision ||
            ledgerHash(ledgerSupplierAllocationInput(proof)) !== receipt.inputFingerprint ||
            ledgerMicros(proof.recordedAt) > ledgerMicros(ledger.asOf)) ledgerError('service_unavailable', 503);
      } catch {ledgerError('service_unavailable', 503);}
    }
    if (receipt?.operation === 'recordStoreSupplierRefund' && receipt.status === 'saved') {
      try {
        const ledger = JSON.parse(value.current!.json), proof = checkedLedgerSupplierRefundProof(ledger.refunds?.[receipt.entryId!], scope);
        const entries = (ledger.entries as Record<string, unknown>[]).filter(entry => entry.operationId === receipt.entryId);
        if (proof.intent.operationId !== receipt.entryId || proof.intent.supplierId !== receipt.targetId ||
            proof.committedRevision > value.current!.revision || ledgerHash(proof.intent) !== receipt.inputFingerprint ||
            ledgerMicros(proof.recordedAt) > ledgerMicros(ledger.asOf) || entries.length !== 1 ||
            ledgerHash(entries[0]) !== ledgerHash(ledgerSupplierRefundEntry(proof))) ledgerError('service_unavailable', 503);
      } catch {ledgerError('service_unavailable', 503);}
    }
    if (receipt?.operation === 'recordStoreSupplierCreditNote' && receipt.status === 'saved') {
      try {
        const ledger = JSON.parse(value.current!.json), proof = checkedLedgerSupplierCreditProof(ledger.creditNotes?.[receipt.entryId!], scope);
        const entries = (ledger.entries as Record<string, unknown>[]).filter(entry => entry.operationId === receipt.entryId);
        if (proof.operationId !== receipt.entryId || proof.supplierId !== receipt.targetId || proof.committedRevision > value.current!.revision ||
            ledgerHash(ledgerSupplierCreditInput(proof)) !== receipt.inputFingerprint || ledgerMicros(proof.recordedAt) > ledgerMicros(ledger.asOf) ||
            entries.length !== 1 || ledgerHash(entries[0]) !== ledgerHash(ledgerSupplierCreditEntry(proof))) ledgerError('service_unavailable', 503);
      } catch {ledgerError('service_unavailable', 503);}
    }
    return {...this.frame(scope), state: value.revision === null ? 'empty' : 'ready',
      sourceRevision: value.revision, attempt: receipt, current: value.current};
  }
  async handle(actor: LedgerActor, operation: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    try {return await this.handleOperation(actor, operation, body);} catch (error) {
      if (error instanceof WorkspaceProfileError) ledgerError(error.code, error.httpStatus);
      throw error;
    }
  }
  private async handleOperation(actor: LedgerActor, operation: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    if (body.operation !== operation) ledgerError();
    if (operation === 'readStoreLedgerSource') {
      ledgerExact(body, [...common, 'kind', 'parentId', 'cursor']); const scope = this.scope(actor, body);
      if (!kinds.includes(body.kind as LedgerKind) || body.cursor !== null && typeof body.cursor !== 'string') ledgerError();
      const kind = body.kind as LedgerKind, parentId = body.parentId === null ? null : ledgerText(body.parentId);
      if (kind === 'moneyEntry' ? parentId === null : parentId !== null) ledgerError();
      const page = await this.repository!.list(actor, scope, kind, parentId, body.cursor as string | null);
      if (page.kind !== kind || page.parentId !== parentId || !Number.isSafeInteger(page.totalCount) || page.totalCount < 0 ||
          typeof page.startsSource !== 'boolean' || page.startsSource !== (body.cursor === null) ||
          page.nextCursor !== null && (typeof page.nextCursor !== 'string' || !page.nextCursor || page.nextCursor === body.cursor || !page.rows.length) ||
          page.rows.length > page.totalCount || page.revision === null &&
          (page.totalCount !== 0 || page.rows.length !== 0 || page.nextCursor !== null || body.cursor !== null)) ledgerError('service_unavailable', 503);
      if (page.revision !== null) purchaseEntryRevision(page.revision);
      const ids = new Set<string>();
      for (const rawRow of page.rows) {
        const row = checkedLedgerRow(rawRow, scope);
        if (row.kind !== kind || row.parentId !== parentId || ids.has(row.id)) ledgerError('service_unavailable', 503);
        ids.add(row.id);
      }
      const {revision, ...content} = page;
      return {...this.frame(scope), state: revision === null ? 'empty' : 'ready', sourceRevision: revision, ...content};
    }
    if (operation === 'readStoreLedgerAttempt') {
      ledgerExact(body, [...common, 'idempotencyKey', 'fingerprint']); const scope = this.scope(actor, body);
      const key = purchaseEntryId(body.idempotencyKey), fingerprint = purchaseEntryFingerprint(body.fingerprint);
      const result = await this.repository!.status(actor, scope, key, fingerprint);
      if (result.receipt) checkedLedgerReceipt(result.receipt, scope, key, fingerprint);
      return this.statusFrame(scope, result);
    }
    if (!operations.includes(operation as LedgerOperation)) ledgerError();
    const specific = operation === 'recordStoreExpense' ? ['expense'] : operation === 'confirmStoreSupplierOpening'
      ? ['opening', 'expectedPurchaseRevision', 'expectedPurchaseFingerprint', 'confirmedAt', 'confirmedUtcOffsetMinutes']
      : operation === 'recordStoreSupplierMoney' ? ['supplierId', 'expectedSupplierRevision', 'entry', 'confirmedUtcOffsetMinutes']
      : operation === 'confirmStoreSupplierBill' ? supplierBillFields
      : operation === 'recordStoreSupplierMoneyAllocation' ? supplierAllocationFields
      : operation === 'recordStoreSupplierRefund' ? supplierRefundFields
      : operation === 'recordStoreSupplierCreditNote' ? supplierCreditFields
      : ['registerId', 'expectedRegisterRevision', 'entry', 'capturedAt'];
    ledgerExact(body, [...saveKeys, ...specific]); const scope = this.scope(actor, body);
    const command = checkedLedgerCommand({scope, operation, expectedRevision: body.expectedRevision,
      idempotencyKey: body.idempotencyKey, fingerprint: body.fingerprint,
      ...Object.fromEntries(specific.map(key => [key, body[key]]))});
    if (command.operation === 'recordStoreSupplierMoney' && !this.repository!.recordSupplierMoney) ledgerError('service_unavailable', 503);
    if (command.operation === 'confirmStoreSupplierBill' && !this.repository!.confirmSupplierBill) ledgerError('service_unavailable', 503);
    if (command.operation === 'recordStoreSupplierMoneyAllocation' && !this.repository!.allocateSupplierMoney) ledgerError('service_unavailable', 503);
    if (command.operation === 'recordStoreSupplierRefund' && !this.repository!.recordSupplierRefund) ledgerError('service_unavailable', 503);
    if (command.operation === 'recordStoreSupplierCreditNote' && !this.repository!.recordSupplierCredit) ledgerError('service_unavailable', 503);
    const result = command.operation === 'recordStoreExpense' ? await this.repository!.recordExpense(actor, command)
      : command.operation === 'confirmStoreSupplierOpening' ? await this.repository!.confirmOpening(actor, command)
      : command.operation === 'recordStoreSupplierMoney' ? await this.repository!.recordSupplierMoney!(actor, command)
      : command.operation === 'confirmStoreSupplierBill' ? await this.repository!.confirmSupplierBill!(actor, command)
      : command.operation === 'recordStoreSupplierMoneyAllocation' ? await this.repository!.allocateSupplierMoney!(actor, command)
      : command.operation === 'recordStoreSupplierRefund' ? await this.repository!.recordSupplierRefund!(actor, command)
      : command.operation === 'recordStoreSupplierCreditNote' ? await this.repository!.recordSupplierCredit!(actor, command)
      : await this.repository!.recordRegisterEntry(actor, command);
    if (result.receipt) checkedLedgerReceipt(result.receipt, scope, command.idempotencyKey, command.fingerprint);
    return this.statusFrame(scope, result, command);
  }
}
