import assert from "node:assert/strict";
import test from "node:test";

import type { Bucket } from "@google-cloud/storage";

import { ChatError } from "./contracts.js";
import { GoogleCloudStorageChatAttachmentStore } from "./media_store.js";

const uploadId = "00000000-0000-4000-8000-000000000002";
const now = new Date("2026-08-29T04:00:00.000Z");

test("prepares opaque voice upload and validates bound M4A signature", async () => {
  const bucket = new FakeBucket();
  const store = new GoogleCloudStorageChatAttachmentStore(
    bucket as unknown as Bucket,
    () => now,
    () => uploadId,
  );
  const input = {
    userId: "user-private",
    threadId: "thread-private",
    kind: "voice" as const,
    fileName: "Voice message.m4a",
    contentType: "audio/mp4",
    sizeBytes: 4096,
    durationMilliseconds: 2400,
  };
  const grant = await store.prepare(input);
  assert.equal(grant.requiredHeaders["x-goog-meta-moolsocial-kind"], "voice");
  assert.equal(JSON.stringify(grant).includes(input.userId), false);
  const path = `chat-media/v1/voice/${uploadId}`;
  bucket.objects.set(path, {
    metadata: {
      contentType: input.contentType,
      size: String(input.sizeBytes),
      generation: "21",
      metadata: customMetadata(grant.requiredHeaders),
    },
    prefix: Buffer.from([0, 0, 0, 24, 0x66, 0x74, 0x79, 0x70, 0, 0, 0, 0]),
  });
  const validated = await store.validate({ ...input, uploadId });
  assert.equal(validated.objectPath, path);
  assert.equal(validated.durationMilliseconds, 2400);
  const read = await store.readUrl({ objectPath: path, generation: "21" });
  assert.equal(read.expiresAt, "2026-08-29T04:05:00.000Z");
});

test("rejects unsupported and oversized attachment shapes", async () => {
  const store = new GoogleCloudStorageChatAttachmentStore(
    new FakeBucket() as unknown as Bucket,
    () => now,
    () => uploadId,
  );
  await assert.rejects(
    store.prepare({
      userId: "user-private",
      threadId: "thread-private",
      kind: "document",
      fileName: "archive.zip",
      contentType: "application/zip",
      sizeBytes: 10,
    }),
    invalidUpload,
  );
  await assert.rejects(
    store.prepare({
      userId: "user-private",
      threadId: "thread-private",
      kind: "voice",
      fileName: "long.m4a",
      contentType: "audio/mp4",
      sizeBytes: 10,
      durationMilliseconds: 301_000,
    }),
    invalidUpload,
  );
});

function customMetadata(headers: Readonly<Record<string, string>>) {
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

class FakeBucket {
  readonly objects = new Map<string, {
    metadata: Record<string, unknown>;
    prefix: Buffer;
  }>();

  file(path: string, options?: { generation?: string }) {
    return new FakeFile(this, path, options?.generation);
  }
}

class FakeFile {
  constructor(
    private readonly bucket: FakeBucket,
    private readonly path: string,
    private readonly generation?: string,
  ) {}

  async getSignedUrl(config: Record<string, unknown>): Promise<[string]> {
    return [
      `https://storage.googleapis.test/${encodeURIComponent(this.path)}?generation=${this.generation ?? "new"}&action=${config.action}`,
    ];
  }

  async getMetadata(): Promise<[Record<string, unknown>]> {
    const value = this.bucket.objects.get(this.path);
    if (!value) throw new Error("missing");
    return [value.metadata];
  }

  async download(): Promise<[Buffer]> {
    const value = this.bucket.objects.get(this.path);
    if (!value) throw new Error("missing");
    return [value.prefix];
  }
}
