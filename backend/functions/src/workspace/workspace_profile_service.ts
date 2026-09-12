import { createHash } from "node:crypto";

import type { DocumentData, Firestore } from "firebase-admin/firestore";

import type { WorkspaceProofStore } from "./workspace_proof_store.js";

export type WorkspaceProfileStatus =
  | "pending"
  | "approved"
  | "rejected"
  | "suspended"
  | "live";

export class WorkspaceProfileError extends Error {
  constructor(
    readonly code: string,
    message: string,
    readonly httpStatus: number,
    readonly retryable = false,
  ) {
    super(message);
    this.name = "WorkspaceProfileError";
  }
}

export interface WorkspaceProfileRecord {
  schemaVersion: 1;
  caseId: string;
  ownerUserId: string;
  familyId: string;
  profileId: string;
  name: string;
  area: string;
  primaryActivity: string;
  proofReferences: Readonly<Record<string, string>>;
  alternateMobileVerified: boolean;
  idempotencyKey: string;
  requestFingerprint: string;
  status: WorkspaceProfileStatus;
  plan: "free" | "paid";
  createdAt: string;
  updatedAt: string;
  workspaceId?: string;
  reason?: string;
  gstin?: string;
  shopEnabled?: boolean;
  setup?: {
    quantity: number;
    buyPrice: number;
    sellPrice: number;
    homeDelivery: boolean;
    storeCollection: boolean;
  };
}

export interface WorkspaceProfileRepository {
  createOrRead(record: WorkspaceProfileRecord): Promise<WorkspaceProfileRecord>;
  read(caseId: string): Promise<WorkspaceProfileRecord | undefined>;
  list(ownerUserId: string): Promise<WorkspaceProfileRecord[]>;
  update(
    caseId: string,
    ownerUserId: string,
    patch: Readonly<Record<string, unknown>>,
  ): Promise<WorkspaceProfileRecord>;
}

const profilesByFamily = new Map<string, ReadonlySet<string>>([
  ["products-trade", new Set([
    "retailer-grocery",
    "retailer-speciality",
    "wholesaler",
    "manufacturer",
  ])],
  ["food-business", new Set(["restaurant", "cloud-kitchen"])],
  ["health", new Set(["clinic", "pharmacy"])],
  ["services", new Set(["salon", "service-provider"])],
  ["ride", new Set(["captain", "fleet"])],
  ["create-work", new Set(["creator", "freelancer"])],
]);

const requiredProofIds = ["personal-kyc", "shop-front", "owner-authority"];

export class WorkspaceProfileService {
  constructor(
    private readonly repository: WorkspaceProfileRepository,
    private readonly now: () => Date = () => new Date(),
    private readonly proofStore?: WorkspaceProofStore,
  ) {}

  async prepareProofUpload(
    ownerUserId: string,
    body: Readonly<Record<string, unknown>>,
  ): Promise<object> {
    const store = this.requiredProofStore();
    return store.prepare({
      ownerUserId: identifier(ownerUserId, "owner"),
      proofId: stringField(body, "proofId", 2, 40),
      fileName: stringField(body, "fileName", 3, 180),
      contentType: stringField(body, "contentType", 3, 100),
      sizeBytes: integerField(body, "sizeBytes", 1, 10 * 1024 * 1024),
    });
  }

  async confirmProofUpload(
    ownerUserId: string,
    body: Readonly<Record<string, unknown>>,
  ): Promise<object> {
    const store = this.requiredProofStore();
    const proofReference = await store.confirm({
      ownerUserId: identifier(ownerUserId, "owner"),
      proofId: stringField(body, "proofId", 2, 40),
      uploadId: stringField(body, "uploadId", 36, 36),
      fileName: stringField(body, "fileName", 3, 180),
      contentType: stringField(body, "contentType", 3, 100),
      sizeBytes: integerField(body, "sizeBytes", 1, 10 * 1024 * 1024),
    });
    return { proofReference };
  }

  async listWorkspaces(ownerUserId: string): Promise<{ workspaces: object[] }> {
    const records = await this.repository.list(identifier(ownerUserId, "owner"));
    return {
      workspaces: records.map(publicReview),
    };
  }

