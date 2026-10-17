import {createHash} from "node:crypto";
import {FieldPath, type Firestore} from "firebase-admin/firestore";
import {applyCatalogueCommand, createCatalogueAggregate, referencedOfferTermAt,
  type CatalogueAggregate, type CatalogueCommand} from "../commerce/catalogue_contract.js";
import {isSupplyCapabilityActive, type SupplyActor,
  type SupplyCapabilityQuery, type SupplyParticipantWorkspace} from "../commerce/supply_participant_contract.js";
import {WorkspaceProfileError, type WorkspaceProfileRecord} from "./workspace_profile_service.js";
import {publicSupplierPolicySnapshot, type WorkspaceSupplierPolicyService} from "./workspace_supplier_policy_service.js";

/** Publication mirror only. Never an inventory, order, payment or approval ledger. */
export interface StoreSkuContent {
  title: string; brand: string; variant: string; categoryId: string;
  description: string; highlights: string[];
  specifications: Array<{label: string; value: string}>;
  media: Array<{id: string; revision: string; url: string; storeId: string;
    skuId: string; canonicalProductId: string; publisherWorkspaceId: string;
    file: {mimeType: string; byteLength: number; width: number; height: number; normalized: boolean; frameCount?: number}}>;
}
export interface StoreSkuPack {
  label: string; quantityMilli: number; unit: "kg" | "L" | "count"; unitsPerCase: number;
}
export interface StoreSkuChannel {
  kind: "retail" | "wholesale" | "bulk"; offerId: string;
  priceMinor: number; mrpMinor: number | null; minimumOrder: number;
  quantityStep: number; tiers: Array<{minimumQuantity: number; unitPriceMinor: number}>;
}
export interface StoreSkuInput {
  skuId: string; canonicalProductId: string; verifiedPackId: string; sku: string;
  publicListing: boolean; content: StoreSkuContent; pack: StoreSkuPack;
  channels: StoreSkuChannel[];
  provenance: {entryMethod: "catalogue" | "manual" | "csv"; sourceRecordId: string};
}
export interface StoreSkuRecord extends StoreSkuInput {
  schemaVersion: 1; storeId: string; revision: number; observedAt: string;
}
/** Server-issued listing identity. Original Store SKU/Stock identity is unchanged. */
export interface PublicCatalogueListingBinding {
  schemaVersion: 1; realm: "evaluation" | "production"; listingId: string;
  storeId: string; skuId: string; channel: StoreSkuChannel["kind"];
  canonicalProductId: string; verifiedPackId: string;
}
export interface CatalogueSave {
  ownerUserId: string; profile: WorkspaceProfileRecord; expectedRevision: number;
  idempotencyKey: string; fingerprint: string; input: StoreSkuInput; observedAt: string;
}
/** Explicitly public, descriptive owner text. Never upload private settings. */
export interface StorePublicDetailsInput {
  street: string; city: string; state: string; pinCode: string;
  publicContactPhone: string; openingTime: string; closingTime: string;
}
export interface StorePublicDetailsRecord {
  schemaVersion: 1; realm: "evaluation" | "production"; storeId: string;
  revision: number; publishedAt: string; details: StorePublicDetailsInput;
}
export interface StorePublicDetailsCommand {
  ownerUserId: string; storeId: string; realm: StorePublicDetailsRecord["realm"];
  expectedRevision: number; idempotencyKey: string; fingerprint: string;
  publishedAt: string; details: StorePublicDetailsInput;
}
export interface StorePublicDetailsReceipt {fingerprint: string; record: StorePublicDetailsRecord}
export interface WorkspaceCatalogueRepository {
  readonly realm: "evaluation" | "production";
  store(storeId: string): Promise<WorkspaceProfileRecord | undefined>;
  save(command: CatalogueSave): Promise<StoreSkuRecord>;
  bindReviewed?(command: CatalogueSave, identity: CatalogueIdentity): Promise<StoreSkuRecord>;
  readSaveReceipt?(command: CatalogueSave): Promise<StoreSkuRecord | undefined>;
  page(profile: WorkspaceProfileRecord, ownerUserId: string | undefined,
    after: string | undefined, limit: number, skuId?: string): Promise<StoreSkuRecord[]>;
  catalogue(catalogueId: string): Promise<CatalogueAggregate | undefined>;
  publicListingBindings?(record: StoreSkuRecord): Promise<PublicCatalogueListingBinding[] | undefined>;
  confirmPublicListingSnapshot?(storeId: string, records: readonly StoreSkuRecord[],
    identity: CatalogueIdentity, catalogueFingerprint: string, detailsFingerprint?: string): Promise<WorkspaceProfileRecord | undefined>;
  publicCatalogueSource?(storeId: string, identity: CatalogueIdentity): Promise<PublicCatalogueSource | undefined>;
  readStorePublicDetails?(storeId: string, ownerUserId?: string): Promise<StorePublicDetailsRecord | undefined>;
  saveStorePublicDetails?(command: StorePublicDetailsCommand): Promise<StorePublicDetailsRecord>;
  reconcileStorePublicDetails?(command: StorePublicDetailsCommand): Promise<StorePublicDetailsRecord | undefined>;
}

/** Bounded whole-candidate read, including excluded/unlisted records. Never
 * expose this private envelope to clients; only reviewed projection is public. */
export interface PublicCatalogueSource {
  profile: WorkspaceProfileRecord; catalogue: CatalogueAggregate; records: StoreSkuRecord[];
  bindings: PublicCatalogueListingBinding[]; policy: unknown; publicDetails?: unknown;
}

export function normalizeStorePublicDetails(raw: unknown): StorePublicDetailsInput {
  const value = exact(raw, ["street", "city", "state", "pinCode", "publicContactPhone", "openingTime", "closingTime"]);
  const details = {street: text(value.street, 2000), city: text(value.city), state: text(value.state),
    pinCode: text(value.pinCode, 6), publicContactPhone: text(value.publicContactPhone, 30, true),
    openingTime: text(value.openingTime, 16, true), closingTime: text(value.closingTime, 16, true)};
  const digits = details.publicContactPhone.replace(/[^0-9]/gu, "");
  const validTime = /^(?:(?:[01]?\d|2[0-3]):[0-5]\d|(?:0?[1-9]|1[0-2]):[0-5]\d\s*[AP]M)$/iu;
  if (!/^[1-9][0-9]{5}$/u.test(details.pinCode) ||
      details.publicContactPhone !== "" && (!/^\+?[0-9][0-9 ()-]*$/u.test(details.publicContactPhone) || digits.length < 7 || digits.length > 15) ||
      (details.openingTime !== "" || details.closingTime !== "") &&
        (!validTime.test(details.openingTime) || !validTime.test(details.closingTime))) invalid("Check public address, contact and hours.");
  return details;
}
function publicDetailsRecord(raw: unknown, realm: string, storeId: string): StorePublicDetailsRecord {
  const value = exact(raw, ["schemaVersion", "realm", "storeId", "revision", "publishedAt", "details"]);
  if (value.schemaVersion !== 1 || value.realm !== realm || value.storeId !== storeId ||
      typeof value.publishedAt !== "string" || !Number.isFinite(Date.parse(value.publishedAt)) ||
      new Date(value.publishedAt).toISOString() !== value.publishedAt) invalid();
  return {schemaVersion: 1, realm: realm as StorePublicDetailsRecord["realm"], storeId,
    revision: integer(value.revision, 1, 1000000000), publishedAt: value.publishedAt,
    details: normalizeStorePublicDetails(value.details)};
}
function detailsCommand(ownerUserId: string, realm: StorePublicDetailsRecord["realm"], body: Readonly<Record<string, unknown>>, at: string): StorePublicDetailsCommand {
  exact(body, ["storeId", "expectedRevision", "idempotencyKey", "details"]);
  const storeId = id(body.storeId), user = id(ownerUserId), expectedRevision = integer(body.expectedRevision, 0, 999999999);
  const details = normalizeStorePublicDetails(body.details);
  return {ownerUserId: user, storeId, realm, expectedRevision, details, idempotencyKey: id(body.idempotencyKey),
    publishedAt: at, fingerprint: cataloguePayloadHash({ownerUserId: user, storeId, realm, expectedRevision, details})};
}
function originalPublicDetails(command: StorePublicDetailsCommand, receipt: StorePublicDetailsReceipt): StorePublicDetailsRecord {
  const record = publicDetailsRecord(receipt.record, command.realm, command.storeId);
  if (receipt.fingerprint !== command.fingerprint || record.revision !== command.expectedRevision + 1 ||
      cataloguePayloadHash(record.details) !== cataloguePayloadHash(command.details)) {
    throw new WorkspaceProfileError("conflict", "This public-details request changed. Check its original result.", 409);
  }
  return record;
}
function publicDetailsProjection(raw: unknown, realm: string, storeId: string, profile: WorkspaceProfileRecord, at: string): object {
  const base = {schemaVersion: 1, realm, storeId, observedAt: at, locationVerified: false,
    publicAvailabilityConfirmed: false, area: typeof profile.area === "string" ? text(profile.area, 240, true) : null};
  if (raw === undefined) return {...base, state: "unavailable", revision: null, details: null};
  if (raw === null) return {...base, state: "none", revision: 0, details: null};
  try {
    const record = publicDetailsRecord(raw, realm, storeId);
    if (record.publishedAt > at) throw new Error("Future metadata");
    return {...base, state: "ready", revision: record.revision, details: record.details};
  } catch { return {...base, state: "unavailable", revision: null, details: null}; }
}
export function planStorePublicDetailsSave(command: StorePublicDetailsCommand, profile: WorkspaceProfileRecord | undefined,
  current?: StorePublicDetailsRecord, receipt?: StorePublicDetailsReceipt): StorePublicDetailsRecord {
  requireStore(profile, command.storeId, command.ownerUserId);
  if (!["evaluation", "production"].includes(command.realm)) invalid();
  if (receipt) return originalPublicDetails(command, receipt);
  const previous = current && publicDetailsRecord(current, command.realm, command.storeId);
  if ((previous?.revision ?? 0) !== command.expectedRevision) {
    throw new WorkspaceProfileError("revision_conflict", "Public Store details changed. Refresh before saving.", 409);
  }
  return publicDetailsRecord({schemaVersion: 1, realm: command.realm, storeId: command.storeId,
    revision: command.expectedRevision + 1, publishedAt: command.publishedAt,
    details: normalizeStorePublicDetails(command.details)}, command.realm, command.storeId);
}

