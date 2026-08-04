import assert from "node:assert/strict";
import test from "node:test";

import type { CatalogueAggregate, CatalogueReviewState } from "./catalogue_contract.js";
import type {
  SupplyActor,
  SupplyCapabilityState,
  SupplyParticipantWorkspace,
} from "./supply_participant_contract.js";
import {
  WholesalePackContractError,
  applyWholesalePackCommand,
  createWholesalePackProfileSet,
  normalizeExactPackQuantity,
  referencedWholesalePackProfileAt,
  type LogisticsLevelKind,
  type ProposeWholesalePackProfileCommand,
  type WholesalePackDimension,
  type WholesalePackProfileInput,
  type WholesalePackProfileSet,
  type WholesalePackUqcCode,
} from "./wholesale_pack_contract.js";

const HASH_A = "A".repeat(64);
const HASH_B = "B".repeat(64);
const HASH_C = "C".repeat(64);
const HASH_D = "D".repeat(64);

const workspaceActor: SupplyActor = {
  actorId: "actor.pack-proposer-001",
  tenantId: "tenant.india-001",
  workspaceId: "workspace.master-001",
  scopes: ["supply.workspace.admin"],
};

const reviewer: SupplyActor = {
  actorId: "actor.catalogue-reviewer-001",
  tenantId: "tenant.india-001",
  scopes: ["supply.catalogue.review"],
};

function workspace(
  state: SupplyCapabilityState = "verified",
  expiresAt = "2027-01-01T00:00:00.000Z",
): SupplyParticipantWorkspace {
  return {
    schemaVersion: 1,
    workspaceId: "workspace.master-001",
    tenantId: "tenant.india-001",
    legalEntityReference: "entity.master-001",
    participantType: "manufacturer",
    status: "registered",
    version: 2,
    capabilities: [
      {
        kind: "product_master_stewardship",
        state,
        requestedAt: "2026-08-01T00:00:00.000Z",
        requestedBy: "actor.pack-proposer-001",
        evidence: [],
        qualifiers: {
          categoryIds: ["category.fmcg"],
          serviceAreaIds: [],
        },
        reviewedAt: "2026-08-01T00:10:00.000Z",
        reviewedBy: "actor.capability-reviewer-001",
        effectiveFrom: "2026-08-01T00:10:00.000Z",
        expiresAt,
      },
    ],
    commandReceipts: [],
    auditEvents: [],
  };
}

function catalogue(
  packState: CatalogueReviewState = "verified",
  productState: CatalogueReviewState = "verified",
): CatalogueAggregate {
  return {
    schemaVersion: 1,
    catalogueId: "catalogue.india-001",
    tenantId: "tenant.india-001",
    version: 4,
    products: [
      {
        productId: "product.oil-001",
        categoryId: "category.fmcg",
        brandId: "brand.verified-001",
        contentSha256: HASH_A,
        codes: [],
        state: productState,
        proposedByWorkspaceId: "workspace.master-001",
        proposedAt: "2026-08-01T00:00:00.000Z",
        reviewedBy: "actor.catalogue-reviewer-001",
        reviewedAt: "2026-08-01T00:10:00.000Z",
      },
    ],
    packs: [
      {
        packId: "pack.oil-001",
        productId: "product.oil-001",
        descriptorSha256: HASH_B,
        codes: [],
        state: packState,
        proposedByWorkspaceId: "workspace.master-001",
        proposedAt: "2026-08-01T00:20:00.000Z",
        reviewedBy: "actor.catalogue-reviewer-001",
        reviewedAt: "2026-08-01T00:30:00.000Z",
      },
    ],
    offers: [],
    disputes: [],
    commandReceipts: [],
    auditEvents: [],
  };
}

function createSet(
  sourceCatalogue = catalogue(),
  participant = workspace(),
  actor = workspaceActor,
): WholesalePackProfileSet {
  return createWholesalePackProfileSet(
    {
      commandId: "command.pack-set-create-001",
      profileSetId: "pack-profile-set.oil-001",
      packId: "pack.oil-001",
      occurredAt: "2026-08-03T02:00:00.000Z",
      actor,
    },
    sourceCatalogue,
    participant,
  );
}