  async submitProfile(
    ownerUserId: string,
    body: Readonly<Record<string, unknown>>,
  ): Promise<object> {
    const owner = identifier(ownerUserId, "owner");
    const familyId = stringField(body, "familyId", 2, 64);
    const profileId = stringField(body, "profileId", 2, 64);
    if (!profilesByFamily.get(familyId)?.has(profileId)) {
      throw invalid("Choose a supported work profile.");
    }
    const proofReferences = proofMap(body.proofReferences);
    for (const proofId of requiredProofIds) {
      if (!proofReferences[proofId]) {
        throw invalid("Add every required proof before submission.");
      }
    }
    const proofStore = this.requiredProofStore();
    await Promise.all(requiredProofIds.map((proofId) =>
      proofStore.assertOwned(owner, proofId, proofReferences[proofId]!),
    ));
    const input = {
      familyId,
      profileId,
      name: stringField(body, "name", 3, 120),
      area: stringField(body, "area", 3, 120),
      primaryActivity: stringField(body, "primaryActivity", 3, 280),
      proofReferences,
      alternateMobileVerified: body.alternateMobileVerified === true,
      idempotencyKey: identifier(
        stringField(body, "idempotencyKey", 8, 128),
        "idempotency key",
      ),
    };
    const requestFingerprint = digest(stableJson(input));
    const caseId = `wp_${digest(`${owner}:${input.idempotencyKey}`).slice(0, 28)}`;
    const timestamp = this.now().toISOString();
    const record = await this.repository.createOrRead({
      schemaVersion: 1,
      caseId,
      ownerUserId: owner,
      ...input,
      requestFingerprint,
      status: "pending",
      plan: "free",
      createdAt: timestamp,
      updatedAt: timestamp,
    });
    if (record.ownerUserId !== owner || record.requestFingerprint !== requestFingerprint) {
      throw new WorkspaceProfileError(
        "idempotency_conflict",
        "This submission key was already used for different work details.",
        409,
      );
    }
    return publicReview(record);
  }

  async reviewStatus(ownerUserId: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    const record = await this.ownerRecord(ownerUserId, stringField(body, "caseId", 8, 80));
    return publicReview(record);
  }

