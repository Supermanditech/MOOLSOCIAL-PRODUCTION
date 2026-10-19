import {FieldPath, type Firestore} from "firebase-admin/firestore";
import {cataloguePayloadHash, type WorkspaceCatalogueService} from "./workspace_catalogue_service.js";
import {WorkspaceProfileError, type WorkspaceProfileRecord} from "./workspace_profile_service.js";

/** Owner-advertised terms only; never evaluated/applied savings or redemption. */
export interface PromotionBenefitTerms {
  schemaVersion: 1; kind: "flat" | "percentage"; currency: "INR";
  flatAmountMinor: number | null; flatBasis: "per_pack" | "per_order" | null;
  percentageBasisPoints: number | null; maximumSavingMinor: number | null;
  minimumSpendMinor: number | null; minimumQuantity: number | null;
}
/** Public product promotion only: no discount, consent, redemption or order authority. */
export interface PromotionInput {
  skuId: string; skuRevision: number; channel: "retail" | "wholesale" | "bulk";
  headline: string; detail: string; validFrom: string; validUntil: string; active: boolean;
  benefitTerms?: PromotionBenefitTerms;
}
export interface PromotionRecord extends PromotionInput {
  schemaVersion: 1; realm: "evaluation" | "production"; storeId: string;
  placementId: string; revision: number; observedAt: string;
}
export interface PromotionCommand {
  ownerUserId: string; realm: PromotionRecord["realm"]; storeId: string; placementId: string;
  expectedRevision: number; idempotencyKey: string; promotion: PromotionInput;
  fingerprint: string; observedAt: string;
  promotionTermsVersion?: 1;
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
  benefitTerms?: PromotionBenefitTerms;
}
interface PublicPromotionPage {
  schemaVersion: 1; realm: PromotionRecord["realm"]; storeId: string; observedAt: string;
  state: "ready" | "unavailable"; coverage: "verified_public_promotions_only";
  orderingAvailable: false; items: PublicPromotion[]; nextCursor: string | null;
  promotionTermsVersion?: 1;
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
export function promotionBenefitTerms(value: unknown): PromotionBenefitTerms {
  const row = exact(value, ["schemaVersion", "kind", "currency", "flatAmountMinor", "flatBasis", "percentageBasisPoints",
    "maximumSavingMinor", "minimumSpendMinor", "minimumQuantity"]);
  if (row.schemaVersion !== 1 || row.currency !== "INR" || typeof row.kind !== "string" || !["flat", "percentage"].includes(row.kind)) fail();
  const money = (value: unknown, minimum = 1) => value === null ? null : integer(value, minimum, 4_503_599_627_370_495);
  const flatAmountMinor = money(row.flatAmountMinor), maximumSavingMinor = money(row.maximumSavingMinor);
  const minimumSpendMinor = money(row.minimumSpendMinor, 0);
  const percentageBasisPoints = row.percentageBasisPoints === null ? null : integer(row.percentageBasisPoints, 1, 10000);
  const minimumQuantity = row.minimumQuantity === null ? null : integer(row.minimumQuantity, 1);
  if (row.kind === "flat" ? flatAmountMinor === null || percentageBasisPoints !== null ||
      typeof row.flatBasis !== "string" || !["per_pack", "per_order"].includes(row.flatBasis) : flatAmountMinor !== null || row.flatBasis !== null || percentageBasisPoints === null) fail();
  return {schemaVersion: 1, currency: "INR", kind: row.kind as PromotionBenefitTerms["kind"], flatAmountMinor,
    flatBasis: row.flatBasis as PromotionBenefitTerms["flatBasis"], percentageBasisPoints, maximumSavingMinor, minimumSpendMinor, minimumQuantity};
}
function inputFromRecord(row: Record<string, unknown>): PromotionInput {
  return input(Object.fromEntries([...inputKeys, ...(Object.hasOwn(row, "benefitTerms") ? ["benefitTerms"] : [])].map(k => [k, row[k]])));
}
function input(value: unknown): PromotionInput {
  const row = exact(value, inputKeys, ["benefitTerms"]);
  if (typeof row.channel !== "string" || !["retail", "wholesale", "bulk"].includes(row.channel) || typeof row.active !== "boolean") fail();
  const validFrom = time(row.validFrom), validUntil = time(row.validUntil);
  if (validFrom >= validUntil) fail();
  return {skuId: id(row.skuId), skuRevision: integer(row.skuRevision, 1), channel: row.channel as PromotionInput["channel"],
    headline: text(row.headline, 160), detail: text(row.detail, 2000), validFrom, validUntil, active: row.active,
    ...(Object.hasOwn(row, "benefitTerms") ? {benefitTerms: promotionBenefitTerms(row.benefitTerms)} : {})};
}
function record(value: unknown, realm: PromotionRecord["realm"], storeId: string): PromotionRecord {
  const row = exact(value, [...inputKeys, "schemaVersion", "realm", "storeId", "placementId", "revision", "observedAt"], ["benefitTerms"]);
  if (row.schemaVersion !== 1 || row.realm !== realm || row.storeId !== storeId) fail();
  return {...inputFromRecord(row), schemaVersion: 1, realm, storeId,
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
function request(userId: string, realm: PromotionRecord["realm"], raw: Readonly<Record<string, unknown>>, now: string, terms = false): PromotionCommand {
  const row = exact(structuredClone(raw), ["storeId", "placementId", "expectedRevision", "idempotencyKey", "promotion"]);
  const facts = {ownerUserId: id(userId), realm, storeId: id(row.storeId), placementId: id(row.placementId),
    expectedRevision: integer(row.expectedRevision), promotion: input(row.promotion)};
  if (facts.promotion.benefitTerms !== undefined && !terms) fail("unavailable", 503);
  return {...facts, idempotencyKey: id(row.idempotencyKey), fingerprint: cataloguePayloadHash(facts), observedAt: time(now),
    ...(terms ? {promotionTermsVersion: 1 as const} : {})};
}
function original(command: PromotionCommand, receipt: PromotionReceipt): PromotionRecord {
  const result = record(receipt.record, command.realm, command.storeId);
  if (receipt.fingerprint !== command.fingerprint || result.placementId !== command.placementId ||
      result.revision !== command.expectedRevision + 1 ||
      cataloguePayloadHash(inputFromRecord(result as unknown as Record<string, unknown>)) !== cataloguePayloadHash(command.promotion)) fail("conflict", 409);
  return result;
}
/** Atomic planner. Historical receipt is not current publication or renewed validity. */
export function planPromotionSave(command: PromotionCommand, profile: WorkspaceProfileRecord | undefined,
  sku: unknown, current?: PromotionRecord, receipt?: PromotionReceipt, authorizationAt = command.observedAt): PromotionRecord {
  owner(profile, command.storeId, command.ownerUserId);
  if (receipt) return original(command, receipt);
  const prior = current && record(current, command.realm, command.storeId);
  if (prior?.benefitTerms && command.promotionTermsVersion !== 1) fail("unavailable", 503);
  if (prior?.placementId !== undefined && prior.placementId !== command.placementId ||
      (prior?.revision ?? 0) !== command.expectedRevision) fail("conflict", 409);
  if (command.observedAt > time(authorizationAt)) fail();
  // Pausing an original publication must remain possible after source/expiry loss.
  if (!command.promotion.active && prior) {
    const old = inputFromRecord(prior as unknown as Record<string, unknown>);
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
    private readonly catalogue: Pick<WorkspaceCatalogueService, "publicCatalogue"> & Partial<Pick<WorkspaceCatalogueService, "publicDiscovery">>,
    private readonly now: () => Date = () => new Date(),
    private readonly options: {benefitTermsSupported?: boolean} = {}) {}
  private negotiation(body: Readonly<Record<string, unknown>>) {
    const {promotionTermsVersion, ...plain} = body;
    if (Object.hasOwn(body, "promotionTermsVersion") && promotionTermsVersion !== 1) fail();
    if (promotionTermsVersion === 1 && !this.options.benefitTermsSupported) fail("unavailable", 503);
    return {body: plain, terms: promotionTermsVersion === 1};
  }
  /** Endpoint still performs Firebase/default-tenant/AppCheck verification. */
  async handleOperation(userId: string, operation: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    id(userId); body = structuredClone(body);
    if (Buffer.byteLength(JSON.stringify({operation, ...body}), "utf8") > 60000) fail();
    const negotiated = this.negotiation(body);
    if (operation === "readPublicStorePromotions") return this.publicPage(body);
    if (operation === "readPublicPromotionDiscovery") return this.publicDiscovery(body);
    if (operation === "listStorePromotions") {
      const query = exact(negotiated.body, ["storeId", "limit"], ["after"]), storeId = id(query.storeId);
      const limit = integer(query.limit, 1, 20), after = query.after === undefined ? undefined : id(query.after);
      owner(await this.repository.store(storeId), storeId, userId);
      const rows = (await this.repository.page(storeId, after, limit, userId)).map(r => record(r, this.repository.realm, storeId));
      if (!negotiated.terms && rows.some(row => row.benefitTerms)) fail("unavailable", 503);
      return {schemaVersion: 1, realm: this.repository.realm, storeId, items: rows,
        nextCursor: rows.length === limit ? rows.at(-1)!.placementId : null, publicationConfirmed: false,
        ...(negotiated.terms ? {promotionTermsVersion: 1} : {})};
    }
    let result: PromotionRecord | undefined;
    if (operation === "saveStorePromotion") result = await this.save(userId, body);
    else if (operation === "readStorePromotion") result = await this.readOwned(userId, body);
    else if (operation === "reconcileStorePromotion") result = await this.reconcile(userId, body);
    else fail();
    return {schemaVersion: 1, realm: this.repository.realm, storeId: id(body.storeId),
      record: result ?? null, publicationConfirmed: false, ...(negotiated.terms ? {promotionTermsVersion: 1} : {})};
  }
  private async command(userId: string, body: Readonly<Record<string, unknown>>): Promise<PromotionCommand> {
    const n = this.negotiation(body), command = request(userId, this.repository.realm, n.body, this.now().toISOString(), n.terms);
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
    const n = this.negotiation(body), query = exact(n.body, ["storeId", "placementId"]), storeId = id(query.storeId), placementId = id(query.placementId);
    id(userId); owner(await this.repository.store(storeId), storeId, userId);
    const result = await this.repository.read(storeId, placementId, userId);
    if (result?.benefitTerms && !n.terms) fail("unavailable", 503);
    return result && record(result, this.repository.realm, storeId);
  }
  /** Descriptive placements only. Coverage/counts do not assert platform or
   * other publisher feeds, geography, discounts, eligibility or redemption. */
  async publicDiscovery(body: Readonly<Record<string, unknown>>): Promise<object> {
    const negotiated = this.negotiation(body); body = negotiated.body;
    exact(body, ["promotionDiscoveryVersion", "query", "pageSize"], ["cursor"]);
    if (body.promotionDiscoveryVersion !== 1) fail();
    const raw = exact(body.query, ["search", "categoryId", "publisher", "supplierOnly"]);
    if (typeof raw.search !== "string" || raw.search.length > 240 || typeof raw.supplierOnly !== "boolean" ||
        raw.publisher !== null && !["retailer", "manufacturer", "wholesaler", "moolSocial"].includes(String(raw.publisher))) fail();
    const query = {search: raw.search.trim().toLowerCase().replace(/\s+/gu, " "), categoryId: id(raw.categoryId),
      publisher: raw.publisher, supplierOnly: raw.supplierOnly};
    const unavailable = (): never => fail("unavailable", 503);
    if (!this.catalogue.publicDiscovery || query.publisher !== null && query.publisher !== "retailer") unavailable();
    const pageSize = integer(body.pageSize, 1, 50);
    const coverage = {kind: "connected_publishers", publisherTypes: ["retailer"], countBasis: "publications"};
    // Remove ONLY generated read observations. Persisted SKU observations,
    // revisions, content and validity remain part of the cohort fingerprint.
    const stableListing = (value: Record<string, unknown>) => {
      const copy = structuredClone(value); delete copy.observedAt;
      const store = copy.publicStore as Record<string, unknown> | undefined;
      if (store?.details) delete (store.details as Record<string, unknown>).observedAt;
      for (const row of copy.items as Record<string, unknown>[]) {
        if (row.supplierPolicy) delete (row.supplierPolicy as Record<string, unknown>).observedAt;
      }
      return copy;
    };
    const directory = async () => {
      const rows: Array<{channel: string; listing: Record<string, unknown>}> = [], snapshots: string[] = [];
      for (const destination of ["shop", "wholesale"]) {
        const catalogueQuery = {destination, search: "", categoryId: "all", sort: "relevance", brands: [],
          maximumPriceMinor: null, tradeType: null, listingIds: []};
        let cursor: string | undefined, snapshot: string | undefined, count = 0, complete = false;
        const cursors = new Set<string>();
        for (let pageIndex = 0; pageIndex < 11; pageIndex++) {
          const page = object(await this.catalogue.publicDiscovery!({discoveryPageVersion: 1,
            query: catalogueQuery, pageSize: 50, resultKind: "products", ...(cursor ? {cursor} : {})}));
          const metadata = object(page.page);
          if (page.schemaVersion !== 1 || page.discoveryPageVersion !== 1 || page.realm !== this.repository.realm ||
              page.state !== "ready" || page.coverage !== "verified_public_only" || page.directoryCoverage !== "complete_bounded" ||
              page.orderingAvailable !== false || page.resultKind !== "products" || page.requestedStore !== null ||
              time(page.observedAt) > this.now().toISOString() || cataloguePayloadHash(page.query) !== cataloguePayloadHash(catalogueQuery) ||
              !Array.isArray(page.items) || page.items.length > 50 || metadata.startIndex !== count ||
              snapshot !== undefined && metadata.snapshotId !== snapshot) unavailable();
          snapshot = text(metadata.snapshotId, 64);
          const total = integer(metadata.totalCount, 0, 500);
          for (const rawRow of page.items as unknown[]) {
            const row = exact(rawRow, ["channel", "listing"]), listing = object(row.listing);
            if (destination === "shop" ? row.channel !== "retail" : !["wholesale", "bulk"].includes(String(row.channel))) unavailable();
            id(listing.storeId);
            if (!Array.isArray(listing.items) || listing.items.length !== 1) unavailable();
            rows.push({channel: String(row.channel), listing});
          }
          const returned = (page.items as unknown[]).length;
          count += returned;
          if (count > total || count < total && returned !== 50 || rows.length > 500) unavailable();
          if (metadata.nextCursor === null) {if (count !== total) unavailable(); complete = true; break;}
          cursor = text(metadata.nextCursor, 2048);
          if (!cursors.add(cursor) || count >= total) unavailable();
        }
        if (!complete) unavailable();
        snapshots.push(snapshot!);
      }
      const stores = [...new Set(rows.map(row => id(row.listing.storeId)))].sort();
      if (stores.length > 20) unavailable();
      return {rows, stores, fingerprint: cataloguePayloadHash([snapshots, rows.map(row => ({channel: row.channel, listing: stableListing(row.listing)}))])};
    };
    type Item = {publication: PublicPromotion; listing: Record<string, unknown>};
    let nextActivation: string | undefined;
    const cohort = async (catalogue: Awaited<ReturnType<typeof directory>>) => {
      const items: Item[] = [], keys = new Set<string>();
      let scanned = 0, scannedRecords = 0;
      for (const storeId of catalogue.stores) {
        let after: string | undefined, complete = false;
        for (let pageIndex = 0; pageIndex < 26; pageIndex++) {
          const page = await this.publicPage({storeId, limit: 20, ...(after ? {after} : {}),
            ...(negotiated.terms ? {promotionTermsVersion: 1} : {})}, promotion => {
            if (++scannedRecords > 500) unavailable();
            if (promotion.active && promotion.validFrom > this.now().toISOString() &&
                (nextActivation === undefined || promotion.validFrom < nextActivation)) nextActivation = promotion.validFrom;
          });
          if (page.state !== "ready") unavailable();
          for (const publication of page.items) {
            const key = cataloguePayloadHash([storeId, publication.publicationId]);
            if (!keys.add(key) || ++scanned > 500) unavailable();
            const matches = catalogue.rows.filter(row => row.listing.storeId === storeId &&
              row.channel === publication.product.channels[0]?.kind &&
              object((row.listing.items as unknown[])[0]).skuId === publication.product.skuId);
            if (matches.length !== 1) unavailable();
            const listing = matches[0]!.listing, sku = object((listing.items as unknown[])[0]);
            const expected = structuredClone(Object.fromEntries(["skuId", "canonicalProductId", "verifiedPackId", "sku", "revision", "observedAt", "content", "pack"]
              .filter(k => Object.hasOwn(sku, k)).map(k => [k, sku[k]])));
            const actual: Record<string, unknown> = structuredClone(publication.product); delete actual.supplierPolicy; delete actual.channels;
            // publicPage's legacy static-media contract omits frameCount=1.
            const media = (actual.content as Record<string, unknown>)?.media;
            const expectedMedia = (expected.content as Record<string, unknown>)?.media;
            if (Array.isArray(media) && Array.isArray(expectedMedia)) expectedMedia.forEach((value, index) => {
              const file = (value as Record<string, any>).file, other = (media[index] as Record<string, any> | undefined)?.file;
              if (file?.frameCount === 1 && other && !Object.hasOwn(other, "frameCount")) delete file.frameCount;
            });
            const channel = (sku.channels as Record<string, unknown>[]).find(c => c.kind === publication.product.channels[0]?.kind);
            if (cataloguePayloadHash(expected) !== cataloguePayloadHash(actual) ||
                cataloguePayloadHash(channel) !== cataloguePayloadHash(publication.product.channels[0])) unavailable();
            items.push({publication, listing});
          }
          if (page.nextCursor === null) {complete = true; break;}
          if (after !== undefined && page.nextCursor <= after) unavailable();
          after = page.nextCursor;
        }
        if (!complete) unavailable();
      }
      return items;
    };
    const stableItems = (items: Item[]) => items.map(({publication, listing}) => {
      const copy = structuredClone(publication); delete (copy as Partial<PublicPromotion>).observedAt;
      if (copy.product.supplierPolicy) delete (copy.product.supplierPolicy as Record<string, unknown>).observedAt;
      return {publication: copy, listing: stableListing(listing)};
    });
    const firstDirectory = await directory(), first = await cohort(firstDirectory);
    const secondDirectory = await directory(), confirmed = await cohort(secondDirectory);
    const lastDirectory = await directory();
    if (firstDirectory.fingerprint !== secondDirectory.fingerprint || secondDirectory.fingerprint !== lastDirectory.fingerprint ||
        cataloguePayloadHash(stableItems(first)) !== cataloguePayloadHash(stableItems(confirmed))) fail("stale_snapshot", 409);
    const observedAt = this.now().toISOString();
    if (nextActivation !== undefined && nextActivation <= observedAt ||
        confirmed.some(item => item.publication.validUntil <= observedAt)) fail("stale_snapshot", 409);
    const selected = confirmed.filter(({publication, listing}) => {
      const sku = object((listing.items as unknown[])[0]), content = object(sku.content), pack = object(sku.pack);
      return (query.categoryId === "all" || content.categoryId === query.categoryId) &&
        (!query.search || [publication.headline, publication.detail, content.title, content.brand, content.variant, pack.label]
          .join(" ").toLowerCase().replace(/\s+/gu, " ").includes(query.search));
    }).sort((a, b) => a.publication.publisherId.localeCompare(b.publication.publisherId) ||
      a.publication.publicationId.localeCompare(b.publication.publicationId));
    const snapshotId = cataloguePayloadHash([this.repository.realm, coverage, firstDirectory.fingerprint, stableItems(confirmed)]).toLowerCase();
    const queryHash = cataloguePayloadHash([this.repository.realm, query, coverage, ...(negotiated.terms ? [1] : [])]).toLowerCase();
    let index = 0;
    if (body.cursor !== undefined) {
      const encoded = text(body.cursor, 2048);
      let cursor: Record<string, unknown>;
      try {cursor = exact(JSON.parse(Buffer.from(encoded, "base64url").toString("utf8")), ["v", "q", "s", "n", "i"]);} catch {fail();}
      if (Buffer.from(JSON.stringify(cursor)).toString("base64url") !== encoded || cursor.v !== 1 || cursor.q !== queryHash ||
          cursor.s !== snapshotId || cursor.n !== pageSize) fail("stale_cursor", 409);
      index = integer(cursor.i, 0, 500);
      if (index % pageSize || index >= selected.length) fail("stale_cursor", 409);
    }
    const cursorAt = (i: number) => Buffer.from(JSON.stringify({v: 1, q: queryHash, s: snapshotId, n: pageSize, i})).toString("base64url");
    const result = {schemaVersion: 1, promotionDiscoveryVersion: 1, realm: this.repository.realm, state: "ready", coverage,
      ...(negotiated.terms ? {promotionTermsVersion: 1} : {}),
      orderingAvailable: false, observedAt, query, items: selected.slice(index, index + pageSize),
      page: {snapshotId, startIndex: index, totalCount: selected.length,
        previousCursor: index === 0 ? null : cursorAt(index - pageSize),
        nextCursor: index + pageSize < selected.length ? cursorAt(index + pageSize) : null}};
    if (Buffer.byteLength(JSON.stringify(result), "utf8") > 480 * 1024) unavailable();
    return result;
  }
  async publicPage(body: Readonly<Record<string, unknown>>, observe?: (record: PromotionRecord) => void): Promise<PublicPromotionPage> {
    const negotiated = this.negotiation(body);
    const query = exact(structuredClone(negotiated.body), ["storeId", "limit"], ["after"]), storeId = id(query.storeId);
    const limit = integer(query.limit, 1, 20), after = query.after === undefined ? undefined : id(query.after);
    const base = (): Omit<PublicPromotionPage, "state" | "items" | "nextCursor"> => ({schemaVersion: 1,
      realm: this.repository.realm, storeId, observedAt: this.now().toISOString(), orderingAvailable: false,
      coverage: "verified_public_promotions_only", ...(negotiated.terms ? {promotionTermsVersion: 1} : {})});
    try {
      owner(await this.repository.store(storeId), storeId);
      const rows = (await this.repository.page(storeId, after, limit)).map(r => record(r, this.repository.realm, storeId));
      const items: PublicPromotion[] = [];
      for (const promotion of rows) {
        observe?.(promotion);
        let now = this.now().toISOString();
        if (!promotion.active || promotion.observedAt > now || promotion.validFrom > now || promotion.validUntil <= now) continue;
        if (promotion.benefitTerms && !negotiated.terms) fail("unavailable", 503);
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
          observedAt: now, validUntil, product, ...(promotion.benefitTerms ? {benefitTerms: structuredClone(promotion.benefitTerms)} : {})});
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
