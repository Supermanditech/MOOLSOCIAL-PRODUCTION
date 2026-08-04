import assert from "node:assert/strict";
import test from "node:test";

import {
  CatalogueContractError,
  applyCatalogueCommand,
  createCatalogueAggregate,
  matchCanonicalProductByCode,
  matchVerifiedPackByCode,
  normalizeCatalogueCode,
  referencedOfferTermAt,
  type CatalogueAggregate,
  type CatalogueCodeReference,
  type CatalogueContractErrorCode,
} from "./catalogue_contract.js";
import {
  applySupplyParticipantCommand,
  registerSupplyParticipantWorkspace,
  type SupplyCapabilityKind,
  type SupplyParticipantWorkspace,
} from "./supply_participant_contract.js";

const HASH_A = "A".repeat(64);
const HASH_B = "B".repeat(64);
const HASH_C = "C".repeat(64);
const PRODUCT_CODE = { type: "ean", value: "4006381333931" } as const;
const SECOND_PRODUCT_CODE = { type: "ean", value: "5901234123457" } as const;
const PACK_CODE = { type: "upc", value: "036000291452" } as const;

const workspaceActor = {
  actorId: "user.workspace-001",
  tenantId: "tenant.india-001",
  workspaceId: "workspace.seller-001",
  scopes: ["supply.workspace.admin"],
} as const;

const capabilityReviewer = {
  actorId: "user.capability-reviewer-001",
  tenantId: "tenant.india-001",
  scopes: ["supply.capability.review"],
} as const;

const catalogueReviewer = {
  actorId: "user.catalogue-reviewer-001",
  tenantId: "tenant.india-001",
  scopes: ["supply.catalogue.review"],
} as const;

function expectCode(
  callback: () => unknown,
  code: CatalogueContractErrorCode,
): void {
  assert.throws(
    callback,
    (error: unknown) =>
      error instanceof CatalogueContractError && error.code === code,
  );
}

function supplyWorkspace(
  capabilities: readonly SupplyCapabilityKind[] = [
    "product_master_stewardship",
  ],
): SupplyParticipantWorkspace {
  let workspace = registerSupplyParticipantWorkspace({
    commandId: "command.workspace-register-001",
    occurredAt: "2026-08-03T00:00:00.000Z",
    workspaceId: "workspace.seller-001",
    tenantId: "tenant.india-001",
    legalEntityReference: "entity.seller-001",
    participantType: "manufacturer",
    actor: workspaceActor,
  });
  for (const [index, capability] of capabilities.entries()) {
    workspace = applySupplyParticipantCommand(workspace, {
      type: "request_capability",
      commandId: `command.capability-request-${capability}`,
      workspaceId: workspace.workspaceId,
      expectedVersion: workspace.version,
      occurredAt: `2026-08-03T00:0${index + 1}:00.000Z`,
      actor: workspaceActor,
      capability,
      evidence: [{ kind: "identity", sha256: HASH_A }],
      qualifiers:
        capability === "product_master_stewardship"
          ? { categoryIds: ["category.fmcg"], serviceAreaIds: [] }
          : {
              categoryIds: ["category.fmcg"],
              serviceAreaIds: ["area.342001"],
            },
    });
    workspace = applySupplyParticipantCommand(workspace, {
      type: "review_capability",
      commandId: `command.capability-verify-${capability}`,
      workspaceId: workspace.workspaceId,
      expectedVersion: workspace.version,
      occurredAt: `2026-08-03T00:1${index}:00.000Z`,
      actor: capabilityReviewer,
      capability,
      decision: "verify",
      reason: "Governed capability evidence passed.",
      effectiveFrom: "2026-08-03T00:00:00.000Z",
      expiresAt: "2026-09-03T00:00:00.000Z",
    });
  }
  return workspace;
}

function emptyCatalogue(): CatalogueAggregate {
  return createCatalogueAggregate({
    commandId: "command.catalogue-create-001",
    catalogueId: "catalogue.india-001",
    tenantId: "tenant.india-001",
    occurredAt: "2026-08-03T01:00:00.000Z",
    actor: catalogueReviewer,
  });
}

