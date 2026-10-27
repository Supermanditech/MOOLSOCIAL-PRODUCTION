import test from "node:test";
import assert from "node:assert/strict";
import {AccountPlansService} from "../account/plans_service.js";
import {CompositePreparationContext, OriginalCataloguePreparationContext} from "./domain_context.js";
import {AssistantModelError, type PreparationContext, type PreparationRequest} from "./model_contract.js";

const actor = {uid: "domain-host-a", projectId: "domain-host-project"};
const at = new Date("2026-10-28T08:00:00.000Z");
const scope = {audience: "personal" as const, storeId: null};
const request: PreparationRequest = {scope, requestId: "host-request", requestRevision: 1,
  message: "Find rice", language: "English", history: [], actionId: "AI-ACT-001", entityId: null,
  expectedEntitlementRevision: "personal:null:1:1"};
/** Original Plans class, explicit isolated host subscription and catalogue seams. */
function fixture() {
  let state = "active", revision = 1, reads = 0, clock = new Date(at), change = false, unavailable = false;
  let mutate = (value: Record<string, unknown>) => value;
  let familyReply = (_body: Readonly<Record<string, unknown>>): object => ({state: "unavailable"});
  const familyCalls: Readonly<Record<string, unknown>>[] = [];
  const calls: Readonly<Record<string, unknown>>[] = [];
  const plans = new AccountPlansService({async read(uid, selected) {return {ownerUid: uid, accountStatus: "ACTIVE",
    catalogue: {audience: selected.audience, revision: 1, state: "approved", offers: []},
    subscription: {ownerUid: uid, scope: selected, revision, planId: "host-only", planVersion: "v1", name: "Host-only source",
      state, validFrom: "2026-10-27T00:00:00.000Z", validUntil: "2026-10-29T00:00:00.000Z", featureIds: ["mool_ai"]}};}},
  {projectId: actor.projectId, now: () => clock});
  const catalogue = {async publicDiscovery(body: Readonly<Record<string, unknown>>) {
    reads++; calls.push(body); if (unavailable) throw Error("Private provider failure not for the model");
    return mutate({schemaVersion: 1, realm: "evaluation", discoveryPageVersion: 1, supplierPublishersVersion: 1,
      state: "ready", coverage: "verified_public_only", directoryCoverage: "complete_bounded", orderingAvailable: false,
      observedAt: at.toISOString(), query: body.query, items: [], privateRawSource: "must-not-enter-context",
      page: {snapshotId: (change && reads > 2 ? "b" : "a").repeat(64), startIndex: 0, totalCount: 0, nextCursor: null}});
  }, async publicVariantFamilies(body: Readonly<Record<string, unknown>>) {familyCalls.push(body); return familyReply(body);}};
  return {context: new OriginalCataloguePreparationContext({projectId: actor.projectId, plans, catalogue, now: () => clock}),
    calls, familyCalls, family: (fn: typeof familyReply) => {familyReply = fn;}, reads: () => reads, deny: () => {state = "revoked";}, change: () => {change = true;},
    unavailable: () => {unavailable = true;}, mutate: (fn: typeof mutate) => {mutate = fn;},
    advance: (ms: number) => {clock = new Date(clock.getTime() + ms);}, bump: () => {revision++;}};
}
test("Domain search uses current paid authority and original public snapshots only", async () => {
  const f = fixture(), c = await f.context.read(actor, request);
  assert.equal(f.reads(), 4); assert.deepEqual(c.tools.map(t => t.actionId), ["AI-ACT-001"]);
  assert.equal(c.tools[0]!.entityId, null); assert.ok(c.tools[0]!.sourceRevision.startsWith("catalogue-search:"));
  assert.deepEqual(c.tools[0]!.decodeFields!({query: " rice  5kg "}), {query: "rice 5kg"});
  assert.equal(c.tools[0]!.validate({query: "rice", owner: "other"}), false);
  assert.ok(!JSON.stringify(c.modelContext).includes("must-not-enter-context"));
  assert.deepEqual(f.calls.map(v => (v.query as {destination: string}).destination), ["shop", "wholesale", "shop", "wholesale"]);
});
test("Domain search refuses unpaid, foreign, tenant and unsupported Store context before reading catalogue", async () => {
  const f = fixture(); f.deny(); await assert.rejects(f.context.read(actor, request)); assert.equal(f.reads(), 0);
  for (const who of [{...actor, projectId: "foreign-project"}, {...actor, tenantId: "foreign-tenant"}]) {
    const next = fixture(); await assert.rejects(next.context.read(who, request)); assert.equal(next.reads(), 0);
  }
  const next = fixture(); await assert.rejects(next.context.read(actor, {...request, scope: {audience: "workspace", storeId: "store-a"}}));
  assert.equal(next.reads(), 0);
});
test("Domain search rejects a guessed entity or unregistered action", async () => {
  for (const input of [{...request, entityId: "guessed-product"}, {...request, actionId: "AI-ACT-235"}]) {
    const f = fixture(); await assert.rejects(f.context.read(actor, input)); assert.equal(f.reads(), 0);
  }
});
test("Domain source changes across awaits retire preparation", async () => {
  const f = fixture(); f.change(); await assert.rejects(f.context.read(actor, request), /stale_preparation/u);
});
test("Domain catalogue failures and incomplete or stale original evidence never become zero stock", async () => {
  const failure = fixture(); failure.unavailable(); await assert.rejects(failure.context.read(actor, request), /context_unavailable/u);
  for (const mutate of [(v: Record<string, unknown>) => ({...v, coverage: "demo"}),
    (v: Record<string, unknown>) => ({...v, directoryCoverage: "partial"}),
    (v: Record<string, unknown>) => ({...v, orderingAvailable: true}),
    (v: Record<string, unknown>) => ({...v, observedAt: "2026-10-27T08:00:00.000Z"}),
    (v: Record<string, unknown>) => ({...v, page: {snapshotId: "bad", startIndex: 0, totalCount: 0}})]) {
    const f = fixture(); f.mutate(mutate); await assert.rejects(f.context.read(actor, request));
  }
});
test("Domain paid access is rechecked after catalogue awaits", async () => {
  const f = fixture(); f.mutate(v => {if (f.reads() === 4) f.deny(); return v;});
  await assert.rejects(f.context.read(actor, request));
});
test("Domain composite preserves original Profile and separately selects exact domain actions", async () => {
  const f = fixture(); let originalReads = 0;
  const original = {async read(): Promise<PreparationContext> {originalReads++; return {revision: "profile:3",
    validUntil: "2026-10-28T08:00:30.000Z", tools: [], modelContext: {audience: "personal"}};}};
  const source = new CompositePreparationContext({original, catalogue: f.context});
  assert.equal((await source.read(actor, {...request, actionId: "AI-ACT-197"})).revision, "profile:3");
  assert.equal(originalReads, 1); assert.equal(f.reads(), 0);
  assert.equal((await source.read(actor, request)).tools[0]!.actionId, "AI-ACT-001"); assert.equal(originalReads, 1);
  const merged = await source.read(actor, {...request, actionId: null});
  assert.ok(merged.revision.startsWith("composite:")); assert.equal(merged.validUntil, "2026-10-28T08:00:30.000Z");
});
test("Domain composite missing optional catalogue does not remove established Profile tools", async () => {
  const f = fixture(); f.unavailable();
  const original = {async read(): Promise<PreparationContext> {return {revision: "profile:3", validUntil: "2026-10-28T08:01:00.000Z", tools: []};}};
  const c = new CompositePreparationContext({original, catalogue: f.context});
  assert.equal((await c.read(actor, {...request, actionId: null})).revision, "profile:3");
  await assert.rejects(c.read(actor, request));
  const denied = new CompositePreparationContext({original: {async read() {throw new AssistantModelError("ai_access_required", 403);}}, catalogue: f.context});
  await assert.rejects(denied.read(actor, {...request, actionId: null}), /ai_access_required/u);
});