  async submitGst(ownerUserId: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    const caseId = stringField(body, "caseId", 8, 80);
    const gstin = stringField(body, "gstin", 15, 15).toUpperCase();
    if (!/^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][A-Z0-9]Z[A-Z0-9]$/u.test(gstin)) {
      throw invalid("Enter a valid 15-character GSTIN.");
    }
    const record = await this.ownerRecord(ownerUserId, caseId);
    if (record.status !== "pending") {
      throw new WorkspaceProfileError(
        "invalid_state",
        "GST proof can only be added while review is active.",
        409,
      );
    }
    const proofReference = stringField(body, "proofReference", 8, 256);
    await this.requiredProofStore().assertOwned(
      record.ownerUserId,
      "gst",
      proofReference,
    );
    await this.repository.update(caseId, record.ownerUserId, {
      gstin,
      gstProofReference: proofReference,
      updatedAt: this.now().toISOString(),
    });
    return { gstReference: `gst_${digest(`${record.ownerUserId}:${caseId}:${gstin}`).slice(0, 24)}` };
  }

  async finishRetailerSetup(
    ownerUserId: string,
    body: Readonly<Record<string, unknown>>,
  ): Promise<object> {
    const workspaceId = stringField(body, "workspaceId", 5, 80);
    const records = await this.repository.list(identifier(ownerUserId, "owner"));
    const record = records.find((candidate) => candidate.workspaceId === workspaceId);
    if (!record) throw notFound();
    if (record.status !== "approved" && record.status !== "live") {
      throw new WorkspaceProfileError(
        "invalid_state",
        "Wait for Workspace approval before finishing setup.",
        409,
      );
    }
    if (!record.profileId.startsWith("retailer-")) {
      throw invalid("This setup is only available to retailer Workspaces.");
    }
    const quantity = integerField(body, "quantity", 1, 1_000_000);
    const buyPrice = integerField(body, "buyPrice", 1, 100_000_000);
    const sellPrice = integerField(body, "sellPrice", buyPrice + 1, 100_000_000);
    const homeDelivery = body.homeDelivery === true;
    const storeCollection = body.storeCollection === true;
    if (!homeDelivery && !storeCollection) {
      throw invalid("Choose home delivery or store collection before going live.");
    }
    await this.repository.update(record.caseId, record.ownerUserId, {
      status: "live",
      shopEnabled: true,
      setup: { quantity, buyPrice, sellPrice, homeDelivery, storeCollection },
      updatedAt: this.now().toISOString(),
    });
    return { workspaceId, status: "live", plan: record.plan };
  }

  async retailerStoreState(ownerUserId: string): Promise<object> {
    return retailerStore(await this.ownerRetailer(ownerUserId));
  }

  async setRetailerAvailability(
    ownerUserId: string,
    body: Readonly<Record<string, unknown>>,
  ): Promise<object> {
    if (typeof body.enabled !== "boolean") throw invalid("enabled is required.");
    const record = await this.ownerRetailer(ownerUserId);
    if (record.status !== "live" || !record.setup) {
      throw new WorkspaceProfileError(
        "invalid_state",
        "Finish retailer setup before changing customer availability.",
        409,
      );
    }
    if (body.enabled && record.setup.quantity < 1) {
      throw new WorkspaceProfileError(
        "invalid_state",
        "Add available stock before turning customer orders on.",
        409,
      );
    }
    const updated = await this.repository.update(record.caseId, record.ownerUserId, {
      shopEnabled: body.enabled,
      updatedAt: this.now().toISOString(),
    });
    return retailerStore(updated);
  }

  async saveRetailerProduct(
    ownerUserId: string,
    body: Readonly<Record<string, unknown>>,
  ): Promise<object> {
    const record = await this.ownerRetailer(ownerUserId);
    if (record.status !== "live" || !record.setup) {
      throw new WorkspaceProfileError(
        "invalid_state",
        "Finish retailer setup before editing live products.",
        409,
      );
    }
    if (stringField(body, "productId", 2, 80) !== "atta") {
      throw invalid("That product is not in this Workspace catalogue.");
    }
    const stock = integerField(body, "stock", 0, 1_000_000);
    const buyPrice = integerField(body, "buyPrice", 1, 100_000_000);
    const sellPrice = integerField(body, "sellPrice", buyPrice + 1, 100_000_000);
    const updated = await this.repository.update(record.caseId, record.ownerUserId, {
      setup: {
        ...record.setup,
        quantity: stock,
        buyPrice,
        sellPrice,
      },
      updatedAt: this.now().toISOString(),
    });
    return retailerStore(updated);
  }

  private async ownerRecord(ownerUserId: string, caseId: string): Promise<WorkspaceProfileRecord> {
    const record = await this.repository.read(caseId);
    if (!record || record.ownerUserId !== identifier(ownerUserId, "owner")) throw notFound();
    return record;
  }

  private requiredProofStore(): WorkspaceProofStore {
    if (!this.proofStore) {
      throw new WorkspaceProfileError(
        "service_unavailable",
        "Proof upload is unavailable right now. Try again later.",
        503,
        true,
      );
    }
    return this.proofStore;
  }

  private async ownerRetailer(ownerUserId: string): Promise<WorkspaceProfileRecord> {
    const owner = identifier(ownerUserId, "owner");
    const records = await this.repository.list(owner);
    const record = records
      .filter((item) => item.profileId.startsWith("retailer-"))
      .sort((left, right) => {
        const leftLive = left.status === "live" ? 1 : 0;
        const rightLive = right.status === "live" ? 1 : 0;
        return rightLive - leftLive || right.updatedAt.localeCompare(left.updatedAt);
      })[0];
    if (!record) throw notFound();
    return record;
  }
}

export class FirestoreWorkspaceProfileRepository implements WorkspaceProfileRepository {
  constructor(private readonly firestore: Firestore) {}

  async createOrRead(record: WorkspaceProfileRecord): Promise<WorkspaceProfileRecord> {
    const ref = this.firestore.collection("workspaceProfiles").doc(record.caseId);
    return this.firestore.runTransaction(async (transaction) => {
      const existing = await transaction.get(ref);
      if (existing.exists) return recordFromData(existing.data()!);
      transaction.create(ref, record);
      return record;
    });
  }

  async read(caseId: string): Promise<WorkspaceProfileRecord | undefined> {
    const snapshot = await this.firestore.collection("workspaceProfiles").doc(caseId).get();
    return snapshot.exists ? recordFromData(snapshot.data()!) : undefined;
  }

  async list(ownerUserId: string): Promise<WorkspaceProfileRecord[]> {
    const snapshot = await this.firestore
      .collection("workspaceProfiles")
      .where("ownerUserId", "==", ownerUserId)
      .limit(50)
      .get();
    return snapshot.docs.map((document) => recordFromData(document.data()));
  }

  async update(
    caseId: string,
    ownerUserId: string,
    patch: Readonly<Record<string, unknown>>,
  ): Promise<WorkspaceProfileRecord> {
    const ref = this.firestore.collection("workspaceProfiles").doc(caseId);
    return this.firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(ref);
      if (!snapshot.exists || snapshot.get("ownerUserId") !== ownerUserId) throw notFound();
      transaction.update(ref, patch);
      return recordFromData({ ...snapshot.data()!, ...patch });
    });
  }
}

