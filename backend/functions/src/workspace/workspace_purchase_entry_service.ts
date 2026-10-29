import {createHash} from 'node:crypto';
import {WorkspaceProfileError} from './workspace_profile_service.js';

/** Private owner-recorded contacts and purchase evidence. Never tax, Stock,
 * invoice-posting, payment, global supplier or Workspace-approval authority. */
export type PurchaseEntryRealm = 'evaluation' | 'production';
export interface PurchaseEntryActor {uid: string; projectId: string; tenantId?: string}
export interface PurchaseEntryScope {account: string; store: string; realm: PurchaseEntryRealm}
export interface PurchaseEntrySupplier {
  id: string; name: string; phone: string; address: string; gstin: string;
  source: 'manual'; createdAt: string; updatedAt: string;
}
// WorkSession.production uses the non-QA private book in both backend realms.
// Local review QA data is a separate namespace and is never remotely adopted.
export interface PurchaseEntryBook {
  version: 1; account: string; store: string; qa: boolean; revision: number;
  profiles: readonly PurchaseEntrySupplier[]; draft: unknown;
  copies?: readonly unknown[]; openingRecords?: readonly unknown[];
  goodsReceiptDrafts?: readonly unknown[]; goodsReceiptCancellations?: readonly unknown[];
  billGoodsReviews?: readonly unknown[]; billGoodsCancellations?: readonly unknown[];
  restockGoodsAttempts?: readonly unknown[];
}
export interface PurchaseEntrySupplierCommand {
  scope: PurchaseEntryScope; expectedRevision: number | null;
  idempotencyKey: string; fingerprint: string; profile: PurchaseEntrySupplier;
}
export interface PurchaseEntryDraft extends Readonly<Record<string, unknown>> {
  id: string; supplierId: string; invoiceReference: string; invoiceDate: string;
  createdAt: string; updatedAt: string; source: 'manual'; stage: 'draft';
  goods: readonly Readonly<Record<string, string>>[];
  details?: Readonly<Record<string, string>>;
  attachments?: readonly Readonly<Record<string, unknown>>[];
  additionalFields?: readonly Readonly<Record<string, unknown>>[];
  printedTaxRows?: readonly Readonly<Record<string, string>>[];
}
export interface PurchaseEntryCopy extends Readonly<Record<string, unknown>> {
  id: string; storeName: string; revision: number; savedAt: string;
  supplier: PurchaseEntrySupplier; draft: PurchaseEntryDraft; labels: Readonly<Record<string, string>>;
}
export interface PurchaseEntryDraftCommand extends PurchaseEntrySupplierCommand {
  draft: PurchaseEntryDraft; reviewedCopy: PurchaseEntryCopy | null; replaceReviewedDraftId: string | null;
}
export type PurchaseEntrySaveCommand = PurchaseEntrySupplierCommand | PurchaseEntryDraftCommand;
export interface PurchaseEntryReceipt {
  schemaVersion: 1; scope: PurchaseEntryScope; operation: 'saveSupplierProfile' | 'savePurchaseDraft';
  idempotencyKey: string; fingerprint: string; status: 'saved' | 'not_saved'; reason: string | null; changed: boolean;
  resultRevision: number | null; profile: PurchaseEntrySupplier; recordedAt: string;
  draftId?: string; draftFingerprint?: string; copyId?: string | null; copyFingerprint?: string | null;
}
export interface PurchaseEntryResult {receipt: PurchaseEntryReceipt | null; currentBook: PurchaseEntryBook | null}
/** Implementations must authorize the original Store source even for receipts.
 * No caller-supplied access grant or process-local lock can implement this port. */