const originalListingId = (n: number) => "listing-" + n.toString(16).padStart(64, "0");
function populatedFixture(count = 2, channel = "retail", contactReady = false) {
  const f = fixture(), ids = Array.from({length: count}, (_, n) => originalListingId(n + 1));
  f.mutate(data => {
    const query = data.query as {listingIds: string[]; destination: string; categoryId: string; tradeType: string | null};
    const matches = query.destination === (channel === "retail" ? "shop" : "wholesale") &&
      ["all", "grocery"].includes(query.categoryId) && (query.tradeType === null || query.tradeType === channel);
    const selected = matches ? query.listingIds.length ? query.listingIds : ids.slice(0, 1) : [];
    return {...data, items: selected.map(listingId => ({channel, listing: {storeId: "original-store", realm: "evaluation",
      publicStore: {id: "original-store", name: "Original supplier", ...(contactReady ? {details: {
        schemaVersion: 1, realm: "evaluation", storeId: "original-store", state: "ready", revision: 1,
        details: {publicContactPhone: "+919000000000"}}} : {})},
      items: [{skuId: listingId, canonicalProductId: "canonical-rice", verifiedPackId: "verified-pack", content: {title: "Original rice", brand: "Original brand", variant: "", categoryId: "grocery", description: "Untrusted text must stay out", productFacts: {requiresPrescription: false}},
        pack: {label: "5 kg", quantityMilli: 5000, unit: "kg", unitsPerCase: 1},
        channels: [{kind: channel, priceMinor: 10000, mrpMinor: 12000, minimumOrder: 1, quantityStep: 1,
          revision: "original-term", validUntil: "2026-10-28T09:00:00.000Z", supplierTax: {version: 2, rateBasisPoints: 1800, basis: "included"}}],
        listings: [{schemaVersion: 1, realm: "evaluation", listingId, storeId: "original-store", skuId: listingId,
          canonicalProductId: "canonical-rice", verifiedPackId: "verified-pack", channel}]}]}})),
      page: {...data.page as object, totalCount: matches && !query.listingIds.length ? count : selected.length}};
  });
  return {...f, ids};
}
test("Original listing selector maps public record to exact native entity without descriptive instructions", async () => {
  const f = populatedFixture(), c = await f.context.read(actor, {...request, actionId: null, catalogueListingIds: f.ids});
  const tool = c.tools.find(t => t.actionId === "AI-ACT-006")!;
  const result = tool.resolveTarget!({listingId: f.ids[1]});
  assert.equal(result.entityId, f.ids[1]); assert.deepEqual(result.fields, {});
  assert.ok(c.nativeTargets!.some(t => t.entityId === f.ids[1] && t.sourceRevision === result.sourceRevision));
  assert.ok(!JSON.stringify(c.modelContext).includes("Untrusted text"));
  assert.throws(() => tool.resolveTarget!({listingId: originalListingId(99)}));
  assert.throws(() => tool.resolveTarget!({listingId: f.ids[0], owner: "foreign"}));
  const recovered = await f.context.read(actor, {...request, actionId: "AI-ACT-006", entityId: f.ids[1]!});
  assert.equal(recovered.tools.length, 1); assert.equal(recovered.tools[0]!.entityId, result.entityId);
  assert.equal(recovered.tools[0]!.sourceRevision, result.sourceRevision);
  assert.equal(recovered.tools[0]!.validate({}), true);
});
test("Original listing reads batch 201 products within original 50-ID source bound", async () => {
  const f = populatedFixture(201), c = await f.context.read(actor, {...request, actionId: "AI-ACT-006", catalogueListingIds: f.ids});
  assert.equal(c.tools.length, 1); assert.equal(c.nativeTargets!.length, 201);
  assert.equal(f.calls.length, 14);
  assert.ok(f.calls.every(call => ((call.query as {listingIds: string[]}).listingIds.length <= 50)));
});

