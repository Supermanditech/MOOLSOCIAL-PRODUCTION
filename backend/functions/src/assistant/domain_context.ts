import type {AccountPlansService, PlansReadback} from "../account/plans_service.js";
import type {AccountProfileActor} from "../account/profile_service.js";
import type {WorkspaceCatalogueService, StoreSkuRecord} from "../workspace/workspace_catalogue_service.js";
import type {WorkspacePurchaseProjectionService, WorkspaceOrderOperationsService, PurchaseReference, ProductFeedbackTarget} from "../workspace/workspace_purchase_projection_service.js";
import type {PreparationContextSource} from "./model_service.js";
import {AssistantModelError, canonical, digest, fail, id, object,
  catalogueListingSelection, preparationNativeTargetLimit, type PreparationReply, type PreparationTool, type PreparationContext, type PreparationRequest} from "./model_contract.js";
import {canonicalContextProjection, catalogueProductActions, catalogueSearchActions, nativePreferenceActions, personalDeliveryAddressActions, storeProductActions, storeProductOwnerActions,storeStockOwnerActions,storeRestockOwnerActions,storeOrderOriginalActions,storeSupplierDraftActions,storePurchaseRootActions, searchSuggestion} from "./domain_context_contract.js";

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

async function approvedWorkspacePreparationAuthority(source:PreparationContextSource,actor:AccountProfileActor,
  input:PreparationRequest,now:number){
  const value=await source.read(actor,{...input,actionId:null,entityId:null});
  if(value.modelContext?.audience!=='workspace'||object(value.modelContext.current).id!==input.scope.storeId||
      !value.tools.some(tool=>tool.actionId==='AI-ACT-317'&&tool.entityId===input.scope.storeId)||
      !Number.isFinite(Date.parse(value.validUntil))||Date.parse(value.validUntil)<=now)return fail('workspace_access_unavailable');
  return value;
}
/** Exact original catalogue reader. No client catalogue, fixture or local master. */
export class OriginalCataloguePreparationContext implements PreparationContextSource {
  constructor(private readonly deps: {projectId: string;
    plans: Pick<AccountPlansService, "read">;
    catalogue: Pick<WorkspaceCatalogueService, "publicDiscovery"> & Partial<Pick<WorkspaceCatalogueService, "publicVariantFamilies">>;
    workspaceAuthority?:PreparationContextSource;now?: () => Date}) {}
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
    if(input.scope.audience==='workspace')return this.readRestock(actor,input);
    return this.readOriginal(actor, input);
  }
  private async readRestock(actor:AccountProfileActor,input:PreparationRequest):Promise<PreparationContext>{
    if(!this.deps.workspaceAuthority||input.scope.audience!=='workspace'||!input.scope.storeId||input.entityId!==null||
        input.catalogueListingIds!==undefined||input.actionId!==null&&!storeRestockOwnerActions.has(input.actionId))return fail('context_unavailable');
    const started=this.now(),before=await this.paid(actor,input);
    const authority=await approvedWorkspacePreparationAuthority(this.deps.workspaceAuthority,actor,input,this.now());
    const original=await this.catalogueSnapshot('wholesale'),fresh=await this.catalogueSnapshot('wholesale');
    const current=await approvedWorkspacePreparationAuthority(this.deps.workspaceAuthority,actor,input,this.now()),after=await this.paid(actor,input);
    if(canonical(original)!==canonical(fresh)||authority.revision!==current.revision||paidRevision(before)!==paidRevision(after))return fail('stale_preparation',409);
    const until=Math.min(started+60000,Date.parse(authority.validUntil),Date.parse(current.validUntil),Date.parse(before.validUntil),Date.parse(after.validUntil));
    if(until<=this.now())return fail('stale_preparation',409);
    const sourceRevision='store-restock-source:'+digest([actor.projectId,actor.uid,input.scope.storeId,current.revision,original]);
    const validate=(fields:Readonly<Record<string,unknown>>)=>
      Object.keys(fields).every(key=>['channel','query'].includes(key))&&['wholesale','bulk'].includes(String(fields.channel))&&
      typeof fields.channel==='string'&&(!Object.hasOwn(fields,'query')||typeof fields.query==='string'&&fields.query.length<=80&&
        !/[\u0000-\u001f\u007f]/u.test(fields.query)&&Buffer.from(fields.query,'utf8').toString('utf8')===fields.query);
    const tool:PreparationTool={name:'store_prepare_restock_search',actionId:'AI-ACT-234',entityId:null,sourceRevision,
      description:'Prepare the explicitly requested Wholesale or Bulk channel and product search for the current approved Store. Use supplied search text; ask when the channel is unclear. The original Restock controller checks supplier eligibility and loads current products/pack/terms. No supplier, product, price, credit eligibility, quote, quantity, order or payment is selected or confirmed by this tool.',
      parameters:{type:'object',properties:{channel:{type:'string',enum:['wholesale','bulk']},query:{type:['string','null']}},
        required:['channel','query'],additionalProperties:false},validate,
      resolveTarget:args=>{
        if(Object.keys(args).length!==2||!Object.hasOwn(args,'channel')||!Object.hasOwn(args,'query'))return fail('invalid_model_result');
        const fields=Object.fromEntries(Object.entries(args).filter(([,value])=>value!==null));
        if(!validate(fields))return fail('invalid_model_result');
        return {entityId:null,sourceRevision,fields,title:'Review Restock search',
          summary:'Check your Store, buying channel and product search before continuing.'};
      }};
    return {revision:sourceRevision,validUntil:new Date(until).toISOString(),tools:[tool],modelContext:{
      audience:'workspace',storeId:input.scope.storeId,sourceKind:'original-store-restock-search-v1',
      source:{snapshotId:original.snapshotId,verifiedPublicCount:original.count},
      purpose:'Read-only verified public supplier directory witness. Current Store eligibility, product selection, pack, quantity, terms, quotes and final order remain with the original native procurement journey. No source product has been selected.'}};
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
    if(storeRestockOwnerActions.has(proposal.actionId)){
      if(proposal.actionId!==input.actionId||proposal.entityId!==null||input.entityId!==null)return fail('stale_preparation',409);
      return this.readRestock(actor,input);
    }
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
      ["AI-ACT-014", "buy_prepare_cart_product", "Review adding whole packs to Cart"],
      ["AI-ACT-017", "buy_prepare_product_purchase", "Review buying this product"],
      ["AI-ACT-018", "buy_prepare_cart_quantity", "Review the new whole-pack quantity in Cart"],
      ["AI-ACT-019", "buy_prepare_cart_removal", "Review removing this product from Cart"],
      ["AI-ACT-336", "buy_review_product_link", "Review copying the original product link"],
      ["AI-ACT-337", "buy_review_product_sharing", "Review sharing the original product"],
      ["AI-ACT-338", "buy_prepare_store_search", "Review a search within the original supplier Store"],
      ["AI-ACT-339", "buy_review_supplier_contact", "Review the original supplier contact"],
    ] as const) {
      const candidates = products.filter(product => actionId !== "AI-ACT-339" || product.contactAvailable);
      if (!candidates.length) continue;
      const properties: Record<string, object> = actionId === "AI-ACT-009" ? {saved: {type: "boolean"}}
        : actionId === "AI-ACT-014" || actionId === "AI-ACT-017" || actionId === "AI-ACT-018" ? {quantity: {type: actionId === 'AI-ACT-018' ? 'integer' : ["integer", "null"], minimum: 1,
          description: actionId === 'AI-ACT-018' ? 'The new whole-pack total explicitly supplied by the user, not an increment. Ask if missing. The original native Cart must contain this exact listing and independently validates current quantity, price, eligibility and pack steps before confirmation.' :
            'Only the whole-pack count explicitly supplied by the user; null when unspecified. This prepares the original native review, not availability, pricing, an order or payment confirmation.'}}
        : actionId === "AI-ACT-338" ? {query: {type: "string"}} : {};
      const validate = (fields: Readonly<Record<string, unknown>>) => {
        if (actionId === "AI-ACT-009") return Object.keys(fields).length === 1 && typeof fields.saved === "boolean";
        if (actionId === 'AI-ACT-018') return Object.keys(fields).length === 1 && Number.isSafeInteger(fields.quantity) && (fields.quantity as number) >= 1;
        if (actionId === "AI-ACT-014" || actionId === "AI-ACT-017") return Object.keys(fields).every(key => key === 'quantity') &&
          (!Object.hasOwn(fields, 'quantity') || Number.isSafeInteger(fields.quantity) && (fields.quantity as number) >= 1);
        if (actionId === "AI-ACT-338") {try {searchSuggestion(fields); return true;} catch {return false;}}
        return Object.keys(fields).length === 0;
      };
      const decodeFields = actionId === "AI-ACT-338" ? searchSuggestion :
        actionId === "AI-ACT-014" || actionId === "AI-ACT-017" || actionId === 'AI-ACT-018' ? (args: Readonly<Record<string, unknown>>) => {
          if (Object.keys(args).length !== 1 || !Object.hasOwn(args, 'quantity')) return fail('invalid_model_result');
          const fields = args.quantity === null ? {} : {quantity: args.quantity};
          if (!validate(fields)) return fail('invalid_model_result');
          return fields;
        } : undefined;
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
          if (!product || !(decodeFields ? validate(decodeFields(fields)) : validate(fields))) return fail("invalid_model_result");
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

// Exact original StoreProductInitialData text controllers. These are proposed
// inputs, not authoritative Stock balances, tax decisions or order prices.
export const storeProductNativeTextFields = [
  "title", "brand", "variant", "pack", "categoryId", "sku", "barcode", "purchasePrice", "sellingPrice", "mrp", "stock",
  "lowStockThreshold", "minimumOrder", "deliveryPromise", "unitPrice", "origin", "returnPolicy", "composition", "regulatoryNote", "visualLabel",
  "quantityPerPack", "quantityUnit", "unitsPerCase", "sellingChannels", "wholesaleSaleType", "wholesalePrice", "wholesaleMinimum",
  "wholesaleIncrement", "wholesaleTiers", "priceChangesFrequently", "priceValidityMinutes", "gstPercent", "gstBasis",
  "description", "highlights", "specifications", "genericName", "netQuantity", "manufacturerName", "manufacturerAddress", "packerName",
  "packerAddress", "importerName", "importerAddress", "countryOfOrigin", "fssaiLicenseNumber", "consumerCare",
] as const;
const storeSalePriceFields = ["sellingPrice", "wholesalePrice", "wholesaleTiers", "priceChangesFrequently", "priceValidityMinutes"];
const storeReferenceFields = ["sourceCanonicalId", "sourceSku", "sourcePack", "sourceRetailEnabled", "sourceWholesaleEnabled"];
export const storeVariantNativeKinds=['colour','size','storage','pack','other'] as const;
// Exact descriptive controls from the existing native warranty guide. These
// strings do not establish a warranty entitlement or decide claim eligibility.
export const storeWarrantyNativeLabels = ["Warranty issuer", "Warranty duration", "Warranty start basis", "Warranty coverage",
  "Warranty exclusions", "Warranty service", "Warranty contact", "Warranty reference"] as const;
const originalOwnedReadVersions = {supplierTaxReadbackVersion: 1, productFactsReadbackVersion: 1,
  mediaReadbackVersion: 1, unbrandedProduceReadbackVersion: 1};

/** Original owned catalogue reader; no local inventory is promoted to a master. */
export class OriginalStoreProductPreparationContext implements PreparationContextSource {
  constructor(private readonly deps: {projectId: string; authority: PreparationContextSource;
    catalogue: Pick<WorkspaceCatalogueService, "listSkus">; now?: () => Date}) {}
  private now() {return (this.deps.now?.() ?? new Date()).getTime();}
  private async authority(actor: AccountProfileActor, input: PreparationRequest) {
    return approvedWorkspacePreparationAuthority(this.deps.authority,actor,input,this.now());
  }
  private async snapshot(actor: AccountProfileActor, storeId: string, skuId: string | null, ownerOnly = false) {
    const records: StoreSkuRecord[] = [], seen = new Set<string>();
    let after: string | null = null, realm: string | null = null;
    do {
      let raw: object;
      try {raw = await this.deps.catalogue.listSkus(actor.uid, {storeId, ...originalOwnedReadVersions,
        ...(skuId !== null ? {skuId} : {limit: ownerOnly ? 1 : 50, ...(after !== null ? {after} : {})})});}
      catch (error) {
        // Preserve permission/ownership denial; a missing source is not an
        // empty Store and must not become editable through another reader.
        const status = error !== null && typeof error === "object" && "status" in error ? error.status : null;
        if (status === 403 || status === 401) return fail("workspace_access_unavailable", 403);
        return fail("context_unavailable");
      }
      const page = object(raw);
      if (page.schemaVersion !== 1 || page.storeId !== storeId || !["evaluation", "production"].includes(String(page.realm)) ||
          realm !== null && page.realm !== realm || !Array.isArray(page.items) || page.items.length > (skuId === null && !ownerOnly ? 50 : 1) ||
          page.supplierTaxReadbackVersion !== 1 || page.productFactsReadbackVersion !== 1 || page.mediaReadbackVersion !== 1 ||
          page.nextCursor !== null && (typeof page.nextCursor !== "string" || !/^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$/u.test(page.nextCursor))) return fail("context_unavailable");
      realm = page.realm as string;
      // This confirms the existing reader's Store-owner boundary only; no
      // product/default value or complete catalogue is claimed by this path.
      if (ownerOnly) return {realm, records};
      for (const rawRecord of page.items) {
        const row = object(rawRecord), content = object(row.content), pack = object(row.pack);
        if (row.schemaVersion !== 1 || row.storeId !== storeId || !Number.isSafeInteger(row.revision) || (row.revision as number) < 1 ||
            typeof row.skuId !== "string" || !/^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$/u.test(row.skuId) ||
            skuId !== null && row.skuId !== skuId || seen.has(row.skuId) ||
            [row.canonicalProductId, row.verifiedPackId].some(value => typeof value !== "string" || !/^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$/u.test(value)) ||
            typeof row.sku !== "string" || !row.sku.trim() || row.sku.length > 80 || typeof pack.label !== "string" || !pack.label.trim() ||
            typeof content.title !== "string" || !content.title.trim() || typeof content.brand !== "string" || typeof content.variant !== "string" ||
            typeof row.observedAt !== "string" || !Number.isFinite(Date.parse(row.observedAt)) || Date.parse(row.observedAt) > this.now() ||
            !Array.isArray(row.channels) || !row.channels.length || row.channels.length > 2 ||
            row.channels.some(value => !["retail", "wholesale", "bulk"].includes(String(object(value).kind))) ||
            new Set(row.channels.map(value => object(value).kind)).size !== row.channels.length) return fail("context_unavailable");
        seen.add(row.skuId); records.push(rawRecord as StoreSkuRecord);
      }
      if (records.length > 2500 || page.nextCursor !== null && (page.items.length !== 50 ||
          object(page.items.at(-1)).skuId !== page.nextCursor || page.nextCursor === after) || skuId !== null && page.nextCursor !== null) return fail("context_unavailable");
      after = page.nextCursor as string | null;
    } while (after !== null);
    return {realm, records};
  }
  private references(record: StoreSkuRecord): Readonly<Record<string, unknown>> {
    return {sourceCanonicalId: record.canonicalProductId, sourceSku: record.sku, sourcePack: record.pack.label,
      sourceRetailEnabled: record.channels.some(channel => channel.kind === "retail"),
      sourceWholesaleEnabled: record.channels.some(channel => channel.kind === "wholesale" || channel.kind === "bulk")};
  }
  private nativeOwnerTools(actor: AccountProfileActor, input: PreparationRequest, authority: PreparationContext, realm: string | null): PreparationTool[] {
    const sourceRevision = "store-product-defaults-owner:" + digest([actor.projectId, actor.uid, input.scope.storeId, authority.revision, realm]);
    const validate = (fields: Readonly<Record<string, unknown>>) => {
      const keys = Object.keys(fields);
      if (!keys.length || keys.some(key => !["stockMode", "lowStockThreshold", "customerListingRequested"].includes(key))) return false;
      if (Object.hasOwn(fields, "stockMode") && !["exactQuantity", "availabilityOnly"].includes(String(fields.stockMode))) return false;
      if (Object.hasOwn(fields, "customerListingRequested") && typeof fields.customerListingRequested !== "boolean") return false;
      if (Object.hasOwn(fields, "lowStockThreshold")) {
        const raw = fields.lowStockThreshold;
        if (typeof raw !== "string" || raw.length > 64 || !/^[+-]?\d+$/u.test(raw.trim())) return false;
        const count = Number(raw.trim());
        if (!Number.isSafeInteger(count) || count < 0 || count > 999999999) return false;
      }
      return true;
    };
    const authoringFields = new Set<string>(storeProductNativeTextFields);
    const validateAuthoring = (fields: Readonly<Record<string, unknown>>) => Object.keys(fields).length > 0 &&
      Object.entries(fields).every(([key, value]) => authoringFields.has(key) && typeof value === 'string' &&
        value.length <= 2000 && !/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/u.test(value) &&
        Buffer.from(value, 'utf8').toString('utf8') === value);
    const authoringRevision=`store-product-authoring-owner:${realm}:`+digest([actor.projectId,actor.uid,input.scope.storeId,authority.revision,realm]);
    const familyRevision=`store-product-family-owner:${realm}:`+digest([actor.projectId,actor.uid,input.scope.storeId,authority.revision,realm]);
    const variantRevision=`store-product-variants-owner:${realm}:`+digest([actor.projectId,actor.uid,input.scope.storeId,authority.revision,realm]);
    const submissionRevision=`store-product-submission-owner:${realm}:`+digest([actor.projectId,actor.uid,input.scope.storeId,authority.revision,realm]);
    const validateVariantChanges=(fields:Readonly<Record<string,unknown>>)=>{
      if(Object.keys(fields).length!==1||!Object.hasOwn(fields,'changes')||!Array.isArray(fields.changes)||
          !fields.changes.length||fields.changes.length>128)return false;
      return fields.changes.every(raw=>{
        if(raw===null||typeof raw!=='object'||Array.isArray(raw))return false;
        const row=raw as Record<string,unknown>;
        if(Object.keys(row).length!==4||Object.keys(row).some(key=>!['operation','label','kind','options'].includes(key))||
            typeof row.operation!=='string'||!['add','edit'].includes(row.operation)||typeof row.kind!=='string'||
            !(storeVariantNativeKinds as readonly string[]).includes(row.kind))return false;
        return ['label','options'].every(key=>typeof row[key]==='string'&&(row[key] as string).trim().length>0&&
          (row[key] as string).length<=2000&&!/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/u.test(row[key] as string)&&
          Buffer.from(row[key] as string,'utf8').toString('utf8')===row[key]);
      });
    };
    const decodeAuthoring=(args:Readonly<Record<string,unknown>>)=>{
      if(Object.keys(args).length!==1||!Array.isArray(args.changes)||!args.changes.length||
          args.changes.length>storeProductNativeTextFields.length)return fail('invalid_model_result');
      const fields:Record<string,unknown>={};
      for(const raw of args.changes){
        const value=object(raw);
        if(Object.keys(value).length!==2||typeof value.field!=='string'||
            !authoringFields.has(value.field)||Object.hasOwn(fields,value.field))return fail('invalid_model_result');
        fields[value.field]=value.value;
      }
      if(!validateAuthoring(fields))return fail('invalid_model_result');
      return fields;
    };
    const tools: PreparationTool[] = [
      ...(realm===null||input.entityId!==null?[]:[...storeStockOwnerActions].map(actionId=>{
        const adjustment=actionId==='AI-ACT-233',history=actionId==='AI-ACT-232';
        const keys=adjustment?['quantity','reason']:history?['from','until']:[];
        const validate=(fields:Readonly<Record<string,unknown>>)=>
          Object.keys(fields).every(key=>keys.includes(key))&&(!adjustment||keys.every(key=>Object.hasOwn(fields,key)))&&
          Object.values(fields).every(value=>typeof value==='string'&&value.length<=2000&&
            !/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/u.test(value)&&Buffer.from(value,'utf8').toString('utf8')===value)&&
          (!history||Object.values(fields).every(value=>/(Z|[+-]00:00)$/iu.test(value as string)&&Number.isFinite(Date.parse(value as string)))&&
            (!fields.from||!fields.until||Date.parse(fields.from as string)<Date.parse(fields.until as string)));
        const sourceRevision=`store-stock-owner:${realm}:`+digest([actor.projectId,actor.uid,input.scope.storeId,authority.revision,realm,actionId]);
        const title=adjustment?'Review Stock adjustment':history?'Review Stock movements':actionId==='AI-ACT-231'?'View Stock':
          actionId==='AI-ACT-407'?'Review Stock print options':'Review Stock download options';
        return {name:`store_review_stock_${actionId.slice(-3)}`,actionId,entityId:null,sourceRevision,
          description:'Prepare the existing account/Store-owned native Stock controls only. Current quantity, product identity, inventory revision and local movements are read by the native saved-inventory owner, not this catalogue reader. Select any product natively. No Stock balance, full history, adjustment, print or download is claimed or performed here.'+
            (adjustment?' Preserve only the user-supplied new on-hand total and reason. Ask for missing inputs; never invent a reason, infer a balance or convert an increment into a total.':''),
          parameters:{type:'object',properties:Object.fromEntries(keys.map(key=>[key,{type:history?['string','null']:'string'}])),
            required:keys,additionalProperties:false},validate,
          resolveTarget:(args:Readonly<Record<string,unknown>>)=>{
            if(Object.keys(args).length!==keys.length||!keys.every(key=>Object.hasOwn(args,key)))return fail('invalid_model_result');
            const fields=Object.fromEntries(Object.entries(args).filter(([,value])=>value!==null));
            if(!validate(fields))return fail('invalid_model_result');
            return {entityId:null,sourceRevision,fields,title,
              summary:adjustment?'Choose a product and review the new on-hand total and reason.':
                history?'Choose a product to view its recorded Stock movements.':actionId==='AI-ACT-231'?'View your saved Stock list.':
                  actionId==='AI-ACT-407'?'Check the Stock statement before printing.':'Check the Stock statement before downloading.'};
          }};
      })),
      ...(realm===null||input.entityId!==null?[]:[{name:'store_review_saved_private_product',actionId:'AI-ACT-223',entityId:null,
        sourceRevision:submissionRevision,
        description:'Review an actual saved native product selected by its Store owner. A public catalogue mirror is not required. No product or submission status has been selected or read here. Only the original native final Submit can send saved details for review; approval/publication is not performed.',
        parameters:{type:'object',properties:{},required:[],additionalProperties:false},
        validate:(fields:Readonly<Record<string,unknown>>)=>Object.keys(fields).length===0,
        resolveTarget:(args:Readonly<Record<string,unknown>>)=>{
          if(Object.keys(args).length)return fail('invalid_model_result');
          return {entityId:null,sourceRevision:submissionRevision,fields:{},title:'Review saved product',
            summary:'Choose a saved product and check its details before submitting for review.'};
        }}]),
      ...(realm===null?[]:[{name:'store_prepare_variant_changes',actionId:'AI-ACT-215',entityId:null,sourceRevision:variantRevision,
        description:'Prepare supplied add/edit dimension text for the existing native variant editor. The user selects the saved product and each existing dimension to edit. Never invent SKU/family/dimension/option IDs, match an edit by label, or turn an edit into an addition. Final native Apply/Save and member assignments remain required.',
        parameters:{type:'object',properties:{changes:{type:'array',items:{type:'object',properties:{
          operation:{type:'string',enum:['add','edit']},label:{type:'string'},kind:{type:'string',enum:storeVariantNativeKinds},
          options:{type:'string'}},required:['operation','label','kind','options'],additionalProperties:false}}},
          required:['changes'],additionalProperties:false},validate:validateVariantChanges,
        resolveTarget:(args:Readonly<Record<string,unknown>>)=>{
          if(!validateVariantChanges(args))return fail('invalid_model_result');
          return {entityId:null,sourceRevision:variantRevision,fields:args,title:'Review product variants',
            summary:'Choose the product and any option groups to edit, then review your changes before saving.'};
        }}]),
      ...(realm === null ? [] : [{name:'store_review_saved_product_group',actionId:'AI-ACT-224',entityId:null,
        sourceRevision:familyRevision,
        description:'Review an actual saved product group selected in the original native Store form. This preparation has not selected a group or confirmed its submission status. Only the native final Submit can send its saved members for review; no approval or publication is performed here.',
        parameters:{type:'object',properties:{},required:[],additionalProperties:false},
        validate:(fields:Readonly<Record<string,unknown>>)=>Object.keys(fields).length===0,
        resolveTarget:(args:Readonly<Record<string,unknown>>)=>{
          if(Object.keys(args).length)return fail('invalid_model_result');
          return {entityId:null,sourceRevision:familyRevision,fields:{},title:'Review product group',
            summary:'Choose a saved product group and check its details before submitting for review.'};
        }}]),
      ...(realm === null ? [] : [{name: 'store_prepare_new_product', actionId: 'AI-ACT-213', entityId: null,
        sourceRevision:authoringRevision,
        description: 'Prepare only user-supplied text in the original blank manual product editor. No master-catalogue identity, Stock, tax, approval or publication is inferred. The native final Save is required.',
        parameters: {type: 'object', properties: {changes: {type: 'array', items: {type: 'object',
          properties: {field: {type: 'string', enum: storeProductNativeTextFields}, value: {type: 'string'}},
          required: ['field', 'value'], additionalProperties: false}}}, required: ['changes'], additionalProperties: false},
        validate: validateAuthoring,
        decodeFields:decodeAuthoring,
        resolveTarget:(args:Readonly<Record<string,unknown>>)=>{
          return {entityId:null,sourceRevision:authoringRevision,fields:decodeAuthoring(args),title:'Review new product',
            summary:'Check the product details and save when ready.'};
        }}]),
      ...([['AI-ACT-225', 'store_review_original_listing_request'],
        ['AI-ACT-374', 'store_review_original_family_request']] as const).filter(() => realm !== null).map(([actionId, name]) => {
        const capture = input.nativeOriginalCaptures?.find(value => value.actionId === actionId)?.digest;
        const sourceRevision = `store-product-original-owner:${realm}:` + digest([actor.projectId, actor.uid, input.scope.storeId, authority.revision, realm, actionId]);
        return {name, actionId, entityId: null, sourceRevision,
        description: 'Review the current Store-owned native retained original request. This preparation has not read its contents or status. The native journal must identify the complete frozen original; only the original native Check can reconcile it. No resend, publication or cleanup is performed here.',
        parameters: {type: 'object', properties: {}, required: [], additionalProperties: false},
        validate: (fields: Readonly<Record<string, unknown>>) => capture !== undefined && Object.keys(fields).length === 1 && fields.originalCapture === capture,
        resolveTarget: (fields: Readonly<Record<string, unknown>>) => {
          if (!capture || Object.keys(fields).length !== 0) return fail('invalid_model_result');
          return {entityId: null, sourceRevision, fields: {originalCapture: capture},
            title: actionId === 'AI-ACT-225' ? 'Review original listing request' : 'Review original product-group request',
            summary: 'Check the retained original in its existing form. Its status has not been confirmed.'};
        },
      };}),
      {name: "store_review_price_attention", actionId: "AI-ACT-372", entityId: null,
        sourceRevision: "store-price-attention-owner:" + digest([actor.projectId, actor.uid, input.scope.storeId, authority.revision, realm]),
        description: "Read the original native supplier price-attention list. This preparation has not read or inferred price status.",
        parameters: {type: "object", properties: {}, required: [], additionalProperties: false},
        validate: fields => Object.keys(fields).length === 0},
      {name: "store_review_product_defaults", actionId: "AI-ACT-218", entityId: null, sourceRevision,
        description: "Review the current native Store product defaults", parameters: {type: "object", properties: {}, required: [], additionalProperties: false},
        validate: fields => Object.keys(fields).length === 0},
      {name: "store_prepare_product_defaults", actionId: "AI-ACT-219", entityId: null, sourceRevision,
        description: "Review supplied changes to native Store product defaults; no listing publication",
        parameters: {type: "object", properties: {stockMode: {type: ["string", "null"], enum: [null, "exactQuantity", "availabilityOnly"]},
          lowStockThreshold: {type: ["string", "null"]}, customerListingRequested: {type: ["boolean", "null"]}},
          required: ["stockMode", "lowStockThreshold", "customerListingRequested"], additionalProperties: false}, validate,
        decodeFields: args => {
          if (Object.keys(args).length !== 3 || !["stockMode", "lowStockThreshold", "customerListingRequested"].every(key => Object.hasOwn(args, key))) return fail("invalid_model_result");
          const fields = Object.fromEntries(Object.entries(args).filter(([, value]) => value !== null));
          if (!validate(fields)) return fail("invalid_model_result");
          return fields;
        }},
    ];
    return tools.filter(tool => input.actionId === null || tool.actionId === input.actionId);
  }
  async readPrepared(actor: AccountProfileActor, input: PreparationRequest,
    proposal: Extract<PreparationReply["outcome"], {kind: "proposal"}>): Promise<PreparationContext> {
    if (proposal.actionId !== input.actionId || proposal.entityId !== input.entityId) return fail("stale_preparation", 409);
    if (proposal.actionId === 'AI-ACT-225' || proposal.actionId === 'AI-ACT-374') {
      if (proposal.entityId !== null || Object.keys(proposal.fields).length !== 1 ||
          typeof proposal.fields.originalCapture !== 'string' || !/^[a-f0-9]{64}$/u.test(proposal.fields.originalCapture)) return fail('stale_preparation', 409);
      // Status reconstructs only the stored server-echoed capture, never a newer
      // private native journal. The native Review independently matches it.
      return this.read(actor, {...input, nativeOriginalCaptures: [{actionId: proposal.actionId, digest: proposal.fields.originalCapture}]});
    }
    return this.read(actor, input);
  }
  async read(actor: AccountProfileActor, input: PreparationRequest): Promise<PreparationContext> {
    if (actor.projectId !== this.deps.projectId || !actor.uid || actor.tenantId !== undefined) return fail("account_scope_mismatch", 403);
    if (input.scope.audience !== "workspace" || !input.scope.storeId ||
        input.actionId !== null && !storeProductActions.has(input.actionId) && !storeProductOwnerActions.has(input.actionId)&&!storeStockOwnerActions.has(input.actionId) ||
        input.entityId !== null && !storeProductActions.has(input.actionId ?? "") || input.catalogueListingIds?.length) return fail("context_unavailable");
    const started = this.now(), before = await this.authority(actor, input);
    const ownerOnly = input.actionId !== null && (storeProductOwnerActions.has(input.actionId)||storeStockOwnerActions.has(input.actionId)||
      input.actionId==='AI-ACT-223'&&input.entityId===null);
    const first = await this.snapshot(actor, input.scope.storeId, input.entityId, ownerOnly);
    const second = await this.snapshot(actor, input.scope.storeId, input.entityId, ownerOnly);
    const after = await this.authority(actor, input);
    if (before.revision !== after.revision || canonical(first) !== canonical(second)) return fail("stale_preparation", 409);
    const until = Math.min(started + 60_000, Date.parse(before.validUntil), Date.parse(after.validUntil));
    if (until <= this.now() || input.entityId !== null && !second.records.length) return fail("context_unavailable");
    const proof = (record: StoreSkuRecord) => `store-owned-product:${second.realm}:${record.revision}:` +
      digest([actor.projectId, actor.uid, input.scope.storeId, after.revision, second.realm, record]);
    const eligible = (actionId: string) => actionId === "AI-ACT-370"
      ? second.records.filter(record => record.content.categoryId === "other") : actionId === "AI-ACT-220"
        ? second.records.filter(record => record.channels.some(channel => channel.kind === "wholesale" || channel.kind === "bulk")) : second.records;
    const tools: PreparationTool[] = [];
    for (const actionId of storeProductActions) {
      if (input.actionId !== null && input.actionId !== actionId || !second.records.length) continue;
      // Root223 explicitly chooses an original saved native SKU. Fixed-entity
      // requests retain the earlier mirrored contract for saved preparations.
      if(actionId==='AI-ACT-223'&&input.entityId===null)continue;
      if (["AI-ACT-222", "AI-ACT-223", "AI-ACT-226", "AI-ACT-227", "AI-ACT-371"].includes(actionId)) {
        const records = second.records, fixed = input.entityId !== null ? records.find(record => record.skuId === input.entityId) : undefined;
        if (input.entityId !== null && !fixed) continue;
        const visibility = actionId === "AI-ACT-222" || actionId === "AI-ACT-371";
        const title = actionId === "AI-ACT-223" ? "Review saved product for submission" : actionId === "AI-ACT-222" ? "Review public listing" : actionId === "AI-ACT-371"
          ? "Review public quantity visibility" : actionId === "AI-ACT-226" ? "Review pausing Counter sale" : "Review resuming Counter sale";
        const valid = (record: StoreSkuRecord, fields: Readonly<Record<string, unknown>>) =>
          Object.keys(fields).length === storeReferenceFields.length + (visibility ? 1 : 0) &&
          storeReferenceFields.every(key => fields[key] === this.references(record)[key]) &&
          (!visibility || typeof fields.visible === "boolean");
        tools.push({name: actionId === "AI-ACT-223" ? "store_review_product_submission" : actionId === "AI-ACT-222" ? "store_prepare_listing_visibility" : actionId === "AI-ACT-371"
          ? "store_prepare_quantity_visibility" : actionId === "AI-ACT-226" ? "store_prepare_counter_pause" : "store_prepare_counter_resume",
          actionId, entityId: input.entityId, sourceRevision: fixed ? proof(fixed) : "store-owned-selection:" + digest(records),
          ...(fixed ? {} : {targetSelector: "skuId"}),
          description: actionId === "AI-ACT-223" ? "Review this saved product for submission. Submission status is not read or claimed here. The original native controller must read current status before review; only its final Submit can send the saved details."
            : actionId === "AI-ACT-222" ? "Review the explicitly requested public listing preference. The original native journal and final confirmation own publication; no result is claimed here."
            : actionId === "AI-ACT-371" ? "Review the explicitly requested public quantity disclosure. This owner read has not read current visibility or Stock; the original native readback and final switch own the result."
            : "Review the requested Counter-sale pause or resume only. Stock and public listing are unchanged; the original native confirmation owns the change.",
          parameters: {type: "object", properties: {...(fixed ? {} : {skuId: {type: "string", enum: records.map(record => record.skuId)}}),
            ...(visibility ? {visible: {type: "boolean"}} : {})},
            required: [...(fixed ? [] : ["skuId"]), ...(visibility ? ["visible"] : [])], additionalProperties: false},
          validate: fields => (fixed ? [fixed] : records).some(record => valid(record, fields)),
          resolveTarget: args => {
            if (Object.keys(args).length !== (fixed ? 0 : 1) + (visibility ? 1 : 0)) return fail("invalid_model_result");
            const record = fixed ?? records.find(value => value.skuId === args.skuId);
            if (!record) return fail("invalid_model_result");
            const fields = {...this.references(record), ...(visibility ? {visible: args.visible} : {})};
            if (!valid(record, fields)) return fail("invalid_model_result");
            return {entityId: record.skuId, sourceRevision: proof(record), fields, title,
              summary: [record.content.title, record.content.variant, record.pack.label].filter(Boolean).join(" · ")};
          }});
        continue;
      }
      if (actionId === "AI-ACT-230") {
        const records = second.records, fixed = input.entityId !== null ? records.find(record => record.skuId === input.entityId) : undefined;
        if (input.entityId !== null && !fixed) continue;
        const valid = (record: StoreSkuRecord, fields: Readonly<Record<string, unknown>>) =>
          Object.keys(fields).length === storeReferenceFields.length + 1 &&
          storeReferenceFields.every(key => fields[key] === this.references(record)[key]) &&
          record.channels.some(channel => channel.kind === fields.channel);
        tools.push({name: "store_review_public_product", actionId, entityId: input.entityId,
          sourceRevision: fixed ? proof(fixed) : "store-owned-selection:" + digest(records), ...(fixed ? {} : {targetSelector: "skuId"}),
          description: "Review the original public product in an existing selling channel. The native authenticated reader must independently confirm publication; this owner read does not claim that the product is published or available.",
          parameters: {type: "object", properties: {...(fixed ? {} : {skuId: {type: "string", enum: records.map(record => record.skuId)}}),
            channel: {type: "string", enum: [...new Set(records.flatMap(record => record.channels.map(channel => channel.kind)))]}},
            required: [...(fixed ? [] : ["skuId"]), "channel"], additionalProperties: false},
          validate: fields => (fixed ? [fixed] : records).some(record => valid(record, fields)),
          resolveTarget: args => {
            if (Object.keys(args).length !== (fixed ? 1 : 2) || !Object.hasOwn(args, "channel")) return fail("invalid_model_result");
            const record = fixed ?? records.find(value => value.skuId === args.skuId);
            if (!record) return fail("invalid_model_result");
            const fields = {...this.references(record), channel: args.channel};
            if (!valid(record, fields)) return fail("invalid_model_result");
            return {entityId: record.skuId, sourceRevision: proof(record), fields, title: "Review public product",
              summary: [record.content.title, record.content.variant, record.pack.label, args.channel].filter(Boolean).join(" · ")};
          }});
        continue;
      }
      if (actionId === "AI-ACT-220") {
        const records = eligible(actionId), fixed = input.entityId !== null ? records.find(record => record.skuId === input.entityId) : undefined;
        if (!records.length || input.entityId !== null && !fixed) continue;
        const validDuration = (value: unknown) => typeof value === "string" && value.length <= 64 && /^[+-]?\d+$/u.test(value.trim()) &&
          Number.isSafeInteger(Number(value.trim())) && Number(value.trim()) >= 1 && Number(value.trim()) <= 525600;
        const validate = (record: StoreSkuRecord, fields: Readonly<Record<string, unknown>>) =>
          storeReferenceFields.every(key => fields[key] === this.references(record)[key]) &&
          Object.keys(fields).every(key => storeReferenceFields.includes(key) || key === "validityMinutes" && validDuration(fields[key]));
        tools.push({name: "store_review_price_confirmation", actionId, entityId: input.entityId,
          sourceRevision: fixed ? proof(fixed) : "store-owned-selection:" + digest(records), ...(fixed ? {} : {targetSelector: "skuId"}),
          description: "Review the original SKU trade-price confirmation. Original native status, current price and final Confirm remain authoritative; no price is confirmed here.",
          parameters: {type: "object", properties: {...(fixed ? {} : {skuId: {type: "string", enum: records.map(record => record.skuId)}}),
            validityMinutes: {type: ["string", "null"]}}, required: [...(fixed ? [] : ["skuId"]), "validityMinutes"], additionalProperties: false},
          validate: fields => (fixed ? [fixed] : records).some(record => validate(record, fields)),
          resolveTarget: args => {
            if (Object.keys(args).length !== (fixed ? 1 : 2) || !Object.hasOwn(args, "validityMinutes") ||
                args.validityMinutes !== null && !validDuration(args.validityMinutes)) return fail("invalid_model_result");
            const record = fixed ?? records.find(value => value.skuId === args.skuId);
            if (!record) return fail("invalid_model_result");
            return {entityId: record.skuId, sourceRevision: proof(record), fields: {...this.references(record),
              ...(args.validityMinutes === null ? {} : {validityMinutes: args.validityMinutes})}, title: "Review price confirmation",
              summary: [record.content.title, record.content.variant, record.pack.label].filter(Boolean).join(" · ")};
          }});
        continue;
      }
      if (actionId === "AI-ACT-370") {
        const records = eligible(actionId), fixed = input.entityId !== null ? records.find(record => record.skuId === input.entityId) : undefined;
        if (!records.length || input.entityId !== null && !fixed) continue;
        const validWarranty = (value: unknown) => {
          if (value === null || typeof value !== "object" || Array.isArray(value)) return false;
          const fields = value as Record<string, unknown>, keys = Object.keys(fields);
          return keys.length > 0 && keys.length <= storeWarrantyNativeLabels.length &&
            keys.every(key => (storeWarrantyNativeLabels as readonly string[]).includes(key) && typeof fields[key] === "string" &&
              (fields[key] as string).length <= 2000 && !/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/u.test(fields[key] as string) &&
              Buffer.from(fields[key] as string, "utf8").toString("utf8") === fields[key]) &&
            keys.some(key => (fields[key] as string).trim().length > 0);
        };
        const validate = (record: StoreSkuRecord, fields: Readonly<Record<string, unknown>>) =>
          Object.keys(fields).length === storeReferenceFields.length + 1 &&
          storeReferenceFields.every(key => fields[key] === this.references(record)[key]) && validWarranty(fields.warranty);
        const decodeWarranty = (raw: unknown) => {
          let values: Record<string, unknown>;
          try {values = object(raw, [...storeWarrantyNativeLabels]);}
          catch {return fail("invalid_model_result");}
          const fields = Object.fromEntries(Object.entries(values).filter(([, value]) => value !== null));
          if (!validWarranty(fields)) return fail("invalid_model_result");
          return fields;
        };
        tools.push({name: "store_prepare_warranty_details", actionId, entityId: input.entityId,
          sourceRevision: fixed ? proof(fixed) : "store-owned-selection:" + digest(records), ...(fixed ? {} : {targetSelector: "skuId"}),
          description: "Review supplied descriptive warranty text in the original product guide; never invent warranty terms",
          parameters: {type: "object", properties: {...(fixed ? {} : {skuId: {type: "string", enum: records.map(record => record.skuId)}}),
            warranty: {type: "object", properties: Object.fromEntries(storeWarrantyNativeLabels.map(label => [label, {type: ["string", "null"]}])),
              required: [...storeWarrantyNativeLabels], additionalProperties: false}}, required: [...(fixed ? [] : ["skuId"]), "warranty"], additionalProperties: false},
          validate: fields => (fixed ? [fixed] : records).some(record => validate(record, fields)),
          resolveTarget: args => {
            if (Object.keys(args).length !== (fixed ? 1 : 2)) return fail("invalid_model_result");
            const warranty = decodeWarranty(args.warranty);
            const record = fixed ?? records.find(value => value.skuId === args.skuId);
            if (!record) return fail("invalid_model_result");
            return {entityId: record.skuId, sourceRevision: proof(record), fields: {...this.references(record), warranty},
              title: "Review warranty details", summary: [record.content.title, record.content.variant, record.pack.label].filter(Boolean).join(" · ")};
          }});
        continue;
      }
      const price = actionId === "AI-ACT-221", names: readonly string[] = price ? storeSalePriceFields : storeProductNativeTextFields;
      const allowed = new Set(names);
      const validate = (record: StoreSkuRecord, fields: Readonly<Record<string, unknown>>) => {
        const references = this.references(record), keys = Object.keys(fields).filter(key => !storeReferenceFields.includes(key));
        if (!keys.length || storeReferenceFields.some(key => fields[key] !== references[key]) ||
            keys.some(key => !allowed.has(key) || typeof fields[key] !== "string" || (fields[key] as string).length > 2000 ||
              /[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/u.test(fields[key] as string) ||
              Buffer.from(fields[key] as string, "utf8").toString("utf8") !== fields[key])) return false;
        if (price && (!keys.some(key => ["sellingPrice", "wholesalePrice", "wholesaleTiers"].includes(key)) ||
            keys.includes("sellingPrice") && references.sourceRetailEnabled !== true ||
            keys.some(key => key !== "sellingPrice") && references.sourceWholesaleEnabled !== true)) return false;
        return true;
      };
      const fixed = input.entityId !== null ? second.records.find(record => record.skuId === input.entityId) : undefined;
      tools.push({name: price ? "store_prepare_sale_prices" : "store_prepare_product_details", actionId, entityId: input.entityId,
        sourceRevision: fixed ? proof(fixed) : "store-owned-selection:" + digest(second),
        ...(fixed ? {} : {targetSelector: "skuId"}),
        description: price ? "Review the original SKU sale-price inputs" : "Review edits in the original Store product editor",
        parameters: {type: "object", properties: {...(fixed ? {} : {skuId: {type: "string", enum: second.records.map(record => record.skuId)}}),
          changes: {type: "array", items: {type: "object", properties: {field: {type: "string", enum: names}, value: {type: "string"}},
            required: ["field", "value"], additionalProperties: false}}}, required: [...(fixed ? [] : ["skuId"]), "changes"], additionalProperties: false},
        validate: fields => (fixed ? [fixed] : second.records).some(record => validate(record, fields)),
        resolveTarget: args => {
          if (Object.keys(args).length !== (fixed ? 1 : 2) || !Array.isArray(args.changes) || !args.changes.length || args.changes.length > names.length) return fail("invalid_model_result");
          const record = fixed ?? second.records.find(value => value.skuId === args.skuId);
          if (!record) return fail("invalid_model_result");
          const changes: Record<string, unknown> = {};
          for (const value of args.changes) {
            const change = object(value);
            if (Object.keys(change).length !== 2 || typeof change.field !== "string" || !allowed.has(change.field) || Object.hasOwn(changes, change.field)) return fail("invalid_model_result");
            changes[change.field] = change.value;
          }
          const fields = {...this.references(record), ...changes};
          if (!validate(record, fields)) return fail("invalid_model_result");
          return {entityId: record.skuId, sourceRevision: proof(record), fields,
            title: price ? "Review sale prices" : "Review product changes", summary: [record.content.title, record.content.variant, record.pack.label].filter(Boolean).join(" · ")};
        }});
    }
    tools.push(...this.nativeOwnerTools(actor, input, after, second.realm));
    if (input.actionId !== null && !tools.length) return fail("context_unavailable");
    return {revision: "store-owned-products:" + digest([actor.projectId, actor.uid, input.scope.storeId, after.revision, second]),
      validUntil: new Date(until).toISOString(), tools,
      nativeTargets: [
        ...tools.filter(tool => storeProductActions.has(tool.actionId)&&tool.name!=='store_review_saved_private_product').flatMap(tool => eligible(tool.actionId).map(record => ({actionId: tool.actionId, entityId: record.skuId, sourceRevision: proof(record)}))),
        ...(input.entityId===null&&(input.actionId===null||input.actionId==='AI-ACT-223')?second.records.map(record=>({actionId:'AI-ACT-223',entityId:record.skuId,sourceRevision:proof(record)})):[]),
        ...tools.filter(tool=>tool.name==='store_review_saved_private_product').map(tool=>({actionId:tool.actionId,entityId:null,sourceRevision:tool.sourceRevision})),
        ...tools.filter(tool => storeProductOwnerActions.has(tool.actionId)||storeStockOwnerActions.has(tool.actionId)).map(tool => ({actionId: tool.actionId, entityId: null, sourceRevision: tool.sourceRevision})),
      ],
      modelContext: {audience: "workspace", storeId: input.scope.storeId, sourceKind: 'original-store-owned-skus-v1',
        priceAttentionSource: "Original native commodity-price reads and final confirmation remain native. This preparation has not read attention status or confirmed a price.",
        defaultsSource: "Existing account/Store-owned native preferences only. Their current values have not been read here; native snapshot and confirmation own them. Requesting a customer listing never confirms publication.",
        originalRequestSource: "Retained listing/family originals are native-owned, not inferred from the current catalogue. No pending identity, receipt, submission or publication status has been read here. Native review must bind the exact frozen original and preserve it.",
        purpose: "Prepare only supplied replacement text for the existing native editor. Preserve omitted fields. Owner catalogue channel prices are INR minor units, not a live trade quote, Stock balance or accepted order. Never infer purchase cost, Stock or missing tax.",
        products: second.records.map(record => ({skuId: record.skuId, sku: record.sku, canonicalId: record.canonicalProductId,
          title: record.content.title, brand: record.content.brand, variant: record.content.variant, pack: record.pack,
          channels: record.channels.map(({kind, priceMinor, mrpMinor, supplierTax}) => ({kind, priceMinor, mrpMinor, supplierTax: supplierTax ?? null}))}))}};
  }
}

/** Compose source readers; preserve the qualified original Profile path. */
/** Indexed immutable purchase facts only: never tracking, payment or invoice bytes. */
export class OriginalStoreOrderPreparationContext implements PreparationContextSource {
  constructor(private readonly deps: {projectId: string; authority: PreparationContextSource;
    purchases: Pick<WorkspacePurchaseProjectionService, "listStore">; now?: () => Date}) {}
  private now() {return (this.deps.now?.() ?? new Date()).getTime();}
  private async snapshot(actor: AccountProfileActor, storeId: string, selected: string | null, deadline: number) {
    const references: PurchaseReference[] = [], ids = new Set<string>(), cursors = new Set<string>();
    let cursor: string | null = null, realm: string | null = null;
    do {
      if(this.now()>=deadline)return fail('stale_preparation',409);
      let raw: unknown;
      try {raw = await this.deps.purchases.listStore(actor.uid, {storeId, limit: 5, cursor});}
      catch (error) {
        const status = error !== null && typeof error === 'object' && 'status' in error ? error.status : null;
        if (status === 401 || status === 403 || status === 404) return fail('workspace_access_unavailable', 403);
        return fail('context_unavailable');
      }
      if(this.now()>=deadline)return fail('stale_preparation',409);
      const page = object(raw, ['schemaVersion','realm','authNamespace','viewerRole','viewerUserId','storeId','coverage','references','nextCursor']);
      if (page.schemaVersion !== 2 || !['evaluation','production'].includes(String(page.realm)) ||
          realm !== null && realm !== page.realm || page.authNamespace !== 'firebase-default' ||
          page.viewerRole !== 'seller' || page.viewerUserId !== actor.uid || page.storeId !== storeId ||
          page.coverage !== 'indexed_original_facts' || !Array.isArray(page.references) || page.references.length > 5 ||
          page.nextCursor !== null && (typeof page.nextCursor !== 'string' || !page.nextCursor || page.nextCursor.length > 512)) return fail('context_unavailable');
      realm = page.realm as string;
      for (const value of page.references) {
        const row = object(value, ['purchaseId','storeId','orderId','originalFingerprint','sourceRevision']);
        const reference: PurchaseReference = {purchaseId: id(row.purchaseId), storeId: id(row.storeId), orderId: id(row.orderId),
          originalFingerprint: String(row.originalFingerprint), sourceRevision: id(row.sourceRevision)};
        if (reference.storeId !== storeId || !/^[a-f0-9]{64}$/u.test(reference.originalFingerprint) || ids.has(reference.orderId)) return fail('context_unavailable');
        ids.add(reference.orderId);
        if (selected === null || reference.orderId === selected) references.push(reference);
        if (ids.size > preparationNativeTargetLimit) return fail('context_unavailable');
      }
      cursor = page.nextCursor as string | null;
      if (cursor !== null && cursors.has(cursor)) return fail('context_unavailable');
      if (cursor !== null) cursors.add(cursor);
      if (selected !== null && references.length) break;
    } while (cursor !== null);
    references.sort((a,b) => a.orderId < b.orderId ? -1 : a.orderId > b.orderId ? 1 : 0);
    return {realm, references};
  }
  async readPrepared(actor: AccountProfileActor, input: PreparationRequest, proposal: Extract<PreparationReply['outcome'], {kind: 'proposal'}>): Promise<PreparationContext> {
    if (proposal.actionId !== 'AI-ACT-274' || input.actionId !== proposal.actionId || input.entityId !== proposal.entityId ||
        Object.keys(proposal.fields).length !== 0) return fail('stale_preparation', 409);
    return this.read(actor, input);
  }
  async read(actor: AccountProfileActor, input: PreparationRequest): Promise<PreparationContext> {
    if (actor.projectId !== this.deps.projectId || !actor.uid || actor.tenantId !== undefined) return fail('account_scope_mismatch', 403);
    if (input.scope.audience !== 'workspace' || !input.scope.storeId || input.actionId !== null && input.actionId !== 'AI-ACT-274' ||
        input.entityId !== null && input.actionId !== 'AI-ACT-274' || input.catalogueListingIds?.length) return fail('context_unavailable');
    const started = this.now(), before = await approvedWorkspacePreparationAuthority(this.deps.authority, actor, input, started);
    const deadline=Math.min(started+60_000,Date.parse(before.validUntil));
    const first = await this.snapshot(actor, input.scope.storeId, input.entityId, deadline);
    const second = await this.snapshot(actor, input.scope.storeId, input.entityId, deadline);
    const after = await approvedWorkspacePreparationAuthority(this.deps.authority, actor, input, this.now());
    if (before.revision !== after.revision || canonical(first) !== canonical(second)) return fail('stale_preparation', 409);
    const until = Math.min(started + 60_000, Date.parse(before.validUntil), Date.parse(after.validUntil));
    if (until <= this.now() || input.entityId !== null && !second.references.length) return fail('context_unavailable');
    const proof = (row: PurchaseReference) => `store-order-original:${second.realm}:` + digest([
      row.purchaseId,row.storeId,row.orderId,row.originalFingerprint,row.sourceRevision]);
    const revision = 'store-order-original-context:' + digest([actor.projectId,actor.uid,input.scope.storeId,after.revision,second]);
    const dynamic = input.entityId === null, tools: PreparationTool[] = [];
    if (second.references.length) tools.push({name:'store_review_order_original',actionId:'AI-ACT-274',entityId:input.entityId,
      sourceRevision: dynamic ? revision : proof(second.references[0]!),description:'View saved original purchase facts for this Store order; current payment and delivery status are separate.',
      parameters:{type:'object',properties:dynamic?{orderId:{type:'string',enum:second.references.map(row=>row.orderId)}}:{},
        required:dynamic?['orderId']:[],additionalProperties:false},validate:fields=>Object.keys(fields).length===0,
      ...(dynamic?{targetSelector:'orderId',resolveTarget:(args:Readonly<Record<string,unknown>>)=>{
        if(Object.keys(args).length!==1)return fail('invalid_model_result');
        const row=second.references.find(row=>row.orderId===args.orderId);
        if(!row)return fail('invalid_model_result');
        return {entityId:row.orderId,sourceRevision:proof(row),fields:{}};
      }}:{})});
    return {revision,validUntil:new Date(until).toISOString(),tools,
      nativeTargets:second.references.map(row=>({actionId:'AI-ACT-274',entityId:row.orderId,sourceRevision:proof(row)})),
      modelContext:{sourceKind:'original-store-order-facts-v1',coverage:'indexed_original_facts',
        orders:second.references.map(row=>({orderId:row.orderId,sourceRevision:row.sourceRevision}))}};
  }
}
/** Existing private purchased-item stars only; never public review eligibility. */
export class OriginalPurchasedStarsPreparationContext implements PreparationContextSource {
  constructor(private readonly deps:{projectId:string;authority:PreparationContextSource;
    operations:Pick<WorkspaceOrderOperationsService,'listBuyerProductFeedbackTargets'|'readBuyerProductStars'>;now?:()=>Date}){}
  private now(){return (this.deps.now?.()??new Date()).getTime();}
  private async authority(actor:AccountProfileActor,input:PreparationRequest){
    const value=await this.deps.authority.read(actor,{...input,actionId:null,entityId:null});
    if(value.modelContext?.audience!=='personal'||!value.tools.some(tool=>tool.actionId==='AI-ACT-196')||
      !Number.isFinite(Date.parse(value.validUntil))||Date.parse(value.validUntil)<=this.now())return fail('account_scope_mismatch',403);
    return value;
  }
  private async snapshot(actor:AccountProfileActor,selected:string|null,deadline:number){
    const targets:ProductFeedbackTarget[]=[],seen=new Set<string>(),cursors=new Set<string>();
    const ratings:Record<string,readonly unknown[]>={};
    let cursor:string|null=null,realm:string|null=null;
    do{
      if(this.now()>=deadline)return fail('stale_preparation',409);
      let raw:unknown;
      try{raw=await this.deps.operations.listBuyerProductFeedbackTargets(actor.uid,{limit:5,cursor});}
      catch(error){
        const status=error!==null&&typeof error==='object'&&'status' in error?error.status:null;
        if(status===401||status===403)return fail('account_scope_mismatch',403);
        return fail('context_unavailable');
      }
      if(this.now()>=deadline)return fail('stale_preparation',409);
      const page=object(raw,['schemaVersion','realm','authNamespace','viewerRole','viewerUserId','coverage','targets','nextCursor']);
      if(page.schemaVersion!==1||!['evaluation','production'].includes(String(page.realm))||realm!==null&&realm!==page.realm||
        page.authNamespace!=='firebase-default'||page.viewerRole!=='buyer'||page.viewerUserId!==actor.uid||
        page.coverage!=='indexed_recorded_completions'||!Array.isArray(page.targets)||page.targets.length>5||
        page.nextCursor!==null&&(typeof page.nextCursor!=='string'||!page.nextCursor||page.nextCursor.length>512))return fail('context_unavailable');
      realm=page.realm as string;
      for(const value of page.targets){
        const row=object(value,['id','kind','purchaseId','storeId','orderId','orderLineId','productId','productLabel',
          'originalFingerprint','sourceRevision','purchasedListing','completedAt','completionId','completionRevision']);
        const listing=object(row.purchasedListing,['schemaVersion','realm','listingId','storeId','skuId','canonicalProductId','verifiedPackId','channel']);
        for(const key of ['purchaseId','storeId','orderId','orderLineId','sourceRevision','completionRevision'])id(row[key]);
        for(const key of ['listingId','storeId','skuId','canonicalProductId','verifiedPackId'])id(listing[key]);
        if(row.kind!=='product'||typeof row.productLabel!=='string'||row.productLabel.trim()!==row.productLabel||!row.productLabel||
          row.productLabel.length>240||!/^completion-[a-f0-9]{64}$/u.test(String(row.completionId))||
          !/^[a-f0-9]{64}$/u.test(String(row.originalFingerprint))||listing.schemaVersion!==1||listing.realm!==realm||listing.storeId!==row.storeId||
          listing.listingId!==row.productId||!['retail','wholesale','bulk'].includes(String(listing.channel))||
          listing.listingId!=='listing-'+digest([1,realm,listing.storeId,listing.skuId,listing.channel])||
          typeof row.completedAt!=='string'||!Number.isFinite(Date.parse(row.completedAt))||Date.parse(row.completedAt)>this.now())return fail('context_unavailable');
        const expected='feedback-'+digest([1,realm,'firebase-default',actor.uid,row.purchaseId,row.storeId,row.orderId,row.orderLineId,
          row.originalFingerprint,row.sourceRevision,row.productLabel,listing.listingId,listing.skuId,listing.canonicalProductId,
          listing.verifiedPackId,listing.channel,row.completionId,row.completionRevision,row.completedAt]);
        if(row.id!==expected||seen.has(expected))return fail('context_unavailable');
        seen.add(expected);if(seen.size>preparationNativeTargetLimit)return fail('context_unavailable');
        if(selected===null||row.orderId===selected){
          if(this.now()>=deadline)return fail('stale_preparation',409);
          let saved;
          try{saved=await this.deps.operations.readBuyerProductStars(actor.uid,{targetId:expected});}
          catch{return fail('context_unavailable');}
          if(this.now()>=deadline)return fail('stale_preparation',409);
          if(saved!==null&&(canonical(saved.target)!==canonical(row)||!Number.isSafeInteger(saved.revision)||saved.revision<1||
            !Number.isInteger(saved.stars)||saved.stars<1||saved.stars>5||!Number.isFinite(Date.parse(saved.updatedAt))||
            Date.parse(saved.updatedAt)>this.now()))return fail('context_unavailable');
          ratings[expected]=saved===null?[0,null,null]:[saved.revision,saved.stars,saved.updatedAt];
          targets.push(row as unknown as ProductFeedbackTarget);
        }
      }
      cursor=page.nextCursor as string|null;
      if(cursor!==null&&cursors.has(cursor))return fail('context_unavailable');
      if(cursor!==null)cursors.add(cursor);
    }while(cursor!==null);
    targets.sort((a,b)=>a.id<b.id?-1:a.id>b.id?1:0);
    return {realm,targets,ratings};
  }
  async readPrepared(actor:AccountProfileActor,input:PreparationRequest,proposal:Extract<PreparationReply['outcome'],{kind:'proposal'}>){
    if(input.actionId!=='AI-ACT-055'||proposal.actionId!==input.actionId||proposal.entityId!==input.entityId)return fail('stale_preparation',409);
    const value=await this.read(actor,input);
    if(value.tools.length!==1||!value.tools[0]!.validate(proposal.fields))return fail('stale_preparation',409);
    return value;
  }
  async read(actor:AccountProfileActor,input:PreparationRequest):Promise<PreparationContext>{
    if(actor.projectId!==this.deps.projectId||!actor.uid||actor.tenantId!==undefined)return fail('account_scope_mismatch',403);
    if(input.scope.audience!=='personal'||input.scope.storeId!==null||input.actionId!==null&&input.actionId!=='AI-ACT-055'||
      input.entityId!==null&&input.actionId!=='AI-ACT-055')return fail('context_unavailable');
    const started=this.now(),before=await this.authority(actor,input),deadline=Math.min(started+60_000,Date.parse(before.validUntil));
    const first=await this.snapshot(actor,input.entityId,deadline),second=await this.snapshot(actor,input.entityId,deadline);
    const after=await this.authority(actor,input);
    if(before.revision!==after.revision||canonical(first)!==canonical(second))return fail('stale_preparation',409);
    const until=Math.min(deadline,Date.parse(after.validUntil));if(until<=this.now())return fail('stale_preparation',409);
    const orders=new Map<string,ProductFeedbackTarget[]>();
    for(const target of second.targets){const rows=orders.get(target.orderId)??[];rows.push(target);orders.set(target.orderId,rows);}
    if(input.entityId!==null&&!orders.has(input.entityId))return fail('context_unavailable');
    for(const rows of orders.values())if(new Set(rows.map(row=>canonical([row.purchaseId,row.storeId,row.originalFingerprint,row.sourceRevision]))).size!==1||
      new Set(rows.map(row=>row.orderLineId)).size!==rows.length)return fail('context_unavailable');
    // Target IDs commit to exact purchase/listing/completion facts; the saved
    // rating revision (including confirmed absence) also retires old proposals.
    const proof=(orderId:string)=>`buyer-product-stars:${second.realm}:`+digest(orders.get(orderId)!.map(row=>[row.id,...second.ratings[row.id]!]));
    const valid=(orderId:string,fields:Readonly<Record<string,unknown>>)=>Object.keys(fields).length===2&&
      typeof fields.lineId==='string'&&orders.get(orderId)?.some(row=>row.orderLineId===fields.lineId)===true&&
      typeof fields.stars==='number'&&Number.isInteger(fields.stars)&&fields.stars>=1&&fields.stars<=5;
    const revision='buyer-product-stars-context:'+digest([actor.projectId,actor.uid,after.revision,second]);
    const dynamic=input.entityId===null,tools:PreparationTool[]=[];
    if(orders.size)tools.push({name:'buyer_prepare_private_product_stars',actionId:'AI-ACT-055',entityId:input.entityId,
      sourceRevision:dynamic?revision:proof(input.entityId!),description:'Review private stars for a completed purchased item; not a public review.',
      parameters:{type:'object',additionalProperties:false,required:[...(dynamic?['orderId']:[]),'lineId','stars'],properties:{
        ...(dynamic?{orderId:{type:'string',enum:[...orders.keys()]}}:{}),
        lineId:{type:'string',enum:second.targets.map(row=>row.orderLineId)},stars:{type:'integer',minimum:1,maximum:5}}},
      validate:fields=>input.entityId!==null?valid(input.entityId,fields):[...orders.keys()].some(orderId=>valid(orderId,fields)),
      ...(dynamic?{targetSelector:'orderId',resolveTarget:(args:Readonly<Record<string,unknown>>)=>{
        if(Object.keys(args).length!==3||typeof args.orderId!=='string'||!orders.has(args.orderId))return fail('invalid_model_result');
        const fields={lineId:args.lineId,stars:args.stars};if(!valid(args.orderId,fields))return fail('invalid_model_result');
        return {entityId:args.orderId,sourceRevision:proof(args.orderId),fields};
      }}:{})});
    return {revision,validUntil:new Date(until).toISOString(),tools,
      nativeTargets:[...orders.keys()].map(orderId=>({actionId:'AI-ACT-055',entityId:orderId,sourceRevision:proof(orderId)})),
      modelContext:{sourceKind:'original-private-product-stars-v1',coverage:'indexed_recorded_completions',
        orders:[...orders.entries()].map(([orderId,rows])=>({orderId,items:rows.map(row=>({lineId:row.orderLineId,label:row.productLabel}))}))}};
  }
}
export class CompositePreparationContext implements PreparationContextSource {
  constructor(private readonly deps: {original?: PreparationContextSource;
    catalogue?: OriginalCataloguePreparationContext; storeProducts?: OriginalStoreProductPreparationContext;
    storeOrders?: OriginalStoreOrderPreparationContext;
    privateStars?: OriginalPurchasedStarsPreparationContext;
    nativePreferencesEnabled?: boolean; nativeBuyerFormsEnabled?: boolean; nativeSupplierFormsEnabled?: boolean;
    nativePurchaseFormsEnabled?: boolean; now?: () => Date}) {}
  private async readPurchaseRoots(actor: AccountProfileActor, input: PreparationRequest): Promise<PreparationContext> {
    if (!this.deps.original || !this.deps.nativePurchaseFormsEnabled || actor.tenantId !== undefined ||
        !actor.uid || !actor.projectId || input.scope.audience !== 'workspace' || !input.scope.storeId ||
        input.entityId !== null || input.catalogueListingIds !== undefined ||
        input.actionId !== null && !storePurchaseRootActions.has(input.actionId)) return fail('context_unavailable');
    const now = () => (this.deps.now?.() ?? new Date()).getTime(), started = now();
    const before = await approvedWorkspacePreparationAuthority(this.deps.original, actor, input, started);
    const after = await approvedWorkspacePreparationAuthority(this.deps.original, actor, input, now());
    if (before.revision !== after.revision) return fail('stale_preparation', 409);
    const until = Math.min(started + 60_000, Date.parse(before.validUntil), Date.parse(after.validUntil));
    if (until <= now()) return fail('stale_preparation', 409);
    const revision = 'store-purchase-root-owner:' + digest([actor.projectId, actor.uid, input.scope.storeId, after.revision]);
    const tools: PreparationTool[] = [...storePurchaseRootActions].filter(action => input.actionId === null || action === input.actionId).map(actionId => {
      const search = actionId === 'AI-ACT-253';
      const validate = (fields: Readonly<Record<string, unknown>>) => search
        ? Object.keys(fields).length === 1 && typeof fields.query === 'string' && fields.query.length <= 2000 &&
          !/[\u0000-\u001f\u007f]/u.test(fields.query) && Buffer.from(fields.query, 'utf8').toString('utf8') === fields.query
        : Object.keys(fields).length === 0;
      return {name: search ? 'store_prepare_purchase_search' : 'store_review_purchase_controls', actionId, entityId: null, sourceRevision: revision,
        description: search ? 'Open the existing native Purchase register with only the supplied search query. The current account/Store saved bill book is read natively; no supplier or bill has been selected, read or verified here.'
          : 'Review the existing native Manage purchases controls. Native source readiness determines which actions are available. This tool does not select a supplier, create or confirm a bill, receive Stock, record money or perform any posting.',
        parameters: {type: 'object', properties: search ? {query: {type: 'string'}} : {}, required: search ? ['query'] : [], additionalProperties: false},
        validate, resolveTarget: args => {
          if (!validate(args)) return fail('invalid_model_result');
          return {entityId: null, sourceRevision: revision, fields: args, title: search ? 'Search purchase bills' : 'Manage purchases',
            summary: search ? 'Find a saved bill in your Store.' : 'Choose an available purchase action in your Store.'};
        }};
    });
    return {revision, validUntil: new Date(until).toISOString(), tools, modelContext: {audience: 'workspace', storeId: input.scope.storeId,
      sourceKind: 'native-purchase-root-owner-v1', purpose: 'Preparation permission only. No purchase records, supplier identities, invoice originals, tax decisions or ledger balances have been read. The original current native book, record selection and final confirmation remain required.'}};
  }
  private async readSupplierDrafts(actor: AccountProfileActor, input: PreparationRequest): Promise<PreparationContext> {
    if (!this.deps.original || !this.deps.nativeSupplierFormsEnabled || actor.tenantId !== undefined ||
        !actor.uid || !actor.projectId || input.scope.audience !== 'workspace' || !input.scope.storeId ||
        input.entityId !== null || input.catalogueListingIds !== undefined ||
        input.actionId !== null && !storeSupplierDraftActions.has(input.actionId)) return fail('context_unavailable');
    const now = () => (this.deps.now?.() ?? new Date()).getTime(), started = now();
    const before = await approvedWorkspacePreparationAuthority(this.deps.original, actor, input, started);
    const after = await approvedWorkspacePreparationAuthority(this.deps.original, actor, input, now());
    if (before.revision !== after.revision) return fail('stale_preparation', 409);
    const until = Math.min(started + 60_000, Date.parse(before.validUntil), Date.parse(after.validUntil));
    if (until <= now()) return fail('stale_preparation', 409);
    // This proves approved paid preparation ownership, never a supplier master,
    // saved directory, duplicate result or verified GST registration.
    const revision = 'store-supplier-draft-owner:' + digest([actor.projectId, actor.uid, input.scope.storeId, after.revision]);
    const clean = (value: unknown, max: number, multiline = false): value is string => typeof value === 'string' && value.length <= 2000 && value.trim().length <= max &&
      !(multiline ? /[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/u : /[\u0000-\u001f\u007f]/u).test(value) &&
      Buffer.from(value, 'utf8').toString('utf8') === value;
    const supplierFields = ['name', 'phone', 'address', 'gstin'];
    const validateAdd = (fields: Readonly<Record<string, unknown>>) =>
      Object.keys(fields).every(key => supplierFields.includes(key)) && clean(fields.name, 120) && fields.name.trim().length > 0 &&
      (!Object.hasOwn(fields, 'phone') || clean(fields.phone, 2000) &&
        (fields.phone.trim() === '' || /^\+?[0-9]{7,15}$/u.test(fields.phone.trim().replace(/[\s()-]/gu, '')))) &&
      (!Object.hasOwn(fields, 'address') || clean(fields.address, 500, true)) &&
      (!Object.hasOwn(fields, 'gstin') || clean(fields.gstin, 15) &&
        (fields.gstin.trim() === '' || /^[0-9A-Z]{15}$/u.test(fields.gstin.trim().toUpperCase())));
    const validateSearch = (fields: Readonly<Record<string, unknown>>) => Object.keys(fields).length === 1 && clean(fields.query, 2000);
    const tools: PreparationTool[] = [
      {name: 'store_prepare_supplier_draft', actionId: 'AI-ACT-235', entityId: null, sourceRevision: revision,
        description: 'Prepare only explicitly supplied supplier name, phone, billing address and GSTIN text in the existing unsaved Add supplier form. Ask for a missing name. Never invent supplier identity, contact, tax registration or duplicate status. Native review and final Save are required; this tool does not register a backend supplier or create a purchase.',
        parameters: {type: 'object', properties: {name: {type: 'string'}, phone: {type: ['string', 'null']},
          address: {type: ['string', 'null']}, gstin: {type: ['string', 'null']}}, required: supplierFields, additionalProperties: false},
        validate: validateAdd, resolveTarget: args => {
          if (Object.keys(args).length !== supplierFields.length || !supplierFields.every(key => Object.hasOwn(args, key))) return fail('invalid_model_result');
          const fields = Object.fromEntries(Object.entries(args).filter(([, value]) => value !== null));
          if (!validateAdd(fields)) return fail('invalid_model_result');
          return {entityId: null, sourceRevision: revision, fields, title: 'Review supplier details', summary: 'Check the supplied details before saving the supplier.'};
        }},
      {name: 'store_prepare_supplier_search', actionId: 'AI-ACT-236', entityId: null, sourceRevision: revision,
        description: 'Open the original current Store supplier search with the user-supplied query. The native directory is the sole source of results; no supplier is selected or inferred. No shared master, duplicate check or account balance is read here.',
        parameters: {type: 'object', properties: {query: {type: 'string'}}, required: ['query'], additionalProperties: false},
        validate: validateSearch, resolveTarget: args => {
          if (!validateSearch(args)) return fail('invalid_model_result');
          return {entityId: null, sourceRevision: revision, fields: args, title: 'Search suppliers', summary: 'Review matching suppliers in your Store.'};
        }},
    ];
    return {revision, validUntil: new Date(until).toISOString(), tools: tools.filter(tool => input.actionId === null || tool.actionId === input.actionId), modelContext: {audience: 'workspace',
      storeId: input.scope.storeId, sourceKind: 'native-supplier-draft-owner-v1',
      purpose: 'Unsaved user-supplied draft or query only. No supplier records, identities, GST verification or duplicate results have been read. The current account/Store native directory and final confirmation remain authoritative.'}};
  }
  private deliveryAddresses(input: PreparationRequest, original: PreparationContext): PreparationContext {
    if (!this.deps.nativeBuyerFormsEnabled || input.scope.audience !== 'personal' ||
        original.modelContext?.audience !== 'personal' || !Array.isArray(original.modelContext.deliveryChoices)) return fail('context_unavailable');
    const seen = new Set<string>();
    const choices = original.modelContext.deliveryChoices.map(raw => {
      const row = object(raw, ['id', 'label', 'area']), addressId = id(row.id);
      if (seen.has(addressId) || typeof row.label !== 'string' || typeof row.area !== 'string' ||
          !original.tools.some(tool => tool.actionId === 'AI-ACT-026' && tool.entityId === addressId && tool.sourceRevision === original.revision)) return fail('context_unavailable');
      seen.add(addressId); return {id: addressId, label: row.label, area: row.area};
    }).filter(row => input.entityId === null || row.id === input.entityId);
    const tools: PreparationTool[] = [];
    if (choices.length) for (const actionId of personalDeliveryAddressActions) {
      if (input.actionId !== null && input.actionId !== actionId) continue;
      const dynamic = input.entityId === null;
      tools.push({name: actionId === 'AI-ACT-024' ? 'buy_review_delivery_address' : 'buy_review_address_removal', actionId,
        entityId: input.entityId, sourceRevision: original.revision,
        description: actionId === 'AI-ACT-024' ? 'Review choosing my saved delivery address' : 'Review removing my saved delivery address',
        parameters: {type: 'object', properties: dynamic ? {addressId: {type: 'string', enum: choices.map(row => row.id)}} : {},
          required: dynamic ? ['addressId'] : [], additionalProperties: false},
        validate: fields => Object.keys(fields).length === 0,
        ...(dynamic ? {targetSelector: 'addressId', resolveTarget: (args: Readonly<Record<string, unknown>>) => {
          if (Object.keys(args).length !== 1) return fail('invalid_model_result');
          const choice = choices.find(row => row.id === args.addressId); if (!choice) return fail('invalid_model_result');
          return {entityId: choice.id, sourceRevision: original.revision, fields: {},
            title: actionId === 'AI-ACT-024' ? 'Review delivery address' : 'Review address removal', summary: [choice.label, choice.area].filter(Boolean).join(' · ')};
        }} : {})});
    }
    if (input.actionId !== null && !tools.length) return fail('context_unavailable');
    return {revision: 'buy-profile-addresses:' + digest([original.revision, choices]), validUntil: original.validUntil, tools,
      modelContext: {audience: 'personal', sourceKind: 'original-profile-delivery-choices-v1', deliveryChoices: choices,
        purpose: 'Account-owned saved address choices only. No street, phone, delivery availability or price is inferred. Original native review and removal confirmation own any change.'},
      nativeTargets: tools.flatMap(tool => choices.map(row => ({actionId: tool.actionId, entityId: row.id, sourceRevision: original.revision})))};
  }
  private async readDeliveryAddresses(actor: AccountProfileActor, input: PreparationRequest) {
    if (!this.deps.original || !this.deps.nativeBuyerFormsEnabled || input.scope.audience !== 'personal') return fail('context_unavailable');
    const original = await this.deps.original.read(actor, {...input, actionId: null, entityId: null});
    return this.deliveryAddresses(input, original);
  }
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
    if (storePurchaseRootActions.has(proposal.actionId)) {
      if (proposal.actionId !== input.actionId || proposal.entityId !== null || input.entityId !== null) return fail('stale_preparation', 409);
      const source = await this.readPurchaseRoots(actor, input);
      if (!source.tools.some(tool => tool.actionId === proposal.actionId && tool.sourceRevision === proposal.sourceRevision && tool.validate(proposal.fields))) return fail('stale_preparation', 409);
      return source;
    }
    if (storeSupplierDraftActions.has(proposal.actionId)) {
      if (proposal.actionId !== input.actionId || proposal.entityId !== null || input.entityId !== null) return fail('stale_preparation', 409);
      const source = await this.readSupplierDrafts(actor, input);
      if (!source.tools.some(tool => tool.actionId === proposal.actionId && tool.sourceRevision === proposal.sourceRevision && tool.validate(proposal.fields))) return fail('stale_preparation', 409);
      return source;
    }
    if(proposal.actionId==='AI-ACT-055'){
      if(!this.deps.privateStars)return fail('context_unavailable');
      return this.deps.privateStars.readPrepared(actor,input,proposal);
    }
    if (personalDeliveryAddressActions.has(proposal.actionId)) {
      if (input.actionId !== proposal.actionId || input.entityId !== proposal.entityId || Object.keys(proposal.fields).length !== 0) return fail('stale_preparation', 409);
      return this.readDeliveryAddresses(actor, input);
    }
    if(storeOrderOriginalActions.has(proposal.actionId)){
      if(!this.deps.storeOrders)return fail('context_unavailable');
      return this.deps.storeOrders.readPrepared(actor,input,proposal);
    }
    if(storeRestockOwnerActions.has(proposal.actionId)){
      if(!this.deps.catalogue)return fail('context_unavailable');
      return this.deps.catalogue.readPrepared(actor,input,proposal);
    }
    if (storeProductActions.has(proposal.actionId) || storeProductOwnerActions.has(proposal.actionId)||storeStockOwnerActions.has(proposal.actionId)) {
      if (!this.deps.storeProducts) return fail("context_unavailable");
      return this.deps.storeProducts.readPrepared(actor, input, proposal);
    }
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
      if (storePurchaseRootActions.has(input.actionId)) return this.readPurchaseRoots(actor, input);
      if (storeSupplierDraftActions.has(input.actionId)) return this.readSupplierDrafts(actor, input);
      if(input.actionId==='AI-ACT-055'){
        if(!this.deps.privateStars)return fail('context_unavailable');
        return this.deps.privateStars.read(actor,input);
      }
      if (personalDeliveryAddressActions.has(input.actionId)) return this.readDeliveryAddresses(actor, input);
      if(storeOrderOriginalActions.has(input.actionId)){
        if(!this.deps.storeOrders)return fail('context_unavailable');
        return this.deps.storeOrders.read(actor,input);
      }
      if(storeRestockOwnerActions.has(input.actionId)){
        if(!this.deps.catalogue)return fail('context_unavailable');
        return this.deps.catalogue.read(actor,input);
      }
      if (storeProductActions.has(input.actionId) || storeProductOwnerActions.has(input.actionId)||storeStockOwnerActions.has(input.actionId)) {
        if (!this.deps.storeProducts) return fail("context_unavailable");
        return this.deps.storeProducts.read(actor, input);
      }
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
      if (this.deps.nativeBuyerFormsEnabled && input.scope.audience === 'personal') values.push(this.deliveryAddresses(input, original));
      if (this.deps.nativePreferencesEnabled && input.scope.audience === "personal") values.push(this.preferences(actor, input, original));
    }
    if (this.deps.catalogue) {
      try {values.push(await this.deps.catalogue.read(actor, input));}
      catch (error) {
        // A missing optional catalogue must not remove established Profile
        // tools. Denied access, stale sources or malformed data still fail.
        if (!(error instanceof AssistantModelError) || error.code !== "context_unavailable" || !values.length) throw error;
      }
    }
    if (this.deps.storeProducts && input.scope.audience === "workspace") {
      try {values.push(await this.deps.storeProducts.read(actor, input));}
      catch (error) {
        if (!(error instanceof AssistantModelError) || error.code !== "context_unavailable" || !values.length) throw error;
      }
    }
    if (this.deps.nativeSupplierFormsEnabled && input.scope.audience === 'workspace' &&
        input.entityId === null && input.catalogueListingIds === undefined) {
      values.push(await this.readSupplierDrafts(actor, input));
    }
    if (this.deps.nativePurchaseFormsEnabled && input.scope.audience === 'workspace' &&
        input.entityId === null && input.catalogueListingIds === undefined) {
      values.push(await this.readPurchaseRoots(actor, input));
    }
    if (this.deps.storeOrders && input.scope.audience === 'workspace') {
      try {
        const orders=await this.deps.storeOrders.read(actor,input);
        const candidate=this.combine([...values,orders]);
        // Qualify the complete optional index against the existing wire
        // protocol. Never return a prefix or let it disable established tools.
        canonicalContextProjection(actor,input.scope,candidate,1);
        values.push(orders);
      }
      catch(error){
        if(!(error instanceof AssistantModelError)||error.code!=='context_unavailable'||!values.length)throw error;
      }
    }
    if(this.deps.privateStars&&input.scope.audience==='personal'){
      try{
        const stars=await this.deps.privateStars.read(actor,input);
        canonicalContextProjection(actor,input.scope,this.combine([...values,stars]));
        values.push(stars);
      }catch(error){
        if(!(error instanceof AssistantModelError)||error.code!=='context_unavailable'||!values.length)throw error;
      }
    }
    if (!values.length) return fail("context_unavailable");
    return this.combine(values);
  }
  private combine(values: PreparationContext[]): PreparationContext {
    if (values.length === 1) return values[0]!;
    return {revision: "composite:" + digest(values.map(v => v.revision)),
      validUntil: new Date(Math.min(...values.map(v => Date.parse(v.validUntil)))).toISOString(),
      tools: values.flatMap(v => v.tools), modelContext: {sourceKind: 'composite-original-context-v1', sources: values.map(v => v.modelContext ?? null)},
      ...(values.some(v => v.nativeTargets !== undefined) ? {nativeTargets: values.flatMap(v => v.nativeTargets ??
        v.tools.map(t => ({actionId: t.actionId, entityId: t.entityId, sourceRevision: t.sourceRevision})))} : {})};
  }
}