export interface PurchaseEntryRepository {
  readonly realm: PurchaseEntryRealm; readonly projectId: string;
  read(actor: PurchaseEntryActor, scope: PurchaseEntryScope): Promise<PurchaseEntryBook | null>;
  saveSupplier(actor: PurchaseEntryActor, command: PurchaseEntrySupplierCommand): Promise<PurchaseEntryResult>;
  savePurchaseDraft?(actor: PurchaseEntryActor, command: PurchaseEntryDraftCommand): Promise<PurchaseEntryResult>;
  status(actor: PurchaseEntryActor, scope: PurchaseEntryScope, key: string, fingerprint: string): Promise<PurchaseEntryResult>;
}
export function purchaseEntryError(code = 'invalid_input', status = 400): never {
  const message = code === 'stale_book' ? 'Purchase records changed. Reopen the original supplier details.'
    : code === 'duplicate_supplier' ? 'These details belong to an existing supplier. Select that supplier.'
    : code === 'idempotency_conflict' ? 'Recover the original supplier Save before changing it.'
    : code === 'service_unavailable' ? 'The original private purchase source is unavailable. Saved records are kept.'
    : 'Check the original supplier details and account/Store context.';
  throw new WorkspaceProfileError(code, message, status);
}
export function purchaseEntryObject(raw: unknown): Record<string, unknown> {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw) ||
      ![Object.prototype, null].includes(Object.getPrototypeOf(raw))) purchaseEntryError();
  return raw as Record<string, unknown>;
}
export function purchaseEntryExact(raw: unknown, required: readonly string[], optional: readonly string[] = []): Record<string, unknown> {
  const value = purchaseEntryObject(raw);
  if (!required.every(key => Object.hasOwn(value, key)) ||
      Object.keys(value).some(key => !required.includes(key) && !optional.includes(key))) purchaseEntryError();
  return value;
}
function string(value: unknown, max: number, empty = false): string {
  if (typeof value !== 'string' || value.length > max || !empty && !value.trim() ||
      /[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/u.test(value) || Buffer.from(value).toString('utf8') !== value) purchaseEntryError();
  return value;
}
export function purchaseEntryId(value: unknown): string {
  const result = string(value, 2000);
  if (/[\r\n\t]/u.test(result)) purchaseEntryError();
  return result;
}
export function purchaseEntryRevision(value: unknown, minimum = 1): number {
  if (!Number.isSafeInteger(value) || (value as number) < minimum) purchaseEntryError();
  return value as number;
}
export function purchaseEntryFingerprint(value: unknown): string {
  if (typeof value !== 'string' || !/^[a-f0-9]{64}$/u.test(value)) purchaseEntryError();
  return value;
}
/** Dart UTC captures preserve either millisecond or microsecond precision. */
export function purchaseEntryMicros(value: unknown): bigint {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}(?:\d{3})?Z$/u.test(value)) purchaseEntryError();
  const millis = Date.parse(value);
  if (!Number.isFinite(millis) || new Date(millis).toISOString().slice(0, 23) !== value.slice(0, 23)) purchaseEntryError();
  return BigInt(millis) * 1000n + BigInt(value.length === 27 ? value.slice(23, 26) : '0');
}
export function purchaseEntryCanonical(value: unknown): string {
  if (value === null || typeof value === 'boolean' || typeof value === 'string') return JSON.stringify(value);
  if (typeof value === 'number') {if (!Number.isFinite(value)) purchaseEntryError(); return JSON.stringify(value);}
  if (Array.isArray(value)) return '[' + value.map(purchaseEntryCanonical).join(',') + ']';
  const object = purchaseEntryObject(value);
  return '{' + Object.keys(object).sort().map(key => JSON.stringify(key) + ':' + purchaseEntryCanonical(object[key])).join(',') + '}';
}
export function purchaseEntryHash(value: unknown): string {
  return createHash('sha256').update(purchaseEntryCanonical(value), 'utf8').digest('hex');
}
export function purchaseEntryClone<T>(value: T): T {return JSON.parse(purchaseEntryCanonical(value)) as T;}
export function checkedPurchaseEntrySupplier(raw: unknown): PurchaseEntrySupplier {
  const p = purchaseEntryExact(raw, ['id', 'name', 'phone', 'address', 'gstin', 'source', 'createdAt', 'updatedAt']);
  const id = purchaseEntryId(p.id), name = string(p.name, 120), address = string(p.address, 500, true),
    phone = string(p.phone, 16, true), gstin = string(p.gstin, 15, true);
  if (phone && !/^\+?[0-9]{7,15}$/u.test(phone) || gstin && !/^[0-9A-Z]{15}$/u.test(gstin) ||
      p.source !== 'manual' || purchaseEntryMicros(p.updatedAt) < purchaseEntryMicros(p.createdAt)) purchaseEntryError();
  return {id, name, phone, address, gstin, source: 'manual', createdAt: p.createdAt as string, updatedAt: p.updatedAt as string};
}
export function checkedPurchaseEntryScope(raw: unknown): PurchaseEntryScope {
  const v = purchaseEntryExact(raw, ['account', 'store', 'realm']);
  if (v.realm !== 'evaluation' && v.realm !== 'production') purchaseEntryError();
  return {account: purchaseEntryId(v.account), store: purchaseEntryId(v.store), realm: v.realm};
}
const sectionKeys = ['copies', 'openingRecords', 'goodsReceiptDrafts', 'goodsReceiptCancellations',
  'billGoodsReviews', 'billGoodsCancellations', 'restockGoodsAttempts'] as const;