/** Stable persisted identity, not a claim of publication, stock or eligibility. */
export function cataloguePublicListingBindings(realm: "evaluation" | "production", value: StoreSkuRecord): PublicCatalogueListingBinding[] {
  if (!["evaluation", "production"].includes(realm)) invalid();
  const record = normalizeRecord(value, id(value.storeId));
  return record.channels.map(channel => ({schemaVersion: 1, realm,
    listingId: `listing-${cataloguePayloadHash([1, realm, record.storeId, record.skuId, channel.kind]).toLowerCase()}`,
    storeId: record.storeId, skuId: record.skuId, channel: channel.kind,
    canonicalProductId: record.canonicalProductId, verifiedPackId: record.verifiedPackId}));
}
function checkedListingBinding(value: unknown, expected: PublicCatalogueListingBinding): PublicCatalogueListingBinding {
  const row = exact(value, ["schemaVersion", "realm", "listingId", "storeId", "skuId", "channel", "canonicalProductId", "verifiedPackId"]);
  if (cataloguePayloadHash(row) !== cataloguePayloadHash(expected)) invalid("Public listing identity conflicts with its saved SKU.");
  return structuredClone(expected);
}
export interface CatalogueIdentity {catalogueId: string; tenantId: string}

/** Server-owned grants, never accepted from an owner/client request. No grant writer. */
export interface CatalogueProducerAuthority {
  schemaVersion: 1; userId: string; revision: number; enabled: boolean;
  actor: SupplyActor; validFrom: string; expiresAt: string;
}
export interface CatalogueProductionReceipt {fingerprint: string; result: CatalogueAggregate}
export interface CatalogueProduction {
  operatorUserId: string; identity: CatalogueIdentity;
  input: Readonly<Record<string, unknown>>; observedAt: string;
}

function producerActor(operator: string, identity: CatalogueIdentity, at: string,
  authority: CatalogueProducerAuthority | undefined): SupplyActor {
  const deny = () => new WorkspaceProfileError("forbidden", "Catalogue authority is not available.", 403);
  if (!Number.isFinite(Date.parse(at)) || !authority || authority.schemaVersion !== 1 || authority.userId !== operator ||
      authority.enabled !== true || !Number.isSafeInteger(authority.revision) || authority.revision < 1 ||
      authority.actor?.actorId !== operator || authority.actor.tenantId !== identity.tenantId ||
      !Array.isArray(authority.actor.scopes) ||
      !Number.isFinite(Date.parse(authority.validFrom)) || !Number.isFinite(Date.parse(authority.expiresAt)) ||
      Date.parse(at) < Date.parse(authority.validFrom) || Date.parse(at) >= Date.parse(authority.expiresAt)) throw deny();
  return structuredClone(authority.actor);
}

function currentCapability(participant: SupplyParticipantWorkspace, query: SupplyCapabilityQuery): boolean {
  if (participant.schemaVersion !== 1 || !Array.isArray(participant.capabilities)) return false;
  const records = participant.capabilities.filter(c => c?.kind === query.capability);
  const capability = records[0];
  if (records.length !== 1 || !capability || !Number.isFinite(Date.parse(capability.effectiveFrom ?? "")) ||
      !Number.isFinite(Date.parse(capability.expiresAt ?? "")) ||
      Date.parse(capability.effectiveFrom!) >= Date.parse(capability.expiresAt!) ||
      !Array.isArray(capability.qualifiers?.categoryIds) || !Array.isArray(capability.qualifiers?.serviceAreaIds)) return false;
  return isSupplyCapabilityActive(participant, query);
}

function productionInput(raw: Readonly<Record<string, unknown>>): Record<string, unknown> {
  const type = text(raw.type, 32);
  const fields: Record<string, string[]> = {
    create: [],
    propose_product: ["productId", "categoryId", "brandId", "contentSha256", "codes"],
    review_product: ["productId", "decision", "reasonCode", "expectedContentSha256"],
    propose_pack: ["packId", "productId", "descriptorSha256", "codes"],
    review_pack: ["packId", "decision", "reasonCode", "expectedDescriptorSha256"],
    create_offer: ["offerId", "packId", "buyingContext", "serviceAreaIds", "termWindows"],
  };
  if (!Object.hasOwn(fields, type)) invalid("Unsupported catalogue operation.");
  exact(raw, ["type", "commandId", ...(type === "create" ? [] : ["expectedVersion"]), ...fields[type]!]);
  const input = structuredClone(raw) as Record<string, unknown>;
  input.commandId = id(input.commandId);
  if (type !== "create") input.expectedVersion = integer(input.expectedVersion, 1, 1_000_000_000);
  for (const key of ["productId", "categoryId", "brandId", "packId", "offerId", "reasonCode"]) {
    if (key in input) input[key] = id(input[key]);
  }
  for (const key of ["contentSha256", "descriptorSha256", "expectedContentSha256", "expectedDescriptorSha256"]) {
    if (key in input) {
      const hash = text(input[key], 64);
      if (!/^[A-Fa-f0-9]{64}$/u.test(hash)) invalid();
      input[key] = hash.toUpperCase();
    }
  }
  if ("decision" in input && (typeof input.decision !== "string" || !["verify", "reject"].includes(input.decision))) invalid();
  for (const key of ["codes", "serviceAreaIds", "termWindows"]) {
    if (key in input && !Array.isArray(input[key])) invalid();
  }
  // The shared contract validates code checksums, windows, capabilities and transitions.
  return input;
}

/** Pure transaction planner; input contains no actor, approval or client timestamp. */
export function planCatalogueProduction(command: CatalogueProduction,
  authority: CatalogueProducerAuthority | undefined,
  current?: CatalogueAggregate, participant?: SupplyParticipantWorkspace,
  profile?: WorkspaceProfileRecord, receipt?: CatalogueProductionReceipt,
  authorizationAt = command.observedAt):
  {aggregate: CatalogueAggregate; fingerprint: string; replayed: boolean} {
  const operator = id(command.operatorUserId);
  const identity = {catalogueId: id(command.identity.catalogueId), tenantId: id(command.identity.tenantId)};
  const input = productionInput(command.input);
  const at = command.observedAt;
  if (!Number.isFinite(Date.parse(at)) || new Date(at).toISOString() !== at) invalid();
  const deny = () => new WorkspaceProfileError("forbidden", "Catalogue authority is not available.", 403);
  const actor = producerActor(operator, identity, authorizationAt, authority);
  const validAggregate = (value: CatalogueAggregate) => value.schemaVersion === 1 &&
    value.catalogueId === identity.catalogueId && value.tenantId === identity.tenantId &&
    Number.isSafeInteger(value.version) && value.version >= 1;
  if (current && !validAggregate(current)) invalid("Catalogue identity changed.");
  const participantOperation = ["propose_product", "propose_pack", "create_offer"].includes(String(input.type));
  if (!participantOperation) {
    if (!actor.scopes.includes("supply.catalogue.review")) throw deny();
  } else {
    if (!participant || participant.schemaVersion !== 1 || participant.status !== "registered" ||
        participant.tenantId !== identity.tenantId || actor.workspaceId !== participant.workspaceId ||
        !actor.scopes.includes("supply.workspace.admin")) throw deny();
    requireStore(profile, participant.workspaceId, operator);
    const productId = input.type === "create_offer"
      ? current?.packs.find(p => p.packId === input.packId)?.productId : input.productId;
    const categoryId = input.type === "propose_product" ? input.categoryId as string :
      current?.products.find(p => p.productId === productId)?.categoryId;
    const capability = input.type === "create_offer"
      ? (input.buyingContext === "consumer" ? "retail_fulfilment" : "wholesale_supply")
      : "product_master_stewardship";
    const areas = input.type === "create_offer" ? input.serviceAreaIds as string[] : [undefined];
    if (!categoryId || areas.length === 0 || areas.some(serviceAreaId => !currentCapability(participant, {
      capability, at: authorizationAt, categoryId, ...(serviceAreaId === undefined ? {} : {serviceAreaId}),
    }))) throw deny();
  }
  const fingerprint = cataloguePayloadHash({operator, identity, input});
  if (receipt) {
    if (receipt.fingerprint !== fingerprint || !validAggregate(receipt.result) || !current ||
        receipt.result.version > current.version) {
      throw new WorkspaceProfileError("conflict", "Catalogue command changed. Use its original request.", 409);
    }
    return {aggregate: structuredClone(receipt.result), fingerprint, replayed: true};
  }
  let aggregate: CatalogueAggregate;
  if (input.type === "create") {
    if (current) throw new WorkspaceProfileError("conflict", "Catalogue already exists.", 409);
    aggregate = createCatalogueAggregate({commandId: input.commandId as string,
      ...identity, occurredAt: at, actor});
  } else {
    if (!current) throw new WorkspaceProfileError("not_found", "Catalogue is not available.", 404);
    const {expectedContentSha256, expectedDescriptorSha256, ...fields} = input;
    if (input.type === "review_product" && current.products.find(p => p.productId === input.productId)
      ?.contentSha256.toUpperCase() !== expectedContentSha256) invalid("Review content changed.");
    if (input.type === "review_pack" && current.packs.find(p => p.packId === input.packId)
      ?.descriptorSha256.toUpperCase() !== expectedDescriptorSha256) invalid("Review pack changed.");
    aggregate = applyCatalogueCommand(current, {...fields, catalogueId: identity.catalogueId,
      occurredAt: at, actor} as unknown as CatalogueCommand, participant);
  }
  return {aggregate, fingerprint, replayed: false};
}

