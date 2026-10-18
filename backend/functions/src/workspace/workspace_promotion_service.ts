import {FieldPath, type Firestore} from "firebase-admin/firestore";
import {cataloguePayloadHash, type WorkspaceCatalogueService} from "./workspace_catalogue_service.js";
import {WorkspaceProfileError, type WorkspaceProfileRecord} from "./workspace_profile_service.js";

/** Public product promotion only: no discount, consent, redemption or order authority. */
export interface PromotionInput {
  skuId: string; skuRevision: number; channel: "retail" | "wholesale" | "bulk";
  headline: string; detail: string; validFrom: string; validUntil: string; active: boolean;
}
export interface PromotionRecord extends PromotionInput {
  schemaVersion: 1; realm: "evaluation" | "production"; storeId: string;
  placementId: string; revision: number; observedAt: string;
}
export interface PromotionCommand {
  ownerUserId: string; realm: PromotionRecord["realm"]; storeId: string; placementId: string;
  expectedRevision: number; idempotencyKey: string; promotion: PromotionInput;
  fingerprint: string; observedAt: string;
}
export interface PromotionReceipt {fingerprint: string; record: PromotionRecord}
export interface PromotionRepository {
  readonly realm: PromotionRecord["realm"];
  store(storeId: string): Promise<WorkspaceProfileRecord | undefined>;
  save(command: PromotionCommand): Promise<PromotionRecord>;
  read(storeId: string, placementId: string, userId?: string): Promise<PromotionRecord | undefined>;
  page(storeId: string, after: string | undefined, limit: number, userId?: string): Promise<PromotionRecord[]>;
  reconcile(command: PromotionCommand): Promise<PromotionRecord | undefined>;
}
interface PublicSku extends Record<string, unknown> {skuId: string; channels: Record<string, unknown>[]}
export interface PublicPromotion {
  publicationId: string; revision: number; publisherType: "retailer"; publisherId: string;
  publisherName: string; headline: string; detail: string; sourceId: string;
  observedAt: string; validUntil: string; product: PublicSku;
}
interface PublicPromotionPage {
  schemaVersion: 1; realm: PromotionRecord["realm"]; storeId: string; observedAt: string;
  state: "ready" | "unavailable"; coverage: "verified_public_promotions_only";
  orderingAvailable: false; items: PublicPromotion[]; nextCursor: string | null;
}
function fail(code = "invalid_input", status = 400): never {
  throw new WorkspaceProfileError(code, "Product promotion could not be confirmed.", status);
}
function object(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value) ||
      ![Object.prototype, null].includes(Object.getPrototypeOf(value))) fail();
  return value as Record<string, unknown>;
}
function exact(value: unknown, keys: string[], optional: string[] = []): Record<string, unknown> {
  const row = object(value);
  if (keys.some(k => !Object.hasOwn(row, k)) || Object.keys(row).some(k => ![...keys, ...optional].includes(k))) fail();
  return row;
}
function text(value: unknown, max: number): string {
  if (typeof value !== "string" || !value || value !== value.trim() || value.length > max ||
      /[\u0000-\u0008\u000b\u000c\u000e-\u001f]/u.test(value)) fail();
  return value;
}
function id(value: unknown): string {
  const result = text(value, 128);
  if (!/^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$/u.test(result)) fail();
  return result;
}
function integer(value: unknown, minimum = 0, maximum = 1_000_000_000): number {
  if (!Number.isSafeInteger(value) || (value as number) < minimum || (value as number) > maximum) fail();
  return value as number;
}
function time(value: unknown): string {
  if (typeof value !== "string" || !Number.isFinite(Date.parse(value)) || new Date(value).toISOString() !== value) fail();
  return value;
}
const inputKeys = ["skuId", "skuRevision", "channel", "headline", "detail", "validFrom", "validUntil", "active"];
function input(value: unknown): PromotionInput {
  const row = exact(value, inputKeys);
  if (typeof row.channel !== "string" || !["retail", "wholesale", "bulk"].includes(row.channel) || typeof row.active !== "boolean") fail();
  const validFrom = time(row.validFrom), validUntil = time(row.validUntil);
  if (validFrom >= validUntil) fail();
  return {skuId: id(row.skuId), skuRevision: integer(row.skuRevision, 1), channel: row.channel as PromotionInput["channel"],
    headline: text(row.headline, 160), detail: text(row.detail, 2000), validFrom, validUntil, active: row.active};
}
function record(value: unknown, realm: PromotionRecord["realm"], storeId: string): PromotionRecord {
  const row = exact(value, [...inputKeys, "schemaVersion", "realm", "storeId", "placementId", "revision", "observedAt"]);
  if (row.schemaVersion !== 1 || row.realm !== realm || row.storeId !== storeId) fail();
  return {...input(Object.fromEntries(inputKeys.map(k => [k, row[k]]))), schemaVersion: 1, realm, storeId,
    placementId: id(row.placementId), revision: integer(row.revision, 1), observedAt: time(row.observedAt)};
}
function owner(profile: WorkspaceProfileRecord | undefined, storeId: string, userId?: string): WorkspaceProfileRecord {
  if (!profile || profile.schemaVersion !== 1 || profile.workspaceId !== storeId ||
      userId !== undefined && profile.ownerUserId !== userId) fail("not_found", 404);
  if (profile.familyId !== "products-trade" || !profile.profileId.startsWith("retailer-") || profile.status !== "live") fail("invalid_state", 409);
  if (userId === undefined && profile.shopEnabled !== true) fail("not_found", 404);
  return profile;
}
function checkSku(raw: unknown, storeId: string, promotion: PromotionInput): void {
  const sku = object(raw);
  if (sku.schemaVersion !== 1 || sku.storeId !== storeId || sku.skuId !== promotion.skuId ||
      sku.revision !== promotion.skuRevision || sku.publicListing !== true ||
      !Array.isArray(sku.channels) || !sku.channels.some(c => object(c).kind === promotion.channel)) fail("invalid_state", 409);
  id(sku.canonicalProductId); id(sku.verifiedPackId);
}
function request(userId: string, realm: PromotionRecord["realm"], raw: Readonly<Record<string, unknown>>, now: string): PromotionCommand {
  const row = exact(structuredClone(raw), ["storeId", "placementId", "expectedRevision", "idempotencyKey", "promotion"]);
  const facts = {ownerUserId: id(userId), realm, storeId: id(row.storeId), placementId: id(row.placementId),
    expectedRevision: integer(row.expectedRevision), promotion: input(row.promotion)};
  return {...facts, idempotencyKey: id(row.idempotencyKey), fingerprint: cataloguePayloadHash(facts), observedAt: time(now)};
}
function original(command: PromotionCommand, receipt: PromotionReceipt): PromotionRecord {
  const result = record(receipt.record, command.realm, command.storeId);
  if (receipt.fingerprint !== command.fingerprint || result.placementId !== command.placementId ||
      result.revision !== command.expectedRevision + 1 ||
      cataloguePayloadHash(Object.fromEntries(inputKeys.map(k => [k, result[k as keyof PromotionInput]]))) !== cataloguePayloadHash(command.promotion)) fail("conflict", 409);
  return result;
}
/** Atomic planner. Historical receipt is not current publication or renewed validity. */
export function planPromotionSave(command: PromotionCommand, profile: WorkspaceProfileRecord | undefined,
  sku: unknown, current?: PromotionRecord, receipt?: PromotionReceipt, authorizationAt = command.observedAt): PromotionRecord {
  owner(profile, command.storeId, command.ownerUserId);
  if (receipt) return original(command, receipt);
  const prior = current && record(current, command.realm, command.storeId);
  if (prior?.placementId !== undefined && prior.placementId !== command.placementId ||
      (prior?.revision ?? 0) !== command.expectedRevision) fail("conflict", 409);
  if (command.observedAt > time(authorizationAt)) fail();
  // Pausing an original publication must remain possible after source/expiry loss.
  if (!command.promotion.active && prior) {
    const old = Object.fromEntries(inputKeys.map(k => [k, prior[k as keyof PromotionInput]]));
    if (cataloguePayloadHash({...old, active: false}) !== cataloguePayloadHash(command.promotion)) fail("invalid_state", 409);
  } else {
    if (!command.promotion.active || command.promotion.validUntil <= authorizationAt) fail();
    checkSku(sku, command.storeId, command.promotion);
  }
  return {...structuredClone(command.promotion), schemaVersion: 1, realm: command.realm, storeId: command.storeId,
    placementId: command.placementId, revision: command.expectedRevision + 1, observedAt: command.observedAt};
}