export function checkedPurchaseEntryBook(raw: unknown, scope: PurchaseEntryScope): PurchaseEntryBook {
  const v = purchaseEntryExact(raw, ['version', 'account', 'store', 'qa', 'revision', 'profiles', 'draft'], sectionKeys);
  if (v.version !== 1 || v.account !== scope.account || v.store !== scope.store || v.qa !== false ||
      !Array.isArray(v.profiles) || v.profiles.length > 10000 || v.draft !== null &&
      (!v.draft || typeof v.draft !== 'object' || Array.isArray(v.draft))) purchaseEntryError('service_unavailable', 503);
  purchaseEntryRevision(v.revision);
  const profiles = v.profiles.map(checkedPurchaseEntrySupplier);
  if (new Set(profiles.map(p => p.id)).size !== profiles.length) purchaseEntryError('service_unavailable', 503);
  for (const key of sectionKeys) if (Object.hasOwn(v, key)) {
    if (!Array.isArray(v[key]) || v[key].length > 1000 || v[key].some(row =>
      !row || typeof row !== 'object' || Array.isArray(row))) purchaseEntryError('service_unavailable', 503);
  }
  if (Buffer.byteLength(purchaseEntryCanonical(v), 'utf8') > 10 * 1024 * 1024) purchaseEntryError('service_unavailable', 503);
  return purchaseEntryClone({...v, profiles}) as unknown as PurchaseEntryBook;
}
export function purchaseEntryCommandFingerprint(input: Omit<PurchaseEntrySupplierCommand, 'fingerprint'>): string {
  return purchaseEntryHash({schemaVersion: 1, operation: 'saveSupplierProfile', ...input});
}
function sameNativeSupplier(left: PurchaseEntrySupplier, right: PurchaseEntrySupplier): boolean {
  // Native DateTime decoding normalises .123000Z to .123Z. Internal capture
  // timestamps are immutable instants, not printed document strings. Keep the
  // original book bytes on a no-op while the receipt retains the exact intent.
  return ['id', 'name', 'phone', 'address', 'gstin', 'source'].every(key =>
    left[key as keyof PurchaseEntrySupplier] === right[key as keyof PurchaseEntrySupplier]) &&
    purchaseEntryMicros(left.createdAt) === purchaseEntryMicros(right.createdAt) &&
    purchaseEntryMicros(left.updatedAt) === purchaseEntryMicros(right.updatedAt);
}

// Exact existing native raw-data field names; no tax/accounting calculations.
const purchaseDraftDetailKeys = new Set(["documentType", "placeOfSupply", "buyerName", "buyerAddress", "buyerGstin", "priceBasis", "taxTreatment", "reverseCharge", "billDiscount", "freight", "otherCharges", "roundOff", "taxableValue", "cgst", "sgst", "igst", "cess", "invoiceTotal", "receiptStatus", "receivedDate", "paymentStatus", "paidAmount", "paymentMethod", "paymentReference", "paymentDate", "dueDate", "notes", "placeOfSupplyCode", "buyerUin", "buyerState", "buyerStateCode", "deliveryAddress", "deliveryState", "deliveryStateCode", "supplyValue", "sgstAmount", "utgst", "eInvoiceStatus", "irn", "ackNumber", "ackDate", "qrStatus", "signatureStatus", "eInvoiceDeclaration", "supplierEmail", "buyerPhone", "buyerEmail", "poReference", "documentCopy", "totalTax", "amountPayable", "amountInWords", "bankName", "bankAccount", "bankIfsc", "bankBranch", "upiType", "upiId", "paymentQrStatus", "terms", "signatory", "expectedDeliveryDate", "shippingTerms", "paymentTerms", "documentTitle", "originalInvoiceDate", "printedTotalItems", "printedTotalQuantity", "printedTaxRate", "printedCgstRate", "printedSgstRate", "printedUtgstRate", "printedIgstRate", "printedPaymentMark", "printedFooter", "printedSignatoryLabel", "printedCompanyLabel", "printedDeclaration", "billOfSupplyReason", "supplyNature", "buyerRegistration", "exemptValue"]);
const purchaseDraftGoodsExtraKeys = new Set(["hsn", "barcode", "freeQuantity", "batch", "expiry", "mrp", "sellingPrice", "discount", "gstRate", "cess", "lineTotal", "receivedQuantity", "damagedQuantity", "shortQuantity", "unitCode", "taxableValue", "cgstRate", "cgst", "sgstRate", "sgst", "utgstRate", "utgst", "igstRate", "igst", "cessRate", "specifications", "taxAmount", "printedSerial"]);
const purchaseDraftPrintedTaxKeys = new Set(["label", "hsn", "taxableValue", "cgstRate", "cgst", "sgstRate", "sgst", "utgstRate", "utgst", "igstRate", "igst", "cessRate", "cess", "taxRate", "totalTax"]);