export class WorkspaceCatalogueService {
  constructor(private readonly repository: WorkspaceCatalogueRepository,
    private readonly identity?: CatalogueIdentity,
    private readonly now: () => Date = () => new Date(),
    private readonly policyReader?: Pick<WorkspaceSupplierPolicyService, "forPublicSku">) {}

  async handleStorePublicDetails(ownerUserId: string, operation: string, raw: Readonly<Record<string, unknown>>): Promise<object> {
    const body = structuredClone(raw);
    if (Buffer.byteLength(JSON.stringify(body), "utf8") > 16000) invalid("Public Store details are too long.");
    let record: StorePublicDetailsRecord | undefined;
    if (operation === "readStorePublicDetails") {
      exact(body, ["storeId"]);
      const storeId = id(body.storeId);
      requireStore(await this.repository.store(storeId), storeId, id(ownerUserId));
      if (!this.repository.readStorePublicDetails) throw new WorkspaceProfileError("unavailable", "Public details are not connected.", 503);
      record = await this.repository.readStorePublicDetails(storeId, ownerUserId);
    } else {
      const command = detailsCommand(ownerUserId, this.repository.realm, body, this.now().toISOString());
      requireStore(await this.repository.store(command.storeId), command.storeId, command.ownerUserId);
      if (operation === "saveStorePublicDetails" && this.repository.saveStorePublicDetails) {
        record = await this.repository.saveStorePublicDetails(command);
      } else if (operation === "reconcileStorePublicDetails" && this.repository.reconcileStorePublicDetails) {
        record = await this.repository.reconcileStorePublicDetails(command);
      } else throw new WorkspaceProfileError("unavailable", "Public details are not connected.", 503);
    }
    return {schemaVersion: 1, realm: this.repository.realm, storeId: id(body.storeId),
      operation, idempotencyKey: operation === "readStorePublicDetails" ? null : id(body.idempotencyKey),
      record: record ? publicDetailsRecord(record, this.repository.realm, id(body.storeId)) : null,
      locationVerified: false, publicAvailabilityConfirmed: false};
  }

  async saveSku(ownerUserId: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    const command = await this.saveCommand(ownerUserId, body);
    const record = await this.repository.save(command);
    return this.savedResult(command.profile.workspaceId!, record);
  }

  /** Owner intent only. Server configuration and private review sources decide eligibility. */
  async bindReviewedSku(ownerUserId: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    if (!this.identity || !this.repository.bindReviewed) {
      throw new WorkspaceProfileError("service_unavailable", "Product publication is unavailable right now.", 503, true);
    }
    const identity = {...this.identity};
    const command = await this.saveCommand(ownerUserId, body);
    const record = await this.repository.bindReviewed(command, identity);
    return this.savedResult(command.profile.workspaceId!, record);
  }

  /** Historical receipt only. Missing receipt is unknown, never a reason to resend. */
  async reconcileBinding(ownerUserId: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    if (!this.repository.readSaveReceipt) {
      throw new WorkspaceProfileError("service_unavailable", "Listing updates are unavailable right now.", 503, true);
    }
    const command = await this.saveCommand(ownerUserId, body);
    const record = await this.repository.readSaveReceipt(command);
    return record ? this.savedResult(command.profile.workspaceId!, record) :
      {schemaVersion: 1, realm: this.repository.realm, storeId: command.profile.workspaceId!,
        saved: null, publicationConfirmed: false};
  }

  private async saveCommand(ownerUserId: string, body: Readonly<Record<string, unknown>>): Promise<CatalogueSave> {
    body = structuredClone(body);
    exact(body, ["storeId", "sku", "expectedRevision", "idempotencyKey"]);
    const storeId = id(body.storeId);
    const input = normalizeSku(body.sku, storeId);
    const expectedRevision = integer(body.expectedRevision, 0, 1_000_000_000);
    const idempotencyKey = id(body.idempotencyKey);
    const profile = requireStore(await this.repository.store(storeId), storeId, ownerUserId);
    return {ownerUserId, profile, input,
      expectedRevision, idempotencyKey,
      fingerprint: cataloguePayloadHash({storeId, input, expectedRevision}),
      observedAt: this.now().toISOString()};
  }

  private savedResult(storeId: string, record: StoreSkuRecord): object {
    return {schemaVersion: 1, realm: this.repository.realm, storeId, saved: normalizeRecord(record, storeId),
      publicationConfirmed: false};
  }

  async listSkus(ownerUserId: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    const queryBody = structuredClone(body) as Record<string, unknown>;
    const mediaRequested = queryBody.mediaReadbackVersion === 1;
    if (queryBody.mediaReadbackVersion !== undefined && !mediaRequested) invalid();
    delete queryBody.mediaReadbackVersion;
    const query = pageQuery(queryBody);
    const profile = requireStore(await this.repository.store(query.storeId), query.storeId, ownerUserId);
    const records = await this.repository.page(profile, ownerUserId, query.after, query.limit, query.skuId);
    const items = records.map(r => normalizeRecord(r, query.storeId));
    if (!mediaRequested && items.some(item => item.content.media.some(media => Object.hasOwn(media.file, "frameCount")))) {
      // An editable source must remain exact; never strip reviewed input facts
      // to satisfy an older decoder or silently omit its record from the page.
      throw new WorkspaceProfileError("unsupported_version", "Update MoolSocial to open these saved photo details. Saved data is unchanged.", 409);
    }
    return {schemaVersion: 1, realm: this.repository.realm, storeId: query.storeId, items,
      ...(mediaRequested ? {mediaReadbackVersion: 1} : {}),
      nextCursor: !query.skuId && items.length === query.limit ? items.at(-1)!.skuId : null};
  }

