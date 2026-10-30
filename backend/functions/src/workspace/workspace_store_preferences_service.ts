import {createHash} from 'node:crypto';
import type {DocumentReference, Firestore, Transaction} from 'firebase-admin/firestore';
import type {PurchaseEntryTransactionAuthority} from './workspace_purchase_entry_repository.js';
import {checkedPurchaseEntryScope, purchaseEntryCanonical, purchaseEntryClone,
  purchaseEntryExact, purchaseEntryHash, purchaseEntryId, purchaseEntryFingerprint,
  type PurchaseEntryActor, type PurchaseEntryRealm, type PurchaseEntryScope} from './workspace_purchase_entry_service.js';
import {WorkspaceProfileError} from './workspace_profile_service.js';

/** Only private inputs to the four existing native forms. These records grant
 * no membership, listing, order acceptance or invoice-dispatch authority. */
export type StorePrivatePreferenceKind = 'status' | 'pickup' | 'invoice' | 'staff';
export type StorePrivatePreferenceFields = Readonly<Record<string, string | boolean>>;
export const storePrivatePreferenceActions = new Map<string, StorePrivatePreferenceKind>([
  ['AI-ACT-318', 'status'], ['AI-ACT-319', 'status'], ['AI-ACT-322', 'pickup'],
  ['AI-ACT-323', 'invoice'], ['AI-ACT-326', 'staff'], ['AI-ACT-327', 'status'],
]);
export function storePrivatePreferenceProposalKeys(action: string): readonly string[] {
  if (action === 'AI-ACT-318') return ['acceptingOrders', 'fulfilmentMode', 'busyMinutes', 'reopensAt'];
  if (action === 'AI-ACT-319') return ['openingTime', 'closingTime', 'maximumActiveOrders', 'alertSound', 'alertVibration', 'preparationMinutes', 'fulfilmentPreference'];
  if (action === 'AI-ACT-322') return ['city', 'area', 'pincode', 'pickupEnabled'];
  if (action === 'AI-ACT-323') return ['mode'];
  if (action === 'AI-ACT-326') return ['staffAccessEnabled', 'counterCount'];
  if (action === 'AI-ACT-327') return ['visibleToCustomers'];
  fail();
}
const groupKeys = {
  status: ['acceptingOrders', 'visibleToCustomers', 'fulfilmentMode', 'busyMinutes', 'reopensAt',
    'openingTime', 'closingTime', 'maximumActiveOrders', 'alertSound', 'alertVibration'],
  pickup: ['city', 'area', 'pincode', 'pickupEnabled'],
  invoice: ['mode'], staff: ['staffAccessEnabled', 'counterCount'],
} as const;
const booleanKeys = new Set(['acceptingOrders', 'visibleToCustomers', 'alertSound', 'alertVibration', 'pickupEnabled', 'staffAccessEnabled']);
const integerKeys = new Set(['busyMinutes', 'maximumActiveOrders', 'counterCount']);
const maxInt = 9223372036854775807n, maxBytes = 8 * 1024 * 1024, partBytes = 192 * 1024;
const equal = (a: unknown, b: unknown) => purchaseEntryCanonical(a) === purchaseEntryCanonical(b);
const bytesHash = (v: Buffer) => createHash('sha256').update(v).digest('hex');
function fail(code = 'invalid_input', status = 400): never {
  throw new WorkspaceProfileError(code, 'Check the original Store preferences and account/Store context. Your entries are kept.', status);
}
export function storePreferenceInteger(raw: unknown): string {
  if (typeof raw !== 'string' || !/^(0|[1-9]\d*)$/u.test(raw) || raw.length > 19 || BigInt(raw) > maxInt) fail();
  return raw;
}
function text(raw: unknown): string {
  if (typeof raw !== 'string' || /[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]/u.test(raw) ||
      Buffer.from(raw, 'utf8').toString('utf8') !== raw) fail();
  return raw;
}
// Dart String.trim includes NEL; JavaScript trim alone does not.
const dartTrim = (raw: string) => raw.replace(/^[\s\u0085]+|[\s\u0085]+$/gu, '');
/** Match the existing partial native prefill contract; final complete-form
 * validation remains native. No defaults or unspecified keys are introduced. */