function purchaseTextMap(raw: unknown, allowed: ReadonlySet<string>, maximum: number | ((key: string) => number)):
  Readonly<Record<string, string>> {
  const values = purchaseEntryObject(raw), result: Record<string, string> = {};
  for (const [key, value] of Object.entries(values)) {
    if (!allowed.has(key)) purchaseEntryError();
    result[key] = string(value, typeof maximum === 'number' ? maximum : maximum(key), true);
  }
  return result;
}
export function checkedPurchaseEntryDraft(raw: unknown): PurchaseEntryDraft {
  const v = purchaseEntryExact(raw, ['id', 'supplierId', 'invoiceReference', 'invoiceDate', 'createdAt', 'updatedAt', 'source', 'stage', 'goods'],
    ['details', 'attachments', 'additionalFields', 'printedTaxRows']);
  purchaseEntryId(v.id); purchaseEntryId(v.supplierId); string(v.invoiceReference, 120, true); string(v.invoiceDate, 10, true);
  if (v.source !== 'manual' || v.stage !== 'draft' || purchaseEntryMicros(v.updatedAt) < purchaseEntryMicros(v.createdAt) || !Array.isArray(v.goods)) purchaseEntryError();
  const goodsAllowed = new Set(['productId', 'name', 'pack', 'quantity', 'cost', ...purchaseDraftGoodsExtraKeys]);
  for (const row of v.goods) {
    const values = purchaseTextMap(row, goodsAllowed, key => key === 'specifications' ? 1000 : 200);
    if (!['productId', 'name', 'pack', 'quantity', 'cost'].every(key => Object.hasOwn(values, key))) purchaseEntryError();
  }
  if (Object.hasOwn(v, 'details')) purchaseTextMap(v.details, purchaseDraftDetailKeys, key => key === 'terms' ? 4000 : 500);
  const tax = Object.hasOwn(v, 'printedTaxRows') ? v.printedTaxRows : [];
  if (!Array.isArray(tax) || tax.length > 100) purchaseEntryError();
  for (const row of tax) purchaseTextMap(row, purchaseDraftPrintedTaxKeys, 200);
  const attachments = Object.hasOwn(v, 'attachments') ? v.attachments : [];
  if (!Array.isArray(attachments) || attachments.length > 3) purchaseEntryError();
  let bytes = 0; const attachmentDigests = new Set<string>();
  for (const row of attachments) {
    // This is only a declared local reference. The planner refuses a new file
    // save until the separate private-original service can confirm real bytes.
    const attachment = purchaseEntryObject(row), digest = purchaseEntryFingerprint(attachment.digest);
    if (attachmentDigests.has(digest) || !Number.isSafeInteger(attachment.byteLength) ||
        (attachment.byteLength as number) <= 0 || (attachment.byteLength as number) > 10 * 1024 * 1024) purchaseEntryError();
    bytes += attachment.byteLength as number; attachmentDigests.add(digest);
  }
  if (bytes > 20 * 1024 * 1024) purchaseEntryError();
  const additional = Object.hasOwn(v, 'additionalFields') ? v.additionalFields : [];
  if (!Array.isArray(additional) || additional.length > 200) purchaseEntryError();
  const ids = new Set<string>(); let textSize = 0;
  for (const row of additional) {
    const field = purchaseEntryExact(row, ['version', 'id', 'label', 'value', 'section', 'reviewed'],
      ['itemIndex', 'summaryIndex', 'sourceDigest', 'sourcePage', 'sourceItemIndex']);
    const id = string(field.id, 200), label = string(field.label, 120), value = string(field.value, 4000, true);
    if (field.version !== 1 || typeof field.reviewed !== 'boolean' || ids.has(id) ||
        !['supplier', 'invoice', 'items', 'tax', 'buyer', 'receipt', 'payment'].includes(field.section as string)) purchaseEntryError();
    ids.add(id); textSize += label.length + value.length;
    if (field.itemIndex !== undefined && (field.section !== 'items' || !Number.isSafeInteger(field.itemIndex) ||
        (field.itemIndex as number) < 0 || (field.itemIndex as number) >= v.goods.length)) purchaseEntryError();
    if (field.summaryIndex !== undefined && (field.section !== 'tax' || !Number.isSafeInteger(field.summaryIndex) ||
        (field.summaryIndex as number) < 0 || (field.summaryIndex as number) >= tax.length)) purchaseEntryError();
    if (field.sourceDigest !== undefined && !attachmentDigests.has(purchaseEntryFingerprint(field.sourceDigest))) purchaseEntryError();
    if (field.sourceItemIndex !== undefined && (field.section !== 'items' || field.sourceDigest === undefined ||
        !Number.isSafeInteger(field.sourceItemIndex) || (field.sourceItemIndex as number) < 0)) purchaseEntryError();
    if (field.sourcePage !== undefined && (field.sourceDigest === undefined || !Number.isSafeInteger(field.sourcePage) ||
        (field.sourcePage as number) < 1 || (field.sourcePage as number) > 10000)) purchaseEntryError();
  }
  if (textSize > 48000 || Buffer.byteLength(purchaseEntryCanonical(v), 'utf8') > 10 * 1024 * 1024) purchaseEntryError();
  return purchaseEntryClone(v) as PurchaseEntryDraft;
}
export function checkedPurchaseEntryCopy(raw: unknown, fresh: boolean): PurchaseEntryCopy {
  const v = purchaseEntryExact(raw, ['id', 'storeName', 'revision', 'savedAt', 'supplier', 'draft', 'labels']);
  string(v.id, 240); string(v.storeName, 200); purchaseEntryRevision(v.revision);
  const supplier = checkedPurchaseEntrySupplier(v.supplier), draft = checkedPurchaseEntryDraft(v.draft), labels = purchaseEntryObject(v.labels);
  if (supplier.id !== draft.supplierId || Object.keys(labels).length > 200) purchaseEntryError();
  for (const [key, value] of Object.entries(labels)) {string(key, 120); string(value, 200);}
  if (fresh) {
    if (purchaseEntryMicros(v.savedAt) < purchaseEntryMicros(draft.updatedAt)) purchaseEntryError();
  } else {
    // Historical zone-less captures are preserved, never interpreted as the
    // server/device timezone. Duplicate identity uses printed invoice date.
    string(v.savedAt, 100);
  }
  return purchaseEntryClone(v) as PurchaseEntryCopy;
}
export function purchaseEntryInvoiceFinancialYear(raw: string): number | null {
  const indian = /^(\d{2})\/(\d{2})\/(\d{4})$/u.exec(raw.trim()), iso = /^(\d{4})-(\d{2})-(\d{2})$/u.exec(raw.trim());
  if (!indian && !iso) return null;
  const year = Number(indian?.[3] ?? iso![1]), month = Number(indian?.[2] ?? iso![2]), day = Number(indian?.[1] ?? iso![3]);
  if (year < 1900 || year > 9999 || month < 1 || month > 12 || day < 1) return null;
  const date = new Date(Date.UTC(year, month - 1, day));
  return date.getUTCFullYear() === year && date.getUTCMonth() === month - 1 && date.getUTCDate() === day ? year - (month < 4 ? 1 : 0) : null;
}
export function purchaseEntryDraftCommandFingerprint(input: Omit<PurchaseEntryDraftCommand, 'fingerprint'>): string {
  return purchaseEntryHash({schemaVersion: 1, operation: 'savePurchaseDraft', ...input});
}
export function purchaseEntrySaveOperation(command: PurchaseEntrySaveCommand): 'saveSupplierProfile' | 'savePurchaseDraft' {
  return 'draft' in command ? 'savePurchaseDraft' : 'saveSupplierProfile';
}
export function purchaseEntrySaveFingerprint(command: PurchaseEntrySaveCommand): string {
  const {fingerprint: _, ...input} = command;
  return 'draft' in input ? purchaseEntryDraftCommandFingerprint(input as Omit<PurchaseEntryDraftCommand, 'fingerprint'>) : purchaseEntryCommandFingerprint(input);
}
export function purchaseEntryDraftReceiptFields(command: PurchaseEntrySaveCommand): Pick<PurchaseEntryReceipt, 'draftId' | 'draftFingerprint' | 'copyId' | 'copyFingerprint'> {
  if (!('draft' in command)) return {};
  return {draftId: command.draft.id, draftFingerprint: purchaseEntryHash(command.draft), copyId: command.reviewedCopy?.id ?? null,
    copyFingerprint: command.reviewedCopy === null ? null : purchaseEntryHash(command.reviewedCopy)};
}
export function planPurchaseEntryDraft(command: PurchaseEntryDraftCommand, original: PurchaseEntryBook | null):
  {book: PurchaseEntryBook; profile: PurchaseEntrySupplier; changed: boolean} {
  const scope = checkedPurchaseEntryScope(command.scope), profile = checkedPurchaseEntrySupplier(command.profile),
    draft = checkedPurchaseEntryDraft(command.draft), copy = command.reviewedCopy === null ? null : checkedPurchaseEntryCopy(command.reviewedCopy, true),
    current = original === null ? null : checkedPurchaseEntryBook(original, scope);
  if (draft.supplierId !== profile.id || copy && (purchaseEntryCanonical(copy.supplier) !== purchaseEntryCanonical(profile) ||
      purchaseEntryCanonical(copy.draft) !== purchaseEntryCanonical(draft))) purchaseEntryError();
  let copies: PurchaseEntryCopy[], oldDraft: PurchaseEntryDraft | null;
  try {
    copies = (current?.copies ?? []).map(row => checkedPurchaseEntryCopy(row, false));
    oldDraft = current?.draft === null || current === null ? null : checkedPurchaseEntryDraft(current.draft);
  } catch {return purchaseEntryError('service_unavailable', 503);}
  const existing = copy === null ? undefined : copies.find(row => row.id === copy.id);
  if (existing) {
    if (purchaseEntryCanonical(existing) !== purchaseEntryCanonical(copy)) purchaseEntryError('immutable_copy_conflict', 409);
    // Existing immutable evidence is acknowledged without rolling current
    // contacts/draft back or regenerating its capture under a different key.
    return {book: current!, profile, changed: false};
  }
  if (command.expectedRevision !== (current?.revision ?? null)) purchaseEntryError('stale_book', 409);
  const latest = new Map<string, PurchaseEntryCopy[]>();
  for (const item of copies) {
    const group = latest.get(item.draft.id);
    if (!group || item.revision > group[0]!.revision) latest.set(item.draft.id, [item]);
    else if (item.revision === group[0]!.revision) group.push(item);
  }
  const reviewed = oldDraft === null ? [] : latest.get(oldDraft.id) ?? [];
  const replace = command.replaceReviewedDraftId !== null && oldDraft?.id === command.replaceReviewedDraftId &&
    reviewed.length === 1 && purchaseEntryCanonical(reviewed[0]!.draft) === purchaseEntryCanonical(oldDraft) && draft.id !== oldDraft.id;
  if (replace && latest.has(draft.id)) purchaseEntryError('stale_draft', 409);
  if (command.replaceReviewedDraftId !== null && !replace || oldDraft && !replace &&
      (oldDraft.id !== draft.id || purchaseEntryMicros(oldDraft.createdAt) !== purchaseEntryMicros(draft.createdAt))) purchaseEntryError('stale_draft', 409);
  const base = planPurchaseEntrySupplier(command, current, true).book;
  if ((draft.attachments?.length ?? 0) > 0) purchaseEntryError('private_original_unavailable', 409);
  if (copy) {
    const year = purchaseEntryInvoiceFinancialYear(draft.invoiceDate), reference = draft.invoiceReference.trim().toLowerCase();
    if (!reference || year === null || !draft.goods.some(row => row.name!.trim()) || copy.revision !== (current?.revision ?? 0) + 1) purchaseEntryError('incomplete_reviewed_copy', 409);
    if (copies.length >= 1000) purchaseEntryError('capacity_exceeded', 409);
    if ([...latest.values()].flat().some(row => row.draft.id !== draft.id && row.draft.supplierId === draft.supplierId &&
        purchaseEntryInvoiceFinancialYear(row.draft.invoiceDate) === year && row.draft.invoiceReference.trim().toLowerCase() === reference)) purchaseEntryError('duplicate_invoice', 409);
  }
  const candidate = {...base, revision: (current?.revision ?? 0) + 1, draft,
    ...(copy === null ? {} : {copies: [...copies, copy]})};
  if (!Number.isSafeInteger(candidate.revision) || Buffer.byteLength(purchaseEntryCanonical(candidate), 'utf8') > 10 * 1024 * 1024) purchaseEntryError('capacity_exceeded', 409);
  return {book: checkedPurchaseEntryBook(candidate, scope), profile, changed: true};
}
/** Supplier candidate producer. It receives the server's original book, never a
 * replacement book supplied by a client or inferred from a native diff. */
