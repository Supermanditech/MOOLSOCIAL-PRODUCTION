import assert from "node:assert/strict";
import test from "node:test";

import type { Bucket } from "@google-cloud/storage";

import { ChatError } from "./contracts.js";
import {
  CHAT_PHOTO_SIGNED_URL_SECONDS,
  GoogleCloudStorageChatPhotoStore,
} from "./attachment_store.js";

const uploadId = "00000000-0000-4000-8000-000000000001";
const objectPath = `chat-private/v1/${uploadId}`;
const now = new Date("2026-08-15T00:00:00.000Z");

test("prepares one exact create-only private upload without identity in its path", async () => {
  const bucket = new FakeBucket();
  const store = new GoogleCloudStorageChatPhotoStore(
    bucket as unknown as Bucket,
    () => now,
    () => uploadId,
  );

  const grant = await store.prepare({
    userId: "user-private",
    threadId: "thread-private",
    fileName: "family-photo.png",
    contentType: "image/png",
    sizeBytes: 2048,
  });

  assert.equal(grant.uploadId, uploadId);
  assert.equal(grant.expiresAt, "2026-08-15T00:05:00.000Z");
  assert.equal(grant.requiredHeaders["content-type"], "image/png");
  assert.equal(grant.requiredHeaders["content-length"], "2048");
  assert.equal(grant.requiredHeaders["x-goog-if-generation-match"], "0");
  assert.equal(JSON.stringify(grant).includes("user-private"), false);
  assert.equal(JSON.stringify(grant).includes("thread-private"), false);
  assert.equal(JSON.stringify(grant).includes("family-photo"), false);
  assert.equal(bucket.signedRequests[0]?.path, objectPath);
  assert.equal(bucket.signedRequests[0]?.config.action, "write");
  assert.equal(bucket.signedRequests[0]?.config.version, "v4");
  assert.equal(
    new Date(String(bucket.signedRequests[0]?.config.expires)).getTime() -
      now.getTime(),
    CHAT_PHOTO_SIGNED_URL_SECONDS * 1_000,
  );
});

test("validates signed metadata size generation and PNG signature", async () => {
  const bucket = new FakeBucket();
  const store = new GoogleCloudStorageChatPhotoStore(
    bucket as unknown as Bucket,
    () => now,
    () => uploadId,
  );
  const input = {
    userId: "user-private",
    threadId: "thread-private",
    fileName: "family-photo.png",
    contentType: "image/png" as const,
    sizeBytes: 2048,
  };
  const grant = await store.prepare(input);
  bucket.objects.set(objectPath, {
    metadata: {
      contentType: input.contentType,
      size: String(input.sizeBytes),
      generation: "17",
      metadata: customMetadata(grant.requiredHeaders),
    },
    prefix: Buffer.from([
      0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00,
    ]),
  });

  const validated = await store.validate({ ...input, uploadId });

  assert.deepEqual(validated, {
    uploadId,
    objectPath,
    generation: "17",
    contentType: "image/png",
    sizeBytes: 2048,
  });
});

test("rejects a wrong owner binding and a corrupt file signature", async () => {
  const bucket = new FakeBucket();
  const store = new GoogleCloudStorageChatPhotoStore(
    bucket as unknown as Bucket,
    () => now,
    () => uploadId,
  );
  const input = {
    userId: "user-private",
    threadId: "thread-private",
    fileName: "family-photo.jpg",
    contentType: "image/jpeg" as const,
    sizeBytes: 1024,
  };
  const grant = await store.prepare(input);
  const metadata = customMetadata(grant.requiredHeaders);
  const ownerBinding = metadata["moolsocial-owner"];
  assert.ok(ownerBinding);
  metadata["moolsocial-owner"] = "wrong-owner-binding";
  bucket.objects.set(objectPath, {
    metadata: {
      contentType: input.contentType,
      size: String(input.sizeBytes),
      generation: "18",
      metadata,
    },
    prefix: Buffer.from([0xff, 0xd8, 0xff, 0x00]),
  });
  await assert.rejects(
    store.validate({ ...input, uploadId }),
    invalidUpload,
  );

  metadata["moolsocial-owner"] = ownerBinding;
  bucket.objects.set(objectPath, {
    metadata: {
      contentType: input.contentType,
      size: String(input.sizeBytes),
      generation: "18",
      metadata,
    },
    prefix: Buffer.from("not-a-jpeg"),
  });
  await assert.rejects(
    store.validate({ ...input, uploadId }),
    invalidUpload,
  );
});

test("issues a five-minute read URL for only the opaque generation-bound object", async () => {
  const bucket = new FakeBucket();
  const store = new GoogleCloudStorageChatPhotoStore(
    bucket as unknown as Bucket,
    () => now,
  );

  const result = await store.readUrl({ objectPath, generation: "23" });

  assert.equal(result.expiresAt, "2026-08-15T00:05:00.000Z");
  assert.match(result.readUrl, new RegExp(uploadId, "u"));
  assert.equal(result.readUrl.includes("user-"), false);
  assert.equal(result.readUrl.includes("thread-"), false);
  assert.equal(bucket.signedRequests[0]?.generation, "23");
  assert.equal(bucket.signedRequests[0]?.config.action, "read");
});

function customMetadata(
  headers: Readonly<Record<string, string>>,
): Record<string, string> {
  return Object.fromEntries(
    Object.entries(headers).flatMap(([name, value]) =>
      name.startsWith("x-goog-meta-")
        ? [[name.slice("x-goog-meta-".length), value]]
        : []
    ),
  );
}

function invalidUpload(error: unknown): boolean {
  return error instanceof ChatError && error.code === "bad_request";
}

interface StoredObject {
  metadata: Record<string, unknown>;
  prefix: Buffer;
}

class FakeBucket {
  readonly objects = new Map<string, StoredObject>();
  readonly signedRequests: Array<{
    path: string;
    generation?: string;
    config: Record<string, unknown>;
  }> = [];

  file(path: string, options?: { generation?: string }): FakeFile {
    return new FakeFile(this, path, options?.generation);
  }
}

class FakeFile {
  constructor(
    private readonly bucket: FakeBucket,
    private readonly path: string,
    private readonly generation?: string,
  ) {}

  async getSignedUrl(
    config: Record<string, unknown>,
  ): Promise<[string]> {
    this.bucket.signedRequests.push({
      path: this.path,
      ...(this.generation === undefined ? {} : { generation: this.generation }),
      config,
    });
    return [
      `https://storage.googleapis.test/${encodeURIComponent(this.path)}?signed=1`,
    ];
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