function baseKind(dimension: WholesalePackDimension): LogisticsLevelKind {
  return dimension === "mass" ? "weight" : dimension === "volume" ? "volume" : "each";
}

function uqc(dimension: WholesalePackDimension): WholesalePackUqcCode {
  return dimension === "mass" ? "KG" : dimension === "volume" ? "L" : "EA";
}

function profileInput(
  dimension: WholesalePackDimension = "count",
): WholesalePackProfileInput {
  const base = baseKind(dimension);
  const baseId = `level.${base}-001`;
  const baseNetWeight = dimension === "mass" ? 25_000 : 1_000;
  return {
    measure: {
      dimension,
      uqc: uqc(dimension),
      quantity:
        dimension === "count"
          ? { coefficient: "1", scale: 0 }
          : { coefficient: "2500", scale: 2 },
    },
    levels: [
      {
        levelId: baseId,
        kind: base,
        containedBaseUnits: { coefficient: "1", scale: 0 },
        codes: [{ type: "internal", value: `OIL-${base}-01` }],
        measurements: {
          lengthMillimetres: 100,
          widthMillimetres: 80,
          heightMillimetres: 250,
          grossWeightGrams: dimension === "mass" ? 26_000 : 1_100,
          netWeightGrams: baseNetWeight,
        },
      },
      {
        levelId: "level.inner-006",
        kind: "inner",
        parentLevelId: baseId,
        containedBaseUnits: { coefficient: "6", scale: 0 },
        codes: [{ type: "internal", value: `OIL-${dimension}-INNER-06` }],
        measurements: {
          lengthMillimetres: 220,
          widthMillimetres: 160,
          heightMillimetres: 270,
          grossWeightGrams: dimension === "mass" ? 160_000 : 7_000,
          netWeightGrams: baseNetWeight * 6,
        },
      },
      {
        levelId: "level.case-012",
        kind: "case",
        parentLevelId: "level.inner-006",
        containedBaseUnits: { coefficient: "12", scale: 0 },
        codes: [{ type: "internal", value: `OIL-${dimension}-CASE-12` }],
        measurements: {
          lengthMillimetres: 420,
          widthMillimetres: 320,
          heightMillimetres: 280,
          grossWeightGrams: dimension === "mass" ? 320_000 : 14_000,
          netWeightGrams: baseNetWeight * 12,
        },
      },
      {
        levelId: "level.pallet-120",
        kind: "pallet",
        parentLevelId: "level.case-012",
        containedBaseUnits: { coefficient: "120", scale: 0 },
        codes: [{ type: "internal", value: `OIL-${dimension}-PALLET-120` }],
        measurements: {
          lengthMillimetres: 1_200,
          widthMillimetres: 1_000,
          heightMillimetres: 1_400,
          grossWeightGrams: dimension === "mass" ? 3_200_000 : 150_000,
          netWeightGrams: baseNetWeight * 120,
        },
      },
    ],
    saleMultipleBaseUnits: { coefficient: "12", scale: 0 },
    loadingMultipleBaseUnits: { coefficient: "120", scale: 0 },
    batchPolicy: "required",
    expiryPolicy: "required",
    configurationSha256: HASH_C,
    evidence: [
      {
        evidenceId: "evidence.code-assignment-001",
        kind: "code_assignment",
        sha256: HASH_C,
      },
      {
        evidenceId: "evidence.pack-config-001",
        kind: "pack_configuration",
        sha256: HASH_A,
      },
      {
        evidenceId: "evidence.measurement-001",
        kind: "physical_measurement",
        sha256: HASH_B,
      },
      {
        evidenceId: "evidence.traceability-001",
        kind: "traceability_policy",
        sha256: HASH_D,
      },
    ],
  };
}

function proposal(
  aggregate: WholesalePackProfileSet,
  profileId = "pack-profile.oil-001",
  input = profileInput(),
  commandId = "command.pack-profile-propose-001",
  occurredAt = "2026-08-03T02:05:00.000Z",
): ProposeWholesalePackProfileCommand {
  return {
    type: "propose_profile",
    commandId,
    profileSetId: aggregate.profileSetId,
    expectedVersion: aggregate.version,
    occurredAt,
    actor: workspaceActor,
    profileId,
    ...input,
  };
}

