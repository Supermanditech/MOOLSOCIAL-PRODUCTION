import type {Firestore} from "firebase-admin/firestore";
import {cataloguePayloadHash, type StoreSkuRecord} from "./workspace_catalogue_service.js";
import {WorkspaceProfileError, type WorkspaceProfileRecord} from "./workspace_profile_service.js";

/** Owner-written pre-purchase text only. No quote, payment, refund or consent authority. */
export interface SupplierPolicyInput {
  title: string; body: string; productIds: string[];
  requiresAcceptance: boolean; validUntil: string | null;
}
export interface SupplierPolicyRecord extends SupplierPolicyInput {
  schemaVersion: 1; realm: "evaluation" | "production"; storeId: string;
  id: string; revision: number; publishedAt: string;
}
export interface SupplierPolicyCommand {
  ownerUserId: string; storeId: string; realm: "evaluation" | "production";
  expectedRevision: number; idempotencyKey: string; policy: SupplierPolicyInput;
  fingerprint: string; publishedAt: string;
}
export interface SupplierPolicyReceipt {fingerprint: string; record: SupplierPolicyRecord}
export interface SupplierPolicyPublicSnapshot {
  schemaVersion: 1; realm: "evaluation" | "production"; storeId: string; skuId: string;
  observedAt: string; state: "ready" | "none" | "unavailable";
  revision: number | null; requiresAcceptance: boolean | null;
  policy: {id: string; storeId: string; revision: string; title: string; body: string;
    productIds: string[]; requiresAcceptance: boolean; validUntil: string | null} | null;
}
export interface SupplierPolicyRepository {
  readonly realm: "evaluation" | "production";
  store(storeId: string): Promise<WorkspaceProfileRecord | undefined>;
  save(command: SupplierPolicyCommand): Promise<SupplierPolicyRecord>;
  read(profile: WorkspaceProfileRecord, owner?: string, skuId?: string): Promise<SupplierPolicyRecord | undefined>;
  reconcile(command: SupplierPolicyCommand): Promise<SupplierPolicyRecord | undefined>;
}

/** Pure projection of an already authorized atomic source read. Absence alone
 * means no policy; malformed/expired records remain unresolved, never optional. */
export function publicSupplierPolicySnapshot(raw: unknown, realm: "evaluation" | "production",
  storeId: string, skuId: string, at: string): SupplierPolicyPublicSnapshot {
  const base = {schemaVersion: 1 as const, realm, storeId, skuId, observedAt: at};
  try {
    id(storeId); id(skuId); time(at);
    const current = raw === null || raw === undefined ? undefined : record(raw, realm, storeId);
    if (!current || !current.productIds.includes(skuId)) {
      return {...base, state: "none", revision: current?.revision ?? 0, requiresAcceptance: false, policy: null};
    }
    if (current.publishedAt > at || current.validUntil !== null && current.validUntil <= at) {
      return {...base, state: "unavailable", revision: current.revision, requiresAcceptance: current.requiresAcceptance, policy: null};
    }
    return {...base, state: "ready", revision: current.revision, requiresAcceptance: current.requiresAcceptance, policy: {
      id: `${current.id}.${cataloguePayloadHash(skuId).slice(0, 16).toLowerCase()}`,
      storeId, revision: `policy-v${current.revision}`, title: current.title, body: current.body,
      productIds: [skuId], requiresAcceptance: current.requiresAcceptance, validUntil: current.validUntil}};
  } catch {
    return {...base, state: "unavailable", revision: null, requiresAcceptance: null, policy: null};
  }
}

