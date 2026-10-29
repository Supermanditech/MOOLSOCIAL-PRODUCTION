import {createHash} from 'node:crypto';
import {FieldPath, type DocumentReference, type Firestore, type Transaction} from 'firebase-admin/firestore';
import {WorkspaceProfileError} from './workspace_profile_service.js';
import type {PurchaseEntryTransactionAuthority} from './workspace_purchase_entry_repository.js';
import {checkedPurchaseEntryScope, checkedPurchaseEntryCopy, purchaseEntryFingerprint, purchaseEntryId, purchaseEntryRevision,
  type PurchaseEntryBook} from './workspace_purchase_entry_service.js';
import {checkedLedgerCommand, checkedLedgerOpening, checkedLedgerReceipt, checkedLedgerRegisterHeader,
  checkedLedgerRow, ledgerCanonical, ledgerClone, ledgerCommandInput, ledgerCommandTarget,
  ledgerConfirmedOpening, ledgerCount, ledgerError, ledgerHash, ledgerMicros,
  type LedgerActor, type LedgerCommand, type LedgerExpenseCommand, type LedgerKind,
  type LedgerOpeningCommand, type LedgerPage, type LedgerReceipt, type LedgerRegisterCommand,
  type LedgerRepository, type LedgerRow, type LedgerScope, type LedgerStatus} from './workspace_ledger_service.js';

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
    const [identities, receipts] = await Promise.all([
      tx.get(this.root(scope).collection('recordIdentities').limit(1)),
      tx.get(this.root(scope).collection('attempts').where('status', '==', 'saved').limit(1)),
    ]);
    if (!identities.empty || !receipts.empty) ledgerError('service_unavailable', 503);
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
        if (receipt.entryId !== null) {
          const entry = await this.db.runTransaction(async tx => {await this.authority!.assertCurrent(tx, actor, scope);
            return this.meta(tx, scope, 'moneyEntry', receipt!.entryId!, receipt!.targetId);});
          const header = checkedLedgerRegisterHeader(JSON.parse(captured.row.json), scope);
          if (!entry || entry.payload.fingerprint !== receipt.inputFingerprint || entry.ordinal! > header.entryCount ||
              entry.writeRevision > captured.head!.revision) ledgerError('service_unavailable', 503);
          await this.load(entry);
        }
      }
      return {revision: captured.head?.revision ?? null, receipt, current: captured.row};
    }
    ledgerError('service_unavailable', 503);
  }
  recordExpense(actor: LedgerActor, command: LedgerExpenseCommand): Promise<LedgerStatus> {return this.save(actor, command);}
  confirmOpening(actor: LedgerActor, command: LedgerOpeningCommand): Promise<LedgerStatus> {return this.save(actor, command);}
  recordRegisterEntry(actor: LedgerActor, command: LedgerRegisterCommand): Promise<LedgerStatus> {return this.save(actor, command);}
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