test("Product preference link and Store-search proposals retain the original listing and native confirmation", async () => {
  const f = populatedFixture(), input = {...request, actionId: null, catalogueListingIds: f.ids};
  const context = await f.context.read(actor, input);
  for (const action of ["AI-ACT-009", "AI-ACT-336", "AI-ACT-337", "AI-ACT-338"]) {
    const tool = context.tools.find(value => value.actionId === action)!;
    assert.ok(tool); assert.equal(tool.targetSelector, "listingId");
    const fields = action === "AI-ACT-009" ? {saved: true} : action === "AI-ACT-338" ? {query: " rice  pack "} : {};
    const result = tool.resolveTarget!({listingId: f.ids[1], ...fields});
    assert.equal(result.entityId, f.ids[1]);
    assert.deepEqual(result.fields, action === "AI-ACT-338" ? {query: "rice pack"} : fields);
    assert.ok(context.nativeTargets!.some(value => value.actionId === action && value.entityId === f.ids[1] && value.sourceRevision === result.sourceRevision));
    assert.throws(() => tool.resolveTarget!({listingId: originalListingId(99), ...fields}));
    assert.throws(() => tool.resolveTarget!({listingId: f.ids[1], ...fields, execute: true}));
    const recovery = await f.context.read(actor, {...request, actionId: action, entityId: f.ids[1]!});
    assert.equal(recovery.tools.length, 1);
    assert.equal(recovery.tools[0]!.sourceRevision, result.sourceRevision);
    assert.equal(recovery.tools[0]!.validate(result.fields), true);
    assert.equal(recovery.tools[0]!.validate({...result.fields, listingId: f.ids[0]}), false);
  }
  assert.equal(context.tools.some(value => value.actionId === "AI-ACT-339"), false);
  assert.equal(context.tools.some(value => value.actionId === "AI-ACT-008"), false);
  await assert.rejects(f.context.read(actor, {...request, actionId: "AI-ACT-339", entityId: f.ids[0]!}), /context_unavailable/u);
});