export function checkedStorePrivatePreferenceProposalFields(action: string, raw: unknown): StorePrivatePreferenceFields {
  const keys = storePrivatePreferenceProposalKeys(action), fields = purchaseEntryExact(raw, [], keys);
  if (!Object.keys(fields).length) fail();
  for (const [key, value] of Object.entries(fields)) {
    if (booleanKeys.has(key)) {if (typeof value !== 'boolean') fail();}
    else if (integerKeys.has(key) || key === 'preparationMinutes') {
      const n = BigInt(storePreferenceInteger(value)); if (key === 'counterCount' && (n < 1n || n > 20n)) fail();
    } else {
      const literal = text(value); if (literal.length > 2000) fail();
      if (['openingTime', 'closingTime'].includes(key) &&
          !/^(?:(?:[01]?\d|2[0-3]):[0-5]\d|(?:0?[1-9]|1[0-2]):[0-5]\d\s*[AP]M)$/iu.test(dartTrim(literal))) fail();
      if (['fulfilmentMode', 'fulfilmentPreference'].includes(key) && !['Delivery and pickup', 'Pickup only', 'Delivery only'].includes(literal)) fail();
      if (key === 'mode' && !['off', 'automatic', 'whatsapp', 'moolSocialChat'].includes(literal)) fail();
    }
  }
  return purchaseEntryClone(fields) as StorePrivatePreferenceFields;
}
export function checkedStorePrivatePreferenceKind(raw: unknown): StorePrivatePreferenceKind {
  if (typeof raw !== 'string' || !Object.hasOwn(groupKeys, raw)) fail();
  return raw as StorePrivatePreferenceKind;
}
export function checkedStorePrivatePreferenceFields(kind: StorePrivatePreferenceKind, raw: unknown): StorePrivatePreferenceFields {
  const v = purchaseEntryExact(raw, groupKeys[kind]);
  for (const [key, value] of Object.entries(v)) {
    if (booleanKeys.has(key)) { if (typeof value !== 'boolean') fail(); }
    else if (integerKeys.has(key)) {
      const n = BigInt(storePreferenceInteger(value));
      if (key === 'counterCount' && (n < 1n || n > 20n)) fail();
    } else {
      const s = text(value);
      if (['openingTime', 'closingTime'].includes(key) &&
          !/^(?:(?:[01]?\d|2[0-3]):[0-5]\d|(?:0?[1-9]|1[0-2]):[0-5]\d\s*[AP]M)$/iu.test(dartTrim(s))) fail();
      if (key === 'fulfilmentMode' && !['Delivery and pickup', 'Pickup only', 'Delivery only'].includes(s)) fail();
      if (['city', 'area'].includes(key) && !dartTrim(s)) fail();
      if (key === 'pincode' && !/^[1-9]\d{5}$/u.test(s)) fail();
      if (key === 'mode' && !['off', 'automatic', 'whatsapp', 'moolSocialChat'].includes(s)) fail();
    }
  }
  // Reserve framing for the maximum existing account/Store/project/request IDs.
  // This is a transport budget, not a limit on any native business number.
  if (Buffer.byteLength(purchaseEntryCanonical(v), 'utf8') > maxBytes - 128 * 1024) fail();
  return purchaseEntryClone(v) as StorePrivatePreferenceFields;
}
export interface StorePrivatePreferenceRecord {
  version: 1; projectId: string; scope: PurchaseEntryScope; kind: StorePrivatePreferenceKind;
  revision: string; fields: StorePrivatePreferenceFields;
}
export interface StorePrivatePreferenceCommand {
  version: 1; projectId: string; scope: PurchaseEntryScope; kind: StorePrivatePreferenceKind;
  expectedRevision: string; idempotencyKey: string; fields: StorePrivatePreferenceFields; fingerprint: string;
}
export function storePrivatePreferenceCommandFingerprint(command: Omit<StorePrivatePreferenceCommand, 'fingerprint'>): string {
  return purchaseEntryHash(command);
}
export function checkedStorePrivatePreferenceCommand(raw: unknown): StorePrivatePreferenceCommand {
  const v = purchaseEntryExact(raw, ['version', 'projectId', 'scope', 'kind', 'expectedRevision', 'idempotencyKey', 'fields', 'fingerprint']);
  if (v.version !== 1) fail();
  const kind = checkedStorePrivatePreferenceKind(v.kind), base = {version: 1 as const,
    projectId: purchaseEntryId(v.projectId), scope: checkedPurchaseEntryScope(v.scope), kind,
    expectedRevision: storePreferenceInteger(v.expectedRevision), idempotencyKey: purchaseEntryId(v.idempotencyKey),
    fields: checkedStorePrivatePreferenceFields(kind, v.fields)};
  if (base.expectedRevision === maxInt.toString() || purchaseEntryFingerprint(v.fingerprint) !== storePrivatePreferenceCommandFingerprint(base)) fail();
  return {...base, fingerprint: v.fingerprint as string};
}
export function checkedStorePrivatePreferenceRecord(raw: unknown): StorePrivatePreferenceRecord {
  const v = purchaseEntryExact(raw, ['version', 'projectId', 'scope', 'kind', 'revision', 'fields']);
  if (v.version !== 1 || storePreferenceInteger(v.revision) === '0') fail('service_unavailable', 503);
  const kind = checkedStorePrivatePreferenceKind(v.kind);
  return {version: 1, projectId: purchaseEntryId(v.projectId), scope: checkedPurchaseEntryScope(v.scope), kind,
    revision: v.revision as string, fields: checkedStorePrivatePreferenceFields(kind, v.fields)};
}
interface Pointer {id: string; fingerprint: string; revision: string; byteLength: number; parts: number}
interface Receipt {
  version: 1; projectId: string; scope: PurchaseEntryScope; kind: StorePrivatePreferenceKind;
  idempotencyKey: string; fingerprint: string; expectedRevision: string;
  status: 'saved' | 'not_saved'; reason: 'stale_preferences' | null; input: Pointer; recordedAt: string;
}
export interface StorePrivatePreferenceResult {
  receipt: Receipt | null; original: StorePrivatePreferenceRecord | null; current: StorePrivatePreferenceRecord | null;
}