  private async publicCataloguePage(body: Readonly<Record<string, unknown>>): Promise<object> {
    exact(body, ["storeId", "cataloguePageVersion", "query", "pageSize"], ["cursor", "storeDetailsReadbackVersion"]);
    const detailsRequested = body.storeDetailsReadbackVersion === 1;
    if (body.storeDetailsReadbackVersion !== undefined && !detailsRequested) invalid();
    if (body.cataloguePageVersion !== 1) invalid();
    const storeId = id(body.storeId), pageSize = integer(body.pageSize, 1, 50), query = publicPageQuery(body.query);
    if (!this.identity || !this.repository.publicCatalogueSource) {
      throw new WorkspaceProfileError("unavailable", "Store catalogue is not connected.", 503);
    }
    const source = await this.repository.publicCatalogueSource(storeId, this.identity);
    if (!source || source.records.length > 500) {
      throw new WorkspaceProfileError("unavailable", "The complete Store catalogue could not be confirmed.", 503);
    }
    const sourceHash = cataloguePayloadHash(source);
    const data = await this.publicCatalogue({storeId, listingReadbackVersion: 1,
      ...(detailsRequested ? {storeDetailsReadbackVersion: 1} : {}),
      policyReadbackVersion: 1, mediaReadbackVersion: 1}, source) as Record<string, unknown>;
    if (data.state !== "ready" || data.listingCoverage !== "complete") {
      throw new WorkspaceProfileError("unavailable", "Store listings could not be confirmed.", 503);
    }
    const rows = data.items as Array<{skuId: string; content: StoreSkuContent; pack: StoreSkuPack;
      channels: Array<StoreSkuChannel & {revision: string; validUntil: string}>;
      listings: PublicCatalogueListingBinding[]; supplierPolicy: Record<string, unknown>}>;
    const selected: Array<{channel: StoreSkuChannel["kind"]; listingId: string; row: (typeof rows)[number]; price: number}> = [];
    for (const row of rows) for (const channel of row.channels) {
      if (query.destination === "shop" ? channel.kind !== "retail" : channel.kind === "retail") continue;
      if (query.tradeType !== null && channel.kind !== query.tradeType) continue;
      const binding = row.listings.find(value => value.channel === channel.kind)!;
      if (query.listingIds.length && !query.listingIds.includes(binding.listingId)) continue;
      if (query.categoryId !== "all" && row.content.categoryId !== query.categoryId ||
          query.brands.length && !query.brands.includes(row.content.brand) ||
          query.maximumPriceMinor !== null && channel.priceMinor > query.maximumPriceMinor ||
          query.search && ![row.content.title, row.content.brand, row.content.variant, row.pack.label]
            .join(" ").toLowerCase().replace(/\s+/gu, " ").includes(query.search)) continue;
      // Current Buy prices are whole INR; don't count then silently drop an
      // unrepresentable item on the client. Exact fractional packs obey its model.
      const quantities = [BigInt(row.pack.quantityMilli), BigInt(row.pack.quantityMilli) * 1000n];
      const count = BigInt(row.pack.unitsPerCase);
      const amount = quantities.find((value, i) => (i === 0 || row.pack.unit !== "count") && value % count === 0n);
      if (channel.priceMinor % 100 || channel.mrpMinor !== null && channel.mrpMinor % 100 ||
          channel.tiers.some(tier => tier.unitPriceMinor % 100) || amount === undefined ||
          row.pack.unit === "count" && amount / count % 1000n !== 0n) {
        throw new WorkspaceProfileError("unsupported_representation", "Update required to display exact Store prices or packs.", 409);
      }
      selected.push({channel: channel.kind, listingId: binding.listingId, row, price: channel.priceMinor});
    }
    selected.sort((a, b) => (query.sort === "priceLowToHigh" ? a.price - b.price :
      query.sort === "priceHighToLow" ? b.price - a.price : 0) ||
      (a.listingId < b.listingId ? -1 : a.listingId === b.listingId ? 0 : 1));
    const stableRows = stablePublicProjection(data);
    const queryHash = cataloguePayloadHash([storeId, query]).toLowerCase();
    const snapshotId = cataloguePayloadHash([sourceHash, stableRows]).toLowerCase();
    let index = 0;
    if (body.cursor !== undefined) {
      const encoded = text(body.cursor, 2048);
      let cursor: Record<string, unknown>;
      try { cursor = exact(JSON.parse(Buffer.from(encoded, "base64url").toString("utf8")), ["v", "q", "s", "n", "i"]); }
      catch { invalid("Catalogue cursor is invalid. Refresh the Store."); }
      if (Buffer.from(JSON.stringify(cursor)).toString("base64url") !== encoded || cursor.v !== 1 ||
          cursor.q !== queryHash || cursor.s !== snapshotId || cursor.n !== pageSize) {
        throw new WorkspaceProfileError("stale_cursor", "Store catalogue changed. Refresh the Store.", 409);
      }
      index = integer(cursor.i, 0, 1000);
      if (index % pageSize || index >= selected.length) invalid("Catalogue cursor is outside this snapshot.");
    }
    const current = await this.repository.publicCatalogueSource(storeId, this.identity);
    const responseAt = this.now().toISOString();
    if (!current || cataloguePayloadHash(current) !== sourceHash) {
      throw new WorkspaceProfileError("stale_snapshot", "Store catalogue changed. Refresh the Store.", 409);
    }
    // Pure re-projection at one final response time checks temporal membership
    // of ALL candidates, including offers which were not active on the first pass.
    const finalProjection = await new WorkspaceCatalogueService(this.repository, this.identity,
      () => new Date(responseAt), this.policyReader).publicCatalogue({storeId, listingReadbackVersion: 1,
      ...(detailsRequested ? {storeDetailsReadbackVersion: 1} : {}),
      policyReadbackVersion: 1, mediaReadbackVersion: 1}, current) as Record<string, unknown>;
    if (cataloguePayloadHash(stablePublicProjection(finalProjection)) !== cataloguePayloadHash(stableRows)) {
      throw new WorkspaceProfileError("stale_snapshot", "Store catalogue changed. Refresh the Store.", 409);
    }
    const cursorAt = (offset: number) => Buffer.from(JSON.stringify(
      {v: 1, q: queryHash, s: snapshotId, n: pageSize, i: offset})).toString("base64url");
    const previousCursor = index === 0 ? null : cursorAt(Math.max(0, index - pageSize));
    const nextCursor = index + pageSize < selected.length ? cursorAt(index + pageSize) : null;
    return {...data, observedAt: responseAt, cataloguePageVersion: 1, query,
      items: selected.slice(index, index + pageSize).map(({channel, row}) => ({channel, row})),
      nextCursor, page: {snapshotId, startIndex: index, totalCount: selected.length, previousCursor, nextCursor}};
  }

  async publicCatalogue(body: Readonly<Record<string, unknown>>, source?: PublicCatalogueSource): Promise<object> {
    if (Object.hasOwn(body, "cataloguePageVersion")) return this.publicCataloguePage(body);
    const queryBody = structuredClone(body) as Record<string, unknown>;
    const policyRequested = queryBody.policyReadbackVersion === 1;
    if (queryBody.policyReadbackVersion !== undefined && !policyRequested) invalid();
    delete queryBody.policyReadbackVersion;
    const listingsRequested = queryBody.listingReadbackVersion === 1;
    if (queryBody.listingReadbackVersion !== undefined && !listingsRequested) invalid();
    delete queryBody.listingReadbackVersion;
    const mediaRequested = queryBody.mediaReadbackVersion === 1;
    if (queryBody.mediaReadbackVersion !== undefined && !mediaRequested) invalid();
    delete queryBody.mediaReadbackVersion;
    const detailsRequested = queryBody.storeDetailsReadbackVersion === 1;
    if (queryBody.storeDetailsReadbackVersion !== undefined && !detailsRequested) invalid();
    delete queryBody.storeDetailsReadbackVersion;
    if (detailsRequested && !listingsRequested) invalid();
    const query = pageQuery(queryBody);
    const profile = source ? source.profile : await this.repository.store(query.storeId);
    const observedAt = this.now().toISOString();
    const base = {schemaVersion: 1, realm: this.repository.realm, storeId: query.storeId, observedAt,
      orderingAvailable: false, coverage: "verified_public_only",
      ...(mediaRequested ? {mediaReadbackVersion: 1} : {}),
      ...(detailsRequested ? {storeDetailsReadbackVersion: 1} : {}),
      ...(listingsRequested ? {listingReadbackVersion: 1, listingCoverage: "unavailable"} : {})};
    if (!profile || profile.workspaceId !== query.storeId || profile.status !== "live" ||
        profile.shopEnabled !== true || !this.identity) {
      return {...base, state: "unavailable", items: [], nextCursor: null};
    }
    const catalogue = source ? source.catalogue : await this.repository.catalogue(this.identity.catalogueId);
    if (!catalogue || catalogue.schemaVersion !== 1 ||
        catalogue.catalogueId !== this.identity.catalogueId || catalogue.tenantId !== this.identity.tenantId ||
        !Number.isSafeInteger(catalogue.version) || catalogue.version < 1) {
      return {...base, state: "unavailable", items: [], nextCursor: null};
    }
    const records = source ? source.records : await this.repository.page(profile, undefined, query.after, query.limit, query.skuId);
    const [freshCatalogue, freshStore] = source ? [source.catalogue, source.profile] : await Promise.all([
      this.repository.catalogue(this.identity.catalogueId), this.repository.store(query.storeId)]);
    if (!freshCatalogue || cataloguePayloadHash(freshCatalogue) !== cataloguePayloadHash(catalogue) ||
        freshStore?.workspaceId !== query.storeId || freshStore.status !== "live" || freshStore.shopEnabled !== true) {
      return {...base, state: "unavailable", items: [], nextCursor: null};
    }
    const readbackAt = this.now().toISOString();
    const rows = records.map(r => normalizeRecord(r, query.storeId));
    const items = rows.flatMap(record => {
      if (!record.publicListing || record.observedAt > readbackAt) return [];
      const product = catalogue.products.find(p => p.productId === record.canonicalProductId);
      const pack = catalogue.packs.find(p => p.packId === record.verifiedPackId);
      if (product?.state !== "verified" || pack?.state !== "verified" ||
          pack.productId !== product.productId ||
          product.contentSha256.toUpperCase() !== cataloguePayloadHash(record.content) ||
          pack.descriptorSha256.toUpperCase() !== cataloguePayloadHash(record.pack)) return [];
      const terms = record.channels.map(channel => {
        const offer = catalogue.offers.find(o => o.offerId === channel.offerId &&
          o.workspaceId === query.storeId && o.packId === pack.packId &&
          o.buyingContext === (channel.kind === "retail" ? "consumer" : "wholesale"));
        const window = offer && referencedOfferTermAt(offer, readbackAt);
        if (!window || window.termSnapshotSha256.toUpperCase() !== cataloguePayloadHash(channelTerms(channel))) return null;
        return {...channel, revision: window.termSnapshotId, validUntil: window.expiresAt};
      });
      // A saved trade type cannot silently become another channel or partial offer.
      if (terms.some(t => t === null)) return [];
      const publicContent = structuredClone(record.content);
      // Compatibility projection only, after full reviewed-content validation.
      // Original source, immutable receipts and hashes are never edited here.
      if (!mediaRequested) for (const media of publicContent.media) delete media.file.frameCount;
      return [{skuId: record.skuId, canonicalProductId: record.canonicalProductId,
        verifiedPackId: record.verifiedPackId, sku: record.sku,
        revision: record.revision, observedAt: record.observedAt,
        content: publicContent, pack: record.pack, channels: terms}];
    });
    const publicItems = policyRequested ? await Promise.all(items.map(async item => {
      const unavailable = () => ({schemaVersion: 1 as const, realm: this.repository.realm,
        storeId: query.storeId, skuId: item.skuId, observedAt: this.now().toISOString(),
        state: "unavailable" as const, revision: null, requiresAcceptance: null, policy: null});
      try {
        if (!source && !this.policyReader) return {...item, supplierPolicy: unavailable()};
        const policy = source
          ? publicSupplierPolicySnapshot(source.policy, this.repository.realm, query.storeId, item.skuId, this.now().toISOString())
          : await this.policyReader!.forPublicSku(query.storeId, item.skuId);
        if (policy.schemaVersion !== 1 || policy.realm !== this.repository.realm ||
            policy.storeId !== query.storeId || policy.skuId !== item.skuId ||
            policy.policy !== null && (policy.policy.storeId !== query.storeId ||
              policy.policy.productIds.length !== 1 || policy.policy.productIds[0] !== item.skuId)) {
          return {...item, supplierPolicy: unavailable()};
        }
        return {...item, supplierPolicy: policy};
      } catch { return {...item, supplierPolicy: unavailable()}; }
    })) : items;
    if (listingsRequested) {
      const linked: Array<(typeof publicItems)[number] & {listings: PublicCatalogueListingBinding[]}> = [];
      for (const item of publicItems) {
        const record = rows.find(r => r.skuId === item.skuId)!;
        try {
          // No client-generated fallback or mutation during public readback.
          const bindings = source ? source.bindings.filter(b => b.skuId === record.skuId)
            : await this.repository.publicListingBindings?.(record);
          const expected = cataloguePublicListingBindings(this.repository.realm, record);
          if (!bindings || bindings.length !== expected.length) continue;
          const checked = expected.map(binding => checkedListingBinding(
            bindings.find(v => v.channel === binding.channel), binding));
          if (item.channels.some(c => c!.validUntil <= this.now().toISOString())) continue;
          linked.push({...item, listings: checked});
        } catch { /* Retain an unavailable/partial result, never guess identity. */ }
      }
      let details: unknown;
      if (detailsRequested) {
        try {
          details = source ? source.publicDetails : this.repository.readStorePublicDetails
            ? (await this.repository.readStorePublicDetails(query.storeId)) ?? null : undefined;
        } catch { details = undefined; }
      }
      let store: WorkspaceProfileRecord;
      try {
        if (!linked.length && publicItems.length) return {...base, listingCoverage: "partial", state: "unavailable", items: [], nextCursor: null};
        const currentStore = source ? source.profile : await this.repository.confirmPublicListingSnapshot?.(query.storeId,
          rows.filter(record => linked.some(item => item.skuId === record.skuId)), this.identity, cataloguePayloadHash(catalogue),
          detailsRequested && details !== undefined ? cataloguePayloadHash(details) : undefined);
        store = requireStore(currentStore, query.storeId);
        if (!store.shopEnabled) throw new Error("Store withdrawn");
        text(store.name, 240);
      } catch { return {...base, state: "unavailable", items: [], nextCursor: null}; }
      // All awaits are finished. Do not let a metadata/policy lookup extend
      // reviewed selling terms beyond their original expiry.
      const responseAt = this.now().toISOString();
      const liveLinked = linked.filter(item => item.channels.every(c => c!.validUntil > responseAt));
      const coverage = liveLinked.length === publicItems.length ? "complete" : "partial";
      return {...base, observedAt: responseAt,
        state: liveLinked.length === 0 && publicItems.length > 0 ? "unavailable" : "ready",
        catalogueVersion: catalogue.version, listingCoverage: coverage,
        publicStore: {id: store.workspaceId, name: store.name, profileId: store.profileId,
          ...(detailsRequested ? {details: publicDetailsProjection(details, this.repository.realm, query.storeId, store, responseAt)} : {})},
        items: liveLinked, nextCursor: !query.skuId && rows.length === query.limit ? rows.at(-1)!.skuId : null};
    }
    return {...base, observedAt: readbackAt, state: "ready", catalogueVersion: catalogue.version, items: publicItems,
      nextCursor: !query.skuId && rows.length === query.limit ? rows.at(-1)!.skuId : null};
  }
}