test("Supplier contact prepares only a ready original public contact and never copies its phone into model context", async () => {
  const f = populatedFixture(1, "retail", true), input = {...request, actionId: "AI-ACT-339", entityId: f.ids[0]!};
  const context = await f.context.read(actor, input);
  assert.equal(context.tools.length, 1);
  assert.equal(context.tools[0]!.actionId, "AI-ACT-339");
  assert.equal(context.tools[0]!.validate({}), true);
  assert.equal(context.tools[0]!.validate({phone: "+919000000000"}), false);
  assert.equal(JSON.stringify(context.modelContext).includes("9000000000"), false);
  assert.equal((context.modelContext as {products: {supplier: {contactAvailable: boolean}}[]}).products[0]!.supplier.contactAvailable, true);
});
test("Missing original listing cannot turn a model selector into an invented product", async () => {
  const f = fixture();
  await assert.rejects(f.context.read(actor, {...request, actionId: "AI-ACT-006", catalogueListingIds: [originalListingId(1)]}), /context_unavailable/u);
});
test("Withdrawn listing disables record actions but preserves independent original search recovery", async () => {
  const f = fixture(), missing = originalListingId(1);
  const context = await f.context.read(actor, {...request, actionId: null, catalogueListingIds: [missing]});
  assert.deepEqual(context.tools.map(tool => tool.actionId), ["AI-ACT-001", "AI-ACT-005"]);
  assert.deepEqual(context.modelContext!.unavailableListingIds, [missing]);
  assert.deepEqual(context.modelContext!.products, []);
  await assert.rejects(f.context.read(actor, {...request, actionId: "AI-ACT-006", entityId: missing}), /context_unavailable/u);
});
test("Category choices come only from original selected records; area search grants no delivery eligibility", async () => {
  const f = populatedFixture(), c = await f.context.read(actor, {...request, actionId: null, catalogueListingIds: f.ids});
  const category = c.tools.find(tool => tool.actionId === "AI-ACT-002")!;
  assert.equal(category.validate({categoryId: "grocery"}), true);
  assert.equal(category.validate({categoryId: "invented-category"}), false);
  assert.equal(category.validate({categoryId: "grocery", storeId: "foreign"}), false);
  assert.equal(c.tools.some(tool => tool.actionId === "AI-ACT-004"), false);
  assert.ok(c.nativeTargets!.some(target => target.actionId === category.actionId && target.sourceRevision === category.sourceRevision));
  const area = c.tools.find(tool => tool.actionId === "AI-ACT-005")!;
  assert.deepEqual(area.decodeFields!({query: " Jaipur "}), {query: "Jaipur"});
  assert.equal(area.validate({query: "Jaipur", deliveryAvailable: true}), false);
});
test("Trade channel selector preserves the original Wholesale/Bulk listing channel", async () => {
  for (const channel of ["wholesale", "bulk"]) {
    const f = populatedFixture(2, channel), c = await f.context.read(actor, {...request, actionId: "AI-ACT-004", catalogueListingIds: f.ids});
    assert.equal(c.tools.length, 1); assert.equal(c.tools[0]!.validate({saleType: channel}), true);
    assert.equal(c.tools[0]!.validate({saleType: channel === "bulk" ? "wholesale" : "bulk"}), false);
    assert.equal(c.tools[0]!.validate({saleType: "retail"}), false);
  }
});
test("Stored category and trade choices re-read originals without persisting the old listing selection", async () => {
  for (const action of ["AI-ACT-002", "AI-ACT-004"]) {
    const f = populatedFixture(2, "wholesale");
    const c = await f.context.read(actor, {...request, actionId: action, catalogueListingIds: f.ids});
    assert.equal(c.tools.length, 1);
    const tool = c.tools[0]!;
    const fields = action === "AI-ACT-002" ? {categoryId: "grocery"} : {saleType: "wholesale"};
    const proposal = {kind: "proposal" as const, id: "host-stored-proposal", actionId: action, entityId: null,
      sourceRevision: tool.sourceRevision, title: tool.description, summary: "Host original choice", fields};
    const source = new CompositePreparationContext({catalogue: f.context});
    const recovered = await source.readPrepared(actor, {...request, actionId: action}, proposal);
    assert.equal(recovered.tools.length, 1); assert.equal(recovered.tools[0]!.sourceRevision, tool.sourceRevision);
    assert.equal(recovered.tools[0]!.validate(fields), true);
    const invalid = {...proposal, fields: action === "AI-ACT-002" ? {categoryId: "invented"} : {saleType: "bulk"}};
    await assert.rejects(source.readPrepared(actor, {...request, actionId: action}, invalid));
    f.deny();
    await assert.rejects(source.readPrepared(actor, {...request, actionId: action}, proposal), /ai_access_required/u);
  }
});
test("Filter preparation applies only requested native fields and preserves unrelated native choices", async () => {
  const f = populatedFixture(), c = await f.context.read(actor, {...request, actionId: "AI-ACT-003", catalogueListingIds: f.ids});
  const tool = c.tools[0]!, args = {apply: ["sort"], brands: [], maximumPrice: null, pack: null,
    sort: "priceLowToHigh", availableOnly: false};
  const result = tool.resolveTarget!(args);
  assert.deepEqual(result.fields, {sort: "priceLowToHigh"});
  assert.equal(tool.validate({brands: ["Invented brand"]}), false);
  assert.equal(tool.validate({maximumPrice: 2000}), false);
  assert.equal(tool.validate({pack: "bulk"}), false);
  assert.equal(tool.validate({sort: "deliveryFastest"}), false);
  assert.throws(() => tool.resolveTarget!({...args, apply: ["brands"], brands: ["Invented brand"]}));
  assert.throws(() => tool.resolveTarget!({...args, apply: ["sort", "sort"]}));
  const clear = tool.resolveTarget!({...args, apply: ["maximumPrice"], maximumPrice: null});
  assert.deepEqual(clear.fields, {maximumPrice: null});
  const proposal = {kind: "proposal" as const, id: "host-stored-filter", actionId: tool.actionId, entityId: null,
    sourceRevision: result.sourceRevision, title: tool.description, summary: "Host original filters", fields: result.fields};
  const recovered = await new CompositePreparationContext({catalogue: f.context}).readPrepared(actor, {...request, actionId: tool.actionId}, proposal);
  assert.equal(recovered.tools[0]!.sourceRevision, proposal.sourceRevision);
  assert.equal(recovered.tools[0]!.validate(proposal.fields), true);
  assert.equal(recovered.tools[0]!.validate({sort: "relevance"}), false);
});
function reviewedFamilyFixture() {
  const f = populatedFixture(2), sourceId = "store-reviewed-variants:evaluation:original-store";
  let mutate = (value: Record<string, unknown>) => value;
  const membership = (listingId: string, index: number) => ({listing: {schemaVersion: 1, realm: "evaluation",
    listingId, storeId: "original-store", skuId: listingId, channel: "retail",
    canonicalProductId: "canonical-rice", verifiedPackId: "verified-pack"}, skuRevision: 1,
    familyId: "original-family", sourceId, revision: 2, attributes: [{dimensionId: "colour", dimensionLabel: "Colour",
      optionId: index ? "brown" : "white", optionLabel: index ? "Brown" : "White", kind: "colour", swatchArgb: null}]});
  f.family(body => mutate({schemaVersion: 1, state: "ready", realm: "evaluation", storeId: "original-store", orderingAvailable: false,
    sourceId, revision: 2, observedAt: at.toISOString(), validUntil: "2026-10-28T08:00:30.000Z",
    memberships: [membership(f.ids[0]!, 0)],
    family: body.familyId === undefined ? null : {familyId: "original-family", products: f.ids.map((listingId, index) => ({
      product: {skuId: listingId, revision: 1, canonicalProductId: "canonical-rice", verifiedPackId: "verified-pack",
        content: {title: "Original rice", variant: index ? "Brown" : "White", productFacts: {requiresPrescription: false}}, pack: {label: "5 kg"}},
      membership: membership(listingId, index)}))}}));
  return {...f, mutateFamily: (fn: typeof mutate) => {mutate = fn;}};
}
test("Reviewed variant family selects only an original same-channel member and preserves printed option labels", async () => {
  const f = reviewedFamilyFixture(), input = {...request, actionId: "AI-ACT-007", catalogueListingIds: [f.ids[0]!]};
  const c = await f.context.read(actor, input), tool = c.tools[0]!;
  const target = tool.resolveTarget!({listingId: f.ids[0], variantId: f.ids[1]});
  assert.equal(target.entityId, f.ids[0]); assert.deepEqual(target.fields, {variantId: f.ids[1]});
  assert.equal(c.validUntil, "2026-10-28T08:00:30.000Z");
  assert.equal(f.familyCalls.length, 2);
  assert.ok(JSON.stringify(c.modelContext).includes('"value":"Brown"'));
  assert.throws(() => tool.resolveTarget!({listingId: f.ids[0], variantId: originalListingId(99)}));
  assert.throws(() => tool.resolveTarget!({listingId: f.ids[1], variantId: f.ids[0]}));
  const recovered = await f.context.readPrepared(actor, {...request, actionId: "AI-ACT-007", entityId: f.ids[0]!}, {
    kind: "proposal", id: "original-stored-variant", actionId: "AI-ACT-007", entityId: f.ids[0]!,
    sourceRevision: target.sourceRevision, title: "Original variant", summary: "Host fixture only", fields: target.fields});
  assert.equal(recovered.tools[0]!.entityId, f.ids[0]);
  assert.equal(recovered.tools[0]!.sourceRevision, target.sourceRevision);
  assert.equal(recovered.tools[0]!.validate(target.fields), true);
  assert.equal(recovered.tools[0]!.validate({variantId: originalListingId(99)}), false);
});
test("Missing expired duplicate cross-Store or prescription family does not fabricate a variant or remove product review", async () => {
  for (const kind of ["missing", "expired", "duplicate", "foreign", "prescription"]) {
    const f = reviewedFamilyFixture();
    f.mutateFamily(data => {
      if (kind === "missing") return {...data, state: "unavailable"};
      if (kind === "expired") return {...data, validUntil: "2026-10-28T07:59:00.000Z"};
      if (!data.family) return data;
      const family = data.family as {products: Array<{product: {content: {productFacts: {requiresPrescription: boolean}}}; membership: {listing: {storeId: string}}}>};
      if (kind === "duplicate") family.products.push(structuredClone(family.products[0]!));
      if (kind === "foreign") family.products[1]!.membership.listing.storeId = "foreign-store";
      if (kind === "prescription") family.products[1]!.product.content.productFacts.requiresPrescription = true;
      return data;
    });
    const input = {...request, actionId: null, catalogueListingIds: [f.ids[0]!]};
    const c = await f.context.read(actor, input);
    assert.equal(c.tools.some(tool => tool.actionId === "AI-ACT-007"), false, kind);
    assert.equal(c.tools.some(tool => tool.actionId === "AI-ACT-006"), true, kind);
    await assert.rejects(f.context.read(actor, {...input, actionId: "AI-ACT-007"}), /context_unavailable/u);
  }
});