function fail(code = "invalid_input", message = "Store policy is invalid.", status = 400): never {
  throw new WorkspaceProfileError(code, message, status);
}
function object(value: unknown, keys: string[]): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value) ||
      ![Object.prototype, null].includes(Object.getPrototypeOf(value))) fail();
  const row = value as Record<string, unknown>;
  if (Object.keys(row).length !== keys.length || keys.some(k => !Object.hasOwn(row, k))) fail();
  return row;
}
function text(value: unknown, max: number): string {
  if (typeof value !== "string" || !value.length || value !== value.trim() || value.length > max ||
      /[\u0000-\u0008\u000b\u000c\u000e-\u001f]/u.test(value)) fail();
  return value;
}
function id(value: unknown): string {
  const result = text(value, 128);
  if (!/^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$/u.test(result)) fail();
  return result;
}
function version(value: unknown, minimum = 0): number {
  if (!Number.isSafeInteger(value) || (value as number) < minimum || (value as number) > 1_000_000_000) fail();
  return value as number;
}
function time(value: unknown): string {
  if (typeof value !== "string" || !Number.isFinite(Date.parse(value)) || new Date(value).toISOString() !== value) fail();
  return value;
}
function policyInput(value: unknown): SupplierPolicyInput {
  const row = object(value, ["title", "body", "productIds", "requiresAcceptance", "validUntil"]);
  if (!Array.isArray(row.productIds) || row.productIds.length < 1 || row.productIds.length > 500 ||
      typeof row.requiresAcceptance !== "boolean") fail();
  const productIds = row.productIds.map(id).sort();
  if (new Set(productIds).size !== productIds.length) fail();
  return {title: text(row.title, 160), body: text(row.body, 12000), productIds,
    requiresAcceptance: row.requiresAcceptance, validUntil: row.validUntil === null ? null : time(row.validUntil)};
}
function policyId(realm: string, storeId: string): string {
  return `supplier-policy-${cataloguePayloadHash([realm, storeId]).slice(0, 32).toLowerCase()}`;
}
function recordInput(record: SupplierPolicyRecord): SupplierPolicyInput {
  return policyInput({title: record.title, body: record.body, productIds: record.productIds,
    requiresAcceptance: record.requiresAcceptance, validUntil: record.validUntil});
}
function record(value: unknown, realm: string, storeId: string): SupplierPolicyRecord {
  const row = object(value, ["schemaVersion", "realm", "storeId", "id", "revision", "publishedAt",
    "title", "body", "productIds", "requiresAcceptance", "validUntil"]);
  if (row.schemaVersion !== 1 || row.realm !== realm || row.storeId !== storeId || row.id !== policyId(realm, storeId)) fail();
  return {...policyInput({title: row.title, body: row.body, productIds: row.productIds,
    requiresAcceptance: row.requiresAcceptance, validUntil: row.validUntil}),
    schemaVersion: 1, realm: realm as SupplierPolicyRecord["realm"], storeId,
    id: String(row.id), revision: version(row.revision, 1), publishedAt: time(row.publishedAt)};
}
function owner(profile: WorkspaceProfileRecord | undefined, storeId: string, userId?: string): WorkspaceProfileRecord {
  if (!profile || profile.schemaVersion !== 1 || profile.workspaceId !== storeId ||
      (userId !== undefined && profile.ownerUserId !== userId)) fail("not_found", "That Store is unavailable.", 404);
  if (profile.familyId !== "products-trade" ||
      !(profile.profileId.startsWith("retailer-") || profile.profileId === "wholesaler" || profile.profileId === "manufacturer") ||
      profile.status !== "live") {
    fail("invalid_state", "This Store is not active.", 409);
  }
  return profile;
}
function savedSku(value: unknown, storeId: string, skuId: string): void {
  const sku = value as StoreSkuRecord | undefined;
  if (!sku || sku.schemaVersion !== 1 || sku.storeId !== storeId || sku.skuId !== skuId) {
    fail("invalid_state", "Choose products saved in this Store.", 409);
  }
  id(sku.canonicalProductId); id(sku.verifiedPackId); version(sku.revision, 1);
}
function request(ownerUserId: string, realm: SupplierPolicyRecord["realm"], raw: Readonly<Record<string, unknown>>,
  now: string): SupplierPolicyCommand {
  const body = object(structuredClone(raw), ["storeId", "expectedRevision", "idempotencyKey", "policy"]);
  const storeId = id(body.storeId), policy = policyInput(body.policy), expectedRevision = version(body.expectedRevision);
  const user = id(ownerUserId), idempotencyKey = id(body.idempotencyKey);
  return {ownerUserId: user, storeId, realm, expectedRevision, idempotencyKey, policy,
    fingerprint: cataloguePayloadHash({ownerUserId: user, storeId, realm, expectedRevision, policy}), publishedAt: time(now)};
}
function originalReceipt(command: SupplierPolicyCommand, receipt: SupplierPolicyReceipt): SupplierPolicyRecord {
  const original = record(receipt.record, command.realm, command.storeId);
  if (receipt.fingerprint !== command.fingerprint || original.revision !== command.expectedRevision + 1 ||
      cataloguePayloadHash(recordInput(original)) !== cataloguePayloadHash(command.policy)) {
    fail("conflict", "The policy request changed. Check its original result.", 409);
  }
  return original;
}