function invalid(message = "Catalogue data is invalid."): never {
  throw new WorkspaceProfileError("invalid_input", message, 400);
}
function publicPageQuery(value: unknown) {
  const query = exact(value, ["destination", "search", "categoryId", "sort", "brands", "maximumPriceMinor", "tradeType", "listingIds"]);
  if (typeof query.destination !== "string" || !["shop", "wholesale"].includes(query.destination) ||
      typeof query.sort !== "string" || !["relevance", "priceLowToHigh", "priceHighToLow"].includes(query.sort) ||
      !Array.isArray(query.brands) || query.brands.length > 20 || !Array.isArray(query.listingIds) || query.listingIds.length > 50 ||
      query.tradeType !== null && (typeof query.tradeType !== "string" || !["wholesale", "bulk"].includes(query.tradeType)) ||
      query.destination === "shop" && query.tradeType !== null) invalid();
  const brands = (query.brands as unknown[]).map(value => text(value));
  const listingIds = (query.listingIds as unknown[]).map(value => text(value, 72));
  if (new Set(brands).size !== brands.length || new Set(listingIds).size !== listingIds.length ||
      listingIds.some(value => !/^listing-[a-f0-9]{64}$/u.test(value))) invalid();
  return {destination: String(query.destination), search: text(query.search, 240, true).toLowerCase().replace(/\s+/gu, " "),
    categoryId: id(query.categoryId), sort: String(query.sort), brands: brands.sort(),
    maximumPriceMinor: query.maximumPriceMinor === null ? null : integer(query.maximumPriceMinor, 0),
    tradeType: query.tradeType === null ? null : String(query.tradeType), listingIds: listingIds.sort()};
}
function stablePublicProjection(data: Record<string, unknown>): object {
  const store = data.publicStore as Record<string, unknown> | undefined;
  return {state: data.state, listingCoverage: data.listingCoverage, catalogueVersion: data.catalogueVersion,
    publicStore: store?.details ? {...store, details: Object.fromEntries(Object.entries(store.details as Record<string, unknown>)
      .filter(([key]) => key !== "observedAt"))} : store,
    items: (data.items as Array<Record<string, unknown>>).map(row => ({...row,
      supplierPolicy: Object.fromEntries(Object.entries(row.supplierPolicy as Record<string, unknown>)
        .filter(([key]) => key !== "observedAt"))}))};
}
function object(value: unknown): Record<string, unknown> {
  if (value === null || typeof value !== "object" || Array.isArray(value) ||
      ![Object.prototype, null].includes(Object.getPrototypeOf(value))) invalid();
  return value as Record<string, unknown>;
}
function exact(value: unknown, required: string[], optional: string[] = []): Record<string, unknown> {
  const result = object(value);
  if (required.some(k => !Object.hasOwn(result, k)) ||
      Object.keys(result).some(k => ![...required, ...optional].includes(k))) invalid();
  return result;
}
function text(value: unknown, max = 240, empty = false): string {
  if (typeof value !== "string" || value !== value.trim() || value.length > max ||
      (!empty && value.length === 0) || /[\u0000-\u0008\u000b\u000c\u000e-\u001f]/u.test(value)) invalid();
  return value;
}
function id(value: unknown): string {
  const result = text(value, 128);
  if (!/^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$/u.test(result)) invalid();
  return result;
}
function integer(value: unknown, minimum = 1, maximum = 100_000_000): number {
  if (!Number.isSafeInteger(value) || (value as number) < minimum || (value as number) > maximum) invalid();
  return value as number;
}
function boolean(value: unknown): boolean {if (typeof value !== "boolean") invalid(); return value;}
function list(value: unknown, max: number): unknown[] {
  if (!Array.isArray(value) || value.length > max) invalid(); return value;
}
function requireStore(profile: WorkspaceProfileRecord | undefined, storeId: string, owner?: string): WorkspaceProfileRecord {
  if (!profile || profile.workspaceId !== storeId ||
      (owner !== undefined && profile.ownerUserId !== id(owner))) {
    throw new WorkspaceProfileError("not_found", "That Store is unavailable.", 404);
  }
  if (profile.familyId !== "products-trade" || !profile.profileId.startsWith("retailer-") || profile.status !== "live") {
    throw new WorkspaceProfileError("invalid_state", "This Store is not active.", 409);
  }
  return profile;
}
function pageQuery(body: Readonly<Record<string, unknown>>) {
  exact(body, ["storeId"], ["after", "limit", "skuId"]);
  if (body.skuId !== undefined && (body.after !== undefined || body.limit !== undefined)) invalid();
  return {storeId: id(body.storeId), after: body.after === undefined ? undefined : id(body.after),
    skuId: body.skuId === undefined ? undefined : id(body.skuId),
    limit: body.skuId !== undefined ? 1 : body.limit === undefined ? 30 : integer(body.limit, 1, 50)};
}

export function channelTerms(channel: StoreSkuChannel): object {
  const {offerId: _, ...terms} = channel;
  return {currency: "INR", ...terms};
}

