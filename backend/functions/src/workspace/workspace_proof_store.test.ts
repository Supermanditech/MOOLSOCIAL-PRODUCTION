import assert from "node:assert/strict";
import test from "node:test";

import type { Bucket } from "@google-cloud/storage";
import type { Firestore } from "firebase-admin/firestore";

import { WorkspaceProfileError } from "./workspace_profile_service.js";
import { GoogleCloudStorageWorkspaceProofStore } from "./workspace_proof_store.js";

const uploadId = "00000000-0000-4000-8000-000000000001";
const objectPath = `workspace-private/v1/proofs/${uploadId}`;
const now = new Date("2026-08-29T09:00:00.000Z");
const input = {
  ownerUserId: "owner-private",
  proofId: "shop-front",
  fileName: "shop-front.pdf",
  contentType: "application/pdf",
  sizeBytes: 2048,
};

test("prepares an opaque five-minute private proof upload", async () => {
  const bucket = new FakeBucket();
  const firestore = new FakeFirestore();
  const store = new GoogleCloudStorageWorkspaceProofStore(
    bucket as unknown as Bucket,
    firestore as unknown as Firestore,
    () => now,
    () => uploadId,
  );

  const grant = await store.prepare(input);

  assert.equal(grant.uploadId, uploadId);
  assert.equal(grant.expiresAt, "2026-08-29T09:05:00.000Z");
  assert.equal(grant.requiredHeaders["content-type"], "application/pdf");
  assert.equal(grant.requiredHeaders["x-goog-if-generation-match"], "0");
  assert.equal(JSON.stringify(grant).includes(input.ownerUserId), false);
  assert.equal(JSON.stringify(grant).includes(input.fileName), false);
  assert.equal(bucket.signedPath, objectPath);
});

test("confirms signature and metadata before issuing an owner-bound reference", async () => {
  const bucket = new FakeBucket();
  const firestore = new FakeFirestore();
  const store = new GoogleCloudStorageWorkspaceProofStore(
    bucket as unknown as Bucket,
    firestore as unknown as Firestore,
    () => now,
    () => uploadId,
  );
  const grant = await store.prepare(input);
  bucket.objects.set(objectPath, {
    metadata: {
      contentType: input.contentType,
      size: String(input.sizeBytes),
      generation: "19",
      metadata: customMetadata(grant.requiredHeaders),
    },
    prefix: Buffer.from("%PDF-1.7\n"),
  });

  const reference = await store.confirm({ ...input, uploadId });

  assert.match(reference, /^proof_[a-f0-9]{32}$/u);
  await store.assertOwned(input.ownerUserId, input.proofId, reference);
  await assert.rejects(
    store.assertOwned("other-owner", input.proofId, reference),
    invalidProof,
  );
});

test("rejects corrupt proof content and unverified account KYC", async () => {
  const bucket = new FakeBucket();
  const firestore = new FakeFirestore();
  const store = new GoogleCloudStorageWorkspaceProofStore(
    bucket as unknown as Bucket,
    firestore as unknown as Firestore,
    () => now,
    () => uploadId,
  );
  const grant = await store.prepare(input);
  bucket.objects.set(objectPath, {
    metadata: {
      contentType: input.contentType,
      size: String(input.sizeBytes),
      generation: "20",
      metadata: customMetadata(grant.requiredHeaders),
    },
    prefix: Buffer.from("not-a-pdf"),
  });

  await assert.rejects(store.confirm({ ...input, uploadId }), invalidProof);
  await assert.rejects(
    store.assertOwned(input.ownerUserId, "personal-kyc", "ACCOUNT-KYC"),
    (error: unknown) =>
      error instanceof WorkspaceProfileError &&
      error.code === "verification_required",
  );
});

function customMetadata(headers: Readonly<Record<string, string>>): Record<string, string> {
  return Object.fromEntries(
    Object.entries(headers).flatMap(([name, value]) =>
      name.startsWith("x-goog-meta-")
        ? [[name.slice("x-goog-meta-".length), value]]
        : []
    ),
  );
}

function invalidProof(error: unknown): boolean {
  return error instanceof WorkspaceProfileError &&
    error.code === "invalid_proof_upload";
}

interface StoredObject {
  metadata: Record<string, unknown>;
  prefix: Buffer;
}

class FakeBucket {
  readonly objects = new Map<string, StoredObject>();
  signedPath?: string;

  file(path: string): FakeFile {
    return new FakeFile(this, path);
  }
}

class FakeFile {
  constructor(
    private readonly bucket: FakeBucket,
    private readonly path: string,
  ) {}

  async getSignedUrl(): Promise<[string]> {
    this.bucket.signedPath = this.path;
    return [`https://storage.googleapis.com/${encodeURIComponent(this.path)}?signed=1`];
  }

  async getMetadata(): Promise<[Record<string, unknown>]> {
    const stored = this.bucket.objects.get(this.path);
    if (!stored) throw new Error("missing object");
    return [stored.metadata];
  }

  async download(): Promise<[Buffer]> {
    const stored = this.bucket.objects.get(this.path);
    if (!stored) throw new Error("missing object");
    return [stored.prefix];
  }
}

class FakeFirestore {
  readonly documents = new Map<string, Record<string, unknown>>();

  collection(name: string): FakeCollection {
    return new FakeCollection(this, name);
  }
}

class FakeCollection {
  constructor(
    private readonly firestore: FakeFirestore,
    private readonly name: string,
  ) {}

  doc(id: string): FakeDocument {
    return new FakeDocument(this.firestore, `${this.name}/${id}`);
  }
}

class FakeDocument {
  constructor(
    private readonly firestore: FakeFirestore,
    private readonly path: string,
  ) {}

  async set(value: Record<string, unknown>): Promise<void> {
    this.firestore.documents.set(this.path, structuredClone(value));
  }

  async get(): Promise<FakeSnapshot> {
    return new FakeSnapshot(this.firestore.documents.get(this.path));
  }
}

class FakeSnapshot {
  constructor(private readonly value?: Record<string, unknown>) {}
  get exists(): boolean {
    return this.value !== undefined;
  }
  get(key: string): unknown {
    return this.value?.[key];
  }
}
