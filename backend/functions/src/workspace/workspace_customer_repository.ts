import {createHash} from 'node:crypto';
import type {DocumentReference, Firestore, Transaction} from 'firebase-admin/firestore';
import type {PurchaseEntryTransactionAuthority} from './workspace_purchase_entry_repository.js';
import {checkedPurchaseEntryScope, purchaseEntryCanonical, purchaseEntryClone, purchaseEntryError,
  purchaseEntryExact, purchaseEntryFingerprint, purchaseEntryHash, purchaseEntryId,
  type PurchaseEntryActor, type PurchaseEntryRealm} from './workspace_purchase_entry_service.js';
import {checkedCustomerCounterDraftCommand, checkedCustomerCounterDraftReceipt,
  checkedCustomerCounterDraftWire, planCustomerCounterDraftSave,
  type CustomerCounterDraftCommand, type CustomerCounterDraftReceipt,
  type CustomerCounterDraftResult, type CustomerCounterDraftWire,
  type CustomerScope} from './workspace_customer_service.js';

interface Pointer {id: string; fingerprint: string; byteLength: number; parts: number; revision: string}
interface Head {schemaVersion: 1; projectId: string; scope: CustomerScope; original: Pointer}
const partBytes = 192 * 1024;
const bytesHash = (data: Buffer) => createHash('sha256').update(data).digest('hex');
const equal = (a: unknown, b: unknown) => purchaseEntryCanonical(a) === purchaseEntryCanonical(b);

/** Original recovery input only. Immutable parts are staged privately; the
 * transaction publishes one exact current draft and its receipt. This source
 * cannot complete/cancel a sale, reserve Stock, issue an invoice or move money.
 * Authority must come from the original membership reader, never client input. */
