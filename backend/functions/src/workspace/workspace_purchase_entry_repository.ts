import {createHash} from 'node:crypto';
import type {DocumentReference, Firestore, Transaction} from 'firebase-admin/firestore';
import {WorkspaceProfileError} from './workspace_profile_service.js';
import {
  checkedPurchaseEntryBook, checkedPurchaseEntryReceipt, checkedPurchaseEntryScope,
  planPurchaseEntrySupplier, planPurchaseEntryDraft, purchaseEntryCanonical, purchaseEntryClone,
  purchaseEntrySaveFingerprint, purchaseEntrySaveOperation, purchaseEntryDraftReceiptFields, purchaseEntryTerminalReasons,
  purchaseEntryError, purchaseEntryExact,
  purchaseEntryFingerprint, purchaseEntryHash, purchaseEntryId, purchaseEntryRevision,
  type PurchaseEntryActor, type PurchaseEntryBook, type PurchaseEntryReceipt,
  type PurchaseEntryRealm, type PurchaseEntryRepository, type PurchaseEntryResult,
  type PurchaseEntryScope, type PurchaseEntrySupplierCommand, type PurchaseEntryDraftCommand, type PurchaseEntrySaveCommand,
} from './workspace_purchase_entry_service.js';

/** Only an original server-owned Store authority reader may implement this.
 * It must read its original version/ownership source through this transaction.
 * No concrete membership issuer/reader is manufactured by this repository. */
export interface PurchaseEntryTransactionAuthority {
  assertCurrent(transaction: Transaction, actor: PurchaseEntryActor, scope: PurchaseEntryScope): Promise<void>;
}
interface Pointer {id: string; fingerprint: string; byteLength: number; parts: number; revision: number}
interface Manifest extends Pointer {schemaVersion: 1; projectId: string; scope: PurchaseEntryScope}
interface Head {schemaVersion: 1; projectId: string; scope: PurchaseEntryScope; original: Pointer}
const partBytes = 192 * 1024, maximumBytes = 10 * 1024 * 1024;
const bytesHash = (data: Buffer) => createHash('sha256').update(data).digest('hex');
const equal = (a: unknown, b: unknown) => purchaseEntryCanonical(a) === purchaseEntryCanonical(b);

/** One original book, with immutable private payload parts and atomic head/CAS
 * publication. Staged parts are never active records, receipts or financial
 * outcomes. No client API accepts a book replacement or storage path. */