export function normalizeSku(value: unknown, storeId: string): StoreSkuInput {
  const v = exact(value, ["skuId", "canonicalProductId", "verifiedPackId", "sku", "publicListing",
    "content", "pack", "channels", "provenance"]);
  const skuId = id(v.skuId), canonicalProductId = id(v.canonicalProductId);
  const c = exact(v.content, ["title", "brand", "variant", "categoryId", "description", "highlights", "specifications", "media"]);
  const p = exact(v.pack, ["label", "quantityMilli", "unit", "unitsPerCase"]);
  if (!["kg", "L", "count"].includes(String(p.unit))) invalid();
  const provenance = exact(v.provenance, ["entryMethod", "sourceRecordId"]);
  if (!["catalogue", "manual", "csv"].includes(String(provenance.entryMethod))) invalid();
  const media = list(c.media, 10).map(value => {
    const m = exact(value, ["id", "revision", "url", "storeId", "skuId", "canonicalProductId", "publisherWorkspaceId", "file"]);
    const url = text(m.url, 2048); let parsed: URL;
    try {parsed = new URL(url);} catch {return invalid();}
    if (parsed.protocol !== "https:" || !parsed.hostname || parsed.username || parsed.password ||
        parsed.search || parsed.hash || m.storeId !== storeId || m.skuId !== skuId ||
        m.canonicalProductId !== canonicalProductId) invalid("Product image identity is invalid.");
    const file = exact(m.file, ["mimeType", "byteLength", "width", "height", "normalized"], ["frameCount"]);
    if (!["image/jpeg", "image/png", "image/webp"].includes(String(file.mimeType))) invalid();
    return {id: id(m.id), revision: id(m.revision), url, storeId, skuId, canonicalProductId,
      publisherWorkspaceId: id(m.publisherWorkspaceId),
      file: {mimeType: String(file.mimeType), byteLength: integer(file.byteLength, 1, 10 * 1024 * 1024),
        width: integer(file.width, 1, 8192), height: integer(file.height, 1, 8192), normalized: boolean(file.normalized),
        ...(Object.hasOwn(file, "frameCount") ? {frameCount: integer(file.frameCount, 1, 1)} : {})}};
  });
  if (new Set(media.map(m => m.id)).size !== media.length) invalid();
  const channels = list(v.channels, 2).map(value => {
    const a = exact(value, ["kind", "offerId", "priceMinor", "mrpMinor", "minimumOrder", "quantityStep", "tiers"]);
    if (!["retail", "wholesale", "bulk"].includes(String(a.kind))) invalid();
    const priceMinor = integer(a.priceMinor), minimumOrder = integer(a.minimumOrder), quantityStep = integer(a.quantityStep);
    const mrpMinor = a.mrpMinor === null ? null : integer(a.mrpMinor, priceMinor);
    const tiers = list(a.tiers, 20).map(t => {
      const row = exact(t, ["minimumQuantity", "unitPriceMinor"]);
      return {minimumQuantity: integer(row.minimumQuantity), unitPriceMinor: integer(row.unitPriceMinor)};
    });
    if ((tiers.length &&
        (tiers[0]!.minimumQuantity !== minimumOrder || tiers[0]!.unitPriceMinor !== priceMinor)) ||
        tiers.some((t, i) => (t.minimumQuantity - minimumOrder) % quantityStep !== 0 || (i > 0 &&
          (t.minimumQuantity <= tiers[i - 1]!.minimumQuantity || t.unitPriceMinor > tiers[i - 1]!.unitPriceMinor)))) invalid();
    return {kind: a.kind as StoreSkuChannel["kind"], offerId: id(a.offerId), priceMinor, mrpMinor,
      minimumOrder, quantityStep, tiers};
  });
  if (!channels.length || new Set(channels.map(c => c.kind)).size !== channels.length ||
      (channels.some(c => c.kind === "wholesale") && channels.some(c => c.kind === "bulk"))) invalid();
  return {skuId, canonicalProductId, verifiedPackId: id(v.verifiedPackId), sku: text(v.sku, 80),
    publicListing: boolean(v.publicListing),
    content: {title: text(c.title), brand: text(c.brand), variant: text(c.variant, 240, true),
      categoryId: id(c.categoryId), description: text(c.description, 4000, true),
      highlights: list(c.highlights, 20).map(h => text(h, 500)),
      specifications: list(c.specifications, 40).map(s => {
        const row = exact(s, ["label", "value"]); return {label: text(row.label), value: text(row.value, 1000)};
      }), media},
    pack: {label: text(p.label), quantityMilli: integer(p.quantityMilli), unit: p.unit as StoreSkuPack["unit"],
      unitsPerCase: integer(p.unitsPerCase)}, channels,
    provenance: {entryMethod: provenance.entryMethod as StoreSkuInput["provenance"]["entryMethod"],
      sourceRecordId: id(provenance.sourceRecordId)}};
}

function normalizeRecord(value: unknown, storeId: string): StoreSkuRecord {
  const r = exact(value, ["schemaVersion", "storeId", "revision", "observedAt", "skuId", "canonicalProductId",
    "verifiedPackId", "sku", "publicListing", "content", "pack", "channels", "provenance"]);
  if (r.schemaVersion !== 1 || r.storeId !== storeId) invalid();
  const {schemaVersion: _, storeId: _s, revision, observedAt, ...input} = r;
  const timestamp = text(observedAt, 32);
  if (!Number.isFinite(Date.parse(timestamp)) || new Date(timestamp).toISOString() !== timestamp) invalid();
  return {...normalizeSku(input, storeId), schemaVersion: 1, storeId,
    revision: integer(revision, 1, 1_000_000_001), observedAt: timestamp};
}

export interface CatalogueSaveReceipt {fingerprint: string; record: StoreSkuRecord}

/** Shared by the transaction adapter and isolated tests; no network side effects. */
export function planCatalogueSave(command: CatalogueSave, current?: StoreSkuRecord,
  receipt?: CatalogueSaveReceipt): StoreSkuRecord {
  const storeId = id(command.profile.workspaceId);
  requireStore(command.profile, storeId, command.ownerUserId);
  const input = normalizeSku(command.input, storeId);
  const fingerprint = cataloguePayloadHash({storeId, input, expectedRevision: command.expectedRevision});
  if (command.fingerprint !== fingerprint) invalid();
  const conflict = () => new WorkspaceProfileError("conflict", "This product changed. Refresh before saving again.", 409);
  if (receipt) {
    exact(receipt, ["fingerprint", "record"]);
    const prior = normalizeRecord(receipt.record, storeId);
    if (receipt.fingerprint !== fingerprint || prior.skuId !== input.skuId) throw conflict();
    return prior;
  }
  const prior = current && normalizeRecord(current, storeId);
  if (command.expectedRevision !== (prior?.revision ?? 0) || (prior &&
      (prior.skuId !== input.skuId || prior.canonicalProductId !== input.canonicalProductId ||
       prior.verifiedPackId !== input.verifiedPackId ||
       cataloguePayloadHash(prior.provenance) !== cataloguePayloadHash(input.provenance)))) throw conflict();
  return normalizeRecord({...input, schemaVersion: 1, storeId,
    revision: command.expectedRevision + 1, observedAt: command.observedAt}, storeId);
}

/** The saved mirror is the binding: never allocate a second SKU or Stock record. */
export function planReviewedCatalogueSave(command: CatalogueSave, identity: CatalogueIdentity,
  catalogue: CatalogueAggregate | undefined, authority: CatalogueProducerAuthority | undefined,
  participant: SupplyParticipantWorkspace | undefined, current?: StoreSkuRecord,
  receipt?: CatalogueSaveReceipt, authorizationAt = command.observedAt): StoreSkuRecord {
  const storeId = id(command.profile.workspaceId), at = command.observedAt;
  if (!Number.isFinite(Date.parse(at)) || new Date(at).toISOString() !== at) invalid();
  requireStore(command.profile, storeId, command.ownerUserId);
  const input = normalizeSku(command.input, storeId);
  // Owners may withdraw their exact existing mirror even after review/selling
  // authority expires. This grants no new content, price or publication rights.
  if (!input.publicListing && (current || receipt)) {
    if (receipt) return planCatalogueSave(command, current, receipt);
    const {schemaVersion: _v, storeId: _s, revision: _r, observedAt: _a, ...prior} = normalizeRecord(current, storeId);
    if (cataloguePayloadHash({...prior, publicListing: false}) !== cataloguePayloadHash(input)) {
      invalid("Withdraw the original listing without changing its product facts.");
    }
    return planCatalogueSave(command, current);
  }
  const actor = producerActor(id(command.ownerUserId), identity, authorizationAt, authority);
  if (actor.workspaceId !== storeId || !actor.scopes.includes("supply.workspace.admin") ||
      !participant || participant.schemaVersion !== 1 || participant.status !== "registered" ||
      participant.workspaceId !== storeId || participant.tenantId !== identity.tenantId) {
    throw new WorkspaceProfileError("forbidden", "Reviewed product binding is not available.", 403);
  }
  // Recovery is a historical result, not a new publication decision. Current
  // actor/Store access still applies, but an expired offer cannot erase a receipt.
  if (receipt) return planCatalogueSave(command, current, receipt);
  if (!catalogue || catalogue.schemaVersion !== 1 || catalogue.catalogueId !== identity.catalogueId ||
      catalogue.tenantId !== identity.tenantId) invalid("Reviewed catalogue is not available.");
  const product = catalogue.products.find(p => p.productId === input.canonicalProductId);
  const pack = catalogue.packs.find(p => p.packId === input.verifiedPackId);
  if (product?.state !== "verified" || pack?.state !== "verified" || pack.productId !== product.productId ||
      product.contentSha256.toUpperCase() !== cataloguePayloadHash(input.content) ||
      pack.descriptorSha256.toUpperCase() !== cataloguePayloadHash(input.pack)) {
    invalid("Product or pack does not match its reviewed version.");
  }
  for (const channel of input.channels) {
    const offer = catalogue.offers.find(o => o.offerId === channel.offerId && o.workspaceId === storeId &&
      o.packId === pack.packId && o.buyingContext === (channel.kind === "retail" ? "consumer" : "wholesale"));
    const term = offer && referencedOfferTermAt(offer, authorizationAt);
    if (!offer || !term || term.termSnapshotSha256.toUpperCase() !== cataloguePayloadHash(channelTerms(channel)) ||
        offer.serviceAreaIds.length === 0 || offer.serviceAreaIds.some(serviceAreaId =>
          !currentCapability(participant, {capability: channel.kind === "retail" ? "retail_fulfilment" : "wholesale_supply",
            at: authorizationAt, categoryId: product.categoryId, serviceAreaId}))) {
      invalid("Selling terms do not match an active reviewed offer.");
    }
  }
  return planCatalogueSave(command, current, receipt);
}