/** Closed four-group repository. Immutable staged inputs are not active records.
 * Only the original transaction membership port can authorize reads or writes. */
export class FirestoreStorePrivatePreferenceRepository {
  constructor(private readonly db: Firestore, readonly realm: PurchaseEntryRealm, readonly projectId: string,
    private readonly authority?: PurchaseEntryTransactionAuthority, private readonly now: () => Date = () => new Date()) {}
  private scope(actor: PurchaseEntryActor, raw: PurchaseEntryScope, kind: StorePrivatePreferenceKind): PurchaseEntryScope {
    const scope = checkedPurchaseEntryScope(raw); checkedStorePrivatePreferenceKind(kind);
    if (!actor || actor.uid !== scope.account || actor.projectId !== this.projectId || actor.tenantId !== undefined || scope.realm !== this.realm) fail('permission_denied', 403);
    if (!this.authority) fail('service_unavailable', 503);
    return scope;
  }
  private root(scope: PurchaseEntryScope, kind: StorePrivatePreferenceKind): DocumentReference {
    return this.db.collection('privateWorkspacePreferencesV1').doc(purchaseEntryHash({projectId: this.projectId, scope, kind}));
  }
  private attempt(scope: PurchaseEntryScope, kind: StorePrivatePreferenceKind, key: string): DocumentReference {
    return this.root(scope, kind).collection('attempts').doc(purchaseEntryHash({key: purchaseEntryId(key)}));
  }
  private pointer(raw: unknown): Pointer {
    const v = purchaseEntryExact(raw, ['id', 'fingerprint', 'revision', 'byteLength', 'parts']);
    const revision = storePreferenceInteger(v.revision);
    if (revision === '0' || !Number.isSafeInteger(v.byteLength) || (v.byteLength as number) < 1 || (v.byteLength as number) > maxBytes ||
        !Number.isSafeInteger(v.parts) || v.parts !== Math.ceil((v.byteLength as number) / partBytes)) fail('service_unavailable', 503);
    return {id: purchaseEntryFingerprint(v.id), fingerprint: purchaseEntryFingerprint(v.fingerprint), revision,
      byteLength: v.byteLength as number, parts: v.parts as number};
  }
  private async head(tx: Transaction, scope: PurchaseEntryScope, kind: StorePrivatePreferenceKind): Promise<Pointer | null> {
    const ref = this.root(scope, kind), snap = await tx.get(ref);
    if (!snap.exists) {
      if (!(await tx.get(ref.collection('attempts').where('status', '==', 'saved').limit(1))).empty) fail('service_unavailable', 503);
      return null;
    }
    const v = purchaseEntryExact(snap.data(), ['version', 'projectId', 'scope', 'kind', 'original']);
    if (v.version !== 1 || v.projectId !== this.projectId || !equal(v.scope, scope) || v.kind !== kind) fail('service_unavailable', 503);
    return this.pointer(v.original);
  }
  private authorizedHead(actor: PurchaseEntryActor, scope: PurchaseEntryScope, kind: StorePrivatePreferenceKind): Promise<Pointer | null> {
    return this.db.runTransaction(async tx => { await this.authority!.assertCurrent(tx, actor, scope); return this.head(tx, scope, kind); });
  }
  private manifest(scope: PurchaseEntryScope, kind: StorePrivatePreferenceKind, pointer: Pointer): Record<string, unknown> {
    return {version: 1, projectId: this.projectId, scope, kind, ...pointer};
  }
  private async original(scope: PurchaseEntryScope, kind: StorePrivatePreferenceKind, pointer: Pointer): Promise<StorePrivatePreferenceRecord> {
    const ref = this.root(scope, kind).collection('originals').doc(pointer.id), manifest = await ref.get();
    if (!manifest.exists || !equal(manifest.data(), this.manifest(scope, kind, pointer))) fail('service_unavailable', 503);
    const chunks: Buffer[] = [];
    for (let i = 0; i < pointer.parts; i += 16) {
      const refs = Array.from({length: Math.min(16, pointer.parts - i)}, (_, j) => ref.collection('parts').doc(String(i + j).padStart(5, '0')));
      const rows = await this.db.getAll(...refs);
      for (let j = 0; j < rows.length; j++) {
        const row = rows[j]; if (!row?.exists) fail('service_unavailable', 503);
        const p = purchaseEntryExact(row.data(), ['version', 'index', 'data', 'fingerprint']);
        if (p.version !== 1 || p.index !== i + j || typeof p.data !== 'string') fail('service_unavailable', 503);
        const data = Buffer.from(p.data, 'base64'), size = i + j === pointer.parts - 1 ? pointer.byteLength - partBytes * (i + j) : partBytes;
        if (data.length !== size || data.toString('base64') !== p.data || bytesHash(data) !== p.fingerprint) fail('service_unavailable', 503);
        chunks.push(data);
      }
    }
    const data = Buffer.concat(chunks), value = data.toString('utf8');
    if (data.length !== pointer.byteLength || bytesHash(data) !== pointer.fingerprint || !data.equals(Buffer.from(value, 'utf8'))) fail('service_unavailable', 503);
    let raw: unknown; try { raw = JSON.parse(value); } catch { fail('service_unavailable', 503); }
    const record = checkedStorePrivatePreferenceRecord(raw);
    if (record.projectId !== this.projectId || !equal(record.scope, scope) || record.kind !== kind || record.revision !== pointer.revision ||
        purchaseEntryHash(record) !== pointer.fingerprint || pointer.id !== purchaseEntryHash({scope, kind, revision: record.revision, fingerprint: pointer.fingerprint})) fail('service_unavailable', 503);
    return record;
  }
  async read(actor: PurchaseEntryActor, raw: PurchaseEntryScope, kind: StorePrivatePreferenceKind): Promise<StorePrivatePreferenceRecord | null> {
    const scope = this.scope(actor, raw, kind), before = await this.authorizedHead(actor, scope, kind);
    const record = before === null ? null : await this.original(scope, kind, before);
    if (!equal(before, await this.authorizedHead(actor, scope, kind))) fail('stale_preferences', 409);
    return record;
  }
  private async receipt(actor: PurchaseEntryActor, scope: PurchaseEntryScope, kind: StorePrivatePreferenceKind, key: string, fingerprint: string): Promise<Receipt | null> {
    return this.db.runTransaction(async tx => {
      await this.authority!.assertCurrent(tx, actor, scope);
      const snap = await tx.get(this.attempt(scope, kind, key)); if (!snap.exists) return null;
      const v = purchaseEntryExact(snap.data(), ['version', 'projectId', 'scope', 'kind', 'idempotencyKey', 'fingerprint', 'expectedRevision', 'status', 'reason', 'input', 'recordedAt']);
      if (v.fingerprint !== fingerprint) fail('idempotency_conflict', 409);
      if (v.version !== 1 || v.projectId !== this.projectId || !equal(v.scope, scope) || v.kind !== kind || v.idempotencyKey !== key ||
          !['saved', 'not_saved'].includes(v.status as string) || v.reason !== (v.status === 'saved' ? null : 'stale_preferences') ||
          typeof v.recordedAt !== 'string' || !Number.isFinite(Date.parse(v.recordedAt))) fail('service_unavailable', 503);
      const expectedRevision = storePreferenceInteger(v.expectedRevision), input = this.pointer(v.input);
      if (BigInt(input.revision) !== BigInt(expectedRevision) + 1n) fail('service_unavailable', 503);
      return {...v, expectedRevision, input} as unknown as Receipt;
    });
  }
  async status(actor: PurchaseEntryActor, raw: PurchaseEntryScope, kind: StorePrivatePreferenceKind, key: string, fingerprint: string): Promise<StorePrivatePreferenceResult> {
    const scope = this.scope(actor, raw, kind); purchaseEntryId(key); purchaseEntryFingerprint(fingerprint);
    const before = await this.receipt(actor, scope, kind, key, fingerprint);
    const original = before === null ? null : await this.original(scope, kind, before.input);
    if (before && original) {
      const base = {version: 1 as const, projectId: this.projectId, scope, kind, expectedRevision: before.expectedRevision, idempotencyKey: key, fields: original.fields};
      if (storePrivatePreferenceCommandFingerprint(base) !== fingerprint) fail('service_unavailable', 503);
    }
    const current = await this.read(actor, scope, kind), after = await this.receipt(actor, scope, kind, key, fingerprint);
    if (!equal(before, after)) fail('stale_preferences', 409);
    if (before?.status === 'saved' && (!current || BigInt(current.revision) < BigInt(before.input.revision))) fail('service_unavailable', 503);
    return {receipt: after, original, current};
  }
  private async immutable(ref: DocumentReference, value: Record<string, unknown>): Promise<void> {
    try { await ref.create(value); } catch { const existing = await ref.get(); if (!existing.exists || !equal(existing.data(), value)) fail('service_unavailable', 503); }
  }
  private async stage(scope: PurchaseEntryScope, kind: StorePrivatePreferenceKind, record: StorePrivatePreferenceRecord): Promise<Pointer> {
    const data = Buffer.from(purchaseEntryCanonical(record), 'utf8'); if (data.length > maxBytes) fail();
    const fingerprint = bytesHash(data), revision = record.revision;
    const pointer = {id: purchaseEntryHash({scope, kind, revision, fingerprint}), fingerprint, revision, byteLength: data.length, parts: Math.ceil(data.length / partBytes)};
    const ref = this.root(scope, kind).collection('originals').doc(pointer.id);
    for (let i = 0; i < pointer.parts; i++) {
      const part = data.subarray(i * partBytes, Math.min((i + 1) * partBytes, data.length));
      await this.immutable(ref.collection('parts').doc(String(i).padStart(5, '0')), {version: 1, index: i, data: part.toString('base64'), fingerprint: bytesHash(part)});
    }
    await this.immutable(ref, this.manifest(scope, kind, pointer)); return pointer;
  }
  async save(actor: PurchaseEntryActor, raw: unknown): Promise<StorePrivatePreferenceResult> {
    const command = checkedStorePrivatePreferenceCommand(raw), {kind, idempotencyKey: key, fingerprint} = command;
    const scope = this.scope(actor, command.scope, kind);
    if (command.projectId !== this.projectId) fail('permission_denied', 403);
    if (await this.receipt(actor, scope, kind, key, fingerprint)) return this.status(actor, scope, kind, key, fingerprint);
    // Authorize before any staging, and again inside the publishing transaction.
    await this.authorizedHead(actor, scope, kind);
    const record: StorePrivatePreferenceRecord = {version: 1, projectId: this.projectId, scope, kind,
      revision: (BigInt(command.expectedRevision) + 1n).toString(), fields: command.fields};
    const input = await this.stage(scope, kind, record);
    await this.db.runTransaction(async tx => {
      await this.authority!.assertCurrent(tx, actor, scope);
      const head = await this.head(tx, scope, kind), receipt = await tx.get(this.attempt(scope, kind, key));
      if (receipt.exists) { if (receipt.get('fingerprint') !== fingerprint) fail('idempotency_conflict', 409); return; }
      const saved = (head?.revision ?? '0') === command.expectedRevision;
      const manifest = await tx.get(this.root(scope, kind).collection('originals').doc(input.id));
      if (!manifest.exists || !equal(manifest.data(), this.manifest(scope, kind, input))) fail('service_unavailable', 503);
      if (saved) tx.set(this.root(scope, kind), {version: 1, projectId: this.projectId, scope, kind, original: input});
      tx.create(this.attempt(scope, kind, key), {version: 1, projectId: this.projectId, scope, kind, idempotencyKey: key, fingerprint,
        expectedRevision: command.expectedRevision, status: saved ? 'saved' : 'not_saved', reason: saved ? null : 'stale_preferences', input, recordedAt: this.now().toISOString()} satisfies Receipt);
    });
    // A transaction/transport failure remains unknown, never a fabricated refusal.
    return this.status(actor, scope, kind, key, fingerprint);
  }
}