function proposed(
  input = profileInput(),
): WholesalePackProfileSet {
  const aggregate = createSet();
  return applyWholesalePackCommand(aggregate, proposal(aggregate, undefined, input), workspace());
}

function verified(): WholesalePackProfileSet {
  const aggregate = proposed();
  return applyWholesalePackCommand(aggregate, {
    type: "review_profile",
    commandId: "command.pack-profile-review-001",
    profileSetId: aggregate.profileSetId,
    expectedVersion: aggregate.version,
    occurredAt: "2026-08-03T02:10:00.000Z",
    actor: reviewer,
    profileId: "pack-profile.oil-001",
    decision: "verify",
    reasonCode: "pack.evidence_verified",
    effectiveFrom: "2026-08-03T03:00:00.000Z",
    expiresAt: "2026-09-03T03:00:00.000Z",
  });
}

function expectCode(action: () => unknown, code: string): void {
  assert.throws(
    action,
    (error: unknown) =>
      error instanceof WholesalePackContractError && error.code === code,
  );
}

test("profile set binds one verified SUP-003 pack and freezes its identity", () => {
  const aggregate = createSet();
  assert.equal(aggregate.packId, "pack.oil-001");
  assert.equal(aggregate.productId, "product.oil-001");
  assert.equal(aggregate.categoryId, "category.fmcg");
  assert.equal(aggregate.sourceCatalogueVersion, 4);
  assert.equal(aggregate.sourceProductContentSha256, HASH_A);
  assert.equal(aggregate.sourcePackDescriptorSha256, HASH_B);
  assert.equal(aggregate.version, 1);
  assert.equal(Object.isFrozen(aggregate), true);
  assert.deepEqual(aggregate.auditEvents[0]?.hashReferences, [HASH_A, HASH_B]);
});

test("workspace authorization precedes source lookup and inactive capability fails closed", () => {
  const missingCatalogue = { ...catalogue(), packs: [] };
  expectCode(
    () => createSet(missingCatalogue, workspace(), { ...workspaceActor, tenantId: "tenant.other" }),
    "tenant_mismatch",
  );
  expectCode(() => createSet(catalogue("pending_review")), "invalid_transition");
  expectCode(() => createSet(catalogue("verified", "pending_review")), "invalid_transition");
  expectCode(() => createSet(catalogue(), workspace("suspended")), "capability_inactive");
  expectCode(
    () => createSet(catalogue(), workspace("verified", "2026-08-03T02:00:00.000Z")),
    "capability_inactive",
  );
});

test("exact quantities normalize without floating point or silent rounding", () => {
  assert.deepEqual(
    normalizeExactPackQuantity({ coefficient: "002500", scale: 3 }),
    { coefficient: "25", scale: 1 },
  );
  expectCode(
    () => normalizeExactPackQuantity({ coefficient: "1.5", scale: 1 }),
    "invalid_input",
  );
  expectCode(
    () => normalizeExactPackQuantity({ coefficient: "0", scale: 0 }),
    "invalid_input",
  );
});

test("count pack records exact each-case-pallet configuration and multiples", () => {
  const aggregate = proposed();
  const profile = aggregate.profiles[0];
  assert.equal(profile?.measure.dimension, "count");
  assert.deepEqual(profile?.levels.map((level) => level.kind), [
    "each",
    "inner",
    "case",
    "pallet",
  ]);
  assert.equal(profile?.saleMultipleBaseUnits.coefficient, "12");
  assert.equal(profile?.loadingMultipleBaseUnits.coefficient, "120");
  assert.equal(Object.isFrozen(profile?.levels), true);
});

test("mass and volume UQC profiles retain exact governed dimensions", () => {
  for (const dimension of ["mass", "volume"] as const) {
    const aggregate = createSet();
    const result = applyWholesalePackCommand(
      aggregate,
      proposal(
        aggregate,
        `pack-profile.${dimension}-001`,
        profileInput(dimension),
        `command.pack-${dimension}-001`,
      ),
      workspace(),
    );
    assert.equal(result.profiles[0]?.measure.dimension, dimension);
    assert.equal(result.profiles[0]?.levels[0]?.kind, baseKind(dimension));
  }
});

