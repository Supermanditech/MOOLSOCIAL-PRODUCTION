import {createHash} from 'node:crypto';
import {FieldPath, type DocumentReference, type Firestore, type Transaction} from 'firebase-admin/firestore';
import {WorkspaceProfileError} from './workspace_profile_service.js';
import type {PurchaseEntryTransactionAuthority} from './workspace_purchase_entry_repository.js';
import {checkedPurchaseEntryScope, checkedPurchaseEntryCopy, purchaseEntryFingerprint, purchaseEntryId, purchaseEntryRevision, purchaseEntryInvoiceFinancialYear,
  type PurchaseEntryBook} from './workspace_purchase_entry_service.js';
import {checkedLedgerCommand, checkedLedgerOpening, checkedLedgerReceipt, checkedLedgerRegisterHeader, checkedLedgerSupplierMoneyEntry,
  checkedLedgerSupplierBillAcceptance, ledgerBillLiabilityEntry, ledgerBillOpeningMatches, ledgerPrintedPaise, ledgerReviewedCopyMatches,
  checkedLedgerSupplierAllocationProof, ledgerSupplierAllocationInput, ledgerSupplierFinancialHistory,
  checkedLedgerSupplierRefundProof, ledgerSupplierRefundEntry,
  checkedLedgerSupplierCreditProof, ledgerSupplierCreditInput, ledgerSupplierCreditEntry, ledgerSupplierCreditPrintedTotal,
  checkedLedgerRow, ledgerCanonical, ledgerClone, ledgerCommandInput, ledgerCommandTarget,
  ledgerConfirmedOpening, ledgerCount, ledgerError, ledgerHash, ledgerMicros,
  type LedgerActor, type LedgerCommand, type LedgerExpenseCommand, type LedgerKind,
  type LedgerOpeningCommand, type LedgerPage, type LedgerReceipt, type LedgerRegisterCommand,
  type LedgerRepository, type LedgerRow, type LedgerScope, type LedgerStatus, type LedgerSupplierMoneyCommand,
  type LedgerSupplierBillCommand, type LedgerSupplierBillAcceptance, type LedgerSupplierAllocationCommand, type LedgerSupplierRefundCommand, type LedgerSupplierCreditCommand,
  type LedgerSupplierAllocationProof, type LedgerSupplierMoneySourceKind} from './workspace_ledger_service.js';

/** Only the existing original purchase repository may supply this anchor.
 * assertCurrent must read that original head and current authority through the
 * publication transaction. A client revision or a cached book is insufficient. */
export interface LedgerPurchaseAnchor {
  capture(actor: LedgerActor, scope: LedgerScope): Promise<PurchaseEntryBook | null>;
  assertCurrent(tx: Transaction, actor: LedgerActor, scope: LedgerScope, book: PurchaseEntryBook): Promise<void>;
}
interface Head {
  schemaVersion: 1; projectId: string; scope: LedgerScope; revision: number;
  counts: Record<LedgerKind, number>; updatedAt: string;
}
interface Pointer {id: string; fingerprint: string; byteLength: number; parts: number}
interface RecordMeta {
  schemaVersion: 1; projectId: string; scope: LedgerScope; kind: LedgerKind;
  id: string; parentId: string | null; revision: number; writeRevision: number;
  ordinal: number | null; payload: Pointer;
}
interface Snapshot {head: Head | null; meta: RecordMeta | null; row: LedgerRow | null}
interface PlannedWrite {row: LedgerRow; ref: DocumentReference; first: boolean}
interface Plan {reason: string | null; writes: PlannedWrite[]; purchase: PurchaseEntryBook | null}
const kinds: readonly LedgerKind[] = ['supplierLedger', 'expense', 'moneyRegister', 'moneyEntry'];
const partBytes = 192 * 1024, pageSize = 5;
const equal = (a: unknown, b: unknown) => ledgerCanonical(a) === ledgerCanonical(b);
const bytesHash = (data: Buffer) => createHash('sha256').update(data).digest('hex');
const next = (value: number) => ledgerCount(value + 1);

/** Original private record storage. There is no whole-checkpoint PUT and no
 * lifetime book-size cap: records and register entries are independently paged.
 * Payload parts are immutable; only head/record/attempt publication is atomic.
 * No original authority or register is manufactured by this implementation. */