function proposeProduct(
  catalogue: CatalogueAggregate,
  workspace: SupplyParticipantWorkspace,
  productId = "product.oil-001",
  code: CatalogueCodeReference = PRODUCT_CODE,
): CatalogueAggregate {
  return applyCatalogueCommand(
    catalogue,
    {
      type: "propose_product",
      commandId: `command.propose-${productId}`,
      catalogueId: catalogue.catalogueId,
      expectedVersion: catalogue.version,
      occurredAt: "2026-08-03T02:00:00.000Z",
      actor: workspaceActor,
      productId,
      categoryId: "category.fmcg",
      brandId: "brand.verified-001",
      contentSha256: HASH_A,
      codes: [code],
    },
    workspace,
  );
}

function reviewProduct(
  catalogue: CatalogueAggregate,
  productId = "product.oil-001",
): CatalogueAggregate {
  return applyCatalogueCommand(catalogue, {
    type: "review_product",
    commandId: `command.verify-${productId}`,
    catalogueId: catalogue.catalogueId,
    expectedVersion: catalogue.version,
    occurredAt: "2026-08-03T02:01:00.000Z",
    actor: catalogueReviewer,
    productId,
    decision: "verify",
    reasonCode: "catalogue.evidence_passed",
  });
}

function verifiedProduct(
  workspace = supplyWorkspace(),
): { catalogue: CatalogueAggregate; workspace: SupplyParticipantWorkspace } {
  return {
    catalogue: reviewProduct(proposeProduct(emptyCatalogue(), workspace)),
    workspace,
  };
}

function proposePack(
  catalogue: CatalogueAggregate,
  workspace: SupplyParticipantWorkspace,
  packId = "pack.oil-001",
): CatalogueAggregate {
  return applyCatalogueCommand(
    catalogue,
    {
      type: "propose_pack",
      commandId: `command.propose-${packId}`,
      catalogueId: catalogue.catalogueId,
      expectedVersion: catalogue.version,
      occurredAt: "2026-08-03T02:02:00.000Z",
      actor: workspaceActor,
      packId,
      productId: "product.oil-001",
      descriptorSha256: HASH_B,
      codes: [PACK_CODE],
    },
    workspace,
  );
}

function reviewPack(
  catalogue: CatalogueAggregate,
  packId = "pack.oil-001",
): CatalogueAggregate {
  return applyCatalogueCommand(catalogue, {
    type: "review_pack",
    commandId: `command.verify-${packId}`,
    catalogueId: catalogue.catalogueId,
    expectedVersion: catalogue.version,
    occurredAt: "2026-08-03T02:03:00.000Z",
    actor: catalogueReviewer,
    packId,
    decision: "verify",
    reasonCode: "pack.evidence_passed",
  });
}

function verifiedPack(
  workspace = supplyWorkspace([
    "product_master_stewardship",
    "wholesale_supply",
  ]),
): { catalogue: CatalogueAggregate; workspace: SupplyParticipantWorkspace } {
  const product = verifiedProduct(workspace);
  return {
    catalogue: reviewPack(proposePack(product.catalogue, workspace)),
    workspace,
  };
}

function createWholesaleOffer(
  catalogue: CatalogueAggregate,
  workspace: SupplyParticipantWorkspace,
  expiresAt = "2026-08-10T00:00:00.000Z",
): CatalogueAggregate {
  return applyCatalogueCommand(
    catalogue,
    {
      type: "create_offer",
      commandId: "command.offer-wholesale-001",
      catalogueId: catalogue.catalogueId,
      expectedVersion: catalogue.version,
      occurredAt: "2026-08-03T02:04:00.000Z",
      actor: workspaceActor,
      offerId: "offer.wholesale-001",
      packId: "pack.oil-001",
      buyingContext: "wholesale",
      serviceAreaIds: ["area.342001"],
      termWindows: [
        {
          termSnapshotId: "terms.wholesale-001",
          termSnapshotSha256: HASH_C,
          effectiveFrom: "2026-08-03T03:00:00.000Z",
          expiresAt,
        },
      ],
    },
    workspace,
  );
}

