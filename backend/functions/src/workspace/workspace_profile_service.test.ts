import assert from "node:assert/strict";
import test from "node:test";

import {
  InMemoryWorkspaceProfileRepository,
  WorkspaceProfileError,
  WorkspaceProfileService,
} from "./workspace_profile_service.js";

const now = () => new Date("2026-08-29T09:00:00.000Z");

function validSubmission(overrides: Readonly<Record<string, unknown>> = {}) {
  return {
    familyId: "products-trade",
    profileId: "retailer-grocery",
    name: "Mahadev Fresh Mart",
    area: "Sardarpura, Jodhpur",
    primaryActivity: "Grocery and household products",
    proofReferences: {
      "personal-kyc": "account_kyc_owner",
      "shop-front": "proof_shop_1",
      "owner-authority": "proof_owner_1",
    },
    alternateMobileVerified: false,
    idempotencyKey: "work-submit-001",
    ...overrides,
  };
}

test("submission is server-assigned to Free and remains pending", async () => {
  const repository = new InMemoryWorkspaceProfileRepository();
  const service = new WorkspaceProfileService(repository, now);

  const result = await service.submitProfile("owner-1", validSubmission());

  assert.match(String((result as { caseId: string }).caseId), /^wp_[a-f0-9]{28}$/u);
  assert.equal((result as { status: string }).status, "pending");
  assert.equal((result as { plan: string }).plan, "free");
  assert.equal(repository.records.size, 1);
  assert.equal([...repository.records.values()][0]?.plan, "free");
  const listed = await service.listWorkspaces("owner-1");
  assert.equal(listed.workspaces.length, 1);
  assert.equal(
    (listed.workspaces[0] as { status: string }).status,
    "pending",
  );
});

test("same idempotent submission reuses its case without duplication", async () => {
  const repository = new InMemoryWorkspaceProfileRepository();
  const service = new WorkspaceProfileService(repository, now);

  const first = await service.submitProfile("owner-1", validSubmission());
  const second = await service.submitProfile("owner-1", validSubmission());

  assert.deepEqual(second, first);
  assert.equal(repository.records.size, 1);
});

test("reusing a submission key for changed details fails closed", async () => {
  const service = new WorkspaceProfileService(
    new InMemoryWorkspaceProfileRepository(),
    now,
  );
  await service.submitProfile("owner-1", validSubmission());

  await assert.rejects(
    service.submitProfile("owner-1", validSubmission({ name: "Changed Shop" })),
    (error: unknown) =>
      error instanceof WorkspaceProfileError &&
      error.code === "idempotency_conflict" &&
      error.httpStatus === 409,
  );
});

test("review cases are private to their owner", async () => {
  const service = new WorkspaceProfileService(
    new InMemoryWorkspaceProfileRepository(),
    now,
  );
  const created = await service.submitProfile("owner-1", validSubmission()) as {
    caseId: string;
  };

  await assert.rejects(
    service.reviewStatus("owner-2", { caseId: created.caseId }),
    (error: unknown) =>
      error instanceof WorkspaceProfileError && error.code === "not_found",
  );
});

test("approved review returns only its authoritative Workspace", async () => {
  const repository = new InMemoryWorkspaceProfileRepository();
  const service = new WorkspaceProfileService(repository, now);
  const created = await service.submitProfile("owner-1", validSubmission()) as {
    caseId: string;
  };
  await repository.update(created.caseId, "owner-1", {
    status: "approved",
    workspaceId: "workspace-510001",
  });

  assert.deepEqual(
    await service.reviewStatus("owner-1", { caseId: created.caseId }),
    {
      caseId: created.caseId,
      status: "approved",
      plan: "free",
      profileId: "retailer-grocery",
      name: "Mahadev Fresh Mart",
      area: "Sardarpura, Jodhpur",
      primaryActivity: "Grocery and household products",
      workspaceId: "workspace-510001",
    },
  );
  assert.deepEqual(await service.listWorkspaces("owner-1"), {
    workspaces: [{
      caseId: created.caseId,
      status: "approved",
      plan: "free",
      profileId: "retailer-grocery",
      name: "Mahadev Fresh Mart",
      area: "Sardarpura, Jodhpur",
      primaryActivity: "Grocery and household products",
      workspaceId: "workspace-510001",
    }],
  });
});

test("retailer setup validates price and fulfilment then activates live state", async () => {
  const repository = new InMemoryWorkspaceProfileRepository();
  const service = new WorkspaceProfileService(repository, now);
  const created = await service.submitProfile("owner-1", validSubmission()) as {
    caseId: string;
  };
  await repository.update(created.caseId, "owner-1", {
    status: "approved",
    workspaceId: "workspace-510001",
  });

  await assert.rejects(
    service.finishRetailerSetup("owner-1", {
      workspaceId: "workspace-510001",
      quantity: 20,
      buyPrice: 100,
      sellPrice: 99,
      homeDelivery: true,
      storeCollection: false,
    }),
    (error: unknown) => error instanceof WorkspaceProfileError && error.code === "invalid_input",
  );

  assert.deepEqual(
    await service.finishRetailerSetup("owner-1", {
      workspaceId: "workspace-510001",
      quantity: 20,
      buyPrice: 100,
      sellPrice: 120,
      homeDelivery: true,
      storeCollection: false,
    }),
    { workspaceId: "workspace-510001", status: "live", plan: "free" },
  );
  assert.equal(repository.records.get(created.caseId)?.status, "live");
});