export class InMemoryWorkspaceProfileRepository implements WorkspaceProfileRepository {
  readonly records = new Map<string, WorkspaceProfileRecord>();

  async createOrRead(record: WorkspaceProfileRecord): Promise<WorkspaceProfileRecord> {
    const existing = this.records.get(record.caseId);
    if (existing) return existing;
    this.records.set(record.caseId, structuredClone(record));
    return structuredClone(record);
  }

  async read(caseId: string): Promise<WorkspaceProfileRecord | undefined> {
    const record = this.records.get(caseId);
    return record ? structuredClone(record) : undefined;
  }

  async list(ownerUserId: string): Promise<WorkspaceProfileRecord[]> {
    return [...this.records.values()]
      .filter((record) => record.ownerUserId === ownerUserId)
      .map((record) => structuredClone(record));
  }

  async update(
    caseId: string,
    ownerUserId: string,
    patch: Readonly<Record<string, unknown>>,
  ): Promise<WorkspaceProfileRecord> {
    const current = this.records.get(caseId);
    if (!current || current.ownerUserId !== ownerUserId) throw notFound();
    const updated = { ...current, ...patch } as WorkspaceProfileRecord;
    this.records.set(caseId, updated);
    return structuredClone(updated);
  }
}

function publicReview(record: WorkspaceProfileRecord): object {
  return {
    caseId: record.caseId,
    status: record.status,
    plan: record.plan,
    profileId: record.profileId,
    name: record.name,
    area: record.area,
    primaryActivity: record.primaryActivity,
    ...(record.workspaceId ? { workspaceId: record.workspaceId } : {}),
    ...(record.reason ? { reason: record.reason } : {}),
  };
}

function retailerStore(record: WorkspaceProfileRecord): object {
  const setup = record.setup;
  return {
    workspaceId: record.workspaceId ?? record.caseId,
    name: record.name,
    area: record.area,
    ordersEnabled: record.status === "live" && record.shopEnabled === true,
    products: setup
      ? [{
          id: "atta",
          name: "Aashirvaad Whole Wheat Atta",
          pack: "1 kg",
          sku: "AAT-1K",
          price: setup.sellPrice,
          stock: setup.quantity,
        }]
      : [],
  };
}

function recordFromData(data: DocumentData): WorkspaceProfileRecord {
  return data as WorkspaceProfileRecord;
}

function proofMap(value: unknown): Readonly<Record<string, string>> {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw invalid("Add every required proof before submission.");
  }
  const result: Record<string, string> = {};
  for (const [key, item] of Object.entries(value)) {
    if (!/^[a-z][a-z0-9-]{1,39}$/u.test(key) || typeof item !== "string") {
      throw invalid("A proof reference is invalid.");
    }
    const reference = item.trim();
    if (reference.length < 3 || reference.length > 256) throw invalid("A proof reference is invalid.");
    result[key] = reference;
  }
  return result;
}

function stringField(
  body: Readonly<Record<string, unknown>>,
  key: string,
  minimum: number,
  maximum: number,
): string {
  const value = body[key];
  if (typeof value !== "string") throw invalid(`${key} is required.`);
  const normalized = value.trim();
  if (normalized.length < minimum || normalized.length > maximum) {
    throw invalid(`${key} is invalid.`);
  }
  return normalized;
}

function integerField(
  body: Readonly<Record<string, unknown>>,
  key: string,
  minimum: number,
  maximum: number,
): number {
  const value = body[key];
  if (!Number.isSafeInteger(value) || (value as number) < minimum || (value as number) > maximum) {
    throw invalid(`${key} is invalid.`);
  }
  return value as number;
}

function identifier(value: string, label: string): string {
  const normalized = value.trim();
  if (!/^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$/u.test(normalized)) {
    throw invalid(`${label} is invalid.`);
  }
  return normalized;
}

function stableJson(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(stableJson).join(",")}]`;
  if (value !== null && typeof value === "object") {
    return `{${Object.entries(value)
      .sort(([left], [right]) => left.localeCompare(right))
      .map(([key, item]) => `${JSON.stringify(key)}:${stableJson(item)}`)
      .join(",")}}`;
  }
  return JSON.stringify(value);
}

function digest(value: string): string {
  return createHash("sha256").update(value).digest("hex");
}

function invalid(message: string): WorkspaceProfileError {
  return new WorkspaceProfileError("invalid_input", message, 400);
}

function notFound(): WorkspaceProfileError {
  return new WorkspaceProfileError(
    "not_found",
    "That Workspace review is not available for this account.",
    404,
  );
}