export class FirestoreCustomerCounterDraftRepository {
  constructor(private readonly db: Firestore, readonly realm: PurchaseEntryRealm,
    readonly projectId: string, private readonly authority?: PurchaseEntryTransactionAuthority,
    private readonly now: () => Date = () => new Date()) {}
  private scope(actor: PurchaseEntryActor, raw: CustomerScope): CustomerScope {
    const scope = checkedPurchaseEntryScope(raw);
    if (!actor || actor.uid !== scope.account || actor.projectId !== this.projectId ||
        actor.tenantId !== undefined || scope.realm !== this.realm) purchaseEntryError('permission_denied', 403);
    if (!this.authority) purchaseEntryError('service_unavailable', 503);
    return scope;
  }
  private root(scope: CustomerScope): DocumentReference {
    return this.db.collection('privateWorkspaceCounterDraftsV1').doc(purchaseEntryHash({projectId: this.projectId, scope}));
  }
  private attempt(scope: CustomerScope, key: string): DocumentReference {
    return this.root(scope).collection('attempts').doc(purchaseEntryHash({key: purchaseEntryId(key)}));
  }
  private manifest(scope: CustomerScope, pointer: Pointer): Record<string, unknown> {
    return {schemaVersion: 1, projectId: this.projectId, scope, ...pointer};
  }
  private checkedPointer(raw: unknown): Pointer {
    const v = purchaseEntryExact(raw, ['id', 'fingerprint', 'byteLength', 'parts', 'revision']);
    if (typeof v.revision !== 'string' || !/^[1-9]\d*$/.test(v.revision) ||
        BigInt(v.revision) > 9223372036854775807n ||
        !Number.isSafeInteger(v.byteLength) || (v.byteLength as number) < 1 ||
        !Number.isSafeInteger(v.parts) || v.parts !== Math.ceil((v.byteLength as number) / partBytes)) {
      purchaseEntryError('service_unavailable', 503);
    }
    return {id: purchaseEntryFingerprint(v.id), fingerprint: purchaseEntryFingerprint(v.fingerprint),
      byteLength: v.byteLength as number, parts: v.parts as number, revision: v.revision};
  }
  private async head(transaction: Transaction, scope: CustomerScope): Promise<Head | null> {
    const snapshot = await transaction.get(this.root(scope));
    if (!snapshot.exists) {
      const saved = await transaction.get(this.root(scope).collection('attempts').where('status', '==', 'saved').limit(1));
      if (!saved.empty) purchaseEntryError('service_unavailable', 503);
      return null;
    }
    const v = purchaseEntryExact(snapshot.data(), ['schemaVersion', 'projectId', 'scope', 'original']);
    if (v.schemaVersion !== 1 || v.projectId !== this.projectId || !equal(checkedPurchaseEntryScope(v.scope), scope)) {
      purchaseEntryError('service_unavailable', 503);
    }
    return {schemaVersion: 1, projectId: this.projectId, scope, original: this.checkedPointer(v.original)};
  }
  private async authorizedHead(actor: PurchaseEntryActor, scope: CustomerScope): Promise<Head | null> {
    return this.db.runTransaction(async transaction => {
      await this.authority!.assertCurrent(transaction, actor, scope);
      return this.head(transaction, scope);
    });
  }
  private async original(scope: CustomerScope, pointer: Pointer): Promise<CustomerCounterDraftWire> {
    const ref = this.root(scope).collection('originals').doc(pointer.id), manifest = await ref.get();
    if (!manifest.exists || !equal(manifest.data(), this.manifest(scope, pointer))) purchaseEntryError('service_unavailable', 503);
    const buffers: Buffer[] = [];
    for (let start = 0; start < pointer.parts; start += 16) {
      const refs = Array.from({length: Math.min(16, pointer.parts - start)}, (_, offset) =>
        ref.collection('parts').doc(String(start + offset).padStart(5, '0')));
      const records = await this.db.getAll(...refs);
      for (let offset = 0; offset < records.length; offset++) {
        const item = records[offset];
        if (!item?.exists) purchaseEntryError('service_unavailable', 503);
        const part = purchaseEntryExact(item.data(), ['schemaVersion', 'index', 'data', 'fingerprint']);
        const index = start + offset;
        if (part.schemaVersion !== 1 || part.index !== index || typeof part.data !== 'string') purchaseEntryError('service_unavailable', 503);
        const bytes = Buffer.from(part.data, 'base64'), expected = index === pointer.parts - 1
          ? pointer.byteLength - partBytes * index : partBytes;
        if (bytes.length !== expected || bytes.toString('base64') !== part.data || bytesHash(bytes) !== part.fingerprint) {
          purchaseEntryError('service_unavailable', 503);
        }
        buffers.push(bytes);
      }
    }
    const bytes = Buffer.concat(buffers), text = bytes.toString('utf8');
    if (bytes.length !== pointer.byteLength || bytesHash(bytes) !== pointer.fingerprint ||
        Buffer.compare(Buffer.from(text, 'utf8'), bytes) !== 0) purchaseEntryError('service_unavailable', 503);
    let raw: unknown;
    try {raw = JSON.parse(text);} catch {purchaseEntryError('service_unavailable', 503);}
    const wire = checkedCustomerCounterDraftWire(raw, scope);
    if (wire.draft.revision !== pointer.revision || purchaseEntryHash(wire) !== pointer.fingerprint ||
        pointer.id !== purchaseEntryHash({scope, revision: pointer.revision, fingerprint: pointer.fingerprint})) {
      purchaseEntryError('service_unavailable', 503);
    }
    return wire;
  }
  async read(actor: PurchaseEntryActor, raw: CustomerScope): Promise<CustomerCounterDraftWire | null> {
    const scope = this.scope(actor, raw), before = await this.authorizedHead(actor, scope);
    const draft = before === null ? null : await this.original(scope, before.original);
    const after = await this.authorizedHead(actor, scope);
    if (!equal(before, after)) purchaseEntryError('stale_draft', 409);
    return draft;
  }
  private async receipt(actor: PurchaseEntryActor, scope: CustomerScope, key: string,
    fingerprint: string): Promise<CustomerCounterDraftReceipt | null> {
    return this.db.runTransaction(async transaction => {
      await this.authority!.assertCurrent(transaction, actor, scope);
      const item = await transaction.get(this.attempt(scope, key));
      if (!item.exists) return null;
      if (item.get('fingerprint') !== fingerprint) purchaseEntryError('idempotency_conflict', 409);
      return checkedCustomerCounterDraftReceipt(item.data(), scope, key, fingerprint);
    });
  }
  async status(actor: PurchaseEntryActor, raw: CustomerScope, key: string, fingerprint: string): Promise<CustomerCounterDraftResult> {
    const scope = this.scope(actor, raw); purchaseEntryId(key); purchaseEntryFingerprint(fingerprint);
    const before = await this.receipt(actor, scope, key, fingerprint);
    let currentDraft = await this.read(actor, scope);
    const receipt = await this.receipt(actor, scope, key, fingerprint);
    if (before && (!receipt || !equal(before, receipt))) purchaseEntryError('service_unavailable', 503);
    if (receipt?.resultRevision !== null && receipt?.resultRevision !== undefined &&
        (!currentDraft || BigInt(currentDraft.draft.revision) < BigInt(receipt.resultRevision))) {
      currentDraft = await this.read(actor, scope);
    }
    if (receipt?.resultRevision !== null && receipt?.resultRevision !== undefined &&
        (!currentDraft || BigInt(currentDraft.draft.revision) < BigInt(receipt.resultRevision))) {
      purchaseEntryError('service_unavailable', 503);
    }
    return {receipt, currentDraft};
  }
  private async immutable(ref: DocumentReference, value: Record<string, unknown>): Promise<void> {
    try {await ref.create(value);} catch {
      const item = await ref.get();
      if (!item.exists || !equal(item.data(), value)) purchaseEntryError('service_unavailable', 503);
    }
  }
  private async stage(scope: CustomerScope, wire: CustomerCounterDraftWire): Promise<Pointer> {
    const bytes = Buffer.from(purchaseEntryCanonical(wire), 'utf8');
    const fingerprint = bytesHash(bytes), revision = wire.draft.revision;
    const pointer = {id: purchaseEntryHash({scope, revision, fingerprint}), fingerprint,
      byteLength: bytes.length, parts: Math.ceil(bytes.length / partBytes), revision};
    const ref = this.root(scope).collection('originals').doc(pointer.id);
    for (let index = 0; index < pointer.parts; index++) {
      const data = bytes.subarray(index * partBytes, Math.min((index + 1) * partBytes, bytes.length));
      await this.immutable(ref.collection('parts').doc(String(index).padStart(5, '0')),
        {schemaVersion: 1, index, data: data.toString('base64'), fingerprint: bytesHash(data)});
    }
    await this.immutable(ref, this.manifest(scope, pointer));
    return pointer;
  }
  async save(actor: PurchaseEntryActor, raw: CustomerCounterDraftCommand): Promise<CustomerCounterDraftResult> {
    const command = checkedCustomerCounterDraftCommand(raw), scope = this.scope(actor, command.scope);
    if (await this.receipt(actor, scope, command.idempotencyKey, command.fingerprint)) {
      return this.status(actor, scope, command.idempotencyKey, command.fingerprint);
    }
    const current = await this.read(actor, scope), plan = planCustomerCounterDraftSave(current, command);
    const staged = plan.state === 'save' ? await this.stage(scope, command.wire) : null;
    try {
      await this.db.runTransaction(async transaction => {
        await this.authority!.assertCurrent(transaction, actor, scope);
        const head = await this.head(transaction, scope);
        const existing = await transaction.get(this.attempt(scope, command.idempotencyKey));
        if (existing.exists) {
          if (existing.get('fingerprint') !== command.fingerprint) purchaseEntryError('idempotency_conflict', 409);
          checkedCustomerCounterDraftReceipt(existing.data(), scope, command.idempotencyKey, command.fingerprint);
          return;
        }
        const revision = head?.original.revision ?? null;
        const changedHead = revision !== (current?.draft.revision ?? null);
        if (!changedHead && (head?.original.fingerprint ?? null) !== (current === null ? null : purchaseEntryHash(current))) {
          purchaseEntryError('service_unavailable', 503);
        }
        const saved = !changedHead && plan.state !== 'refused';
        if (saved && staged) {
          const manifest = await transaction.get(this.root(scope).collection('originals').doc(staged.id));
          if (!manifest.exists || !equal(manifest.data(), this.manifest(scope, staged))) purchaseEntryError('service_unavailable', 503);
          transaction.set(this.root(scope), {schemaVersion: 1, projectId: this.projectId, scope, original: staged} satisfies Head);
        } else if (saved && !head) purchaseEntryError('service_unavailable', 503);
        const receipt: CustomerCounterDraftReceipt = {schemaVersion: 1, scope, operation: command.operation,
          idempotencyKey: command.idempotencyKey, fingerprint: command.fingerprint,
          status: saved ? 'saved' : 'not_saved', reason: saved ? null : changedHead ? 'stale_draft' : plan.reason,
          changed: saved && plan.state === 'save', resultRevision: saved ? command.wire.draft.revision : revision,
          recordedAt: this.now().toISOString()};
        checkedCustomerCounterDraftReceipt(receipt, scope, command.idempotencyKey, command.fingerprint);
        transaction.create(this.attempt(scope, command.idempotencyKey), receipt);
      });
    } catch (error) {
      // A lost acknowledgement is not refusal. Recover only this exact original
      // identity under current authority; never blindly repeat a financial IO.
      if (await this.receipt(actor, scope, command.idempotencyKey, command.fingerprint)) {
        return this.status(actor, scope, command.idempotencyKey, command.fingerprint);
      }
      throw error;
    }
    return this.status(actor, scope, command.idempotencyKey, command.fingerprint);
  }
}