export class FirestorePurchaseEntryRepository implements PurchaseEntryRepository {
  constructor(private readonly db: Firestore, readonly realm: PurchaseEntryRealm,
    readonly projectId: string, private readonly authority?: PurchaseEntryTransactionAuthority,
    private readonly now: () => Date = () => new Date()) {}
  private scope(actor: PurchaseEntryActor, raw: PurchaseEntryScope): PurchaseEntryScope {
    const scope = checkedPurchaseEntryScope(raw);
    if (!actor || actor.uid !== scope.account || actor.projectId !== this.projectId || actor.tenantId !== undefined ||
        scope.realm !== this.realm) purchaseEntryError('permission_denied', 403);
    if (!this.authority) purchaseEntryError('service_unavailable', 503);
    return scope;
  }
  private root(scope: PurchaseEntryScope): DocumentReference {
    return this.db.collection('privateWorkspacePurchaseEntriesV1').doc(purchaseEntryHash({projectId: this.projectId, scope}));
  }
  private receiptRef(scope: PurchaseEntryScope, key: string): DocumentReference {
    return this.root(scope).collection('attempts').doc(purchaseEntryHash({key: purchaseEntryId(key)}));
  }
  private checkedPointer(raw: unknown): Pointer {
    const v = purchaseEntryExact(raw, ['id', 'fingerprint', 'byteLength', 'parts', 'revision']);
    const id = purchaseEntryFingerprint(v.id), fingerprint = purchaseEntryFingerprint(v.fingerprint),
      revision = purchaseEntryRevision(v.revision), byteLength = purchaseEntryRevision(v.byteLength), parts = purchaseEntryRevision(v.parts);
    if (byteLength > maximumBytes || parts !== Math.ceil(byteLength / partBytes)) purchaseEntryError('service_unavailable', 503);
    return {id, fingerprint, revision, byteLength, parts};
  }
  private checkedHead(raw: unknown, scope: PurchaseEntryScope): Head {
    const v = purchaseEntryExact(raw, ['schemaVersion', 'projectId', 'scope', 'original']);
    if (v.schemaVersion !== 1 || v.projectId !== this.projectId || !equal(checkedPurchaseEntryScope(v.scope), scope)) purchaseEntryError('service_unavailable', 503);
    return {schemaVersion: 1, projectId: this.projectId, scope, original: this.checkedPointer(v.original)};
  }
  private manifest(scope: PurchaseEntryScope, pointer: Pointer): Manifest {
    return {schemaVersion: 1, projectId: this.projectId, scope: purchaseEntryClone(scope), ...pointer};
  }
  private async head(transaction: Transaction, scope: PurchaseEntryScope): Promise<Head | null> {
    const value = await transaction.get(this.root(scope));
    if (value.exists) return this.checkedHead(value.data(), scope);
    const saved = await transaction.get(this.root(scope).collection('attempts').where('status', '==', 'saved').limit(1));
    if (!saved.empty) purchaseEntryError('service_unavailable', 503);
    return null;
  }
  private async authorizedHead(actor: PurchaseEntryActor, scope: PurchaseEntryScope): Promise<Head | null> {
    return this.db.runTransaction(async transaction => {
      await this.authority!.assertCurrent(transaction, actor, scope);
      return this.head(transaction, scope);
    });
  }
  private async original(scope: PurchaseEntryScope, pointer: Pointer): Promise<PurchaseEntryBook> {
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
        const data = Buffer.from(part.data, 'base64'), expectedBytes = index === pointer.parts - 1
          ? pointer.byteLength - partBytes * index : partBytes;
        if (data.length !== expectedBytes || data.toString('base64') !== part.data || bytesHash(data) !== part.fingerprint) purchaseEntryError('service_unavailable', 503);
        buffers.push(data);
      }
    }
    const data = Buffer.concat(buffers);
    if (data.length !== pointer.byteLength || bytesHash(data) !== pointer.fingerprint ||
        Buffer.from(data.toString('utf8'), 'utf8').compare(data) !== 0) purchaseEntryError('service_unavailable', 503);
    let raw: unknown;
    try {raw = JSON.parse(data.toString('utf8'));} catch {purchaseEntryError('service_unavailable', 503);}
    const book = checkedPurchaseEntryBook(raw, scope);
    if (book.revision !== pointer.revision || purchaseEntryHash(book) !== pointer.fingerprint ||
        pointer.id !== purchaseEntryHash({scope, revision: book.revision, fingerprint: pointer.fingerprint})) purchaseEntryError('service_unavailable', 503);
    return book;
  }
  async read(actor: PurchaseEntryActor, raw: PurchaseEntryScope): Promise<PurchaseEntryBook | null> {
    const scope = this.scope(actor, raw), before = await this.authorizedHead(actor, scope);
    const book = before === null ? null : await this.original(scope, before.original);
    const after = await this.authorizedHead(actor, scope);
    if (!equal(before, after)) purchaseEntryError('stale_book', 409);
    return book;
  }
  private async receipt(actor: PurchaseEntryActor, scope: PurchaseEntryScope, key: string,
    fingerprint: string): Promise<PurchaseEntryReceipt | null> {
    return this.db.runTransaction(async transaction => {
      await this.authority!.assertCurrent(transaction, actor, scope);
      const stored = await transaction.get(this.receiptRef(scope, key));
      if (!stored.exists) return null;
      if (stored.get('fingerprint') !== fingerprint) purchaseEntryError('idempotency_conflict', 409);
      return checkedPurchaseEntryReceipt(stored.data(), scope, key, fingerprint);
    });
  }
  async status(actor: PurchaseEntryActor, raw: PurchaseEntryScope, key: string, fingerprint: string): Promise<PurchaseEntryResult> {
    const scope = this.scope(actor, raw); purchaseEntryId(key); purchaseEntryFingerprint(fingerprint);
    const before = await this.receipt(actor, scope, key, fingerprint);
    let currentBook = await this.read(actor, scope);
    // Absence must be checked after the observed head: the original Save may
    // commit between the first receipt read and the book read. A stale null
    // receipt must never fence or replace an already committed native intent.
    const receipt = await this.receipt(actor, scope, key, fingerprint);
    if (before && (!receipt || !equal(before, receipt))) purchaseEntryError('service_unavailable', 503);
    if (receipt?.resultRevision !== null && receipt?.resultRevision !== undefined &&
        (!currentBook || currentBook.revision < receipt.resultRevision)) currentBook = await this.read(actor, scope);
    if (receipt?.status === 'saved' && currentBook === null || receipt?.resultRevision !== null &&
        receipt?.resultRevision !== undefined && (!currentBook || currentBook.revision < receipt.resultRevision)) purchaseEntryError('service_unavailable', 503);
    return {receipt, currentBook};
  }
  private async immutable(ref: DocumentReference, value: Readonly<Record<string, unknown>>): Promise<void> {
    try {await ref.create(value);} catch {
      // Creation may already have committed before an acknowledgement was lost.
      // A read proves only this private part; no head or Save is published here.
      const current = await ref.get();
      if (!current.exists || !equal(current.data(), value)) purchaseEntryError('service_unavailable', 503);
    }
  }
  private async stage(scope: PurchaseEntryScope, book: PurchaseEntryBook): Promise<Pointer> {
    const data = Buffer.from(purchaseEntryCanonical(book), 'utf8');
    if (!data.length || data.length > maximumBytes) purchaseEntryError('capacity_exceeded', 409);
    const fingerprint = bytesHash(data), pointer = {id: purchaseEntryHash({scope, revision: book.revision, fingerprint}),
      fingerprint, byteLength: data.length, parts: Math.ceil(data.length / partBytes), revision: book.revision};
    const ref = this.root(scope).collection('originals').doc(pointer.id);
    // Bounded individual creates keep each document/request below provider
    // limits and permit exact interruption recovery. No mutable part is reused.
    for (let index = 0; index < pointer.parts; index++) {
      const bytes = data.subarray(index * partBytes, Math.min((index + 1) * partBytes, data.length));
      await this.immutable(ref.collection('parts').doc(String(index).padStart(5, '0')),
        {schemaVersion: 1, index, data: bytes.toString('base64'), fingerprint: bytesHash(bytes)});
    }
    await this.immutable(ref, this.manifest(scope, pointer) as unknown as Record<string, unknown>);
    return pointer;
  }
  private async rejectSave(actor: PurchaseEntryActor, command: PurchaseEntrySaveCommand,
    captured: PurchaseEntryBook | null, reason: string): Promise<PurchaseEntryResult> {
    const scope = command.scope;
    await this.db.runTransaction(async transaction => {
      await this.authority!.assertCurrent(transaction, actor, scope);
      const head = await this.head(transaction, scope), previous = await transaction.get(this.receiptRef(scope, command.idempotencyKey));
      if (previous.exists) {
        if (previous.get('fingerprint') !== command.fingerprint) purchaseEntryError('idempotency_conflict', 409);
        checkedPurchaseEntryReceipt(previous.data(), scope, command.idempotencyKey, command.fingerprint);
        return;
      }
      const revision = head?.original.revision ?? null, fingerprint = head?.original.fingerprint ?? null;
      if (revision === captured?.revision && fingerprint !== (captured === null ? null : purchaseEntryHash(captured))) {
        purchaseEntryError('service_unavailable', 503);
      }
      const currentReason = revision !== (captured?.revision ?? null) ? 'stale_book' : reason;
      const receipt: PurchaseEntryReceipt = {schemaVersion: 1, scope, operation: purchaseEntrySaveOperation(command),
        idempotencyKey: command.idempotencyKey, fingerprint: command.fingerprint, status: 'not_saved', reason: currentReason,
        changed: false, resultRevision: revision, profile: command.profile, recordedAt: this.now().toISOString(),
        ...purchaseEntryDraftReceiptFields(command)};
      transaction.create(this.receiptRef(scope, command.idempotencyKey), receipt);
    });
    return this.status(actor, scope, command.idempotencyKey, command.fingerprint);
  }
  async saveSupplier(actor: PurchaseEntryActor, input: PurchaseEntrySupplierCommand): Promise<PurchaseEntryResult> {
    if ('draft' in input) purchaseEntryError();
    return this.save(actor, input);
  }
  async savePurchaseDraft(actor: PurchaseEntryActor, input: PurchaseEntryDraftCommand): Promise<PurchaseEntryResult> {
    return this.save(actor, input);
  }
  private async save(actor: PurchaseEntryActor, input: PurchaseEntrySaveCommand): Promise<PurchaseEntryResult> {
    const scope = this.scope(actor, input.scope), command = purchaseEntryClone(input);
    if (command.fingerprint !== purchaseEntrySaveFingerprint(command)) purchaseEntryError();
    const oldReceipt = await this.receipt(actor, scope, command.idempotencyKey, command.fingerprint);
    if (oldReceipt) return this.status(actor, scope, command.idempotencyKey, command.fingerprint);
    const current = await this.read(actor, scope);
    // A matching concurrent Save can have advanced the head during this read.
    // Recover its immutable receipt before treating that head as a stale CAS.
    if (await this.receipt(actor, scope, command.idempotencyKey, command.fingerprint)) {
      return this.status(actor, scope, command.idempotencyKey, command.fingerprint);
    }
    let plan: ReturnType<typeof planPurchaseEntrySupplier>;
    try {plan = 'draft' in command ? planPurchaseEntryDraft(command, current) : planPurchaseEntrySupplier(command, current);} catch (error) {
      if (error instanceof WorkspaceProfileError && purchaseEntryTerminalReasons('draft' in command).includes(error.code)) {
        return this.rejectSave(actor, command, current, error.code);
      }
      throw error;
    }
    const staged = plan.changed ? await this.stage(scope, plan.book) : null;
    const receipt: PurchaseEntryReceipt = {schemaVersion: 1, scope, operation: purchaseEntrySaveOperation(command),
      idempotencyKey: command.idempotencyKey, fingerprint: command.fingerprint, status: 'saved', reason: null, changed: plan.changed,
      resultRevision: plan.book.revision, profile: plan.profile, recordedAt: this.now().toISOString(),
      ...purchaseEntryDraftReceiptFields(command)};
    try {
      await this.db.runTransaction(async transaction => {
        await this.authority!.assertCurrent(transaction, actor, scope);
        const head = await this.head(transaction, scope), previous = await transaction.get(this.receiptRef(scope, command.idempotencyKey));
        if (previous.exists) {
          if (previous.get('fingerprint') !== command.fingerprint) purchaseEntryError('idempotency_conflict', 409);
          checkedPurchaseEntryReceipt(previous.data(), scope, command.idempotencyKey, command.fingerprint);
          return;
        }
        if ((head?.original.revision ?? null) !== (current?.revision ?? null) ||
            (head?.original.fingerprint ?? null) !== (current === null ? null : purchaseEntryHash(current))) purchaseEntryError('stale_book', 409);
        if (staged) {
          const manifest = await transaction.get(this.root(scope).collection('originals').doc(staged.id));
          if (!manifest.exists || !equal(manifest.data(), this.manifest(scope, staged))) purchaseEntryError('service_unavailable', 503);
          transaction.set(this.root(scope), {schemaVersion: 1, projectId: this.projectId, scope, original: staged} satisfies Head);
        } else if (head === null) purchaseEntryError('service_unavailable', 503);
        transaction.create(this.receiptRef(scope, command.idempotencyKey), receipt);
      });
    } catch (error) {
      if (error instanceof WorkspaceProfileError && error.code === 'stale_book') {
        return this.rejectSave(actor, command, current, error.code);
      }
      if (!(error instanceof WorkspaceProfileError)) {
        // A transport/transaction error does not prove that this identity was
        // not committed by a concurrent identical caller. Re-read only that
        // original receipt under current authority; never blindly repeat IO.
        const recovered = await this.receipt(actor, scope, command.idempotencyKey, command.fingerprint);
        if (recovered) return this.status(actor, scope, command.idempotencyKey, command.fingerprint);
      }
      throw error;
    }
    // Independent current readback, never the historical receipt's book. If
    // access disappears after commit, caller retains an unknown original Save.
    return this.status(actor, scope, command.idempotencyKey, command.fingerprint);
  }
}