test("catalogue creation requires governance and starts empty", () => {
  const catalogue = emptyCatalogue();
  assert.equal(catalogue.version, 1);
  assert.deepEqual(catalogue.products, []);
  assert.equal(catalogue.commandReceipts.length, 1);
  assert.equal(Object.isFrozen(catalogue), true);
  expectCode(
    () =>
      createCatalogueAggregate({
        commandId: "command.catalogue-create-002",
        catalogueId: "catalogue.india-002",
        tenantId: "tenant.india-001",
        occurredAt: "2026-08-03T01:00:00.000Z",
        actor: workspaceActor,
      }),
    "unauthorized",
  );
});

test("GS1 and governed catalogue codes normalize and invalid check digits fail", () => {
  assert.deepEqual(normalizeCatalogueCode(PRODUCT_CODE), PRODUCT_CODE);
  assert.deepEqual(normalizeCatalogueCode({ type: "internal", value: " sku-01 " }), {
    type: "internal",
    value: "SKU-01",
  });
  expectCode(
    () => normalizeCatalogueCode({ type: "ean", value: "4006381333932" }),
    "invalid_input",
  );
});

test("product proposal requires active category-scoped product stewardship", () => {
  const unverified = supplyWorkspace([]);
  expectCode(
    () => proposeProduct(emptyCatalogue(), unverified),
    "capability_inactive",
  );
  const workspace = supplyWorkspace();
  const proposed = proposeProduct(emptyCatalogue(), workspace);
  assert.equal(proposed.products[0]?.state, "pending_review");
  assert.equal(
    matchCanonicalProductByCode(proposed, PRODUCT_CODE).kind,
    "exact",
  );
});

test("product verification is independent from participant proposal", () => {
  const workspace = supplyWorkspace();
  const proposed = proposeProduct(emptyCatalogue(), workspace);
  const verified = reviewProduct(proposed);
  assert.equal(verified.products[0]?.state, "verified");
  assert.equal(verified.products[0]?.reviewedBy, catalogueReviewer.actorId);
  expectCode(
    () =>
      applyCatalogueCommand(verified, {
        type: "review_product",
        commandId: "command.reverify-product.oil-001",
        catalogueId: verified.catalogueId,
        expectedVersion: verified.version,
        occurredAt: "2026-08-03T02:02:00.000Z",
        actor: catalogueReviewer,
        productId: "product.oil-001",
        decision: "verify",
        reasonCode: "catalogue.second_review",
      }),
    "invalid_transition",
  );
});

test("duplicate product codes stay ambiguous until governed merge", () => {
  const workspace = supplyWorkspace();
  let catalogue = proposeProduct(emptyCatalogue(), workspace);
  catalogue = reviewProduct(catalogue);
  catalogue = proposeProduct(
    catalogue,
    workspace,
    "product.oil-duplicate",
    PRODUCT_CODE,
  );
  const match = matchCanonicalProductByCode(catalogue, PRODUCT_CODE);
  assert.equal(match.kind, "ambiguous");
  expectCode(
    () => reviewProduct(catalogue, "product.oil-duplicate"),
    "duplicate_candidate",
  );
  catalogue = applyCatalogueCommand(catalogue, {
    type: "open_duplicate_dispute",
    commandId: "command.dispute-open-001",
    catalogueId: catalogue.catalogueId,
    expectedVersion: catalogue.version,
    occurredAt: "2026-08-03T02:05:00.000Z",
    actor: catalogueReviewer,
    disputeId: "dispute.product-001",
    leftProductId: "product.oil-duplicate",
    rightProductId: "product.oil-001",
    reasonCode: "duplicate.code_collision",
  });
  catalogue = applyCatalogueCommand(catalogue, {
    type: "resolve_duplicate_dispute",
    commandId: "command.dispute-merge-001",
    catalogueId: catalogue.catalogueId,
    expectedVersion: catalogue.version,
    occurredAt: "2026-08-03T02:06:00.000Z",
    actor: catalogueReviewer,
    disputeId: "dispute.product-001",
    resolution: "merge_left_into_right",
    reasonCode: "duplicate.confirmed_merge",
  });
  assert.equal(catalogue.products[1]?.state, "merged");
  assert.deepEqual(matchCanonicalProductByCode(catalogue, PRODUCT_CODE), {
    kind: "exact",
    id: "product.oil-001",
  });
});