export interface StorePrivatePreferenceRepository {
  readonly realm: PurchaseEntryRealm; readonly projectId: string;
  read(actor: PurchaseEntryActor, scope: PurchaseEntryScope, kind: StorePrivatePreferenceKind): Promise<StorePrivatePreferenceRecord | null>;
  save(actor: PurchaseEntryActor, command: unknown): Promise<StorePrivatePreferenceResult>;
  status(actor: PurchaseEntryActor, scope: PurchaseEntryScope, kind: StorePrivatePreferenceKind, key: string, fingerprint: string): Promise<StorePrivatePreferenceResult>;
}
export function storePrivatePreferenceOperation(operation: string): 'read' | 'save' | 'status' | undefined {
  if (operation === 'readStorePrivatePreferences') return 'read';
  if (operation === 'saveStorePrivatePreferences') return 'save';
  if (operation === 'checkStorePrivatePreferencesSave') return 'status';
  return undefined;
}
export function storePrivatePreferenceRequestBodyLimit(operation: string, version: unknown): number | undefined {
  return version === 1 && storePrivatePreferenceOperation(operation) !== undefined ? maxBytes : undefined;
}
/** Compact current reference prevents duplicating two near-frame-sized originals.
 * Readers must match the separately read current record to both values before
 * using it; a changed source is stale, never silently rebased. */