/** One current policy per Store; replacing it explicitly replaces its exact SKU applicability. */
export function planSupplierPolicySave(command: SupplierPolicyCommand, profile: WorkspaceProfileRecord | undefined,
  skus: ReadonlyMap<string, unknown>, current?: SupplierPolicyRecord, receipt?: SupplierPolicyReceipt,
  authorizationAt = command.publishedAt): SupplierPolicyRecord {
  owner(profile, command.storeId, command.ownerUserId);
  if (receipt) return originalReceipt(command, receipt);
  const prior = current && record(current, command.realm, command.storeId);
  if ((prior?.revision ?? 0) !== command.expectedRevision) fail("conflict", "Store policy changed. Refresh before publishing.", 409);
  const at = time(authorizationAt);
  if (command.publishedAt > at || command.policy.validUntil !== null && command.policy.validUntil <= at) {
    fail("invalid_input", "Choose a future policy expiry.");
  }
  for (const skuId of command.policy.productIds) savedSku(skus.get(skuId), command.storeId, skuId);
  return {...structuredClone(command.policy), schemaVersion: 1, realm: command.realm, storeId: command.storeId,
    id: policyId(command.realm, command.storeId), revision: command.expectedRevision + 1, publishedAt: command.publishedAt};
}

export class WorkspaceSupplierPolicyService {
  constructor(private readonly repository: SupplierPolicyRepository, private readonly now: () => Date = () => new Date()) {}
  async handleOwnerOperation(userId: string, operation: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    body = structuredClone(body);
    if (Buffer.byteLength(JSON.stringify({operation, ...body}), "utf8") > 60000) {
      fail("invalid_input", "Policy text or product selection is too large.");
    }
    let result: SupplierPolicyRecord | undefined;
    if (operation === "readStoreSupplierPolicy") {
      const query = object(body, ["storeId"]);
      result = await this.readOwned(userId, id(query.storeId));
    } else if (operation === "saveStoreSupplierPolicy") {
      result = await this.save(userId, body);
    } else if (operation === "reconcileStoreSupplierPolicy") {
      result = await this.reconcile(userId, body);
    } else {
      fail("invalid_input", "Unsupported Store policy action.");
    }
    return {schemaVersion: 1, realm: this.repository.realm, storeId: id(body.storeId),
      record: result ?? null, publicAvailabilityConfirmed: false};
  }
  private async command(userId: string, body: Readonly<Record<string, unknown>>) {
    const command = request(userId, this.repository.realm, body, this.now().toISOString());
    owner(await this.repository.store(command.storeId), command.storeId, command.ownerUserId);
    return command;
  }
  async save(userId: string, body: Readonly<Record<string, unknown>>): Promise<SupplierPolicyRecord> {
    return this.repository.save(await this.command(userId, body));
  }
  async reconcile(userId: string, body: Readonly<Record<string, unknown>>): Promise<SupplierPolicyRecord | undefined> {
    return this.repository.reconcile(await this.command(userId, body));
  }
  async readOwned(userId: string, storeId: string): Promise<SupplierPolicyRecord | undefined> {
    id(userId); id(storeId);
    const profile = owner(await this.repository.store(storeId), storeId, userId);
    const result = await this.repository.read(profile, userId);
    return result && record(result, this.repository.realm, storeId);
  }
  async forPublicSku(storeId: string, skuId: string): Promise<SupplierPolicyPublicSnapshot> {
    id(storeId); id(skuId);
    const base = () => ({schemaVersion: 1 as const, realm: this.repository.realm, storeId, skuId,
      observedAt: this.now().toISOString()});
    // Unavailable access/parse/read is not proof that policy acceptance is optional.
    try {
      const profile = owner(await this.repository.store(storeId), storeId);
      if (profile.shopEnabled !== true) return {...base(), state: "unavailable", revision: null, requiresAcceptance: null, policy: null};
      const raw = await this.repository.read(profile, undefined, skuId);
      return publicSupplierPolicySnapshot(raw, this.repository.realm, storeId, skuId, this.now().toISOString());
    } catch {
      return {...base(), state: "unavailable", revision: null, requiresAcceptance: null, policy: null};
    }
  }
}