export class FirestoreWorkspaceLedgerRepository implements LedgerRepository {
  constructor(private readonly db: Firestore, readonly realm: LedgerScope['realm'],
    readonly projectId: string, private readonly authority?: PurchaseEntryTransactionAuthority,
    private readonly purchase?: LedgerPurchaseAnchor, private readonly now: () => Date = () => new Date()) {}
  get configured(): boolean {return this.authority !== undefined;}
  private scope(actor: LedgerActor, raw: LedgerScope): LedgerScope {
    const scope = checkedPurchaseEntryScope(raw);
    if (!actor || actor.uid !== scope.account || actor.projectId !== this.projectId ||
        actor.tenantId !== undefined || scope.realm !== this.realm) ledgerError('permission_denied', 403);
    if (!this.authority) ledgerError('service_unavailable', 503);
    return scope;
  }
  private root(scope: LedgerScope): DocumentReference {
    return this.db.collection('privateWorkspaceLedgerV1').doc(ledgerHash({projectId: this.projectId, scope}));
  }
  private records(scope: LedgerScope, kind: LedgerKind, parent: string | null) {
    return kind === 'moneyEntry'
      ? this.recordRef(scope, 'moneyRegister', parent!).collection('entries')
      : this.root(scope).collection(kind);
  }
  private recordRef(scope: LedgerScope, kind: LedgerKind, id: string, parent: string | null = null): DocumentReference {
    return this.records(scope, kind, parent).doc(ledgerHash({id}));
  }
  private identityRef(scope: LedgerScope, kind: LedgerKind, id: string, parent: string | null = null): DocumentReference {
    return this.root(scope).collection('recordIdentities').doc(ledgerHash({kind, id, parent}));
  }
  private attemptRef(scope: LedgerScope, key: string): DocumentReference {
    return this.root(scope).collection('attempts').doc(ledgerHash({key: purchaseEntryId(key)}));
  }
  /** Duplicate-fact index inside the original ledger; never a second balance. */
  private supplierEntryIdentityRef(scope: LedgerScope, id: string): DocumentReference {
    return this.root(scope).collection('supplierEntryIdentities').doc(ledgerHash({id}));
  }
  private supplierBillIdentityRef(scope: LedgerScope, id: string): DocumentReference {
    return this.root(scope).collection('supplierBillIdentities').doc(ledgerHash({id}));
  }
  private identity(meta: RecordMeta): object {
    return {schemaVersion: 1, projectId: this.projectId, scope: meta.scope, kind: meta.kind,
      id: meta.id, parentId: meta.parentId};
  }
  private checkedHead(raw: unknown, scope: LedgerScope): Head {
    try {
      const v = raw as Head;
      if (!v || Object.keys(v).sort().join() !== ['schemaVersion', 'projectId', 'scope', 'revision', 'counts', 'updatedAt'].sort().join() ||
          v.schemaVersion !== 1 || v.projectId !== this.projectId || !equal(v.scope, scope) ||
          !v.counts || Object.keys(v.counts).sort().join() !== [...kinds].sort().join()) ledgerError('service_unavailable', 503);
      purchaseEntryRevision(v.revision); ledgerMicros(v.updatedAt);
      for (const kind of kinds) ledgerCount(v.counts[kind]);
      return ledgerClone(v);
    } catch {ledgerError('service_unavailable', 503);}
  }
  private checkedMeta(raw: unknown, scope: LedgerScope): RecordMeta {
    try {
      const v = raw as RecordMeta;
      if (!v || Object.keys(v).sort().join() !== ['schemaVersion', 'projectId', 'scope', 'kind', 'id', 'parentId',
        'revision', 'writeRevision', 'ordinal', 'payload'].sort().join() || v.schemaVersion !== 1 ||
        v.projectId !== this.projectId || !equal(v.scope, scope) || !kinds.includes(v.kind) ||
        typeof v.id !== 'string' || !v.id.trim() || (v.kind === 'moneyEntry'
          ? typeof v.parentId !== 'string' || !v.parentId.trim() || !Number.isSafeInteger(v.ordinal) || v.ordinal! < 1
          : v.parentId !== null || v.ordinal !== null)) ledgerError('service_unavailable', 503);
      purchaseEntryRevision(v.revision); purchaseEntryRevision(v.writeRevision);
      const p = v.payload;
      if (!p || Object.keys(p).sort().join() !== ['id', 'fingerprint', 'byteLength', 'parts'].sort().join()) ledgerError('service_unavailable', 503);
      purchaseEntryFingerprint(p.id); purchaseEntryFingerprint(p.fingerprint); purchaseEntryRevision(p.byteLength);
      if (p.parts !== Math.ceil(p.byteLength / partBytes) || p.id !== ledgerHash({scope, kind: v.kind,
        id: v.id, parentId: v.parentId, revision: v.revision, fingerprint: p.fingerprint})) ledgerError('service_unavailable', 503);
      return ledgerClone(v);
    } catch {ledgerError('service_unavailable', 503);}
  }
  private async head(tx: Transaction, scope: LedgerScope): Promise<Head | null> {
    const doc = await tx.get(this.root(scope));
    if (doc.exists) return this.checkedHead(doc.data(), scope);
    // Keep query guards serial on this transaction. Under competing first
    // publications, a second in-flight query can surface a closed-transaction
    // error after the SDK rolls back the first, masking its contention retry.
    try {
      const identities = await tx.get(this.root(scope).collection('recordIdentities').limit(1));
      const receipts = await tx.get(this.root(scope).collection('attempts').where('status', '==', 'saved').limit(1));
      if (!identities.empty || !receipts.empty) ledgerError('service_unavailable', 503);
    } catch (error) {
      const failure = error as {code?: unknown; details?: unknown} | null;
      // The emulator reports a lock-aborted query with this exact code/detail.
      // No transaction write has been queued at this read boundary. Classify
      // only that failed read as ABORTED so the SDK uses its bounded transaction
      // retry; never retry a command or reinterpret an unknown commit result.
      if (failure?.code === 3 && failure.details === 'Transaction is invalid or closed.') {
        throw Object.assign(new Error('Original ledger transaction read aborted', {cause: error}), {code: 10});
      }
      throw error;
    }
    // Orphan staged immutable payloads do not establish a published source.
    return null;
  }
  private async meta(tx: Transaction, scope: LedgerScope, kind: LedgerKind, id: string,
    parent: string | null = null): Promise<RecordMeta | null> {
    const [doc, identity] = await Promise.all([tx.get(this.recordRef(scope, kind, id, parent)),
      tx.get(this.identityRef(scope, kind, id, parent))]);
    if (!doc.exists) {if (identity.exists) ledgerError('service_unavailable', 503); return null;}
    const meta = this.checkedMeta(doc.data(), scope);
    if (meta.kind !== kind || meta.id !== id || meta.parentId !== parent ||
        !identity.exists || !equal(identity.data(), this.identity(meta))) ledgerError('service_unavailable', 503);
    return meta;
  }
  private async snapshot(actor: LedgerActor, scope: LedgerScope, kind: LedgerKind, id: string): Promise<Snapshot> {
    const captured = await this.db.runTransaction(async tx => {
      await this.authority!.assertCurrent(tx, actor, scope);
      const head = await this.head(tx, scope), meta = await this.meta(tx, scope, kind, id);
      if (meta && (!head || meta.writeRevision > head.revision)) ledgerError('service_unavailable', 503);
      return {head, meta};
    });
    const row = captured.meta ? await this.load(captured.meta) : null;
    await this.db.runTransaction(async tx => {
      await this.authority!.assertCurrent(tx, actor, scope);
      if (!equal(await this.head(tx, scope), captured.head) ||
          !equal(await this.meta(tx, scope, kind, id), captured.meta)) ledgerError('stale_ledger', 409);
    });
    return {...captured, row};
  }
  private async immutable(ref: DocumentReference, value: object): Promise<void> {
    try {await ref.create(value);} catch {
      const existing = await ref.get();
      if (!existing.exists || !equal(existing.data(), value)) ledgerError('service_unavailable', 503);
    }
  }
  private async stage(scope: LedgerScope, row: LedgerRow, writeRevision: number): Promise<RecordMeta> {
    checkedLedgerRow(row, scope);
    const data = Buffer.from(row.json, 'utf8'), fingerprint = bytesHash(data);
    const payload: Pointer = {id: ledgerHash({scope, kind: row.kind, id: row.id, parentId: row.parentId,
      revision: row.revision, fingerprint}), fingerprint, byteLength: data.length, parts: Math.ceil(data.length / partBytes)};
    const meta: RecordMeta = {schemaVersion: 1, projectId: this.projectId, scope: ledgerClone(scope),
      kind: row.kind, id: row.id, parentId: row.parentId, revision: row.revision, writeRevision, ordinal: row.ordinal, payload};
    const ref = this.root(scope).collection('payloads').doc(payload.id);
    for (let index = 0; index < payload.parts; index++) {
      const bytes = data.subarray(index * partBytes, (index + 1) * partBytes);
      await this.immutable(ref.collection('parts').doc(String(index).padStart(10, '0')),
        {schemaVersion: 1, index, data: bytes.toString('base64'), fingerprint: bytesHash(bytes)});
    }
    await this.immutable(ref, {schemaVersion: 1, projectId: this.projectId, scope, kind: row.kind,
      id: row.id, parentId: row.parentId, revision: row.revision, ordinal: row.ordinal, payload});
    return meta;
  }
  private async load(meta: RecordMeta): Promise<LedgerRow> {
    const ref = this.root(meta.scope).collection('payloads').doc(meta.payload.id), manifest = await ref.get();
    const {writeRevision: _writeRevision, ...expected} = meta;
    if (!manifest.exists || !equal(manifest.data(), expected)) ledgerError('service_unavailable', 503);
    const parts: Buffer[] = [];
    for (let start = 0; start < meta.payload.parts; start += 16) {
      const docs = await this.db.getAll(...Array.from({length: Math.min(16, meta.payload.parts - start)}, (_, offset) =>
        ref.collection('parts').doc(String(start + offset).padStart(10, '0'))));
      for (let offset = 0; offset < docs.length; offset++) {
        const doc = docs[offset], v = doc?.data(), index = start + offset;
        if (!doc?.exists || !v || Object.keys(v).sort().join() !== ['schemaVersion', 'index', 'data', 'fingerprint'].sort().join() ||
            v.schemaVersion !== 1 || v.index !== index || typeof v.data !== 'string') ledgerError('service_unavailable', 503);
        const bytes = Buffer.from(v.data, 'base64'), count = index === meta.payload.parts - 1
          ? meta.payload.byteLength - index * partBytes : partBytes;
        if (bytes.length !== count || bytes.toString('base64') !== v.data || bytesHash(bytes) !== v.fingerprint) ledgerError('service_unavailable', 503);
        parts.push(bytes);
      }
    }
    const data = Buffer.concat(parts), json = data.toString('utf8');
    if (data.length !== meta.payload.byteLength || bytesHash(data) !== meta.payload.fingerprint ||
        !Buffer.from(json, 'utf8').equals(data)) ledgerError('service_unavailable', 503);
    return checkedLedgerRow({kind: meta.kind, id: meta.id, parentId: meta.parentId, revision: meta.revision,
      ordinal: meta.ordinal, json, fingerprint: meta.payload.fingerprint}, meta.scope);
  }
  private row(kind: LedgerKind, id: string, value: object, revision: number,
    parentId: string | null = null, ordinal: number | null = null): LedgerRow {
    return {kind, id, parentId, revision, ordinal, json: ledgerCanonical(value), fingerprint: ledgerHash(value)};
  }
  async list(actor: LedgerActor, raw: LedgerScope, kind: LedgerKind, parentId: string | null,
    cursor: string | null): Promise<LedgerPage> {
    const scope = this.scope(actor, raw);
    if (!kinds.includes(kind) || (kind === 'moneyEntry' ? !parentId : parentId !== null)) ledgerError();
    let last: string | null = null, cursorRevision: number | null = null;
    if (cursor !== null) {
      try {
        const v = JSON.parse(Buffer.from(cursor, 'base64url').toString('utf8'));
        if (Object.keys(v).sort().join() !== ['scope', 'kind', 'parentId', 'revision', 'last'].sort().join() ||
            Buffer.from(ledgerCanonical(v)).toString('base64url') !== cursor || !equal(v.scope, scope) ||
            v.kind !== kind || v.parentId !== parentId || !/^[a-f0-9]{64}$/.test(v.last)) ledgerError();
        cursorRevision = purchaseEntryRevision(v.revision); last = v.last;
      } catch {ledgerError('invalid_input', 400);}
    }
    const capture = await this.db.runTransaction(async tx => {
      await this.authority!.assertCurrent(tx, actor, scope);
      const head = await this.head(tx, scope);
      if (cursor !== null && head?.revision !== cursorRevision) ledgerError('stale_ledger', 409);
      let total = head?.counts[kind] ?? 0;
      if (kind === 'moneyEntry') {
        const register = await this.meta(tx, scope, 'moneyRegister', parentId!);
        if (!register) ledgerError('register_unavailable', 409);
        // Header payload is loaded below; its count is authoritative for this parent.
        return {head, register, total: -1};
      }
      return {head, register: null, total};
    });
    let total = capture.total;
    if (capture.register) total = checkedLedgerRegisterHeader(JSON.parse((await this.load(capture.register)).json), scope).entryCount;
    const collection = this.records(scope, kind, parentId);
    const count = await collection.count().get();
    if (count.data().count !== total) ledgerError('service_unavailable', 503);
    let query = collection.orderBy(FieldPath.documentId()).limit(pageSize + 1);
    if (last !== null) {
      const preceding = await collection.doc(last).get();
      if (!preceding.exists) ledgerError('service_unavailable', 503);
      query = query.startAfter(last);
    }
    const docs = await query.get(), rows: LedgerRow[] = [];
    let lastIncluded: string | null = null, hasMore = false, used = 0;
    for (const doc of docs.docs) {
      const meta = this.checkedMeta(doc.data(), scope);
      if (meta.kind !== kind || meta.parentId !== parentId || doc.id !== ledgerHash({id: meta.id}) ||
          !capture.head || meta.writeRevision > capture.head.revision) ledgerError('service_unavailable', 503);
      const identity = await this.identityRef(scope, kind, meta.id, parentId).get();
      if (!identity.exists || !equal(identity.data(), this.identity(meta))) ledgerError('service_unavailable', 503);
      if (rows.length === pageSize || rows.length > 0 && used + meta.payload.byteLength > 512 * 1024) {hasMore = true; break;}
      const row = await this.load(meta); rows.push(row); used += meta.payload.byteLength; lastIncluded = doc.id;
    }
    await this.db.runTransaction(async tx => {
      await this.authority!.assertCurrent(tx, actor, scope);
      if (!equal(await this.head(tx, scope), capture.head)) ledgerError('stale_ledger', 409);
      if (capture.register && !equal(await this.meta(tx, scope, 'moneyRegister', parentId!), capture.register)) ledgerError('stale_ledger', 409);
    });
    return {revision: capture.head?.revision ?? null, kind, parentId, totalCount: total,
      startsSource: cursor === null, rows, nextCursor: hasMore ? Buffer.from(ledgerCanonical({scope, kind,
        parentId, revision: capture.head!.revision, last: lastIncluded})).toString('base64url') : null};
  }
  private async receipt(actor: LedgerActor, scope: LedgerScope, key: string, fingerprint: string): Promise<LedgerReceipt | null> {
    return this.db.runTransaction(async tx => {
      await this.authority!.assertCurrent(tx, actor, scope);
      const value = await tx.get(this.attemptRef(scope, key));
      if (!value.exists) return null;
      if (value.get('fingerprint') !== fingerprint) ledgerError('idempotency_conflict', 409);
      return checkedLedgerReceipt(value.data(), scope, key, fingerprint);
    });
  }
  async status(actor: LedgerActor, raw: LedgerScope, key: string, fingerprint: string): Promise<LedgerStatus> {
    const scope = this.scope(actor, raw); purchaseEntryId(key); purchaseEntryFingerprint(fingerprint);
    let receipt = await this.receipt(actor, scope, key, fingerprint);
    // Close the receipt/head race without replaying a command.
    for (let pass = 0; pass < 3; pass++) {
      if (!receipt) {
        const head = await this.db.runTransaction(async tx => {await this.authority!.assertCurrent(tx, actor, scope); return this.head(tx, scope);});
        receipt = await this.receipt(actor, scope, key, fingerprint);
        if (receipt) continue;
        return {revision: head?.revision ?? null, receipt: null, current: null};
      }
      const captured = await this.snapshot(actor, scope, receipt.targetKind, receipt.targetId);
      const after = await this.receipt(actor, scope, key, fingerprint);
      if (!after || !equal(receipt, after)) ledgerError('service_unavailable', 503);
      if (receipt.resultRevision !== null && (!captured.head || captured.head.revision < receipt.resultRevision)) continue;
      if (receipt.status === 'saved') {
        if (!captured.row) ledgerError('service_unavailable', 503);
        if (receipt.operation === 'recordStoreExpense' && captured.row.fingerprint !== receipt.inputFingerprint ||
            receipt.operation === 'confirmStoreSupplierOpening' &&
            ledgerHash(JSON.parse(captured.row.json).openingRecord) !== receipt.inputFingerprint) ledgerError('service_unavailable', 503);
        if (receipt.operation === 'recordStoreSupplierMoney') {
          const entries = (JSON.parse(captured.row.json) as {entries: unknown[]}).entries;
          const matching = entries.filter(value => (value as {operationId?: unknown})?.operationId === receipt!.entryId);
          try {
            if (matching.length !== 1 || ledgerHash(checkedLedgerSupplierMoneyEntry(matching[0])) !== receipt.inputFingerprint) {
              ledgerError('service_unavailable', 503);
            }
          } catch {ledgerError('service_unavailable', 503);}
        } else if (receipt.operation === 'confirmStoreSupplierBill') {
          try {
            const ledger = JSON.parse(captured.row.json) as Record<string, unknown>;
            const bill = checkedLedgerSupplierBillAcceptance((ledger.purchaseBills as Record<string, unknown> | undefined)?.[receipt.entryId!]);
            const wanted = ledgerBillLiabilityEntry(bill), entries = ledger.entries as Record<string, unknown>[];
            const matching = entries.filter(entry => entry.kind === 'bill' && entry.billId === receipt!.entryId);
            if (bill.copy.draft.id !== receipt.entryId || ledgerHash(bill) !== receipt.inputFingerprint ||
                (wanted ? matching.length !== 1 || !equal(matching[0], wanted) : matching.length !== 0)) ledgerError('service_unavailable', 503);
          } catch {ledgerError('service_unavailable', 503);}
        } else if (receipt.operation === 'recordStoreSupplierMoneyAllocation') {
          try {
            const ledger = JSON.parse(captured.row.json);
            const proof = checkedLedgerSupplierAllocationProof(ledger.billMoneyAllocations?.[receipt.entryId!], scope);
            if (proof.operationId !== receipt.entryId || proof.supplierId !== receipt.targetId || proof.committedRevision > captured.row.revision ||
                ledgerHash(ledgerSupplierAllocationInput(proof)) !== receipt.inputFingerprint ||
                ledgerMicros(proof.recordedAt) > ledgerMicros(ledger.asOf)) ledgerError('service_unavailable', 503);
          } catch {ledgerError('service_unavailable', 503);}
        } else if (receipt.operation === 'recordStoreSupplierRefund') {
          try {
            const ledger = JSON.parse(captured.row.json), proof = checkedLedgerSupplierRefundProof(ledger.refunds?.[receipt.entryId!], scope);
            const matching = (ledger.entries as Record<string, unknown>[]).filter(entry => entry.operationId === receipt!.entryId);
            if (proof.intent.operationId !== receipt.entryId || proof.intent.supplierId !== receipt.targetId ||
                proof.committedRevision > captured.row.revision || ledgerHash(proof.intent) !== receipt.inputFingerprint ||
                ledgerMicros(proof.recordedAt) > ledgerMicros(ledger.asOf) || matching.length !== 1 ||
                !equal(matching[0], ledgerSupplierRefundEntry(proof))) ledgerError('service_unavailable', 503);
          } catch {ledgerError('service_unavailable', 503);}
        } else if (receipt.operation === 'recordStoreSupplierCreditNote') {
          try {
            const ledger = JSON.parse(captured.row.json), proof = checkedLedgerSupplierCreditProof(ledger.creditNotes?.[receipt.entryId!], scope);
            const matching = (ledger.entries as Record<string, unknown>[]).filter(entry => entry.operationId === receipt!.entryId);
            if (proof.operationId !== receipt.entryId || proof.supplierId !== receipt.targetId ||
                proof.committedRevision > captured.row.revision || ledgerHash(ledgerSupplierCreditInput(proof)) !== receipt.inputFingerprint ||
                ledgerMicros(proof.recordedAt) > ledgerMicros(ledger.asOf) || matching.length !== 1 ||
                !equal(matching[0], ledgerSupplierCreditEntry(proof))) ledgerError('service_unavailable', 503);
          } catch {ledgerError('service_unavailable', 503);}
        } else if (receipt.operation === 'recordStoreMoneyRegisterEntry') {
          const entry = await this.db.runTransaction(async tx => {await this.authority!.assertCurrent(tx, actor, scope);
            return this.meta(tx, scope, 'moneyEntry', receipt!.entryId!, receipt!.targetId);});
          const header = checkedLedgerRegisterHeader(JSON.parse(captured.row.json), scope);
          if (!entry || entry.payload.fingerprint !== receipt.inputFingerprint || entry.ordinal! > header.entryCount ||
              entry.writeRevision > captured.head!.revision) ledgerError('service_unavailable', 503);
          await this.load(entry);
        } else if (receipt.entryId !== null) ledgerError('service_unavailable', 503);
      }
      return {revision: captured.head?.revision ?? null, receipt, current: captured.row};
    }
    ledgerError('service_unavailable', 503);
  }
  recordExpense(actor: LedgerActor, command: LedgerExpenseCommand): Promise<LedgerStatus> {return this.save(actor, command);}
  confirmOpening(actor: LedgerActor, command: LedgerOpeningCommand): Promise<LedgerStatus> {return this.save(actor, command);}
  recordRegisterEntry(actor: LedgerActor, command: LedgerRegisterCommand): Promise<LedgerStatus> {return this.save(actor, command);}
  recordSupplierMoney(actor: LedgerActor, command: LedgerSupplierMoneyCommand): Promise<LedgerStatus> {return this.save(actor, command);}
  confirmSupplierBill(actor: LedgerActor, command: LedgerSupplierBillCommand): Promise<LedgerStatus> {return this.save(actor, command);}
  allocateSupplierMoney(actor: LedgerActor, command: LedgerSupplierAllocationCommand): Promise<LedgerStatus> {return this.save(actor, command);}
  recordSupplierRefund(actor: LedgerActor, command: LedgerSupplierRefundCommand): Promise<LedgerStatus> {return this.save(actor, command);}
  recordSupplierCredit(actor: LedgerActor, command: LedgerSupplierCreditCommand): Promise<LedgerStatus> {return this.save(actor, command);}
  private supplierFinancialHistory(ledger: Record<string, unknown>, scope: LedgerScope, supplierId: string) {
    return ledgerSupplierFinancialHistory(ledger, scope, supplierId);
  }
  private async supplierBillPlan(actor: LedgerActor, command: LedgerSupplierBillCommand, captured: Snapshot): Promise<Plan> {
    const result = (reason: string | null, writes: PlannedWrite[] = [], purchase: PurchaseEntryBook | null = null): Plan => ({reason, writes, purchase});
    if (!captured.row) return result('supplier_unavailable');
    const ledger = JSON.parse(captured.row.json) as Record<string, unknown>;
    if (!ledger.openingRecord || ledger.historyComplete !== true || ledger.openingBalanceMinor === null) return result('bill_opening_evidence_changed');
    const {opening, bills, parsed, balance} = this.supplierFinancialHistory(ledger, command.scope, command.supplierId);
    const bill = command.bill, id = bill.copy.draft.id, previous = parsed.get(id);
    if (previous) return result(equal(previous, bill) ? null : 'record_identity_conflict');
    if ((captured.head?.revision ?? null) !== command.expectedRevision) return result('stale_ledger');
    if (captured.row.revision !== command.expectedSupplierRevision) return result('stale_supplier');
    if (!this.purchase) ledgerError('service_unavailable', 503);
    const book = await this.purchase.capture(actor, command.scope);
    if (!book || book.revision !== command.expectedPurchaseRevision || ledgerHash(book) !== command.expectedPurchaseFingerprint) return result('stale_evidence');
    let copies: ReturnType<typeof checkedPurchaseEntryCopy>[];
    try {copies = (book.copies ?? []).map(value => checkedPurchaseEntryCopy(value, false));} catch {ledgerError('service_unavailable', 503);}
    const exact = copies.filter(copy => copy.id === bill.copy.id);
    if (exact.length !== 1 || !ledgerReviewedCopyMatches(exact[0]!, bill.copy) || !book.profiles.some(profile => profile.id === command.supplierId) ||
        copies.some(copy => copy.draft.id === id && copy.revision > bill.copy.revision) || parsed.size >= 1000) return result('bill_source_changed');
    const yearKey = (copy: typeof bill.copy) => `${purchaseEntryInvoiceFinancialYear(copy.draft.invoiceDate)}:${copy.draft.invoiceReference.trim().toUpperCase()}`;
    const latest = copies.filter(copy => !copies.some(other => other.draft.id === copy.draft.id && other.revision > copy.revision));
    if (latest.some(copy => copy.draft.id !== id && copy.supplier.id === command.supplierId && yearKey(copy) === yearKey(bill.copy)) ||
        [...parsed.values()].some(other => yearKey(other.copy) === yearKey(bill.copy))) return result('bill_source_changed');
    if (!ledgerBillOpeningMatches(bill, opening, command.confirmedUtcOffsetMinutes)) return result('bill_opening_evidence_changed');
    if (ledgerMicros(bill.acceptedAt) > ledgerMicros(this.now().toISOString())) return result('bill_confirmation_invalid');
    const entry = ledgerBillLiabilityEntry(bill), revision = next(captured.row.revision);
    if (entry && (ledger.entries as Record<string, unknown>[]).some(value => value.operationId === entry.operationId)) return result('record_identity_conflict');
    if (!Number.isSafeInteger(balance + (entry?.amountMinor as number | undefined ?? 0))) return result('bill_confirmation_invalid');
    const updated = {...ledger, revision, asOf: ledgerMicros(bill.acceptedAt) > ledgerMicros(ledger.asOf) ? bill.acceptedAt : ledger.asOf,
      purchaseBills: {...bills, [id]: bill}, entries: [...ledger.entries as unknown[], ...(entry ? [entry] : [])]};
    return result(null, [{row: this.row('supplierLedger', command.supplierId, updated, revision),
      ref: this.recordRef(command.scope, 'supplierLedger', command.supplierId), first: false}], book);
  }
  private supplierMoneyPlan(command: LedgerSupplierMoneyCommand, captured: Snapshot): Plan {
    const result = (reason: string | null, writes: PlannedWrite[] = []): Plan => ({reason, writes, purchase: null});
    if (!captured.row) return result('supplier_unavailable');
    const ledger = JSON.parse(captured.row.json) as Record<string, unknown>, entries = ledger.entries as unknown[];
    if (!ledger.openingRecord || ledger.historyComplete !== true || ledger.openingBalanceMinor === null) {
      return result('opening_evidence_changed');
    }
    // The original bill, typed credit and money history jointly prove capacity.
    // An opaque map is never an available balance source.
    const history = this.supplierFinancialHistory(ledger, command.scope, command.supplierId);
    const {opening, parsed, balance} = history;
    const existing = (entries as Record<string, unknown>[]).filter(value => value.operationId === command.entry.operationId);
    if (existing.length > 1) ledgerError('service_unavailable', 503);
    if (existing.length) return result(equal(existing[0], command.entry) ? null : 'record_identity_conflict');
    if ((captured.head?.revision ?? null) !== command.expectedRevision) return result('stale_ledger');
    if (captured.row.revision !== command.expectedSupplierRevision) return result('stale_supplier');
    const entry = command.entry;
    if (entry.moneyReview.openingId !== opening.id || entry.moneyReview.openingRevision !== opening.revision) {
      return result('opening_evidence_changed');
    }
    const local = new Date(Number(ledgerMicros(entry.postedAt) / 1000n) + command.confirmedUtcOffsetMinutes * 60000);
    const localDay = local.toISOString().slice(0, 10);
    if (ledgerMicros(entry.postedAt) > ledgerMicros(this.now().toISOString()) || entry.moneyReview.occurredOn > localDay) {
      return result('supplier_money_evidence_invalid');
    }
    if (entry.origin === 'manualPurchase') {
      const bill = parsed.get(entry.billId!);
      if (!bill || bill.openingTreatment !== 'excluded' || bill.copy.id !== entry.purchaseId ||
          ledgerMicros(entry.postedAt) < ledgerMicros(bill.acceptedAt)) return result('supplier_money_evidence_invalid');
      const remaining = history.billRemaining(entry.billId!);
      if (remaining === null || entry.amountMinor > remaining) {
        return result('supplier_capacity_changed');
      }
    }
    if (!Number.isSafeInteger(balance - entry.amountMinor) || entry.kind === 'payment' && entry.amountMinor > Math.max(balance, 0)) {
      return result('supplier_capacity_changed');
    }
    const revision = next(captured.row.revision), updated = {...ledger, revision,
      asOf: ledgerMicros(entry.postedAt) > ledgerMicros(ledger.asOf) ? entry.postedAt : ledger.asOf,
      entries: [...entries, entry]};
    this.supplierFinancialHistory(updated, command.scope, command.supplierId);
    return result(null, [{row: this.row('supplierLedger', command.supplierId, updated, revision),
      ref: this.recordRef(command.scope, 'supplierLedger', command.supplierId), first: false}]);
  }
  private supplierAllocationPlan(command: LedgerSupplierAllocationCommand, captured: Snapshot): Plan {
    const result = (reason: string | null, writes: PlannedWrite[] = []): Plan => ({reason, writes, purchase: null});
    if (!captured.row) return result('supplier_unavailable');
    const ledger = JSON.parse(captured.row.json) as Record<string, unknown>;
    if (!ledger.openingRecord || ledger.historyComplete !== true || ledger.openingBalanceMinor === null) return result('opening_evidence_changed');
    const history = this.supplierFinancialHistory(ledger, command.scope, command.supplierId), intent = command.intent;
    const old = history.allocations.get(intent.operationId);
    if (old) return result(equal(ledgerSupplierAllocationInput(old), intent) ? null : 'record_identity_conflict');
    if (history.entryById.has(intent.operationId)) return result('record_identity_conflict');
    if ((captured.head?.revision ?? null) !== command.expectedRevision) return result('stale_ledger');
    if (captured.row.revision !== command.expectedSupplierRevision) return result('stale_supplier');
    const opening = history.opening, bill = history.parsed.get(intent.billId), recordedAt = this.now().toISOString();
    if (intent.openingId !== opening.id || intent.openingRevision !== opening.revision) return result('opening_evidence_changed');
    if (!bill || bill.openingTreatment !== 'excluded' || bill.copy.id !== intent.copyId || bill.copy.revision !== intent.copyRevision) return result('allocation_source_changed');
    const sourceAmount = history.sourceAmount(intent.sourceKind, intent.sourceId),
      sourceEntry = history.entryById.get(intent.sourceId);
    if (sourceAmount === null) return result('allocation_source_changed');
    if (intent.sourceKind === 'manualBillSurplus') {
      const sourceBill = history.parsed.get(intent.sourceId);
      if (!sourceBill || sourceBill.copy.id !== intent.sourceCopyId || sourceBill.copy.revision !== intent.sourceCopyRevision) return result('allocation_source_changed');
    }
    if (ledgerMicros(recordedAt) < ledgerMicros(intent.requestedAt) || ledgerMicros(recordedAt) < ledgerMicros(ledger.asOf) ||
        ledgerMicros(recordedAt) < ledgerMicros(bill.acceptedAt) || ledgerMicros(recordedAt) < ledgerMicros(opening.savedAt) ||
        intent.sourceKind !== 'openingAdvance' && intent.sourceKind !== 'manualBillSurplus' &&
          (!sourceEntry || ledgerMicros(sourceEntry.postedAt) > ledgerMicros(recordedAt))) return result('allocation_confirmation_invalid');
    const remaining = history.billRemaining(intent.billId), available = history.sourceAvailable(intent.sourceKind, intent.sourceId);
    if (remaining === null || available === null || intent.amountMinor > remaining || intent.amountMinor > available) return result('allocation_capacity_changed');
    if (history.allocations.size >= 10000) return result('allocation_capacity_changed');
    const revision = next(captured.row.revision), proof = checkedLedgerSupplierAllocationProof({...intent,
      committedRevision: revision, recordedAt,
      ...(intent.sourceKind === 'manualBillSurplus' ? {sourceEntryCount: (ledger.entries as unknown[]).length} : {})}, command.scope);
    const updated = {...ledger, revision, asOf: recordedAt,
      billMoneyAllocations: {...ledger.billMoneyAllocations as object, [intent.operationId]: proof}};
    this.supplierFinancialHistory(updated, command.scope, command.supplierId);
    return result(null, [{row: this.row('supplierLedger', command.supplierId, updated, revision),
      ref: this.recordRef(command.scope, 'supplierLedger', command.supplierId), first: false}]);
  }
  private supplierRefundPlan(command: LedgerSupplierRefundCommand, captured: Snapshot): Plan {
    const result = (reason: string | null, writes: PlannedWrite[] = []): Plan => ({reason, writes, purchase: null});
    if (!captured.row) return result('supplier_unavailable');
    const ledger = JSON.parse(captured.row.json) as Record<string, unknown>;
    if (!ledger.openingRecord || ledger.historyComplete !== true || ledger.openingBalanceMinor === null) return result('opening_evidence_changed');
    const history = this.supplierFinancialHistory(ledger, command.scope, command.supplierId), intent = command.intent;
    const old = history.refunds.get(intent.operationId);
    if (old) return result(equal(old.intent, intent) ? null : 'record_identity_conflict');
    if (history.entryById.has(intent.operationId) || history.allocations.has(intent.operationId) ||
        ['goodsReturns', 'shortageClaims'].some(key => Object.hasOwn((ledger[key] ?? {}) as object, intent.operationId))) return result('record_identity_conflict');
    if ((captured.head?.revision ?? null) !== command.expectedRevision) return result('stale_ledger');
    if (captured.row.revision !== command.expectedSupplierRevision) return result('stale_supplier');
    const opening = history.opening, recordedAt = this.now().toISOString();
    if (intent.openingId !== opening.id || intent.openingRevision !== opening.revision || intent.qa !== opening.qa) return result('opening_evidence_changed');
    const localDay = new Date(Number(ledgerMicros(intent.requestedAt) / 1000n) + command.confirmedUtcOffsetMinutes * 60000).toISOString().slice(0, 10);
    if (intent.occurredOn < opening.asOfDate || intent.occurredOn > localDay ||
        ledgerMicros(intent.requestedAt) > ledgerMicros(recordedAt) || ledgerMicros(recordedAt) < ledgerMicros(ledger.asOf)) return result('refund_confirmation_invalid');
    // The native source contract has no accountPayment refund source. Bill
    // surplus is derived from its exact typed prefix, never net credit alone.
    const source = history.entryById.get(intent.sourceId), sourceAmount = history.sourceAmount(intent.sourceKind, intent.sourceId);
    const surplusCapacity = intent.sourceKind === 'manualBillSurplus'
      ? history.refundSurplusCapacity(intent, (ledger.entries as unknown[]).length, Number(ledger.revision) + 1, recordedAt) : null;
    if (sourceAmount === null || intent.sourceKind === 'manualBillSurplus' && surplusCapacity === null || intent.sourceKind === 'accountAdvance' &&
        (!source || intent.occurredOn < (source.moneyReview as {occurredOn: string}).occurredOn ||
          ledgerMicros(source.postedAt) > ledgerMicros(recordedAt))) return result('refund_source_changed');
    if ([...history.refunds.values()].some(value => value.intent.reference.toUpperCase() === intent.reference.toUpperCase())) return result('refund_reference_conflict');
    const available = intent.sourceKind === 'manualBillSurplus' ? surplusCapacity : history.sourceAvailable(intent.sourceKind, intent.sourceId);
    if (available === null || history.refunds.size >= 10000 || intent.amountMinor > available || intent.amountMinor > Math.max(-history.balance, 0) ||
        !Number.isSafeInteger(history.balance + intent.amountMinor)) return result('refund_capacity_changed');
    const revision = next(captured.row.revision), proof = checkedLedgerSupplierRefundProof({intent, committedRevision: revision, recordedAt}, command.scope);
    const updated = {...ledger, revision, asOf: recordedAt, refunds: {...ledger.refunds as object, [intent.operationId]: proof},
      entries: [...ledger.entries as unknown[], ledgerSupplierRefundEntry(proof)]};
    this.supplierFinancialHistory(updated, command.scope, command.supplierId);
    return result(null, [{row: this.row('supplierLedger', command.supplierId, updated, revision),
      ref: this.recordRef(command.scope, 'supplierLedger', command.supplierId), first: false}]);
  }
  private async supplierCreditPlan(actor: LedgerActor, command: LedgerSupplierCreditCommand, captured: Snapshot): Promise<Plan> {
    const result = (reason: string | null, writes: PlannedWrite[] = [], purchase: PurchaseEntryBook | null = null): Plan => ({reason, writes, purchase});
    if (!captured.row) return result('supplier_unavailable');
    const ledger = JSON.parse(captured.row.json) as Record<string, unknown>;
    if (!ledger.openingRecord || ledger.historyComplete !== true || ledger.openingBalanceMinor === null) return result('opening_evidence_changed');
    const history = this.supplierFinancialHistory(ledger, command.scope, command.supplierId), intent = command.intent;
    const old = history.credits.get(intent.operationId);
    if (old) return result(equal(ledgerSupplierCreditInput(old), intent) ? null : 'record_identity_conflict');
    if (history.entryById.has(intent.operationId) || history.allocations.has(intent.operationId) ||
        ['goodsReturns', 'shortageClaims'].some(key => Object.hasOwn((ledger[key] ?? {}) as object, intent.operationId))) return result('record_identity_conflict');
    if ((captured.head?.revision ?? null) !== command.expectedRevision) return result('stale_ledger');
    if (captured.row.revision !== command.expectedSupplierRevision) return result('stale_supplier');
    const bill = history.parsed.get(intent.billId), opening = history.opening, recordedAt = this.now().toISOString();
    if (intent.openingId !== opening.id || intent.openingRevision !== opening.revision) return result('opening_evidence_changed');
    if (!bill || bill.openingTreatment !== 'excluded' || bill.copy.id !== intent.copyId || bill.copy.revision !== intent.copyRevision) return result('credit_source_changed');
    if (!['return', 'shortage', 'damage'].includes(intent.documentInput.reasonCode)) return result('credit_source_changed');
    if (!this.purchase) ledgerError('service_unavailable', 503);
    const book = await this.purchase.capture(actor, command.scope);
    if (!book || book.revision !== command.expectedPurchaseRevision || ledgerHash(book) !== command.expectedPurchaseFingerprint) return result('stale_evidence');
    let copies: ReturnType<typeof checkedPurchaseEntryCopy>[];
    try {copies = (book.copies ?? []).map(value => checkedPurchaseEntryCopy(value, false));} catch {ledgerError('service_unavailable', 503);}
    const matching = copies.filter(copy => copy.id === intent.copyId);
    if (matching.length !== 1 || !ledgerReviewedCopyMatches(matching[0]!, bill.copy) || !book.profiles.some(profile => profile.id === command.supplierId) ||
        copies.some(copy => copy.draft.id === intent.billId && copy.revision > intent.copyRevision)) return result('credit_source_changed');
    const localDay = new Date(Number(ledgerMicros(intent.requestedAt) / 1000n) + command.confirmedUtcOffsetMinutes * 60000).toISOString().slice(0, 10);
    const printedTotal = ledgerSupplierCreditPrintedTotal(intent.documentInput);
    if (intent.occurredOn > localDay || ledgerMicros(intent.requestedAt) > ledgerMicros(recordedAt) ||
        ledgerMicros(recordedAt) < ledgerMicros(ledger.asOf) || ledgerMicros(recordedAt) < ledgerMicros(opening.savedAt) ||
        intent.documentInput.treatment === 'gst' && (printedTotal === null || printedTotal !== intent.amountMinor)) return result('credit_confirmation_invalid');
    if ([...history.credits.values()].some(note => note.reference.toUpperCase() === intent.reference.toUpperCase())) return result('credit_reference_conflict');
    if (history.credits.size >= 10000 || intent.amountMinor + (history.credited.get(intent.billId) ?? 0) >
        ledgerPrintedPaise(bill.copy.draft.details?.invoiceTotal)!) return result('credit_capacity_changed');
    const revision = next(captured.row.revision), proof = checkedLedgerSupplierCreditProof({...intent, recordedAt, committedRevision: revision}, command.scope);
    const updated = {...ledger, revision, asOf: recordedAt, creditNotes: {...ledger.creditNotes as object, [intent.operationId]: proof},
      entries: [...ledger.entries as unknown[], ledgerSupplierCreditEntry(proof)]};
    try {this.supplierFinancialHistory(updated, command.scope, command.supplierId);}
    catch (error) {
      if (error instanceof WorkspaceProfileError && error.code === 'service_unavailable') return result('credit_source_changed');
      throw error;
    }
    return result(null, [{row: this.row('supplierLedger', command.supplierId, updated, revision),
      ref: this.recordRef(command.scope, 'supplierLedger', command.supplierId), first: false}], book);
  }
  private async plan(actor: LedgerActor, command: LedgerCommand, captured: Snapshot): Promise<Plan> {
    const {scope} = command, target = ledgerCommandTarget(command);
    const result = (reason: string | null, writes: PlannedWrite[] = [], purchase: PurchaseEntryBook | null = null): Plan => ({reason, writes, purchase});
    if (command.operation === 'recordStoreExpense') {
      if (captured.row) return result(captured.row.fingerprint === ledgerHash(command.expense) ? null : 'record_identity_conflict');
      if ((captured.head?.revision ?? null) !== command.expectedRevision) return result('stale_ledger');
      return result(null, [{row: this.row('expense', target.id, command.expense, 1),
        ref: this.recordRef(scope, 'expense', target.id), first: true}]);
    }
    if (command.operation === 'confirmStoreSupplierOpening') {
      if (captured.row) return result(equal(JSON.parse(captured.row.json).openingRecord, command.opening) ? null : 'supplier_has_records');
      if ((captured.head?.revision ?? null) !== command.expectedRevision) return result('stale_ledger');
      if (!this.purchase) ledgerError('service_unavailable', 503);
      const book = await this.purchase.capture(actor, scope);
      if (!book || book.revision !== command.expectedPurchaseRevision || ledgerHash(book) !== command.expectedPurchaseFingerprint) return result('stale_evidence');
      const records = book.openingRecords ?? [], latest = [...records].reverse().find(raw =>
        (raw as Record<string, unknown>)?.supplierId === command.opening.supplierId);
      const supplier = book.profiles.find(profile => profile.id === command.opening.supplierId);
      if (!latest || !supplier || !equal(checkedLedgerOpening(latest, scope), command.opening)) return result('stale_evidence');
      let copies: ReturnType<typeof checkedPurchaseEntryCopy>[];
      try {copies = (book.copies ?? []).map(value => checkedPurchaseEntryCopy(value, false));}
      catch {ledgerError('service_unavailable', 503);}
      if (new Set(copies.map(copy => copy.id)).size !== copies.length || copies.some(copy => copy.revision > book.revision)) ledgerError('service_unavailable', 503);
      const copyById = new Map(copies.map(copy => [copy.id, copy]));
      if (command.opening.bills.some(link => {
        const copy = copyById.get(link.copyId);
        return !copy || copy.revision !== link.copyRevision || copy.revision >= command.opening.revision ||
          copy.draft.id !== link.draftId || copy.draft.supplierId !== command.opening.supplierId;
      })) ledgerError('service_unavailable', 503);
      const max = new Map<string, number>();
      for (const copy of copies) max.set(copy.draft.id, Math.max(max.get(copy.draft.id) ?? 0, copy.revision));
      const latestCopies = copies.filter(copy => copy.revision === max.get(copy.draft.id) && copy.supplier.id === supplier.id);
      if (latestCopies.length !== command.opening.bills.length || latestCopies.some(copy => !command.opening.bills.some(link =>
        link.copyId === copy.id && link.copyRevision === copy.revision && link.draftId === copy.draft.id && link.inclusion !== 'unknown'))) {
        return result('opening_bill_inclusion_missing');
      }
      let value: object;
      try {value = ledgerConfirmedOpening(command, supplier.name);} catch (error) {
        const code = (error as {code?: string}).code;
        if (code === 'opening_amount_unknown' || code === 'opening_confirmation_invalid') return result(code);
        throw error;
      }
      return result(null, [{row: this.row('supplierLedger', target.id, value, 1),
        ref: this.recordRef(scope, 'supplierLedger', target.id), first: true}], book);
    }
    if (command.operation === 'recordStoreSupplierMoney') return this.supplierMoneyPlan(command, captured);
    if (command.operation === 'confirmStoreSupplierBill') return this.supplierBillPlan(actor, command, captured);
    if (command.operation === 'recordStoreSupplierMoneyAllocation') return this.supplierAllocationPlan(command, captured);
    if (command.operation === 'recordStoreSupplierRefund') return this.supplierRefundPlan(command, captured);
    if (command.operation === 'recordStoreSupplierCreditNote') return this.supplierCreditPlan(actor, command, captured);
    if (!captured.row) return result('register_unavailable');
    const header = checkedLedgerRegisterHeader(JSON.parse(captured.row.json), scope);
    const previous = await this.db.runTransaction(async tx => {await this.authority!.assertCurrent(tx, actor, scope);
      return this.meta(tx, scope, 'moneyEntry', command.entry.id, command.registerId);});
    if (previous) return result(previous.payload.fingerprint === ledgerHash(command.entry) ? null : 'record_identity_conflict');
    if ((captured.head?.revision ?? null) !== command.expectedRevision) return result('stale_ledger');
    if (header.revision !== command.expectedRegisterRevision) return result('stale_register');
    const time = ledgerMicros(command.entry.occurredAt), asOf = ledgerMicros(command.capturedAt);
    if (asOf < ledgerMicros(header.asOf) || time >= asOf || time < ledgerMicros(header.openingAt) ||
        header.lastEntryAt !== null && time < ledgerMicros(header.lastEntryAt) ||
        header.historyComplete && time < ledgerMicros(header.asOf) ||
        !Number.isSafeInteger(header.sequenceValidationMinor + command.entry.deltaMinor)) return result('register_history_changed');
    const updated = {...header, revision: next(header.revision), asOf: command.capturedAt, entryCount: next(header.entryCount),
      lastEntryAt: command.entry.occurredAt, sequenceValidationMinor: header.sequenceValidationMinor + command.entry.deltaMinor};
    return result(null, [
      {row: this.row('moneyRegister', header.registerId, updated, updated.revision),
        ref: this.recordRef(scope, 'moneyRegister', header.registerId), first: false},
      {row: this.row('moneyEntry', command.entry.id, command.entry, 1, command.registerId, updated.entryCount),
        ref: this.recordRef(scope, 'moneyEntry', command.entry.id, command.registerId), first: true},
    ]);
  }
  private async save(actor: LedgerActor, raw: LedgerCommand): Promise<LedgerStatus> {
    const command = checkedLedgerCommand(ledgerClone(raw)), scope = this.scope(actor, command.scope), target = ledgerCommandTarget(command);
    const previous = await this.receipt(actor, scope, command.idempotencyKey, command.fingerprint);
    if (previous) return this.status(actor, scope, command.idempotencyKey, command.fingerprint);
    const captured = await this.snapshot(actor, scope, target.kind, target.id), plan = await this.plan(actor, command, captured);
    const revision = plan.writes.length ? next(captured.head?.revision ?? 0) : captured.head?.revision ?? null;
    const staged: RecordMeta[] = [];
    for (const write of plan.writes) staged.push(await this.stage(scope, write.row, revision!));
    try {
      await this.db.runTransaction(async tx => {
        await this.authority!.assertCurrent(tx, actor, scope);
        const head = await this.head(tx, scope), stored = await tx.get(this.attemptRef(scope, command.idempotencyKey));
        if (stored.exists) {
          if (stored.get('fingerprint') !== command.fingerprint) ledgerError('idempotency_conflict', 409);
          checkedLedgerReceipt(stored.data(), scope, command.idempotencyKey, command.fingerprint); return;
        }
        const current = await this.meta(tx, scope, target.kind, target.id);
        const unchanged = equal(head, captured.head) && equal(current, captured.meta);
        let reason = unchanged ? plan.reason : 'stale_ledger';
        if (unchanged && plan.purchase) {
          try {await this.purchase!.assertCurrent(tx, actor, scope, plan.purchase);} catch (error) {
            if (error instanceof WorkspaceProfileError && error.code === 'stale_evidence') reason = 'stale_evidence';
            else throw error;
          }
        }
        const financialEntry = command.operation === 'recordStoreSupplierMoney' ? command.entry
          : command.operation === 'confirmStoreSupplierBill' ? ledgerBillLiabilityEntry(command.bill)
          : command.operation === 'recordStoreSupplierMoneyAllocation' || command.operation === 'recordStoreSupplierRefund' || command.operation === 'recordStoreSupplierCreditNote' ? command.intent : null;
        const moneyIdentityRef = financialEntry ? this.supplierEntryIdentityRef(scope, financialEntry.operationId as string) : null;
        const moneyIdentity = moneyIdentityRef === null ? null : await tx.get(moneyIdentityRef);
        const expectedMoneyIdentity = financialEntry && (command.operation === 'recordStoreSupplierMoney' || command.operation === 'confirmStoreSupplierBill' || command.operation === 'recordStoreSupplierMoneyAllocation' || command.operation === 'recordStoreSupplierRefund' || command.operation === 'recordStoreSupplierCreditNote')
          ? {schemaVersion: 1, projectId: this.projectId, scope, supplierId: command.supplierId,
            operationId: financialEntry.operationId, inputFingerprint: ledgerHash(financialEntry)} : null;
        if (moneyIdentity?.exists && !equal(moneyIdentity.data(), expectedMoneyIdentity)) reason = 'record_identity_conflict';
        const billIdentityRef = command.operation === 'confirmStoreSupplierBill'
          ? this.supplierBillIdentityRef(scope, command.bill.copy.draft.id) : null;
        const billIdentity = billIdentityRef ? await tx.get(billIdentityRef) : null;
        const expectedBillIdentity = command.operation === 'confirmStoreSupplierBill'
          ? {schemaVersion: 1, projectId: this.projectId, scope, supplierId: command.supplierId,
            billId: command.bill.copy.draft.id, copyId: command.bill.copy.id, inputFingerprint: ledgerHash(command.bill)} : null;
        if (billIdentity?.exists && !equal(billIdentity.data(), expectedBillIdentity)) reason = 'record_identity_conflict';
        // Validate every first-record slot before any publication write.
        for (const write of plan.writes) if (write.first) {
          const existing = await this.meta(tx, scope, write.row.kind, write.row.id, write.row.parentId);
          if (existing) reason = 'stale_ledger';
        }
        const changed = reason === null && plan.writes.length > 0, recordedAt = this.now().toISOString();
        const receipt: LedgerReceipt = {schemaVersion: 1, scope, operation: command.operation,
          idempotencyKey: command.idempotencyKey, fingerprint: command.fingerprint,
          inputFingerprint: ledgerHash(ledgerCommandInput(command)), status: reason === null ? 'saved' : 'not_saved',
          reason, changed, resultRevision: changed ? revision : head?.revision ?? null,
          targetKind: target.kind, targetId: target.id, entryId: target.entryId, recordedAt};
        checkedLedgerReceipt(receipt, scope, command.idempotencyKey, command.fingerprint);
        if (changed) {
          if (moneyIdentityRef !== null && !moneyIdentity?.exists) tx.create(moneyIdentityRef, expectedMoneyIdentity!);
          if (billIdentityRef !== null && !billIdentity?.exists) tx.create(billIdentityRef, expectedBillIdentity!);
          const counts = {...(head?.counts ?? {supplierLedger: 0, expense: 0, moneyRegister: 0, moneyEntry: 0})};
          for (let index = 0; index < plan.writes.length; index++) {
            const write = plan.writes[index]!, meta = staged[index]!;
            if (write.first) {counts[write.row.kind] = next(counts[write.row.kind]);
              tx.create(this.identityRef(scope, meta.kind, meta.id, meta.parentId), this.identity(meta));}
            tx.set(write.ref, meta);
          }
          const updated: Head = {schemaVersion: 1, projectId: this.projectId, scope, revision: revision!, counts, updatedAt: recordedAt};
          tx.set(this.root(scope), updated);
        }
        tx.create(this.attemptRef(scope, command.idempotencyKey), receipt);
      });
    } catch (error) {
      // A transport failure may follow a committed transaction. Only its exact
      // original receipt can resolve the outcome; never retry a write here.
      const resolved = await this.status(actor, scope, command.idempotencyKey, command.fingerprint);
      if (resolved.receipt) return resolved;
      throw error;
    }
    return this.status(actor, scope, command.idempotencyKey, command.fingerprint);
  }
}