test("keep-separate resolution permits review but matching remains ambiguous", () => {
  const workspace = supplyWorkspace();
  let catalogue = reviewProduct(proposeProduct(emptyCatalogue(), workspace));
  catalogue = proposeProduct(
    catalogue,
    workspace,
    "product.oil-distinct",
    PRODUCT_CODE,
  );
  catalogue = applyCatalogueCommand(catalogue, {
    type: "open_duplicate_dispute",
    commandId: "command.dispute-open-002",
    catalogueId: catalogue.catalogueId,
    expectedVersion: catalogue.version,
    occurredAt: "2026-08-03T02:05:00.000Z",
    actor: catalogueReviewer,
    disputeId: "dispute.product-002",
    leftProductId: "product.oil-distinct",
    rightProductId: "product.oil-001",
    reasonCode: "duplicate.code_collision",
  });
  catalogue = applyCatalogueCommand(catalogue, {
    type: "resolve_duplicate_dispute",
    commandId: "command.dispute-separate-002",
    catalogueId: catalogue.catalogueId,
    expectedVersion: catalogue.version,
    occurredAt: "2026-08-03T02:06:00.000Z",
    actor: catalogueReviewer,
    disputeId: "dispute.product-002",
    resolution: "keep_separate",
    reasonCode: "duplicate.distinct_products",
  });
  catalogue = reviewProduct(catalogue, "product.oil-distinct");
  const match = matchCanonicalProductByCode(catalogue, PRODUCT_CODE);
  assert.equal(match.kind, "ambiguous");
});

test("pack remains unavailable until its separate review", () => {
  const { catalogue, workspace } = verifiedProduct();
  const proposed = proposePack(catalogue, workspace);
  assert.deepEqual(matchVerifiedPackByCode(proposed, "product.oil-001", PACK_CODE), {
    kind: "none",
  });
  const verified = reviewPack(proposed);
  assert.deepEqual(matchVerifiedPackByCode(verified, "product.oil-001", PACK_CODE), {
    kind: "exact",
    id: "pack.oil-001",
  });
});

test("offer requires verified pack and the exact buying-context capability", () => {
  const productOnly = supplyWorkspace(["product_master_stewardship"]);
  const product = verifiedProduct(productOnly);
  const pendingPack = proposePack(product.catalogue, productOnly);
  expectCode(
    () => createWholesaleOffer(pendingPack, productOnly),
    "invalid_transition",
  );
  const reviewedPack = reviewPack(pendingPack);
  expectCode(
    () => createWholesaleOffer(reviewedPack, productOnly),
    "capability_inactive",
  );
  const qualified = verifiedPack();
  expectCode(
    () =>
      createWholesaleOffer(
        qualified.catalogue,
        qualified.workspace,
        "2026-09-04T00:00:00.000Z",
      ),
    "capability_inactive",
  );
  const offer = createWholesaleOffer(qualified.catalogue, qualified.workspace);
  assert.equal(offer.offers[0]?.buyingContext, "wholesale");
});