export function storePrivatePreferenceRecoveryWire(result: StorePrivatePreferenceResult): Record<string, unknown> {
  return {receipt: result.receipt, original: result.original,
    currentRevision: result.current?.revision ?? '0',
    currentFingerprint: result.current === null ? null : purchaseEntryHash(result.current)};
}
export class WorkspaceStorePrivatePreferenceService {
  constructor(private readonly repository?: StorePrivatePreferenceRepository, private readonly enabled = false) {}
  async handle(actor: PurchaseEntryActor, operation: string, raw: unknown): Promise<object> {
    const method = storePrivatePreferenceOperation(operation);
    if (!method) fail();
    if (!this.enabled || !this.repository) fail('service_unavailable', 503);
    const common = ['schemaVersion', 'storePrivatePreferencesVersion', 'actorAccountId', 'projectId', 'realm', 'storeId', 'kind'];
    const extra = method === 'save' ? ['command'] : method === 'status' ? ['idempotencyKey', 'fingerprint'] : [];
    const body = purchaseEntryExact(raw, [...common, ...extra]);
    if (body.schemaVersion !== 1 || body.storePrivatePreferencesVersion !== 1 || !actor || actor.tenantId !== undefined ||
        body.actorAccountId !== actor.uid || body.projectId !== actor.projectId || actor.projectId !== this.repository.projectId ||
        body.realm !== this.repository.realm) fail('permission_denied', 403);
    const scope = checkedPurchaseEntryScope({account: body.actorAccountId, store: body.storeId, realm: body.realm});
    const kind = checkedStorePrivatePreferenceKind(body.kind);
    let payload: Record<string, unknown>;
    if (method === 'read') payload = {record: await this.repository.read(actor, scope, kind)};
    else if (method === 'save') {
      const command = checkedStorePrivatePreferenceCommand(body.command);
      if (command.projectId !== actor.projectId || !equal(command.scope, scope) || command.kind !== kind) fail('permission_denied', 403);
      payload = {result: storePrivatePreferenceRecoveryWire(await this.repository.save(actor, command))};
    } else {
      const key = purchaseEntryId(body.idempotencyKey), fingerprint = purchaseEntryFingerprint(body.fingerprint);
      payload = {result: storePrivatePreferenceRecoveryWire(await this.repository.status(actor, scope, kind, key, fingerprint))};
    }
    const response = {schemaVersion: 1, storePrivatePreferencesVersion: 1, actorAccountId: scope.account,
      projectId: actor.projectId, realm: scope.realm, storeId: scope.store, kind, ...payload};
    if (Buffer.byteLength(JSON.stringify(response), 'utf8') > maxBytes - 1024) fail('payload_too_large', 413);
    return response;
  }
}
