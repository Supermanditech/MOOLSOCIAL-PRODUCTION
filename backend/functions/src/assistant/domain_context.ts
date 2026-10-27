import type {AccountPlansService, PlansReadback} from "../account/plans_service.js";
import type {AccountProfileActor} from "../account/profile_service.js";
import type {WorkspaceCatalogueService} from "../workspace/workspace_catalogue_service.js";
import type {PreparationContextSource} from "./model_service.js";
import {AssistantModelError, canonical, digest, fail, object,
  catalogueListingSelection, type PreparationReply, type PreparationTool, type PreparationContext, type PreparationRequest} from "./model_contract.js";
import {catalogueProductActions, catalogueSearchActions, nativePreferenceActions, searchSuggestion} from "./domain_context_contract.js";

const paidRevision = (p: PlansReadback) => canonical([p.owner, p.scope, p.catalogueRevision, p.subscriptionRevision]);
const searchSchema = {type: "object", properties: {query: {type: "string"}},
  required: ["query"], additionalProperties: false};
// Same opt-ins as the original public reader; never strip GST/commodity facts.
const originalPublicReadVersions = {supplierPublishersVersion: 1,
  supplierTaxReadbackVersion: 1, commodityPriceReadbackVersion: 1} as const;

const filterNames = ["brands", "maximumPrice", "pack", "sort", "availableOnly"];
// Exact existing BuyBrowseInitialData/native filter choices, not product prices
// or serviceability rules. Final native review owns applying these preferences.
const filterSorts = ["relevance", "priceLowToHigh", "priceHighToLow"];
type OriginalPublicProduct = {listingId: string; title: string; brand: string; variant: string; pack: string;
  categoryId: string; channel: string; storeId: string; skuId: string; realm: string;
  canonicalProductId: string; verifiedPackId: string; revision: string; supplierName: string; contactAvailable: boolean;
  priceMinor: number; mrpMinor: number | null; priceRevision: string; priceValidUntil: string; validUntil: number;
  minimumOrder: number; quantityStep: number; quantityMilli: number; unit: string; unitsPerCase: number;
  supplierTax: Readonly<Record<string, unknown>> | null};
type OriginalPublicFamily = {listingId: string; familyId: string; revision: string;
  validUntil: number; variants: Array<{listingId: string; title: string; variant: string; pack: string;
    attributes: Array<{dimension: string; value: string}>}>};
function filterTool(revision: string, brands: string[], prices: number[], packs: string[]): PreparationTool {
  const sourceRevision = "catalogue-filter:" + digest(revision);
  const validate = (fields: Readonly<Record<string, unknown>>) => {
    if (!Object.keys(fields).length || Object.keys(fields).some(key => !filterNames.includes(key))) return false;
    if (Object.hasOwn(fields, "brands") && (!Array.isArray(fields.brands) || new Set(fields.brands).size !== fields.brands.length ||
        fields.brands.some(value => typeof value !== "string" || !brands.includes(value)))) return false;
    if (Object.hasOwn(fields, "maximumPrice") && fields.maximumPrice !== null && !prices.includes(fields.maximumPrice as number)) return false;
    if (Object.hasOwn(fields, "pack") && fields.pack !== null && !packs.includes(fields.pack as string)) return false;
    if (Object.hasOwn(fields, "sort") && !filterSorts.includes(fields.sort as string)) return false;
    if (Object.hasOwn(fields, "availableOnly") && typeof fields.availableOnly !== "boolean") return false;
    return true;
  };
  return {name: "buy_prepare_product_filters", actionId: "AI-ACT-003", entityId: null, sourceRevision,
    description: "Review product filters", validate,
    parameters: {type: "object", additionalProperties: false,
      required: ["apply", ...filterNames], properties: {
        apply: {type: "array", items: {type: "string", enum: filterNames}},
        brands: {type: "array", items: {type: "string"}},
        maximumPrice: {type: ["integer", "null"], enum: [null, ...prices]},
        pack: {type: ["string", "null"], enum: [null, ...packs]},
        sort: {type: "string", enum: filterSorts}, availableOnly: {type: "boolean"}}},
    resolveTarget: args => {
      if (Object.keys(args).length !== filterNames.length + 1 || !Array.isArray(args.apply) ||
          !args.apply.length || new Set(args.apply).size !== args.apply.length ||
          args.apply.some(key => typeof key !== "string" || !filterNames.includes(key))) return fail("invalid_model_result");
      const fields = Object.fromEntries(args.apply.map(key => [String(key), args[String(key)]]));
      if (!validate(fields)) return fail("invalid_model_result");
      return {entityId: null, sourceRevision, fields};
    }};
}