test("service-area qualifier and consumer/wholesale capability never cross", () => {
  const wholesale = verifiedPack();
  const wrongAreaCommand = {
    type: "create_offer" as const,
    commandId: "command.offer-wrong-area",
    catalogueId: wholesale.catalogue.catalogueId,
    expectedVersion: wholesale.catalogue.version,
    occurredAt: "2026-08-03T02:04:00.000Z",
    actor: workspaceActor,
    offerId: "offer.wholesale-wrong-area",
    packId: "pack.oil-001",
    buyingContext: "wholesale" as const,
    serviceAreaIds: ["area.999999"],
    termWindows: [
      {
        termSnapshotId: "terms.wrong-area",
        termSnapshotSha256: HASH_C,
        effectiveFrom: "2026-08-03T03:00:00.000Z",
        expiresAt: "2026-08-10T00:00:00.000Z",
      },
    ],
  };
  expectCode(
    () =>
      applyCatalogueCommand(
        wholesale.catalogue,
        wrongAreaCommand,
        wholesale.workspace,
      ),
    "capability_inactive",
  );
  expectCode(
    () =>
      applyCatalogueCommand(
        wholesale.catalogue,
        { ...wrongAreaCommand, buyingContext: "consumer" },
        wholesale.workspace,
      ),
    "capability_inactive",
  );
});

test("offer term windows are non-overlapping and expiry is exact", () => {
  const qualified = verifiedPack();
  const offered = createWholesaleOffer(qualified.catalogue, qualified.workspace);
  const offer = offered.offers[0];
  assert.ok(offer !== undefined);
  assert.equal(
    referencedOfferTermAt(offer, "2026-08-03T02:59:59.999Z"),
    undefined,
  );
  assert.equal(
    referencedOfferTermAt(offer, "2026-08-03T03:00:00.000Z")?.termSnapshotId,
    "terms.wholesale-001",
  );
  assert.equal(
    referencedOfferTermAt(offer, "2026-08-10T00:00:00.000Z"),
    undefined,
  );
  const overlapCommand = {
    type: "create_offer" as const,
    commandId: "command.offer-overlap",
    catalogueId: qualified.catalogue.catalogueId,
    expectedVersion: qualified.catalogue.version,
    occurredAt: "2026-08-03T02:04:00.000Z",
    actor: workspaceActor,
    offerId: "offer.overlap-001",
    packId: "pack.oil-001",
    buyingContext: "wholesale" as const,
    serviceAreaIds: ["area.342001"],
    termWindows: [
      {
        termSnapshotId: "terms.overlap-a",
        termSnapshotSha256: HASH_A,
        effectiveFrom: "2026-08-03T03:00:00.000Z",
        expiresAt: "2026-08-05T00:00:00.000Z",
      },
      {
        termSnapshotId: "terms.overlap-b",
        termSnapshotSha256: HASH_B,
        effectiveFrom: "2026-08-04T00:00:00.000Z",
        expiresAt: "2026-08-06T00:00:00.000Z",
      },
    ],
  };
  expectCode(
    () =>
      applyCatalogueCommand(
        qualified.catalogue,
        overlapCommand,
        qualified.workspace,
      ),
    "invalid_input",
  );
  expectCode(
    () =>
      applyCatalogueCommand(
        qualified.catalogue,
        {
          ...overlapCommand,
          commandId: "command.offer-backdated",
          offerId: "offer.backdated-001",
          termWindows: [
            {
              termSnapshotId: "terms.backdated",
              termSnapshotSha256: HASH_A,
              effectiveFrom: "2026-08-03T02:03:59.999Z",
              expiresAt: "2026-08-05T00:00:00.000Z",
            },
          ],
        },
        qualified.workspace,
      ),
    "invalid_input",
  );
});