export class FirestoreWorkspaceCatalogueRepository implements WorkspaceCatalogueRepository {
  constructor(private readonly firestore: Firestore, readonly realm: "evaluation" | "production",
    private readonly now: () => Date = () => new Date()) {}

  /** Internal only: resolves private authority inside the committing transaction.
   * No HTTP operation, automatic grants, approval shortcut or runtime seeds.
   */
  async produceCatalogue(operatorUserId: string, identity: CatalogueIdentity,
    input: Readonly<Record<string, unknown>>): Promise<CatalogueAggregate> {
    const operator = id(operatorUserId), catalogueId = id(identity.catalogueId);
    const normalized = productionInput(input);
    const command: CatalogueProduction = {operatorUserId: operator,
      identity: {catalogueId, tenantId: id(identity.tenantId)}, input: normalized,
      observedAt: this.now().toISOString()};
    const root = this.firestore.collection("workspaceCatalogues").doc(this.realm);
    const aggregateRef = root.collection("canonicalCatalogues").doc(catalogueId);
    const receiptRef = aggregateRef.collection("producerReceipts")
      .doc(cataloguePayloadHash([operator, normalized.commandId]));
    const authorityRef = root.collection("producerAuthorities").doc(operator);
    return this.firestore.runTransaction(async transaction => {
      const [authorityDoc, aggregateDoc, receiptDoc] = await transaction.getAll(authorityRef, aggregateRef, receiptRef);
      const authority = authorityDoc?.data() as CatalogueProducerAuthority | undefined;
      let participant: SupplyParticipantWorkspace | undefined, profile: WorkspaceProfileRecord | undefined;
      if (["propose_product", "propose_pack", "create_offer"].includes(String(normalized.type)) &&
          authority?.actor?.workspaceId) {
        const workspaceId = id(authority.actor.workspaceId);
        const [participantDoc, stores] = await Promise.all([
          transaction.get(root.collection("participants").doc(workspaceId)),
          transaction.get(this.firestore.collection("workspaceProfiles").where("workspaceId", "==", workspaceId).limit(2)),
        ]);
        participant = participantDoc.data() as SupplyParticipantWorkspace | undefined;
        if (stores.docs.length === 1 && stores.docs[0]!.get("caseId") === stores.docs[0]!.id) {
          profile = stores.docs[0]!.data() as WorkspaceProfileRecord;
        }
      }
      const result = planCatalogueProduction(command, authority,
        aggregateDoc?.data() as CatalogueAggregate | undefined, participant, profile,
        receiptDoc?.data() as CatalogueProductionReceipt | undefined, this.now().toISOString());
      if (!result.replayed) {
        transaction.set(aggregateRef, result.aggregate);
        transaction.create(aggregateRef.collection("revisions").doc(String(result.aggregate.version)), result.aggregate);
        transaction.create(receiptRef, {fingerprint: result.fingerprint, result: result.aggregate});
      }
      return result.aggregate;
    });
  }