export class WorkspacePromotionService {
  constructor(private readonly repository: PromotionRepository,
    private readonly catalogue: Pick<WorkspaceCatalogueService, "publicCatalogue">,
    private readonly now: () => Date = () => new Date()) {}
  /** Endpoint still performs Firebase/default-tenant/AppCheck verification. */
  async handleOperation(userId: string, operation: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    id(userId); body = structuredClone(body);
    if (Buffer.byteLength(JSON.stringify({operation, ...body}), "utf8") > 60000) fail();
    if (operation === "readPublicStorePromotions") return this.publicPage(body);
    if (operation === "listStorePromotions") {
      const query = exact(body, ["storeId", "limit"], ["after"]), storeId = id(query.storeId);
      const limit = integer(query.limit, 1, 20), after = query.after === undefined ? undefined : id(query.after);
      owner(await this.repository.store(storeId), storeId, userId);
      const rows = (await this.repository.page(storeId, after, limit, userId)).map(r => record(r, this.repository.realm, storeId));
      return {schemaVersion: 1, realm: this.repository.realm, storeId, items: rows,
        nextCursor: rows.length === limit ? rows.at(-1)!.placementId : null, publicationConfirmed: false};
    }
    let result: PromotionRecord | undefined;
    if (operation === "saveStorePromotion") result = await this.save(userId, body);
    else if (operation === "readStorePromotion") result = await this.readOwned(userId, body);
    else if (operation === "reconcileStorePromotion") result = await this.reconcile(userId, body);
    else fail();
    return {schemaVersion: 1, realm: this.repository.realm, storeId: id(body.storeId),
      record: result ?? null, publicationConfirmed: false};
  }
  private async command(userId: string, body: Readonly<Record<string, unknown>>): Promise<PromotionCommand> {
    const command = request(userId, this.repository.realm, body, this.now().toISOString());
    owner(await this.repository.store(command.storeId), command.storeId, userId);
    return command;
  }
  async save(userId: string, body: Readonly<Record<string, unknown>>): Promise<PromotionRecord> {
    return this.repository.save(await this.command(userId, body));
  }
  async reconcile(userId: string, body: Readonly<Record<string, unknown>>): Promise<PromotionRecord | undefined> {
    return this.repository.reconcile(await this.command(userId, body));
  }
  async readOwned(userId: string, body: Readonly<Record<string, unknown>>): Promise<PromotionRecord | undefined> {
    const query = exact(body, ["storeId", "placementId"]), storeId = id(query.storeId), placementId = id(query.placementId);
    id(userId); owner(await this.repository.store(storeId), storeId, userId);
    const result = await this.repository.read(storeId, placementId, userId);
    return result && record(result, this.repository.realm, storeId);
  }
  async publicPage(body: Readonly<Record<string, unknown>>): Promise<PublicPromotionPage> {
    const query = exact(structuredClone(body), ["storeId", "limit"], ["after"]), storeId = id(query.storeId);
    const limit = integer(query.limit, 1, 20), after = query.after === undefined ? undefined : id(query.after);
    const base = (): Omit<PublicPromotionPage, "state" | "items" | "nextCursor"> => ({schemaVersion: 1,
      realm: this.repository.realm, storeId, observedAt: this.now().toISOString(), orderingAvailable: false,
      coverage: "verified_public_promotions_only"});
    try {
      owner(await this.repository.store(storeId), storeId);
      const rows = (await this.repository.page(storeId, after, limit)).map(r => record(r, this.repository.realm, storeId));
      const items: PublicPromotion[] = [];
      for (const promotion of rows) {
        let now = this.now().toISOString();
        if (!promotion.active || promotion.observedAt > now || promotion.validFrom > now || promotion.validUntil <= now) continue;
        const response = object(await this.catalogue.publicCatalogue({storeId, skuId: promotion.skuId,
          policyReadbackVersion: 1, productFactsReadbackVersion: 1, unbrandedProduceReadbackVersion: 1}));
        if (response.schemaVersion !== 1 || response.realm !== this.repository.realm || response.storeId !== storeId ||
            response.state !== "ready" || response.orderingAvailable !== false || response.coverage !== "verified_public_only" ||
            time(response.observedAt) > this.now().toISOString() || !Array.isArray(response.items) || response.items.length > 1) fail();
        if (!response.items.length) continue;
        const source = object(response.items[0]);
        if (source.skuId !== promotion.skuId || source.revision !== promotion.skuRevision || !Array.isArray(source.channels)) continue;
        const channels = source.channels.map(object).filter(c => c.kind === promotion.channel);
        if (channels.length !== 1) continue;
        now = this.now().toISOString();
        const validUntil = [promotion.validUntil, time(channels[0]!.validUntil)].sort()[0]!;
        if (validUntil <= now || promotion.validFrom > now) continue;
        const fresh = await this.repository.read(storeId, promotion.placementId);
        if (!fresh || cataloguePayloadHash(record(fresh, this.repository.realm, storeId)) !== cataloguePayloadHash(promotion)) continue;
        const freshStore = owner(await this.repository.store(storeId), storeId);
        now = this.now().toISOString();
        if (validUntil <= now) continue;
        const product = Object.fromEntries(["skuId", "canonicalProductId", "verifiedPackId", "sku", "revision", "observedAt",
          "content", "pack", "supplierPolicy"].filter(k => Object.hasOwn(source, k)).map(k => [k, structuredClone(source[k])])) as PublicSku;
        product.channels = structuredClone(channels);
        items.push({publicationId: promotion.placementId, revision: promotion.revision, publisherType: "retailer",
          publisherId: storeId, publisherName: text(freshStore.name, 240), headline: promotion.headline, detail: promotion.detail,
          sourceId: `store-promotion:${this.repository.realm}:${storeId}:${promotion.placementId}:${promotion.revision}`,
          observedAt: now, validUntil, product});
      }
      return {...base(), state: "ready", items, nextCursor: rows.length === limit ? rows.at(-1)!.placementId : null};
    } catch {return {...base(), state: "unavailable", items: [], nextCursor: null};}
  }
}