test("merge fails while source has an active or scheduled offer", () => {
  const workspace = supplyWorkspace([
    "product_master_stewardship",
    "wholesale_supply",
  ]);
  let catalogue = verifiedPack(workspace).catalogue;
  catalogue = createWholesaleOffer(catalogue, workspace);
  catalogue = proposeProduct(
    catalogue,
    workspace,
    "product.target-002",
    SECOND_PRODUCT_CODE,
  );
  catalogue = reviewProduct(catalogue, "product.target-002");
  catalogue = applyCatalogueCommand(catalogue, {
    type: "open_duplicate_dispute",
    commandId: "command.dispute-active-offer",
    catalogueId: catalogue.catalogueId,
    expectedVersion: catalogue.version,
    occurredAt: "2026-08-03T02:07:00.000Z",
    actor: catalogueReviewer,
    disputeId: "dispute.active-offer",
    leftProductId: "product.oil-001",
    rightProductId: "product.target-002",
    reasonCode: "duplicate.manual_review",
  });
  expectCode(
    () =>
      applyCatalogueCommand(catalogue, {
        type: "resolve_duplicate_dispute",
        commandId: "command.dispute-active-merge",
        catalogueId: catalogue.catalogueId,
        expectedVersion: catalogue.version,
        occurredAt: "2026-08-04T00:00:00.000Z",
        actor: catalogueReviewer,
        disputeId: "dispute.active-offer",
        resolution: "merge_left_into_right",
        reasonCode: "duplicate.confirmed_merge",
      }),
    "active_offer_conflict",
  );
});

test("authorization precedes stale-version checks and cross-tenant work fails", () => {
  const workspace = supplyWorkspace();
  const catalogue = emptyCatalogue();
  expectCode(
    () =>
      applyCatalogueCommand(
        catalogue,
        {
          type: "propose_product",
          commandId: "command.unauthorized-product",
          catalogueId: catalogue.catalogueId,
          expectedVersion: 999,
          occurredAt: "2026-08-03T02:00:00.000Z",
          actor: { ...workspaceActor, scopes: [] },
          productId: "product.unauthorized",
          categoryId: "category.fmcg",
          brandId: "brand.verified-001",
          contentSha256: HASH_A,
          codes: [PRODUCT_CODE],
        },
        workspace,
      ),
    "workspace_mismatch",
  );
  expectCode(
    () =>
      applyCatalogueCommand(
        catalogue,
        {
          type: "propose_product",
          commandId: "command.cross-tenant-product",
          catalogueId: catalogue.catalogueId,
          expectedVersion: catalogue.version,
          occurredAt: "2026-08-03T02:00:00.000Z",
          actor: { ...workspaceActor, tenantId: "tenant.other-001" },
          productId: "product.cross-tenant",
          categoryId: "category.fmcg",
          brandId: "brand.verified-001",
          contentSha256: HASH_A,
          codes: [PRODUCT_CODE],
        },
        workspace,
      ),
    "tenant_mismatch",
  );
});

test("catalogue commands are versioned, immutable and exactly idempotent", () => {
  const workspace = supplyWorkspace();
  const catalogue = emptyCatalogue();
  const command = {
    type: "propose_product" as const,
    commandId: "command.idempotent-product",
    catalogueId: catalogue.catalogueId,
    expectedVersion: catalogue.version,
    occurredAt: "2026-08-03T02:00:00.000Z",
    actor: workspaceActor,
    productId: "product.idempotent-001",
    categoryId: "category.fmcg",
    brandId: "brand.verified-001",
    contentSha256: HASH_A,
    codes: [PRODUCT_CODE],
  };
  const applied = applyCatalogueCommand(catalogue, command, workspace);
  const replayed = applyCatalogueCommand(applied, command, workspace);
  assert.strictEqual(replayed, applied);
  assert.equal(catalogue.products.length, 0);
  assert.equal(Object.isFrozen(applied.products), true);
  expectCode(
    () =>
      applyCatalogueCommand(
        applied,
        { ...command, contentSha256: HASH_B },
        workspace,
      ),
    "idempotency_conflict",
  );
  expectCode(
    () =>
      applyCatalogueCommand(
        applied,
        { ...command, commandId: "command.stale-product" },
        workspace,
      ),
    "version_conflict",
  );
});

test("audit events expose governed IDs and hashes without embedded terms", () => {
  const qualified = verifiedPack();
  const offered = createWholesaleOffer(qualified.catalogue, qualified.workspace);
  const event = offered.auditEvents.at(-1);
  assert.equal(event?.eventType, "offer_created");
  assert.deepEqual(event?.hashReferences, [HASH_C]);
  const serialized = JSON.stringify(offered.auditEvents);
  assert.doesNotMatch(serialized, /price|credit|payment|freight|credential|secret/iu);
});
