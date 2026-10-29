import {
  checkedPurchaseEntryScope, checkedPurchaseEntryOpening, purchaseEntryCanonical, purchaseEntryClone,
  purchaseEntryExact, purchaseEntryFingerprint,
  purchaseEntryHash, purchaseEntryId, purchaseEntryMicros, purchaseEntryRevision,
  type PurchaseEntryActor, type PurchaseEntryScope, type PurchaseEntryOpeningRecord, type PurchaseEntryOpeningBill,
} from './workspace_purchase_entry_service.js';
import {WorkspaceProfileError} from './workspace_profile_service.js';

/** Original owner-recorded sections only; never a replacement finance snapshot. */
export type LedgerScope = PurchaseEntryScope;
export type LedgerActor = PurchaseEntryActor;
export type LedgerKind = 'supplierLedger' | 'expense' | 'moneyRegister' | 'moneyEntry';
export type LedgerOperation = 'recordStoreExpense' | 'confirmStoreSupplierOpening' | 'recordStoreMoneyRegisterEntry';
export interface LedgerExpense {
  account: string; store: string; operationId: string; amountMinor: number;
  category: string; method: string; reference: string; note: string; occurredAt: string;
}
export type LedgerOpeningBill = PurchaseEntryOpeningBill;
export type LedgerOpeningRecord = PurchaseEntryOpeningRecord;
export interface LedgerRegisterEntry {id: string; reference: string; occurredAt: string; deltaMinor: number}
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
export type LedgerCommand = LedgerExpenseCommand | LedgerOpeningCommand | LedgerRegisterCommand;
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
}

const kinds: readonly LedgerKind[] = ['supplierLedger', 'expense', 'moneyRegister', 'moneyEntry'];
const operations: readonly LedgerOperation[] = ['recordStoreExpense', 'confirmStoreSupplierOpening', 'recordStoreMoneyRegisterEntry'];
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
  }
}
export function ledgerCommandTarget(command: LedgerCommand): {kind: Exclude<LedgerKind, 'moneyEntry'>; id: string; entryId: string | null} {
  switch (command.operation) {
    case 'recordStoreExpense': return {kind: 'expense', id: command.expense.operationId, entryId: null};
    case 'confirmStoreSupplierOpening': return {kind: 'supplierLedger', id: command.opening.supplierId, entryId: null};
    case 'recordStoreMoneyRegisterEntry': return {kind: 'moneyRegister', id: command.registerId, entryId: command.entry.id};
  }
}
export function ledgerCommandFingerprint(command: Omit<LedgerExpenseCommand, 'fingerprint'> |
  Omit<LedgerOpeningCommand, 'fingerprint'> | Omit<LedgerRegisterCommand, 'fingerprint'>): string {
  return ledgerHash(command);
}
export function checkedLedgerCommand(raw: unknown): LedgerCommand {
  const value = raw as Record<string, unknown>;
  if (!value || !operations.includes(value.operation as LedgerOperation)) ledgerError();
  const fields = value.operation === 'recordStoreExpense' ? ['expense'] : value.operation === 'confirmStoreSupplierOpening'
    ? ['opening', 'expectedPurchaseRevision', 'expectedPurchaseFingerprint', 'confirmedAt', 'confirmedUtcOffsetMinutes']
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
  const kind = operation === 'recordStoreExpense' ? 'expense' : operation === 'confirmStoreSupplierOpening' ? 'supplierLedger' : 'moneyRegister';
  if (v.targetKind !== kind || (operation === 'recordStoreMoneyRegisterEntry' ? typeof v.entryId !== 'string' || !v.entryId.trim() : v.entryId !== null) ||
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
      : ['registerId', 'expectedRegisterRevision', 'entry', 'capturedAt'];
    ledgerExact(body, [...saveKeys, ...specific]); const scope = this.scope(actor, body);
    const command = checkedLedgerCommand({scope, operation, expectedRevision: body.expectedRevision,
      idempotencyKey: body.idempotencyKey, fingerprint: body.fingerprint,
      ...Object.fromEntries(specific.map(key => [key, body[key]]))});
    const result = command.operation === 'recordStoreExpense' ? await this.repository!.recordExpense(actor, command)
      : command.operation === 'confirmStoreSupplierOpening' ? await this.repository!.confirmOpening(actor, command)
      : await this.repository!.recordRegisterEntry(actor, command);
    if (result.receipt) checkedLedgerReceipt(result.receipt, scope, command.idempotencyKey, command.fingerprint);
    return this.statusFrame(scope, result, command);
  }
}