test("UQC and base-level kind cannot cross measure dimensions", () => {
  const aggregate = createSet();
  const input = profileInput();
  expectCode(
    () =>
      applyWholesalePackCommand(
        aggregate,
        proposal(aggregate, undefined, {
          ...input,
          measure: { ...input.measure, uqc: "KG" },
        }),
        workspace(),
      ),
    "invalid_input",
  );
  expectCode(
    () =>
      applyWholesalePackCommand(
        aggregate,
        proposal(aggregate, undefined, {
          ...input,
          levels: input.levels.map((level, index) =>
            index === 0 ? { ...level, kind: "weight" as const } : level,
          ),
        }),
        workspace(),
      ),
    "invalid_input",
  );
});

test("logistics hierarchy must be one increasing divisible parent chain", () => {
  const aggregate = createSet();
  const input = profileInput();
  const brokenParent = input.levels.map((level) =>
    level.kind === "case" ? { ...level, parentLevelId: "level.missing-001" } : level,
  );
  expectCode(
    () => applyWholesalePackCommand(aggregate, proposal(aggregate, undefined, { ...input, levels: brokenParent }), workspace()),
    "invalid_input",
  );
  const indivisible = input.levels.map((level) =>
    level.kind === "pallet"
      ? { ...level, containedBaseUnits: { coefficient: "125", scale: 0 } }
      : level,
  );
  expectCode(
    () => applyWholesalePackCommand(aggregate, proposal(aggregate, undefined, { ...input, levels: indivisible }), workspace()),
    "invalid_input",
  );
});

test("sale and loading multiples must be exact declared compatible levels", () => {
  const aggregate = createSet();
  const input = profileInput();
  expectCode(
    () => applyWholesalePackCommand(aggregate, proposal(aggregate, undefined, {
      ...input,
      saleMultipleBaseUnits: { coefficient: "4", scale: 0 },
    }), workspace()),
    "invalid_input",
  );
  expectCode(
    () => applyWholesalePackCommand(aggregate, proposal(aggregate, undefined, {
      ...input,
      saleMultipleBaseUnits: { coefficient: "12", scale: 1 },
    }), workspace()),
    "invalid_input",
  );
});

test("physical measurements are bounded and gross weight covers known net weight", () => {
  const aggregate = createSet();
  const input = profileInput();
  const invalid = input.levels.map((level, index) =>
    index === 0
      ? { ...level, measurements: { ...level.measurements, grossWeightGrams: 900 } }
      : level,
  );
  expectCode(
    () => applyWholesalePackCommand(aggregate, proposal(aggregate, undefined, { ...input, levels: invalid }), workspace()),
    "invalid_input",
  );
});

test("known net weights remain consistent across the logistics hierarchy", () => {
  const aggregate = createSet();
  const input = profileInput();
  const invalid = input.levels.map((level) =>
    level.kind === "case"
      ? { ...level, measurements: { ...level.measurements, netWeightGrams: 11_999 } }
      : level,
  );
  expectCode(
    () => applyWholesalePackCommand(aggregate, proposal(aggregate, undefined, { ...input, levels: invalid }), workspace()),
    "invalid_input",
  );
  const mass = profileInput("mass");
  expectCode(
    () => applyWholesalePackCommand(aggregate, proposal(aggregate, undefined, {
      ...mass,
      measure: { ...mass.measure, quantity: { coefficient: "24", scale: 0 } },
    }), workspace()),
    "invalid_input",
  );
});

test("governed codes normalize and cannot identify two logistics levels", () => {
  const aggregate = createSet();
  const input = profileInput();
  const duplicate = input.levels.map((level) => ({
    ...level,
    codes: [{ type: "internal" as const, value: "shared-pack-code" }],
  }));
  expectCode(
    () => applyWholesalePackCommand(aggregate, proposal(aggregate, undefined, { ...input, levels: duplicate }), workspace()),
    "invalid_input",
  );
  const malformed = input.levels.map((level, index) =>
    index === 0
      ? { ...level, codes: [{ type: "gtin" as const, value: "NOT-A-GTIN" }] }
      : level,
  );
  expectCode(
    () => applyWholesalePackCommand(aggregate, proposal(aggregate, undefined, { ...input, levels: malformed }), workspace()),
    "invalid_input",
  );
  const result = proposed({
    ...input,
    levels: input.levels.map((level, index) =>
      index === 0
        ? { ...level, codes: [{ type: "internal", value: " oil-each-lower " }] }
        : level,
    ),
  });
  assert.equal(result.profiles[0]?.levels[0]?.codes[0]?.value, "OIL-EACH-LOWER");
});