export function planPurchaseEntrySupplier(command: PurchaseEntrySupplierCommand, original: PurchaseEntryBook | null, deferCapacityForDraft = false):
  {book: PurchaseEntryBook; profile: PurchaseEntrySupplier; changed: boolean} {
  const scope = checkedPurchaseEntryScope(command.scope), p = checkedPurchaseEntrySupplier(command.profile),
    current = original === null ? null : checkedPurchaseEntryBook(original, scope);
  if (command.expectedRevision !== (current?.revision ?? null)) purchaseEntryError('stale_book', 409);
  const previous = current?.profiles.find(profile => profile.id === p.id);
  if (previous && sameNativeSupplier(previous, p)) {
    return {book: current!, profile: purchaseEntryClone(p), changed: false};
  }
  if (previous && (purchaseEntryMicros(previous.createdAt) !== purchaseEntryMicros(p.createdAt) || purchaseEntryMicros(p.updatedAt) < purchaseEntryMicros(previous.updatedAt))) {
    purchaseEntryError('stale_book', 409);
  }
  if (current?.profiles.some(other => other.id !== p.id && (p.phone && other.phone === p.phone || p.gstin && other.gstin === p.gstin))) {
    purchaseEntryError('duplicate_supplier', 409);
  }
  if (!previous && (current?.profiles.length ?? 0) >= 10000) purchaseEntryError('capacity_exceeded', 409);
  const base = current ?? {version: 1 as const, account: scope.account, store: scope.store, qa: false,
    revision: 0, profiles: [], draft: null};
  if (!Number.isSafeInteger(base.revision + 1)) purchaseEntryError('capacity_exceeded', 409);
  const candidate = {...base, revision: base.revision + 1, profiles: [...base.profiles.filter(profile => profile.id !== p.id), p]};
  if (!deferCapacityForDraft && Buffer.byteLength(purchaseEntryCanonical(candidate), 'utf8') > 10 * 1024 * 1024) purchaseEntryError('capacity_exceeded', 409);
  const book = deferCapacityForDraft ? purchaseEntryClone(candidate) : checkedPurchaseEntryBook(candidate, scope);
  return {book, profile: purchaseEntryClone(p), changed: true};
}
export function checkedPurchaseEntryReceipt(raw: unknown, scope: PurchaseEntryScope, key: string, fingerprint: string): PurchaseEntryReceipt {
  const operation = purchaseEntryObject(raw).operation;
  const r = purchaseEntryExact(raw, ['schemaVersion', 'scope', 'operation', 'idempotencyKey', 'fingerprint',
    'status', 'reason', 'changed', 'resultRevision', 'profile', 'recordedAt',
    ...(operation === 'savePurchaseDraft' ? ['draftId', 'draftFingerprint', 'copyId', 'copyFingerprint'] : [])]);
  if (r.schemaVersion !== 1 || !['saveSupplierProfile', 'savePurchaseDraft'].includes(r.operation as string) || r.idempotencyKey !== key ||
      r.fingerprint !== fingerprint || purchaseEntryCanonical(checkedPurchaseEntryScope(r.scope)) !== purchaseEntryCanonical(scope) ||
      typeof r.changed !== 'boolean') purchaseEntryError('service_unavailable', 503);
  if (r.status === 'saved') {
    if (r.reason !== null) purchaseEntryError('service_unavailable', 503);
    purchaseEntryRevision(r.resultRevision);
  } else if (r.status === 'not_saved') {
    if (r.changed !== false || typeof r.reason !== 'string' ||
        !purchaseEntryTerminalReasons(operation === 'savePurchaseDraft').includes(r.reason)) purchaseEntryError('service_unavailable', 503);
    if (r.resultRevision !== null) purchaseEntryRevision(r.resultRevision);
  } else purchaseEntryError('service_unavailable', 503);
  purchaseEntryMicros(r.recordedAt);
  if (operation === 'savePurchaseDraft') {
    purchaseEntryId(r.draftId); purchaseEntryFingerprint(r.draftFingerprint);
    if (r.copyId === null) {
      if (r.copyFingerprint !== null) purchaseEntryError('service_unavailable', 503);
    } else {purchaseEntryId(r.copyId); purchaseEntryFingerprint(r.copyFingerprint);}
  }
  return {...r, profile: checkedPurchaseEntrySupplier(r.profile)} as unknown as PurchaseEntryReceipt;
}
export function purchaseEntryTerminalReasons(draft: boolean): readonly string[] {
  return ['stale_book', 'duplicate_supplier', 'capacity_exceeded', ...(draft ?
    ['stale_draft', 'immutable_copy_conflict', 'incomplete_reviewed_copy', 'duplicate_invoice', 'private_original_unavailable'] : [])];
}
const common = ['schemaVersion', 'purchaseEntryVersion', 'actorAccountId', 'realm', 'storeId'];
export function purchaseEntryOperation(operation: string): 'read' | 'saveSupplier' | 'savePurchaseDraft' | 'status' | undefined {
  if (operation === 'readStorePurchaseEntryBook') return 'read';
  if (operation === 'saveStoreSupplierProfile') return 'saveSupplier';
  if (operation === 'saveStorePurchaseDraft') return 'savePurchaseDraft';
  if (operation === 'readStorePurchaseEntryAttempt') return 'status';
  return undefined;
}
export class WorkspacePurchaseEntryService {
  constructor(private readonly repository?: PurchaseEntryRepository, private readonly now: () => Date = () => new Date()) {}
  async handle(actor: PurchaseEntryActor, operation: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    const method = purchaseEntryOperation(operation);
    if (!method) purchaseEntryError();
    return this[method](actor, body);
  }
  private scope(actor: PurchaseEntryActor, body: Readonly<Record<string, unknown>>): PurchaseEntryScope {
    if (!this.repository) purchaseEntryError('service_unavailable', 503);
    if (!actor || actor.tenantId !== undefined || !actor.uid || !actor.projectId || actor.projectId !== this.repository.projectId ||
        body.actorAccountId !== actor.uid || body.realm !== this.repository.realm || body.schemaVersion !== 1 || body.purchaseEntryVersion !== 1) {
      purchaseEntryError('permission_denied', 403);
    }
    return {account: purchaseEntryId(actor.uid), store: purchaseEntryId(body.storeId), realm: this.repository.realm};
  }
  private response(scope: PurchaseEntryScope, result: PurchaseEntryResult, key?: string, fingerprint?: string): object {
    const book = result.currentBook === null ? null : checkedPurchaseEntryBook(result.currentBook, scope);
    const receipt = result.receipt === null ? null : checkedPurchaseEntryReceipt(result.receipt, scope, key!, fingerprint!);
    if (receipt?.status === 'saved' && (!book || receipt.resultRevision === null) ||
        receipt?.resultRevision !== null && receipt?.resultRevision !== undefined && (!book || book.revision < receipt.resultRevision)) {
      purchaseEntryError('service_unavailable', 503);
    }
    return {schemaVersion: 1, purchaseEntryVersion: 1, actorAccountId: scope.account, realm: scope.realm, storeId: scope.store,
      observedAt: this.now().toISOString(), state: book === null ? 'empty' : 'ready',
      bookJson: book === null ? null : purchaseEntryCanonical(book),
      bookFingerprint: book === null ? null : purchaseEntryHash(book), attempt: receipt};
  }
  async read(actor: PurchaseEntryActor, body: Readonly<Record<string, unknown>>): Promise<object> {
    purchaseEntryExact(body, common); const scope = this.scope(actor, body);
    return this.response(scope, {currentBook: await this.repository!.read(actor, scope), receipt: null});
  }
  async saveSupplier(actor: PurchaseEntryActor, body: Readonly<Record<string, unknown>>): Promise<object> {
    purchaseEntryExact(body, [...common, 'expectedRevision', 'idempotencyKey', 'fingerprint', 'profile']);
    const scope = this.scope(actor, body), profile = checkedPurchaseEntrySupplier(body.profile),
      expectedRevision = body.expectedRevision === null ? null : purchaseEntryRevision(body.expectedRevision),
      idempotencyKey = purchaseEntryId(body.idempotencyKey), fingerprint = purchaseEntryFingerprint(body.fingerprint);
    const command = {scope, profile, expectedRevision, idempotencyKey, fingerprint};
    if (fingerprint !== purchaseEntryCommandFingerprint({scope, profile, expectedRevision, idempotencyKey})) purchaseEntryError();
    const result = await this.repository!.saveSupplier(actor, command);
    if (!result.receipt || result.receipt.operation !== 'saveSupplierProfile' || purchaseEntryCanonical(result.receipt.profile) !== purchaseEntryCanonical(profile)) purchaseEntryError('service_unavailable', 503);
    return this.response(scope, result, idempotencyKey, fingerprint);
  }
  async savePurchaseDraft(actor: PurchaseEntryActor, body: Readonly<Record<string, unknown>>): Promise<object> {
    purchaseEntryExact(body, [...common, 'expectedRevision', 'idempotencyKey', 'fingerprint', 'profile', 'draft', 'reviewedCopy', 'replaceReviewedDraftId']);
    const scope = this.scope(actor, body);
    if (!this.repository!.savePurchaseDraft) purchaseEntryError('service_unavailable', 503);
    const profile = checkedPurchaseEntrySupplier(body.profile), draft = checkedPurchaseEntryDraft(body.draft),
      reviewedCopy = body.reviewedCopy === null ? null : checkedPurchaseEntryCopy(body.reviewedCopy, true),
      replaceReviewedDraftId = body.replaceReviewedDraftId === null ? null : purchaseEntryId(body.replaceReviewedDraftId),
      expectedRevision = body.expectedRevision === null ? null : purchaseEntryRevision(body.expectedRevision),
      idempotencyKey = purchaseEntryId(body.idempotencyKey), fingerprint = purchaseEntryFingerprint(body.fingerprint);
    const command = {scope, profile, draft, reviewedCopy, replaceReviewedDraftId, expectedRevision, idempotencyKey, fingerprint};
    if (fingerprint !== purchaseEntryDraftCommandFingerprint({scope, profile, draft, reviewedCopy, replaceReviewedDraftId, expectedRevision, idempotencyKey})) purchaseEntryError();
    const result = await this.repository!.savePurchaseDraft(actor, command), receipt = result.receipt,
      ids = purchaseEntryDraftReceiptFields(command);
    if (!receipt || receipt.operation !== 'savePurchaseDraft' || purchaseEntryCanonical(receipt.profile) !== purchaseEntryCanonical(profile) ||
        Object.entries(ids).some(([key, value]) => receipt[key as keyof PurchaseEntryReceipt] !== value)) purchaseEntryError('service_unavailable', 503);
    return this.response(scope, result, idempotencyKey, fingerprint);
  }
  async status(actor: PurchaseEntryActor, body: Readonly<Record<string, unknown>>): Promise<object> {
    purchaseEntryExact(body, [...common, 'idempotencyKey', 'fingerprint']); const scope = this.scope(actor, body),
      key = purchaseEntryId(body.idempotencyKey), fingerprint = purchaseEntryFingerprint(body.fingerprint);
    return this.response(scope, await this.repository!.status(actor, scope, key, fingerprint), key, fingerprint);
  }
}
