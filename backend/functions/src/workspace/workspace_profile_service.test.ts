import assert from "node:assert/strict";
import test from "node:test";

import {
  InMemoryWorkspaceProfileRepository,
  WorkspaceProfileError,
  WorkspaceProfileService,
} from "./workspace_profile_service.js";
import type {
  WorkspaceProofInput,
  WorkspaceProofStore,
  WorkspaceProofUploadGrant,
} from "./workspace_proof_store.js";

const now = () => new Date("2026-08-29T09:00:00.000Z");
class ProofStore implements WorkspaceProofStore {
  prepared?: WorkspaceProofInput;
  confirmed?: WorkspaceProofInput & { uploadId: string };
  readonly asserted: Array<[string, string, string]> = [];

  async prepare(input: WorkspaceProofInput): Promise<WorkspaceProofUploadGrant> {
    this.prepared = input;
    return {
      uploadId: "00000000-0000-4000-8000-000000000001",
      uploadUrl: "https://storage.googleapis.com/upload",
      expiresAt: "2026-08-29T09:05:00.000Z",
      requiredHeaders: { "content-type": input.contentType },
    };
  }
  async confirm(input: WorkspaceProofInput & { uploadId: string }): Promise<string> {
    this.confirmed = input;
    return "proof-confirmed";
  }
  async assertOwned(owner: string, proofId: string, reference: string): Promise<void> {
    this.asserted.push([owner, proofId, reference]);
  }
}

function service(
  repository = new InMemoryWorkspaceProfileRepository(),
  proofStore: WorkspaceProofStore = new ProofStore(),
) {
  return new WorkspaceProfileService(repository, now, proofStore);
}

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
  const proofStore = new ProofStore();
  const subject = service(repository, proofStore);

  const result = await subject.submitProfile("owner-1", validSubmission());

  assert.match(String((result as { caseId: string }).caseId), /^wp_[a-f0-9]{28}$/u);
  assert.equal((result as { status: string }).status, "pending");
  assert.equal((result as { plan: string }).plan, "free");
  assert.equal(repository.records.size, 1);
  assert.equal([...repository.records.values()][0]?.plan, "free");
  assert.equal(proofStore.asserted.length, 3);
  const listed = await subject.listWorkspaces("owner-1");
  assert.equal(listed.workspaces.length, 1);
  assert.equal(
    (listed.workspaces[0] as { status: string }).status,
    "pending",
  );
});

test("proof preparation and confirmation remain bound to the signed-in owner", async () => {
  const proofStore = new ProofStore();
  const subject = service(new InMemoryWorkspaceProfileRepository(), proofStore);
  const input = {
    proofId: "shop-front",
    fileName: "shop-front.pdf",
    contentType: "application/pdf",
    sizeBytes: 1200,
  };

  const prepared = await subject.prepareProofUpload("owner-1", input);
  const confirmed = await subject.confirmProofUpload("owner-1", {
    ...input,
    uploadId: "00000000-0000-4000-8000-000000000001",
  });

  assert.equal(proofStore.prepared?.ownerUserId, "owner-1");
  assert.equal(proofStore.confirmed?.ownerUserId, "owner-1");
  assert.deepEqual(prepared, {
    uploadId: "00000000-0000-4000-8000-000000000001",
    uploadUrl: "https://storage.googleapis.com/upload",
    expiresAt: "2026-08-29T09:05:00.000Z",
    requiredHeaders: { "content-type": "application/pdf" },
  });
  assert.deepEqual(confirmed, { proofReference: "proof-confirmed" });
});

test("GST submission accepts only an owner-bound received certificate", async () => {
  const repository = new InMemoryWorkspaceProfileRepository();
  const proofStore = new ProofStore();
  const subject = service(repository, proofStore);
  const created = await subject.submitProfile("owner-1", validSubmission()) as {
    caseId: string;
  };

  const result = await subject.submitGst("owner-1", {
    caseId: created.caseId,
    gstin: "08ABCDE1234F1Z5",
    proofReference: "proof-gst-confirmed",
  });

  assert.match(
    String((result as { gstReference: string }).gstReference),
    /^gst_[a-f0-9]{24}$/u,
  );
  assert.deepEqual(proofStore.asserted.at(-1), [
    "owner-1",
    "gst",
    "proof-gst-confirmed",
  ]);
});

test("same idempotent submission reuses its case without duplication", async () => {
  const repository = new InMemoryWorkspaceProfileRepository();
  const subject = service(repository);

  const first = await subject.submitProfile("owner-1", validSubmission());
  const second = await subject.submitProfile("owner-1", validSubmission());

  assert.deepEqual(second, first);
  assert.equal(repository.records.size, 1);
});

test("reusing a submission key for changed details fails closed", async () => {
  const subject = service();
  await subject.submitProfile("owner-1", validSubmission());

  await assert.rejects(
    subject.submitProfile("owner-1", validSubmission({ name: "Changed Shop" })),
    (error: unknown) =>
      error instanceof WorkspaceProfileError &&
      error.code === "idempotency_conflict" &&
      error.httpStatus === 409,
  );
});

test("review cases are private to their owner", async () => {
  const subject = service();
  const created = await subject.submitProfile("owner-1", validSubmission()) as {
    caseId: string;
  };

  await assert.rejects(
    subject.reviewStatus("owner-2", { caseId: created.caseId }),
    (error: unknown) =>
      error instanceof WorkspaceProfileError && error.code === "not_found",
  );
});

test("approved review returns only its authoritative Workspace", async () => {
  const repository = new InMemoryWorkspaceProfileRepository();
  const subject = service(repository);
  const created = await subject.submitProfile("owner-1", validSubmission()) as {
    caseId: string;
  };
  await repository.update(created.caseId, "owner-1", {
    status: "approved",
    workspaceId: "workspace-510001",
  });

  assert.deepEqual(
    await subject.reviewStatus("owner-1", { caseId: created.caseId }),
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
  assert.deepEqual(await subject.listWorkspaces("owner-1"), {
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
  const subject = service(repository);
  const created = await subject.submitProfile("owner-1", validSubmission()) as {
    caseId: string;
  };
  await repository.update(created.caseId, "owner-1", {
    status: "approved",
    workspaceId: "workspace-510001",
  });

  await assert.rejects(
    subject.finishRetailerSetup("owner-1", {
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
    await subject.finishRetailerSetup("owner-1", {
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