test("profile history is bounded before another proposal is accepted", () => {
  const empty = createSet();
  const template = proposed().profiles[0];
  assert.ok(template !== undefined);
  const capped: WholesalePackProfileSet = {
    ...empty,
    profiles: Array.from({ length: 100 }, (_, index) => ({
      ...template,
      profileId: `pack-profile.history-${String(index).padStart(3, "0")}`,
    })),
  };
  expectCode(
    () => applyWholesalePackCommand(capped, proposal(capped), workspace()),
    "invalid_input",
  );
});

test("required batch or expiry policy needs traceability evidence", () => {
  const aggregate = createSet();
  const input = profileInput();
  expectCode(
    () => applyWholesalePackCommand(aggregate, proposal(aggregate, undefined, {
      ...input,
      evidence: input.evidence.filter((item) => item.kind !== "traceability_policy"),
    }), workspace()),
    "invalid_input",
  );
  expectCode(
    () => applyWholesalePackCommand(aggregate, proposal(aggregate, undefined, {
      ...input,
      evidence: input.evidence.filter((item) => item.kind !== "code_assignment"),
    }), workspace()),
    "invalid_input",
  );
  expectCode(
    () => applyWholesalePackCommand(aggregate, proposal(aggregate, undefined, {
      ...input,
      batchPolicy: "not_required",
      expiryPolicy: "not_required",
      evidence: input.evidence.filter((item) => item.kind !== "physical_measurement"),
    }), workspace()),
    "invalid_input",
  );
});

test("independent governance review controls effective lookup boundaries", () => {
  const aggregate = proposed();
  expectCode(
    () => applyWholesalePackCommand(aggregate, {
      type: "review_profile",
      commandId: "command.self-review-001",
      profileSetId: aggregate.profileSetId,
      expectedVersion: aggregate.version,
      occurredAt: "2026-08-03T02:10:00.000Z",
      actor: { ...workspaceActor, scopes: ["supply.catalogue.review"] },
      profileId: "pack-profile.oil-001",
      decision: "verify",
      reasonCode: "pack.self_review",
      effectiveFrom: "2026-08-03T03:00:00.000Z",
      expiresAt: "2026-09-03T03:00:00.000Z",
    }),
    "unauthorized",
  );
  const qualified = verified();
  assert.equal(referencedWholesalePackProfileAt(qualified, "2026-08-03T02:59:59.999Z"), undefined);
  assert.equal(referencedWholesalePackProfileAt(qualified, "2026-08-03T03:00:00.000Z")?.profileId, "pack-profile.oil-001");
  assert.equal(referencedWholesalePackProfileAt(qualified, "2026-09-03T03:00:00.000Z"), undefined);
  assert.equal(referencedWholesalePackProfileAt(qualified, "invalid"), undefined);
});

test("verified effective windows cannot overlap", () => {
  let aggregate = verified();
  const second = proposal(
    aggregate,
    "pack-profile.oil-002",
    profileInput(),
    "command.pack-profile-propose-002",
    "2026-08-03T02:20:00.000Z",
  );
  aggregate = applyWholesalePackCommand(aggregate, second, workspace());
  expectCode(
    () => applyWholesalePackCommand(aggregate, {
      type: "review_profile",
      commandId: "command.pack-profile-review-002",
      profileSetId: aggregate.profileSetId,
      expectedVersion: aggregate.version,
      occurredAt: "2026-08-03T02:30:00.000Z",
      actor: reviewer,
      profileId: "pack-profile.oil-002",
      decision: "verify",
      reasonCode: "pack.overlap_attempt",
      effectiveFrom: "2026-09-01T00:00:00.000Z",
      expiresAt: "2026-10-01T00:00:00.000Z",
    }),
    "overlap_conflict",
  );
});