/** Exact original catalogue reader. No client catalogue, fixture or local master. */
export class OriginalCataloguePreparationContext implements PreparationContextSource {
  constructor(private readonly deps: {projectId: string;
    plans: Pick<AccountPlansService, "read">;
    catalogue: Pick<WorkspaceCatalogueService, "publicDiscovery"> & Partial<Pick<WorkspaceCatalogueService, "publicVariantFamilies">>;
    now?: () => Date}) {}
  private now() {return (this.deps.now?.() ?? new Date()).getTime();}
  private async paid(actor: AccountProfileActor, input: PreparationRequest) {
    if (actor.projectId !== this.deps.projectId || !actor.uid || actor.tenantId !== undefined) return fail("account_scope_mismatch", 403);
    const p = await this.deps.plans.read(actor, input.scope);
    if (p.owner.userId !== actor.uid || p.owner.projectId !== actor.projectId ||
        canonical(p.scope) !== canonical(input.scope)) return fail("account_scope_mismatch", 403);
    const until = Date.parse(p.validUntil);
    if (!p.activeFeatureIds.includes("mool_ai") || !Number.isFinite(until) || until <= this.now()) return fail("ai_access_required", 403);
    return p;
  }
  private async catalogueSnapshot(destination: "shop" | "wholesale") {
    let raw: object;
    try {
      raw = await this.deps.catalogue.publicDiscovery({discoveryPageVersion: 1, pageSize: 1,
        ...originalPublicReadVersions, query: {destination, search: "", categoryId: "all",
          sort: "relevance", brands: [], maximumPriceMinor: null, tradeType: null, listingIds: []}});
    } catch {return fail("context_unavailable");}
    const data = object(raw), page = object(data.page);
    const observed = typeof data.observedAt === "string" ? Date.parse(data.observedAt) : NaN;
    if (data.schemaVersion !== 1 || data.discoveryPageVersion !== 1 || data.state !== "ready" ||
        data.coverage !== "verified_public_only" || data.directoryCoverage !== "complete_bounded" ||
        data.orderingAvailable !== false || page.startIndex !== 0 ||
        !Number.isSafeInteger(page.totalCount) || (page.totalCount as number) < 0 || (page.totalCount as number) > 500 ||
        !Array.isArray(data.items) || data.items.length !== Math.min(1, page.totalCount as number) ||
        typeof page.snapshotId !== "string" || !/^[a-f0-9]{64}$/u.test(page.snapshotId) ||
        !Number.isFinite(observed) || observed > this.now() || this.now() - observed > 60_000) return fail("context_unavailable");
    // Only an original source's snapshot/count enter the preparation context;
    // full records, private source details and arbitrary descriptions do not.
    return {destination, snapshotId: page.snapshotId, count: page.totalCount as number};
  }
  private async products(ids: readonly string[], snapshots: ReadonlyArray<{destination: "shop" | "wholesale"; snapshotId: string; count: number}>) {
    const found = new Map<string, OriginalPublicProduct>();
    for (let start = 0; start < ids.length; start += 50) {
      const batch = ids.slice(start, start + 50);
      for (const snapshot of snapshots) {
        let raw: object;
        try {raw = await this.deps.catalogue.publicDiscovery({discoveryPageVersion: 1, pageSize: 50,
          ...originalPublicReadVersions, query: {destination: snapshot.destination, search: "", categoryId: "all",
            sort: "relevance", brands: [], maximumPriceMinor: null, tradeType: null, listingIds: batch}});}
        catch {return fail("context_unavailable");}
        const data = object(raw), page = object(data.page);
        const observed = typeof data.observedAt === "string" ? Date.parse(data.observedAt) : NaN;
        if (data.schemaVersion !== 1 || data.discoveryPageVersion !== 1 || data.state !== "ready" ||
            data.coverage !== "verified_public_only" || data.directoryCoverage !== "complete_bounded" ||
            data.orderingAvailable !== false || page.snapshotId !== snapshot.snapshotId || page.startIndex !== 0 ||
            page.nextCursor !== null || !Array.isArray(data.items) || page.totalCount !== data.items.length ||
            data.items.length > batch.length || data.items.length > snapshot.count || !Number.isFinite(observed) || observed > this.now() ||
            this.now() - observed > 60_000) return fail("stale_preparation", 409);
        for (const rawItem of data.items) {
          const item = object(rawItem), listing = object(item.listing);
          if (!Array.isArray(listing.items) || listing.items.length !== 1 ||
              !(snapshot.destination === "shop" ? item.channel === "retail" : ["wholesale", "bulk"].includes(String(item.channel)))) return fail("context_unavailable");
          const row = object(listing.items[0]), content = object(row.content), pack = object(row.pack);
          if (!Array.isArray(row.listings)) return fail("context_unavailable");
          const matches = row.listings.map(value => object(value)).filter(value => value.channel === item.channel);
          if (matches.length !== 1) return fail("context_unavailable");
          const identity = matches[0]!, listingId = identity.listingId;
          const store = object(listing.publicStore);
          if (!Array.isArray(row.channels)) return fail("context_unavailable");
          const channels = row.channels.map(value => object(value)).filter(value => value.kind === item.channel);
          if (channels.length !== 1) return fail("context_unavailable");
          const terms = channels[0]!, expiry = typeof terms.validUntil === "string" ? Date.parse(terms.validUntil) : NaN;
          if (typeof listingId !== "string" || !batch.includes(listingId) || found.has(listingId) ||
              identity.storeId !== listing.storeId || identity.skuId !== row.skuId ||
              typeof listing.storeId !== "string" || !/^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$/u.test(listing.storeId) ||
              typeof row.skuId !== "string" || !/^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$/u.test(row.skuId) ||
              typeof row.canonicalProductId !== "string" || !/^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$/u.test(row.canonicalProductId) ||
              typeof row.verifiedPackId !== "string" || !/^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$/u.test(row.verifiedPackId) ||
              identity.schemaVersion !== 1 || identity.realm !== data.realm ||
              identity.canonicalProductId !== row.canonicalProductId || identity.verifiedPackId !== row.verifiedPackId ||
              !["evaluation", "production"].includes(String(data.realm)) || listing.realm !== data.realm ||
              typeof content.title !== "string" || !content.title.trim() || content.title.length > 300 ||
              typeof content.brand !== "string" || content.brand.length > 160 ||
              typeof content.variant !== "string" || content.variant.length > 240 ||
              typeof content.categoryId !== "string" || !/^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$/u.test(content.categoryId) ||
              typeof pack.label !== "string" || !pack.label.trim() || pack.label.length > 160 ||
              store.id !== listing.storeId || typeof store.name !== "string" || !store.name.trim() || store.name.length > 240 ||
              !Number.isSafeInteger(terms.priceMinor) || (terms.priceMinor as number) < 0 ||
              terms.mrpMinor !== null && (!Number.isSafeInteger(terms.mrpMinor) || (terms.mrpMinor as number) < 0) ||
              typeof terms.revision !== "string" || !terms.revision || terms.revision.length > 256 ||
              !Number.isFinite(expiry) || expiry <= this.now() ||
              [terms.minimumOrder, terms.quantityStep, pack.quantityMilli, pack.unitsPerCase]
                .some(value => !Number.isSafeInteger(value) || (value as number) < 1) ||
              !["kg", "L", "count"].includes(String(pack.unit))) return fail("context_unavailable");
          let supplierTax: Readonly<Record<string, unknown>> | null = null;
          if (terms.supplierTax !== undefined) {
            const tax = object(terms.supplierTax), field = tax.version === 1 ? "amountMinor" : "rateBasisPoints";
            if (![1, 2].includes(tax.version as number) || !["included", "additional"].includes(String(tax.basis)) ||
                !Number.isSafeInteger(tax[field]) || (tax[field] as number) < 0) return fail("context_unavailable");
            supplierTax = {version: tax.version, basis: tax.basis, [field]: tax[field]};
          }
          let contactAvailable = false;
          if (store.details !== undefined && object(store.details).state === "ready") {
            const details = object(store.details), fields = object(details.details), phone = fields.publicContactPhone;
            contactAvailable = details.schemaVersion === 1 && details.realm === data.realm && details.storeId === listing.storeId &&
              Number.isSafeInteger(details.revision) && (details.revision as number) > 0 && typeof phone === "string" &&
              /^\+?[0-9][0-9 ()-]*$/u.test(phone) && phone.replace(/[^0-9]/gu, "").length >= 7 && phone.replace(/[^0-9]/gu, "").length <= 15;
          }
          // Match the original native Buy adapter's existing prescription boundary.
          if (content.productFacts !== undefined && content.productFacts !== null && object(content.productFacts).requiresPrescription === true) continue;
          found.set(listingId, {listingId, title: content.title, brand: content.brand, variant: content.variant, pack: pack.label,
            categoryId: content.categoryId, channel: item.channel as string,
            storeId: listing.storeId, skuId: row.skuId, realm: data.realm as string,
            canonicalProductId: row.canonicalProductId, verifiedPackId: row.verifiedPackId,
            supplierName: store.name, contactAvailable, priceMinor: terms.priceMinor as number, mrpMinor: terms.mrpMinor as number | null,
            priceRevision: terms.revision, priceValidUntil: terms.validUntil as string, validUntil: expiry,
            minimumOrder: terms.minimumOrder as number, quantityStep: terms.quantityStep as number,
            quantityMilli: pack.quantityMilli as number, unit: pack.unit as string, unitsPerCase: pack.unitsPerCase as number, supplierTax,
            revision: "catalogue-product:" + digest([snapshot.snapshotId, identity])});
        }
      }
    }
    // Missing originals grant no record action. Preserve independent search
    // recovery instead of manufacturing zero stock or an old replacement row.
    return ids.flatMap(value => found.has(value) ? [found.get(value)!] : []);
  }
  async read(actor: AccountProfileActor, input: PreparationRequest): Promise<PreparationContext> {
    return this.readOriginal(actor, input);
  }
  private async family(product: OriginalPublicProduct): Promise<OriginalPublicFamily | null> {
    const read = this.deps.catalogue.publicVariantFamilies?.bind(this.deps.catalogue);
    if (!read) return null;
    const listing = {listingId: product.listingId, skuId: product.skuId, channel: product.channel};
    const request = {storeId: product.storeId, listings: [listing], ...originalPublicReadVersions};
    const checked = (raw: object) => {
      const data = object(raw), observed = typeof data.observedAt === "string" ? Date.parse(data.observedAt) : NaN;
      const until = typeof data.validUntil === "string" ? Date.parse(data.validUntil) : NaN;
      if (data.state !== "ready" || data.schemaVersion !== 1 || data.realm !== product.realm ||
          data.storeId !== product.storeId || data.orderingAvailable !== false ||
          data.sourceId !== `store-reviewed-variants:${product.realm}:${product.storeId}` ||
          !Number.isSafeInteger(data.revision) || (data.revision as number) < 1 ||
          !Number.isFinite(observed) || observed > this.now() || this.now() - observed > 60_000 ||
          !Number.isFinite(until) || until <= this.now() || !Array.isArray(data.memberships) ||
          data.memberships.length !== 1) return fail("context_unavailable");
      const member = object(data.memberships[0]), identity = object(member.listing);
      if (identity.listingId !== product.listingId || identity.skuId !== product.skuId ||
          identity.storeId !== product.storeId || identity.realm !== product.realm || identity.channel !== product.channel ||
          identity.schemaVersion !== 1 || identity.canonicalProductId !== product.canonicalProductId || identity.verifiedPackId !== product.verifiedPackId ||
          member.sourceId !== data.sourceId || member.revision !== data.revision ||
          !Number.isSafeInteger(member.skuRevision) || (member.skuRevision as number) < 1) return fail("context_unavailable");
      return {data, member, until};
    };
    try {
      const first = checked(await read(request));
      if (first.member.familyId === null) return null;
      if (typeof first.member.familyId !== "string" || !/^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$/u.test(first.member.familyId)) return null;
      const second = checked(await read({...request, familyId: first.member.familyId}));
      if (second.member.familyId !== first.member.familyId || second.data.revision !== first.data.revision ||
          second.data.sourceId !== first.data.sourceId) return null;
      const family = object(second.data.family);
      if (family.familyId !== first.member.familyId || !Array.isArray(family.products) ||
          !family.products.length || family.products.length > 500) return null;
      const variants: OriginalPublicFamily["variants"] = [], identities: unknown[] = [], seen = new Set<string>();
      for (const raw of family.products) {
        const entry = object(raw), row = object(entry.product), member = object(entry.membership), binding = object(member.listing);
        const content = object(row.content), pack = object(row.pack), listingId = binding.listingId;
        if (typeof listingId !== "string" || !/^listing-[a-f0-9]{64}$/u.test(listingId) || seen.has(listingId) ||
            binding.storeId !== product.storeId || binding.realm !== product.realm || binding.channel !== product.channel ||
            binding.schemaVersion !== 1 || [row.skuId, row.canonicalProductId, row.verifiedPackId].some(value =>
              typeof value !== "string" || !/^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$/u.test(value)) ||
            binding.skuId !== row.skuId || binding.canonicalProductId !== row.canonicalProductId || binding.verifiedPackId !== row.verifiedPackId ||
            listingId === product.listingId && (binding.skuId !== product.skuId ||
              binding.canonicalProductId !== product.canonicalProductId || binding.verifiedPackId !== product.verifiedPackId) ||
            member.familyId !== family.familyId || member.sourceId !== second.data.sourceId || member.revision !== second.data.revision ||
            !Number.isSafeInteger(row.revision) || (row.revision as number) < 1 || member.skuRevision !== row.revision ||
            typeof content.title !== "string" || !content.title.trim() || content.title.length > 300 ||
            typeof content.variant !== "string" || content.variant.length > 240 ||
            typeof pack.label !== "string" || !pack.label.trim() || pack.label.length > 160 ||
            content.productFacts !== undefined && content.productFacts !== null && object(content.productFacts).requiresPrescription === true) return null;
        if (!Array.isArray(member.attributes) || member.attributes.length > 8) return null;
        const dimensions = new Set<string>(), attributes: Array<{dimension: string; value: string}> = [];
        for (const rawAttribute of member.attributes) {
          const attribute = object(rawAttribute);
          if (typeof attribute.dimensionId !== "string" || !attribute.dimensionId || dimensions.has(attribute.dimensionId) ||
              typeof attribute.dimensionLabel !== "string" || !attribute.dimensionLabel.trim() || attribute.dimensionLabel.length > 120 ||
              typeof attribute.optionLabel !== "string" || !attribute.optionLabel.trim() || attribute.optionLabel.length > 120) return null;
          dimensions.add(attribute.dimensionId);
          attributes.push({dimension: attribute.dimensionLabel, value: attribute.optionLabel});
        }
        seen.add(listingId);
        variants.push({listingId, title: content.title, variant: content.variant, pack: pack.label, attributes});
        identities.push([binding, row.revision, attributes]);
      }
      if (!seen.has(product.listingId)) return null;
      return {listingId: product.listingId, familyId: first.member.familyId,
        validUntil: Math.min(first.until, second.until), variants,
        revision: "catalogue-variants:" + digest([product.revision, family.familyId, second.data.sourceId, second.data.revision, identities])};
    } catch {return null;}
  }
  async readPrepared(actor: AccountProfileActor, input: PreparationRequest,
    proposal: Extract<PreparationReply["outcome"], {kind: "proposal"}>): Promise<PreparationContext> {
    if (proposal.actionId !== input.actionId || proposal.entityId !== input.entityId) return fail("stale_preparation", 409);
    return this.readOriginal(actor, input, proposal.fields);
  }
  private async confirmChoice(actionId: string, fields: Readonly<Record<string, unknown>>,
    snapshots: ReadonlyArray<{destination: "shop" | "wholesale"; snapshotId: string}>) {
    const field = actionId === "AI-ACT-002" ? "categoryId" : "saleType", value = fields[field];
    if (Object.keys(fields).length !== 1 || typeof value !== "string" ||
        !/^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$/u.test(value) ||
        actionId === "AI-ACT-004" && !["wholesale", "bulk"].includes(value)) return fail("stale_preparation", 409);
    for (const snapshot of snapshots.filter(s => actionId !== "AI-ACT-004" || s.destination === "wholesale")) {
      let raw: object;
      try {raw = await this.deps.catalogue.publicDiscovery({discoveryPageVersion: 1, pageSize: 1,
        ...originalPublicReadVersions, query: {destination: snapshot.destination, search: "",
          categoryId: field === "categoryId" ? value : "all", sort: "relevance", brands: [],
          maximumPriceMinor: null, tradeType: field === "saleType" ? value : null, listingIds: []}});}
      catch {return fail("context_unavailable");}
      const data = object(raw), page = object(data.page);
      const observed = typeof data.observedAt === "string" ? Date.parse(data.observedAt) : NaN;
      if (data.schemaVersion !== 1 || data.discoveryPageVersion !== 1 || data.state !== "ready" ||
          data.coverage !== "verified_public_only" || data.directoryCoverage !== "complete_bounded" ||
          data.orderingAvailable !== false || page.snapshotId !== snapshot.snapshotId || page.startIndex !== 0 ||
          !Number.isSafeInteger(page.totalCount) || (page.totalCount as number) < 0 || (page.totalCount as number) > 500 ||
          !Array.isArray(data.items) || data.items.length !== Math.min(1, page.totalCount as number) ||
          !Number.isFinite(observed) || observed > this.now() || this.now() - observed > 60_000) return fail("stale_preparation", 409);
      if ((page.totalCount as number) > 0) return value;
    }
    return fail("context_unavailable");
  }
  private async readOriginal(actor: AccountProfileActor, input: PreparationRequest,
    recoveredFields?: Readonly<Record<string, unknown>>): Promise<PreparationContext> {
    if (input.scope.audience !== "personal" || input.entityId !== null && !catalogueProductActions.has(input.actionId ?? "") ||
        input.actionId !== null && !catalogueSearchActions.has(input.actionId)) return fail("context_unavailable");
    const started = this.now(), before = await this.paid(actor, input);
    const snapshots = [await this.catalogueSnapshot("shop"), await this.catalogueSnapshot("wholesale")];
    const ids = catalogueListingSelection(input.entityId === null ? input.catalogueListingIds ?? [] : [input.entityId]);
    const products = await this.products(ids, snapshots);
    if (input.entityId !== null && !products.length) return fail("context_unavailable");
    // The existing native variant action operates on the current product.
    // Do not crawl families for a multi-product browsing list or invent siblings.
    const families = products.length === 1 && (input.actionId === null || input.actionId === "AI-ACT-007")
      ? [await this.family(products[0]!)].filter((value): value is OriginalPublicFamily => value !== null) : [];
    const recoveredChoice = recoveredFields && ["AI-ACT-002", "AI-ACT-004"].includes(input.actionId ?? "")
      ? await this.confirmChoice(input.actionId!, recoveredFields, snapshots) : null;
    const fresh = [await this.catalogueSnapshot("shop"), await this.catalogueSnapshot("wholesale")];
    if (canonical(snapshots) !== canonical(fresh)) return fail("stale_preparation", 409);
    const after = await this.paid(actor, input);
    if (paidRevision(before) !== paidRevision(after)) return fail("stale_preparation", 409);
    const until = Math.min(started + 60_000, Date.parse(before.validUntil), Date.parse(after.validUntil),
      ...products.map(product => product.validUntil), ...families.map(family => family.validUntil));
    if (until <= this.now()) return fail("stale_preparation", 409);
    const revision = "catalogue-search:" + digest([actor.projectId, snapshots]);
    const tools: PreparationTool[] = [{name: "buy_prepare_product_search", actionId: "AI-ACT-001", entityId: null,
      sourceRevision: revision, description: "Review a product search", parameters: searchSchema,
      decodeFields: searchSuggestion,
      validate: fields => {try {searchSuggestion(fields); return true;} catch {return false;}}}];
    // This prepares the original area's search text, never a serviceability result.
    tools.push({name: "buy_prepare_area_search", actionId: "AI-ACT-005", entityId: null,
      sourceRevision: revision, description: "Review a shopping-area search", parameters: searchSchema,
      decodeFields: searchSuggestion,
      validate: fields => {try {searchSuggestion(fields); return true;} catch {return false;}}});
    const choice = (actionId: string, name: string, field: string, values: string[], description: string): PreparationTool => ({
      name, actionId, entityId: null, sourceRevision: "catalogue-choice:" + digest([revision, actionId]), description,
      parameters: {type: "object", properties: {[field]: {type: "string", enum: values}}, required: [field], additionalProperties: false},
      validate: fields => Object.keys(fields).length === 1 && typeof fields[field] === "string" && values.includes(fields[field] as string),
    });
    const retail = products.length > 0 && products.every(product => product.channel === "retail");
    const trade = products.length > 0 && products.every(product => product.channel !== "retail");
    if (retail || trade) tools.push(filterTool(revision, [...new Set(products.map(p => p.brand).filter(Boolean))].sort(),
      retail ? [100, 250, 500, 1000] : [2000, 5000, 10000], retail ? ["standard", "multipack"] : []));
    else if (input.actionId === "AI-ACT-003" && recoveredFields) {
      // Server-owned stored fields were validated before persistence. The live
      // full-catalogue revision must still match in validateReady; no client
      // selection or new model result is accepted by this read-only path.
      const brands = Array.isArray(recoveredFields.brands) ? recoveredFields.brands.filter((v): v is string => typeof v === "string" && v.length <= 160) : [];
      const original = filterTool(revision, brands, [100, 250, 500, 1000, 2000, 5000, 10000], ["standard", "multipack"]);
      if (!original.validate(recoveredFields)) return fail("stale_preparation", 409);
      tools.push({...original, validate: fields => original.validate(fields) && canonical(fields) === canonical(recoveredFields)});
    }
    if (products.length || recoveredChoice !== null) {
      const categories = recoveredChoice && input.actionId === "AI-ACT-002" ? [recoveredChoice]
        : [...new Set(["all", ...products.map(p => p.categoryId)])].sort();
      if (products.length || input.actionId === "AI-ACT-002") {
      tools.push(choice("AI-ACT-002", "buy_prepare_category", "categoryId",
        categories, "Review a product category"));
      }
      const channels = recoveredChoice && input.actionId === "AI-ACT-004" ? [recoveredChoice]
        : [...new Set(products.map(p => p.channel).filter(v => v === "wholesale" || v === "bulk"))].sort();
      if (channels.length) tools.push(choice("AI-ACT-004", "buy_prepare_trade_channel", "saleType", channels, "Review Wholesale or Bulk products"));
    }
    if (families.length) {
      const family = families[0]!, variants = family.variants.map(value => value.listingId);
      const variantFields = {variantId: {type: "string", enum: variants}};
      const validate = (fields: Readonly<Record<string, unknown>>) => Object.keys(fields).length === 1 &&
        typeof fields.variantId === "string" && variants.includes(fields.variantId);
      tools.push({name: "buy_prepare_product_variant", actionId: "AI-ACT-007", entityId: input.entityId,
        sourceRevision: family.revision, description: "Review a product size or pack", validate,
        parameters: {type: "object", properties: input.entityId === null
          ? {listingId: {type: "string", enum: [family.listingId]}, ...variantFields} : variantFields,
          required: input.entityId === null ? ["listingId", "variantId"] : ["variantId"], additionalProperties: false},
        ...(input.entityId === null ? {targetSelector: "listingId", resolveTarget: (fields: Readonly<Record<string, unknown>>) => {
          if (Object.keys(fields).length !== 2 || fields.listingId !== family.listingId || !validate({variantId: fields.variantId})) return fail("invalid_model_result");
          const selected = family.variants.find(value => value.listingId === fields.variantId)!;
          return {entityId: family.listingId, sourceRevision: family.revision, fields: {variantId: fields.variantId},
            title: "Review product size or pack", summary: [selected.title, selected.variant].filter(Boolean).join(" ") + " · " + selected.pack};
        }} : {})});
    }
    if (input.entityId !== null && input.actionId === "AI-ACT-006") {
      const product = products[0]!;
      tools.splice(0, tools.length, {name: "buy_review_product_details", actionId: "AI-ACT-006", entityId: product.listingId,
        sourceRevision: product.revision, description: "Review original product and supplier details",
        parameters: {type: "object", properties: {}, required: [], additionalProperties: false},
        validate: fields => Object.keys(fields).length === 0});
    } else if (products.length) {
      tools.push({name: "buy_review_product_details", actionId: "AI-ACT-006", entityId: null,
        targetSelector: "listingId",
        sourceRevision: revision, description: "Review original product and supplier details",
        parameters: {type: "object", properties: {listingId: {type: "string", enum: products.map(product => product.listingId)}}, required: ["listingId"], additionalProperties: false},
        validate: fields => Object.keys(fields).length === 0,
        resolveTarget: fields => {
          if (Object.keys(fields).length !== 1) return fail("invalid_model_result");
          const product = products.find(value => value.listingId === fields.listingId);
          if (!product) return fail("invalid_model_result");
          return {entityId: product.listingId, sourceRevision: product.revision, fields: {},
            title: "Review product details", summary: [product.title, product.variant].filter(Boolean).join(" ") + " · " + product.pack};
        }});
    }
    // Prepare only the existing native review. Native owned preferences, link
    // generation, Store search and contact confirmation retain their authority.
    // No saved flag, URL, phone action or communication is written here.
    for (const [actionId, name, description] of [
      ["AI-ACT-009", "buy_prepare_saved_product", "Review saving or removing a product"],
      ["AI-ACT-336", "buy_review_product_link", "Review copying the original product link"],
      ["AI-ACT-337", "buy_review_product_sharing", "Review sharing the original product"],
      ["AI-ACT-338", "buy_prepare_store_search", "Review a search within the original supplier Store"],
      ["AI-ACT-339", "buy_review_supplier_contact", "Review the original supplier contact"],
    ] as const) {
      const candidates = products.filter(product => actionId !== "AI-ACT-339" || product.contactAvailable);
      if (!candidates.length) continue;
      const properties: Record<string, object> = actionId === "AI-ACT-009" ? {saved: {type: "boolean"}}
        : actionId === "AI-ACT-338" ? {query: {type: "string"}} : {};
      const validate = (fields: Readonly<Record<string, unknown>>) => {
        if (actionId === "AI-ACT-009") return Object.keys(fields).length === 1 && typeof fields.saved === "boolean";
        if (actionId === "AI-ACT-338") {try {searchSuggestion(fields); return true;} catch {return false;}}
        return Object.keys(fields).length === 0;
      };
      const decodeFields = actionId === "AI-ACT-338" ? searchSuggestion : undefined;
      const fixed = input.entityId !== null ? candidates.find(product => product.listingId === input.entityId) : undefined;
      const dynamic = input.entityId === null;
      if (!dynamic && !fixed) continue;
      tools.push({name, actionId, entityId: input.entityId, sourceRevision: fixed?.revision ?? revision,
        description, validate, ...(decodeFields ? {decodeFields} : {}),
        parameters: {type: "object", properties: {...(dynamic ? {listingId: {type: "string", enum: candidates.map(product => product.listingId)}} : {}), ...properties},
          required: [...(dynamic ? ["listingId"] : []), ...Object.keys(properties)], additionalProperties: false},
        ...(dynamic ? {targetSelector: "listingId", resolveTarget: (args: Readonly<Record<string, unknown>>) => {
          const {listingId, ...fields} = args;
          const product = candidates.find(value => value.listingId === listingId);
          if (!product || !validate(fields)) return fail("invalid_model_result");
          return {entityId: product.listingId, sourceRevision: product.revision,
            fields: decodeFields ? decodeFields(fields) : fields,
            title: description, summary: [product.title, product.variant, product.pack].filter(Boolean).join(" · ")};
        }} : {})});
    }
    if (input.actionId !== null && catalogueProductActions.has(input.actionId) && !products.length) return fail("context_unavailable");
    const selectedTools = input.actionId === null ? tools : tools.filter(value => value.actionId === input.actionId);
    if (!selectedTools.length) return fail("context_unavailable");
    return {revision, validUntil: new Date(until).toISOString(),
      modelContext: {audience: "personal", purpose: "Prepare an original product search for review; no order or catalogue mutation.",
        catalogue: snapshots.map(s => ({destination: s.destination, publishedListingCount: s.count})),
        unavailableListingIds: ids.filter(value => !products.some(product => product.listingId === value)),
        pricingScope: "Original published INR minor-unit prices only; no live stock, delivery or final quote is inferred. Missing tax is unknown, not zero.",
        products: products.map(({listingId, title, brand, variant, pack, categoryId, channel, storeId, supplierName, contactAvailable,
          priceMinor, mrpMinor, priceRevision, priceValidUntil, minimumOrder, quantityStep, quantityMilli, unit, unitsPerCase, supplierTax}) =>
          ({listingId, title, brand, variant, pack, categoryId, channel, supplier: {id: storeId, name: supplierName, contactAvailable},
            priceMinor, mrpMinor, priceRevision, priceValidUntil, minimumOrder, quantityStep, quantityMilli, unit, unitsPerCase, supplierTax})),
        ...(families.length ? {variantFamilies: families.map(({listingId, familyId, variants}) => ({listingId, familyId, variants}))} : {})},
      tools: selectedTools,
      ...(products.length ? {nativeTargets: [
        ...selectedTools.filter(t => !catalogueProductActions.has(t.actionId)).map(t => ({actionId: t.actionId, entityId: t.entityId, sourceRevision: t.sourceRevision})),
        ...products.map(product => ({actionId: "AI-ACT-006", entityId: product.listingId, sourceRevision: product.revision})),
        ...selectedTools.filter(t => catalogueProductActions.has(t.actionId) && !["AI-ACT-006", "AI-ACT-007"].includes(t.actionId))
          .flatMap(tool => products.filter(product => (tool.entityId === null || tool.entityId === product.listingId) &&
            (tool.actionId !== "AI-ACT-339" || product.contactAvailable)).map(product =>
            ({actionId: tool.actionId, entityId: product.listingId, sourceRevision: product.revision}))),
        ...families.map(family => ({actionId: "AI-ACT-007", entityId: family.listingId, sourceRevision: family.revision}))]} : {})};
  }
}