export class FirestorePromotionRepository implements PromotionRepository {
  constructor(private readonly firestore: Firestore, readonly realm: PromotionRecord["realm"],
    private readonly now: () => Date = () => new Date()) {
    if (!["evaluation", "production"].includes(realm)) fail();
  }
  private root(storeId: string) {return this.firestore.collection("workspaceCatalogues").doc(this.realm).collection("stores").doc(id(storeId));}
  private profiles(storeId: string) {return this.firestore.collection("workspaceProfiles").where("workspaceId", "==", id(storeId)).limit(2);}
  async store(storeId: string): Promise<WorkspaceProfileRecord | undefined> {
    const result = await this.profiles(storeId).get();
    return result.size === 1 && result.docs[0]!.id === result.docs[0]!.get("caseId") ? result.docs[0]!.data() as WorkspaceProfileRecord : undefined;
  }
  async save(command: PromotionCommand): Promise<PromotionRecord> {
    command = structuredClone(command);
    if (command.realm !== this.realm) fail();
    const root = this.root(command.storeId), head = root.collection("promotions").doc(id(command.placementId));
    const receiptRef = root.collection("promotionReceipts").doc(cataloguePayloadHash([command.ownerUserId, command.idempotencyKey]));
    return this.firestore.runTransaction(async transaction => {
      const [profiles, current, receipt] = await Promise.all([transaction.get(this.profiles(command.storeId)), transaction.get(head), transaction.get(receiptRef)]);
      const profile = profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get("caseId") ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined;
      const sku = receipt.exists ? undefined : (await transaction.get(root.collection("skus").doc(id(command.promotion.skuId)))).data();
      const result = planPromotionSave(command, profile, sku, current.exists ? current.data() as PromotionRecord : undefined,
        receipt.exists ? receipt.data() as PromotionReceipt : undefined, this.now().toISOString());
      if (!receipt.exists) {
        transaction.set(head, result);
        transaction.create(head.collection("revisions").doc(String(result.revision)), result);
        transaction.create(receiptRef, {fingerprint: command.fingerprint, record: result});
      }
      return result;
    });
  }
  async read(storeId: string, placementId: string, userId?: string): Promise<PromotionRecord | undefined> {
    return this.firestore.runTransaction(async transaction => {
      const profiles = await transaction.get(this.profiles(storeId));
      owner(profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get("caseId") ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined, storeId, userId);
      const result = await transaction.get(this.root(storeId).collection("promotions").doc(id(placementId)));
      if (!result.exists) return undefined;
      const value = record(result.data(), this.realm, storeId);
      if (value.placementId !== placementId) fail();
      if (userId === undefined) {
        const sku = await transaction.get(this.root(storeId).collection("skus").doc(value.skuId));
        checkSku(sku.data(), storeId, value);
      }
      return value;
    });
  }
  async page(storeId: string, after: string | undefined, limit: number, userId?: string): Promise<PromotionRecord[]> {
    return this.firestore.runTransaction(async transaction => {
      const profiles = await transaction.get(this.profiles(storeId));
      owner(profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get("caseId") ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined, storeId, userId);
      let query = this.root(storeId).collection("promotions").orderBy(FieldPath.documentId()).limit(integer(limit, 1, 20));
      if (after !== undefined) query = query.startAfter(id(after));
      const result = await transaction.get(query);
      return result.docs.map(d => {const value = record(d.data(), this.realm, storeId); if (value.placementId !== d.id) fail(); return value;});
    });
  }
  async reconcile(command: PromotionCommand): Promise<PromotionRecord | undefined> {
    command = structuredClone(command);
    if (command.realm !== this.realm) fail();
    return this.firestore.runTransaction(async transaction => {
      const [profiles, receipt] = await Promise.all([transaction.get(this.profiles(command.storeId)),
        transaction.get(this.root(command.storeId).collection("promotionReceipts").doc(cataloguePayloadHash([command.ownerUserId, command.idempotencyKey])))]);
      owner(profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get("caseId") ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined,
        command.storeId, command.ownerUserId);
      return receipt.exists ? original(command, receipt.data() as PromotionReceipt) : undefined;
    });
  }
}