test("adjacent verified windows hand off at the exact expiry boundary", () => {
  let aggregate = verified();
  aggregate = applyWholesalePackCommand(
    aggregate,
    proposal(
      aggregate,
      "pack-profile.oil-002",
      profileInput(),
      "command.pack-profile-propose-adjacent",
      "2026-08-03T02:20:00.000Z",
    ),
    workspace(),
  );
  aggregate = applyWholesalePackCommand(aggregate, {
    type: "review_profile",
    commandId: "command.pack-profile-review-adjacent",
    profileSetId: aggregate.profileSetId,
    expectedVersion: aggregate.version,
    occurredAt: "2026-08-03T02:30:00.000Z",
    actor: reviewer,
    profileId: "pack-profile.oil-002",
    decision: "verify",
    reasonCode: "pack.adjacent_window",
    effectiveFrom: "2026-09-03T03:00:00.000Z",
    expiresAt: "2026-10-03T03:00:00.000Z",
  });
  assert.equal(
    referencedWholesalePackProfileAt(
      aggregate,
      "2026-09-03T03:00:00.000Z",
    )?.profileId,
    "pack-profile.oil-002",
  );
});

test("rejection is terminal and cannot carry an effective window", () => {
  let aggregate = proposed();
  expectCode(
    () => applyWholesalePackCommand(aggregate, {
      type: "review_profile",
      commandId: "command.reject-window-001",
      profileSetId: aggregate.profileSetId,
      expectedVersion: aggregate.version,
      occurredAt: "2026-08-03T02:10:00.000Z",
      actor: reviewer,
      profileId: "pack-profile.oil-001",
      decision: "reject",
      reasonCode: "pack.measurement_failed",
      effectiveFrom: "2026-08-03T03:00:00.000Z",
    }),
    "invalid_input",
  );
  aggregate = applyWholesalePackCommand(aggregate, {
    type: "review_profile",
    commandId: "command.reject-001",
    profileSetId: aggregate.profileSetId,
    expectedVersion: aggregate.version,
    occurredAt: "2026-08-03T02:10:00.000Z",
    actor: reviewer,
    profileId: "pack-profile.oil-001",
    decision: "reject",
    reasonCode: "pack.measurement_failed",
  });
  assert.equal(aggregate.profiles[0]?.state, "rejected");
  expectCode(
    () => applyWholesalePackCommand(aggregate, {
      type: "review_profile",
      commandId: "command.reject-again-001",
      profileSetId: aggregate.profileSetId,
      expectedVersion: aggregate.version,
      occurredAt: "2026-08-03T02:20:00.000Z",
      actor: reviewer,
      profileId: "pack-profile.oil-001",
      decision: "reject",
      reasonCode: "pack.second_rejection",
    }),
    "invalid_transition",
  );
});

test("authorization precedes stale-version checks", () => {
  const aggregate = createSet();
  const command = { ...proposal(aggregate), expectedVersion: 999 };
  expectCode(
    () => applyWholesalePackCommand(aggregate, {
      ...command,
      actor: { ...workspaceActor, workspaceId: "workspace.other-001" },
    }, workspace()),
    "workspace_mismatch",
  );
  expectCode(
    () => applyWholesalePackCommand(aggregate, command, workspace()),
    "version_conflict",
  );
});

test("commands are exactly idempotent, versioned and audit only IDs and hashes", () => {
  const aggregate = createSet();
  const command = proposal(aggregate);
  const applied = applyWholesalePackCommand(aggregate, command, workspace());
  const replayed = applyWholesalePackCommand(applied, command, workspace());
  assert.strictEqual(replayed, applied);
  expectCode(
    () => applyWholesalePackCommand(applied, {
      ...command,
      loadingMultipleBaseUnits: { coefficient: "12", scale: 0 },
    }, workspace()),
    "idempotency_conflict",
  );
  expectCode(
    () => applyWholesalePackCommand(applied, {
      ...command,
      commandId: "command.pack-profile-stale-001",
    }, workspace()),
    "version_conflict",
  );
  const serializedAudit = JSON.stringify(applied.auditEvents);
  assert.doesNotMatch(serializedAudit, /price|tax|freight|payment|credit|stock|availability/iu);
  assert.deepEqual(applied.auditEvents.at(-1)?.hashReferences, [
    applied.profiles[0]?.profileSha256,
    HASH_C,
    HASH_B,
    HASH_A,
    HASH_D,
  ]);
});