/** Compose source readers; preserve the qualified original Profile path. */
export class CompositePreparationContext implements PreparationContextSource {
  constructor(private readonly deps: {original?: PreparationContextSource;
    catalogue?: OriginalCataloguePreparationContext; nativePreferencesEnabled?: boolean}) {}
  private preferences(actor: AccountProfileActor, input: PreparationRequest, original: PreparationContext): PreparationContext {
    if (!this.deps.nativePreferencesEnabled || input.scope.audience !== "personal" || input.entityId !== null ||
        original.modelContext?.audience !== "personal") return fail("context_unavailable");
    // This is an account-authority proof, NOT a saved-items data revision. The
    // existing native adapter captures its own owned-storage revision and must
    // still validate it at Review. No private preference contents are read,
    // inferred, persisted or cleared by this source reader.
    const revision = "native-preferences-owner:" + digest([actor.projectId, actor.uid, original.revision]);
    const tools = [
      ["AI-ACT-010", "buy_review_saved_products", "Review my saved products"],
      ["AI-ACT-011", "buy_review_clear_saved_products", "Review clearing my saved products"],
      ["AI-ACT-012", "buy_review_clear_recent_products", "Review clearing my recently viewed products"],
      ["AI-ACT-013", "buy_review_clear_recent_searches", "Review clearing my recent searches"],
    ].filter(([actionId]) => input.actionId === null || input.actionId === actionId).map(([actionId, name, description]) => ({
      name: name!, actionId: actionId!, entityId: null, sourceRevision: revision, description: description!,
      parameters: {type: "object", properties: {}, required: [], additionalProperties: false},
      validate: (fields: Readonly<Record<string, unknown>>) => Object.keys(fields).length === 0,
    }));
    if (!tools.length) return fail("context_unavailable");
    return {revision, validUntil: original.validUntil, tools, modelContext: {audience: "personal",
      purpose: "Prepare native review only. The current account-owned native saved/recent storage is the sole preference source. Its contents and availability have not been read here. Native confirmation owns any change."}};
  }
  private async readPreferences(actor: AccountProfileActor, input: PreparationRequest) {
    if (!this.deps.original || !this.deps.nativePreferencesEnabled || input.scope.audience !== "personal" || input.entityId !== null) return fail("context_unavailable");
    const original = await this.deps.original.read(actor, {...input, actionId: null, entityId: null});
    return this.preferences(actor, input, original);
  }
  async readPrepared(actor: AccountProfileActor, input: PreparationRequest,
    proposal: Extract<PreparationReply["outcome"], {kind: "proposal"}>): Promise<PreparationContext> {
    if (nativePreferenceActions.has(proposal.actionId)) {
      if (proposal.actionId !== input.actionId || proposal.entityId !== null ||
          Object.keys(proposal.fields).length !== 0) return fail("stale_preparation", 409);
      return this.readPreferences(actor, input);
    }
    if (catalogueSearchActions.has(proposal.actionId)) {
      if (!this.deps.catalogue) return fail("context_unavailable");
      return this.deps.catalogue.readPrepared(actor, input, proposal);
    }
    if (!this.deps.original) return fail("context_unavailable");
    return this.deps.original.readPrepared?.(actor, input, proposal) ?? this.deps.original.read(actor, input);
  }
  async read(actor: AccountProfileActor, input: PreparationRequest): Promise<PreparationContext> {
    if (input.actionId !== null) {
      if (nativePreferenceActions.has(input.actionId)) return this.readPreferences(actor, input);
      if (catalogueSearchActions.has(input.actionId)) {
        if (!this.deps.catalogue) return fail("context_unavailable");
        return this.deps.catalogue.read(actor, input);
      }
      if (!this.deps.original) return fail("context_unavailable");
      return this.deps.original.read(actor, input);
    }
    const values: PreparationContext[] = [];
    if (this.deps.original) {
      const original = await this.deps.original.read(actor, input);
      values.push(original);
      if (this.deps.nativePreferencesEnabled && input.scope.audience === "personal") values.push(this.preferences(actor, input, original));
    }
    if (this.deps.catalogue && input.scope.audience === "personal") {
      try {values.push(await this.deps.catalogue.read(actor, input));}
      catch (error) {
        // A missing optional catalogue must not remove established Profile
        // tools. Denied access, stale sources or malformed data still fail.
        if (!(error instanceof AssistantModelError) || error.code !== "context_unavailable" || !values.length) throw error;
      }
    }
    if (!values.length) return fail("context_unavailable");
    if (values.length === 1) return values[0]!;
    return {revision: "composite:" + digest(values.map(v => v.revision)),
      validUntil: new Date(Math.min(...values.map(v => Date.parse(v.validUntil)))).toISOString(),
      tools: values.flatMap(v => v.tools), modelContext: {sources: values.map(v => v.modelContext ?? null)},
      ...(values.some(v => v.nativeTargets !== undefined) ? {nativeTargets: values.flatMap(v => v.nativeTargets ??
        v.tools.map(t => ({actionId: t.actionId, entityId: t.entityId, sourceRevision: t.sourceRevision})))} : {})};
  }
}