  private root(storeId: string) {
    return this.firestore.collection("workspaceCatalogues").doc(this.realm)
      .collection("stores").doc(id(storeId));
  }
  private listingRoot() {
    return this.firestore.collection("workspaceCatalogues").doc(this.realm).collection("publicListingBindings");
  }
  private detailsHead(storeId: string) { return this.root(storeId).collection("publicDetails").doc("current"); }
  async readStorePublicDetails(storeId: string, ownerUserId?: string): Promise<StorePublicDetailsRecord | undefined> {
    storeId = id(storeId);
    return this.firestore.runTransaction(async transaction => {
      const profiles = await transaction.get(this.firestore.collection("workspaceProfiles").where("workspaceId", "==", storeId).limit(2));
      if (profiles.size !== 1 || profiles.docs[0]!.id !== profiles.docs[0]!.get("caseId")) requireStore(undefined, storeId, ownerUserId);
      const profile = requireStore(profiles.docs[0]!.data() as WorkspaceProfileRecord, storeId, ownerUserId);
      if (ownerUserId === undefined && !profile.shopEnabled) throw new WorkspaceProfileError("not_found", "Store is unavailable.", 404);
      const head = await transaction.get(this.detailsHead(storeId));
      return head.exists ? publicDetailsRecord(head.data(), this.realm, storeId) : undefined;
    });
  }
  async saveStorePublicDetails(original: StorePublicDetailsCommand): Promise<StorePublicDetailsRecord> {
    const command = structuredClone(original), head = this.detailsHead(command.storeId);
    if (command.realm !== this.realm) invalid();
    const receipt = head.collection("receipts").doc(cataloguePayloadHash([command.ownerUserId, command.idempotencyKey]));
    return this.firestore.runTransaction(async transaction => {
      const [profiles, current, saved] = await Promise.all([
        transaction.get(this.firestore.collection("workspaceProfiles").where("workspaceId", "==", command.storeId).limit(2)),
        transaction.get(head), transaction.get(receipt)]);
      const profile = profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get("caseId")
        ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined;
      const record = planStorePublicDetailsSave(command, profile,
        current.exists ? current.data() as StorePublicDetailsRecord : undefined,
        saved.exists ? saved.data() as StorePublicDetailsReceipt : undefined);
      if (!saved.exists) {
        transaction.set(head, record);
        transaction.create(head.collection("revisions").doc(String(record.revision)), record);
        transaction.create(receipt, {fingerprint: command.fingerprint, record});
      }
      return record;
    });
  }
  async reconcileStorePublicDetails(original: StorePublicDetailsCommand): Promise<StorePublicDetailsRecord | undefined> {
    const command = structuredClone(original);
    if (command.realm !== this.realm) invalid();
    const receipt = this.detailsHead(command.storeId).collection("receipts").doc(cataloguePayloadHash([command.ownerUserId, command.idempotencyKey]));
    return this.firestore.runTransaction(async transaction => {
      const [profiles, saved] = await Promise.all([
        transaction.get(this.firestore.collection("workspaceProfiles").where("workspaceId", "==", command.storeId).limit(2)),
        transaction.get(receipt)]);
      requireStore(profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get("caseId")
        ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined, command.storeId, command.ownerUserId);
      return saved.exists ? originalPublicDetails(command, saved.data() as StorePublicDetailsReceipt) : undefined;
    });
  }
  async store(storeId: string): Promise<WorkspaceProfileRecord | undefined> {
    const result = await this.firestore.collection("workspaceProfiles")
      .where("workspaceId", "==", id(storeId)).limit(2).get();
    if (result.docs.length !== 1) return undefined;
    const doc = result.docs[0]!;
    const profile = doc.data() as WorkspaceProfileRecord;
    // A duplicate/changed internal identity never silently selects another Store.
    return profile.caseId === doc.id ? profile : undefined;
  }
  async bindReviewed(command: CatalogueSave, identity: CatalogueIdentity): Promise<StoreSkuRecord> {
    return this.save(command, identity);
  }
  async readSaveReceipt(command: CatalogueSave): Promise<StoreSkuRecord | undefined> {
    command = structuredClone(command);
    const root = this.root(command.profile.workspaceId!);
    const receiptRef = root.collection("receipts").doc(cataloguePayloadHash([
      command.ownerUserId, command.input.skuId, command.idempotencyKey]));
    const profileRef = this.firestore.collection("workspaceProfiles").doc(command.profile.caseId);
    return this.firestore.runTransaction(async transaction => {
      const [profile, receipt] = await transaction.getAll(profileRef, receiptRef);
      const fresh = requireStore(profile?.data() as WorkspaceProfileRecord | undefined,
        command.profile.workspaceId!, command.ownerUserId);
      if (!receipt?.exists) return undefined;
      return planCatalogueSave({...command, profile: fresh}, undefined, receipt.data() as CatalogueSaveReceipt);
    });
  }
  async save(command: CatalogueSave, reviewedIdentity?: CatalogueIdentity): Promise<StoreSkuRecord> {
    // Freeze original intent before computing paths or yielding to a transaction.
    command = structuredClone(command);
    reviewedIdentity = reviewedIdentity && structuredClone(reviewedIdentity);
    const root = this.root(command.profile.workspaceId!);
    const head = root.collection("skus").doc(command.input.skuId);
    const receiptRef = root.collection("receipts").doc(cataloguePayloadHash([
      command.ownerUserId, command.input.skuId, command.idempotencyKey]));
    const profileRef = this.firestore.collection("workspaceProfiles").doc(command.profile.caseId);
    return this.firestore.runTransaction(async transaction => {
      const [profile, current, receipt] = await transaction.getAll(profileRef, head, receiptRef);
      const fresh = requireStore(profile?.data() as WorkspaceProfileRecord | undefined,
        command.profile.workspaceId!, command.ownerUserId);
      const prior = current?.exists ? current.data() as StoreSkuRecord : undefined;
      const original = receipt?.exists ? receipt.data() as CatalogueSaveReceipt : undefined;
      let result: StoreSkuRecord;
      if (reviewedIdentity) {
        const source = this.firestore.collection("workspaceCatalogues").doc(this.realm);
        const [catalogue, authority, participant] = await transaction.getAll(
          source.collection("canonicalCatalogues").doc(id(reviewedIdentity.catalogueId)),
          source.collection("producerAuthorities").doc(id(command.ownerUserId)),
          source.collection("participants").doc(id(fresh.workspaceId)));
        result = planReviewedCatalogueSave({...command, profile: fresh}, reviewedIdentity,
          catalogue?.data() as CatalogueAggregate | undefined,
          authority?.data() as CatalogueProducerAuthority | undefined,
          participant?.data() as SupplyParticipantWorkspace | undefined, prior, original, this.now().toISOString());
      } else {
        result = planCatalogueSave({...command, profile: fresh}, prior, original);
      }
      if (!receipt?.exists) {
        const bindings = cataloguePublicListingBindings(this.realm, result);
        const refs = bindings.map(binding => this.listingRoot().doc(binding.listingId));
        const existing = await transaction.getAll(...refs);
        for (let i = 0; i < bindings.length; i++) {
          if (existing[i]!.exists) checkedListingBinding(existing[i]!.data(), bindings[i]!);
        }
        transaction.create(head.collection("revisions").doc(String(result.revision)), result);
        transaction.set(head, result);
        transaction.create(receiptRef, {fingerprint: command.fingerprint, record: result});
        for (let i = 0; i < bindings.length; i++) {
          if (!existing[i]!.exists) transaction.create(refs[i]!, bindings[i]!);
        }
      }
      return result;
    });
  }
  async page(profile: WorkspaceProfileRecord, owner: string | undefined,
    after: string | undefined, limit: number, skuId?: string): Promise<StoreSkuRecord[]> {
    return this.firestore.runTransaction(async transaction => {
      const doc = await transaction.get(this.firestore.collection("workspaceProfiles").doc(profile.caseId));
      const fresh = requireStore(doc.data() as WorkspaceProfileRecord | undefined, profile.workspaceId!, owner);
      if (owner === undefined && fresh.shopEnabled !== true) return [];
      let query = this.root(fresh.workspaceId!).collection("skus").orderBy(FieldPath.documentId()).limit(limit);
      if (after !== undefined) query = query.startAfter(id(after));
      if (skuId !== undefined) query = query.where(FieldPath.documentId(), "==", id(skuId));
      const snapshot = await transaction.get(query);
      return snapshot.docs.map(d => {
        const result = normalizeRecord(d.data(), fresh.workspaceId!);
        if (result.skuId !== d.id) invalid(); return result;
      });
    });
  }
  async catalogue(catalogueId: string): Promise<CatalogueAggregate | undefined> {
    const doc = await this.firestore.collection("workspaceCatalogues").doc(this.realm)
      .collection("canonicalCatalogues").doc(id(catalogueId)).get();
    // This adapter never invents/reviews a canonical catalogue or seeds offer terms.
    return doc.exists ? doc.data() as CatalogueAggregate : undefined;
  }
  async publicCatalogueSource(storeId: string, identity: CatalogueIdentity): Promise<PublicCatalogueSource | undefined> {
    storeId = id(storeId);
    return this.firestore.runTransaction(async transaction => {
      const [profiles, catalogueDoc, skuDocs, policyDoc, detailsDoc] = await Promise.all([
        transaction.get(this.firestore.collection("workspaceProfiles").where("workspaceId", "==", storeId).limit(2)),
        transaction.get(this.firestore.collection("workspaceCatalogues").doc(this.realm).collection("canonicalCatalogues").doc(id(identity.catalogueId))),
        transaction.get(this.root(storeId).collection("skus").orderBy(FieldPath.documentId()).limit(501)),
        transaction.get(this.root(storeId).collection("supplierPolicies").doc("current")),
        transaction.get(this.detailsHead(storeId)),
      ]);
      if (profiles.size !== 1 || profiles.docs[0]!.id !== profiles.docs[0]!.get("caseId") ||
          skuDocs.size > 500 || !catalogueDoc.exists) return undefined;
      const profile = requireStore(profiles.docs[0]!.data() as WorkspaceProfileRecord, storeId);
      if (!profile.shopEnabled) return undefined;
      const catalogue = catalogueDoc.data() as CatalogueAggregate;
      if (catalogue.catalogueId !== identity.catalogueId || catalogue.tenantId !== identity.tenantId) return undefined;
      const records = skuDocs.docs.map(doc => {
        const row = normalizeRecord(doc.data(), storeId);
        if (row.skuId !== doc.id) invalid();
        return row;
      });
      const expected = records.flatMap(row => cataloguePublicListingBindings(this.realm, row));
      const docs = expected.length ? await transaction.getAll(...expected.map(row => this.listingRoot().doc(row.listingId))) : [];
      const bindings = docs.flatMap((doc, i) => doc.exists ? [checkedListingBinding(doc.data(), expected[i]!)] : []);
      return {profile, catalogue, records, bindings, policy: policyDoc.exists ? policyDoc.data()! : null,
        publicDetails: detailsDoc.exists ? detailsDoc.data()! : null};
    });
  }
  async publicListingBindings(record: StoreSkuRecord): Promise<PublicCatalogueListingBinding[] | undefined> {
    record = structuredClone(record);
    const expected = cataloguePublicListingBindings(this.realm, record);
    return this.firestore.runTransaction(async transaction => {
      const profiles = await transaction.get(this.firestore.collection("workspaceProfiles")
        .where("workspaceId", "==", record.storeId).limit(2));
      if (profiles.size !== 1 || profiles.docs[0]!.id !== profiles.docs[0]!.get("caseId")) return undefined;
      const store = requireStore(profiles.docs[0]!.data() as WorkspaceProfileRecord, record.storeId);
      if (!store.shopEnabled) return undefined;
      const [head, ...bindings] = await transaction.getAll(this.root(record.storeId).collection("skus").doc(record.skuId),
        ...expected.map(binding => this.listingRoot().doc(binding.listingId)));
      if (!head?.exists) return undefined;
      const current = normalizeRecord(head.data(), record.storeId);
      if (!current.publicListing || cataloguePayloadHash(current) !== cataloguePayloadHash(record) ||
          bindings.some(binding => !binding.exists)) return undefined;
      return expected.map((binding, i) => checkedListingBinding(bindings[i]!.data(), binding));
    });
  }
  /** One final read transaction for the admitted page: earlier rows cannot be
   * withdrawn/rebound unnoticed while later per-SKU lookups are awaited. */
  async confirmPublicListingSnapshot(storeId: string, records: readonly StoreSkuRecord[],
    identity: CatalogueIdentity, catalogueFingerprint: string, detailsFingerprint?: string): Promise<WorkspaceProfileRecord | undefined> {
    storeId = id(storeId);
    const expected = records.map(record => normalizeRecord(structuredClone(record), storeId));
    const catalogueId = id(identity.catalogueId), tenantId = id(identity.tenantId);
    if (expected.length > 50 || new Set(expected.map(record => record.skuId)).size !== expected.length ||
        !/^[A-F0-9]{64}$/u.test(catalogueFingerprint) ||
        detailsFingerprint !== undefined && !/^[A-F0-9]{64}$/u.test(detailsFingerprint)) invalid();
    const bindings = expected.flatMap(record => cataloguePublicListingBindings(this.realm, record));
    return this.firestore.runTransaction(async transaction => {
      const profiles = await transaction.get(this.firestore.collection("workspaceProfiles")
        .where("workspaceId", "==", storeId).limit(2));
      if (profiles.size !== 1 || profiles.docs[0]!.id !== profiles.docs[0]!.get("caseId")) return undefined;
      const profile = requireStore(profiles.docs[0]!.data() as WorkspaceProfileRecord, storeId);
      if (!profile.shopEnabled) return undefined;
      const documents = await transaction.getAll(
        this.firestore.collection("workspaceCatalogues").doc(this.realm).collection("canonicalCatalogues").doc(catalogueId),
        ...expected.map(record => this.root(storeId).collection("skus").doc(record.skuId)),
        ...bindings.map(binding => this.listingRoot().doc(binding.listingId)),
        ...(detailsFingerprint === undefined ? [] : [this.detailsHead(storeId)]));
      const catalogue = documents[0]?.data() as CatalogueAggregate | undefined;
      if (!catalogue || catalogue.catalogueId !== catalogueId || catalogue.tenantId !== tenantId ||
          cataloguePayloadHash(catalogue) !== catalogueFingerprint) return undefined;
      for (let i = 0; i < expected.length; i++) {
        const current = documents[i + 1];
        if (!current?.exists || !expected[i]!.publicListing ||
            cataloguePayloadHash(normalizeRecord(current.data(), storeId)) !== cataloguePayloadHash(expected[i])) return undefined;
      }
      for (let i = 0; i < bindings.length; i++) {
        const doc = documents[1 + expected.length + i];
        if (!doc?.exists) return undefined;
        checkedListingBinding(doc.data(), bindings[i]!);
      }
      if (detailsFingerprint !== undefined) {
        const doc = documents[1 + expected.length + bindings.length];
        if (!doc || cataloguePayloadHash(doc.exists ? doc.data() : null) !== detailsFingerprint) return undefined;
      }
      return profile;
    });
  }
}

/** Canonical, cross-runtime digest of reviewed content/pack/term payloads. */
export function cataloguePayloadHash(value: unknown): string {
  function sorted(item: unknown): unknown {
    if (Array.isArray(item)) return item.map(sorted);
    if (item !== null && typeof item === "object") return Object.fromEntries(
      Object.keys(item).sort().map(k => [k, sorted((item as Record<string, unknown>)[k])]));
    return item;
  }
  return createHash("sha256").update(JSON.stringify(sorted(value))).digest("hex").toUpperCase();
}