export class FirestoreSupplierPolicyRepository implements SupplierPolicyRepository {
  constructor(private readonly firestore: Firestore, readonly realm: "evaluation" | "production",
    private readonly now: () => Date = () => new Date()) {}
  private root(storeId: string) {
    return this.firestore.collection("workspaceCatalogues").doc(this.realm).collection("stores").doc(id(storeId));
  }
  private profiles(storeId: string) {
    return this.firestore.collection("workspaceProfiles").where("workspaceId", "==", id(storeId)).limit(2);
  }
  async store(storeId: string): Promise<WorkspaceProfileRecord | undefined> {
    const result = await this.profiles(storeId).get();
    return result.docs.length === 1 && result.docs[0]!.id === result.docs[0]!.get("caseId")
      ? result.docs[0]!.data() as WorkspaceProfileRecord : undefined;
  }
  async save(command: SupplierPolicyCommand): Promise<SupplierPolicyRecord> {
    command = structuredClone(command);
    if (command.realm !== this.realm) fail();
    const root = this.root(command.storeId), head = root.collection("supplierPolicies").doc("current");
    const receiptRef = head.collection("receipts").doc(cataloguePayloadHash([command.ownerUserId, command.idempotencyKey]));
    return this.firestore.runTransaction(async transaction => {
      const [profiles, current, receipt] = await Promise.all([transaction.get(this.profiles(command.storeId)),
        transaction.get(head), transaction.get(receiptRef)]);
      const profile = profiles.docs.length === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get("caseId")
        ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined;
      const skus = new Map<string, unknown>();
      if (!receipt.exists) {
        const docs = await transaction.getAll(...command.policy.productIds.map(skuId => root.collection("skus").doc(skuId)));
        for (const doc of docs) skus.set(doc.id, doc.data());
      }
      const result = planSupplierPolicySave(command, profile, skus,
        current.exists ? current.data() as SupplierPolicyRecord : undefined,
        receipt.exists ? receipt.data() as SupplierPolicyReceipt : undefined, this.now().toISOString());
      if (!receipt.exists) {
        transaction.set(head, result);
        transaction.create(head.collection("revisions").doc(String(result.revision)), result);
        transaction.create(receiptRef, {fingerprint: command.fingerprint, record: result});
      }
      return result;
    });
  }
  async read(profile: WorkspaceProfileRecord, userId?: string, skuId?: string): Promise<SupplierPolicyRecord | undefined> {
    const storeId = id(profile.workspaceId), root = this.root(storeId);
    return this.firestore.runTransaction(async transaction => {
      const profiles = await transaction.get(this.profiles(storeId));
      const currentStore = profiles.docs.length === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get("caseId")
        ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined;
      const fresh = owner(currentStore, storeId, userId);
      if (userId === undefined && (fresh.shopEnabled !== true || skuId === undefined)) fail("not_found", "That Store is unavailable.", 404);
      if (skuId !== undefined) {
        const sku = await transaction.get(root.collection("skus").doc(id(skuId)));
        savedSku(sku.data(), storeId, skuId);
        if (userId === undefined && sku.get("publicListing") !== true) fail("not_found", "That product is unavailable.", 404);
      }
      const result = await transaction.get(root.collection("supplierPolicies").doc("current"));
      return result.exists ? record(result.data(), this.realm, storeId) : undefined;
    });
  }
  async reconcile(command: SupplierPolicyCommand): Promise<SupplierPolicyRecord | undefined> {
    command = structuredClone(command);
    if (command.realm !== this.realm) fail();
    const receipt = this.root(command.storeId).collection("supplierPolicies").doc("current")
      .collection("receipts").doc(cataloguePayloadHash([command.ownerUserId, command.idempotencyKey]));
    return this.firestore.runTransaction(async transaction => {
      const [profiles, result] = await Promise.all([transaction.get(this.profiles(command.storeId)), transaction.get(receipt)]);
      owner(profiles.docs.length === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get("caseId")
        ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined, command.storeId, command.ownerUserId);
      return result.exists ? originalReceipt(command, result.data() as SupplierPolicyReceipt) : undefined;
    });
  }
}
