import { createHash, randomUUID } from "node:crypto";

import type { Bucket } from "@google-cloud/storage";

import {
  ChatError,
  type ChatAttachmentKind,
  type ChatAttachmentStore,
  type ChatAttachmentUploadGrant,
  type ChatValidatedAttachment,
} from "./contracts.js";

const signedUrlSeconds = 300;
const contentTypes: Record<ChatAttachmentKind, ReadonlySet<string>> = {
  document: new Set([
    "application/pdf",
    "text/plain",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  ]),
  video: new Set(["video/mp4", "video/quicktime"]),
  voice: new Set(["audio/mp4", "audio/aac", "audio/webm"]),
};
const maximumBytes: Record<ChatAttachmentKind, number> = {
  document: 15 * 1024 * 1024,
  video: 50 * 1024 * 1024,
  voice: 10 * 1024 * 1024,
};

export class GoogleCloudStorageChatAttachmentStore
implements ChatAttachmentStore {
  constructor(
    private readonly bucket: Bucket,
    private readonly now: () => Date = () => new Date(),
    private readonly createUploadId: () => string = () => randomUUID(),
  ) {}

  async prepare(input: {
    userId: string;
    threadId: string;
    kind: ChatAttachmentKind;
    fileName: string;
    contentType: string;
    sizeBytes: number;
    durationMilliseconds?: number;
  }): Promise<ChatAttachmentUploadGrant> {
    validateShape(input);
    const uploadId = this.createUploadId();
    if (!isUploadId(uploadId)) throw unavailable();
    const expiresAt = new Date(this.now().getTime() + signedUrlSeconds * 1000);
    const headers = signedHeaders(input);
    try {
      const [uploadUrl] = await this.bucket.file(objectPath(input.kind, uploadId))
        .getSignedUrl({
          action: "write",
          version: "v4",
          expires: expiresAt,
          contentType: input.contentType,
          extensionHeaders: Object.fromEntries(
            Object.entries(headers).filter(([name]) => name !== "content-type"),
          ),
        });
      return {
        uploadId,
        uploadUrl,
        expiresAt: expiresAt.toISOString(),
        requiredHeaders: headers,
      };
    } catch {
      throw unavailable();
    }
  }

  async validate(input: {
    userId: string;
    threadId: string;
    kind: ChatAttachmentKind;
    uploadId: string;
    fileName: string;
    contentType: string;
    sizeBytes: number;
    durationMilliseconds?: number;
  }): Promise<ChatValidatedAttachment> {
    validateShape(input);
    if (!isUploadId(input.uploadId)) throw invalidUpload();
    const path = objectPath(input.kind, input.uploadId);
    const file = this.bucket.file(path);
    try {
      const [[metadata], [prefix]] = await Promise.all([
        file.getMetadata(),
        file.download({ start: 0, end: 31 }),
      ]);
      const custom = metadata.metadata && typeof metadata.metadata === "object"
        ? metadata.metadata as Record<string, unknown>
        : {};
      const generation = String(metadata.generation ?? "").trim();
      if (metadata.contentType !== input.contentType ||
          Number(metadata.size) !== input.sizeBytes || !generation ||
          custom["moolsocial-schema"] !== "chat-attachment-v1" ||
          custom["moolsocial-kind"] !== input.kind ||
          custom["moolsocial-owner"] !== digest(input.userId) ||
          custom["moolsocial-thread"] !== digest(input.threadId) ||
          custom["moolsocial-name"] !== digest(input.fileName) ||
          custom["moolsocial-size"] !== String(input.sizeBytes) ||
          custom["moolsocial-duration"] !== String(input.durationMilliseconds ?? 0) ||
          !matchesSignature(prefix, input.contentType)) {
        throw invalidUpload();
      }
      return {
        uploadId: input.uploadId,
        objectPath: path,
        generation,
        kind: input.kind,
        contentType: input.contentType,
        sizeBytes: input.sizeBytes,
        ...(input.durationMilliseconds === undefined
          ? {}
          : { durationMilliseconds: input.durationMilliseconds }),
      };
    } catch (error) {
      if (error instanceof ChatError) throw error;
      throw invalidUpload();
    }
  }

  async readUrl(input: { objectPath: string; generation: string }) {
    if (!/^chat-media\/v1\/(document|video|voice)\/[0-9a-f-]{36}$/u
      .test(input.objectPath)) throw invalidUpload();
    const expiresAt = new Date(this.now().getTime() + signedUrlSeconds * 1000);
    try {
      const [readUrl] = await this.bucket.file(
        input.objectPath,
        { generation: input.generation },
      ).getSignedUrl({ action: "read", version: "v4", expires: expiresAt });
      return { readUrl, expiresAt: expiresAt.toISOString() };
    } catch {
      throw unavailable();
    }
  }
}

function validateShape(input: {
  kind: ChatAttachmentKind;
  contentType: string;
  sizeBytes: number;
  durationMilliseconds?: number;
}): void {
  const duration = input.durationMilliseconds;
  const durationValid = input.kind === "voice"
    ? Number.isSafeInteger(duration) && duration! >= 500 && duration! <= 300_000
    : duration === undefined;
  if (!contentTypes[input.kind].has(input.contentType) ||
      !Number.isSafeInteger(input.sizeBytes) || input.sizeBytes < 1 ||
      input.sizeBytes > maximumBytes[input.kind] || !durationValid) {
    throw new ChatError(
      "bad_request",
      input.kind === "document"
        ? "Choose a PDF, text or DOCX document up to 15 MB."
        : input.kind === "video"
          ? "Choose an MP4 or MOV video up to 50 MB."
          : "Record a voice message between 1 second and 5 minutes.",
      400,
    );
  }
}

function signedHeaders(input: {
  userId: string;
  threadId: string;
  kind: ChatAttachmentKind;
  fileName: string;
  contentType: string;
  sizeBytes: number;
  durationMilliseconds?: number;
}): Readonly<Record<string, string>> {
  return {
    "content-type": input.contentType,
    "content-length": String(input.sizeBytes),
    "x-goog-if-generation-match": "0",
    "x-goog-meta-moolsocial-schema": "chat-attachment-v1",
    "x-goog-meta-moolsocial-kind": input.kind,
    "x-goog-meta-moolsocial-owner": digest(input.userId),
    "x-goog-meta-moolsocial-thread": digest(input.threadId),
    "x-goog-meta-moolsocial-name": digest(input.fileName),
    "x-goog-meta-moolsocial-size": String(input.sizeBytes),
    "x-goog-meta-moolsocial-duration": String(input.durationMilliseconds ?? 0),
  };
}

function matchesSignature(value: Buffer, contentType: string): boolean {
  if (contentType === "application/pdf") return value.subarray(0, 4).toString() === "%PDF";
  if (contentType.includes("openxmlformats")) return value[0] === 0x50 && value[1] === 0x4b;
  if (contentType === "text/plain") return !value.includes(0);
  if (contentType === "audio/aac") return value.length >= 2 &&
    value[0] === 0xff && ((value[1] ?? 0) & 0xf6) === 0xf0;
  if (contentType === "audio/webm") return value.subarray(0, 4)
    .equals(Buffer.from([0x1a, 0x45, 0xdf, 0xa3]));
  return value.length >= 12 && value.subarray(4, 8).toString("ascii") === "ftyp";
}

function objectPath(kind: ChatAttachmentKind, uploadId: string): string {
  return `chat-media/v1/${kind}/${uploadId}`;
}

function isUploadId(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/u
    .test(value);
}

function digest(value: string): string {
  return createHash("sha256").update(value).digest("hex");
}

function invalidUpload(): ChatError {
  return new ChatError(
    "bad_request",
    "That attachment upload is invalid or expired. Choose it again.",
    400,
  );
}

function unavailable(): ChatError {
  return new ChatError(
    "service_unavailable",
    "Attachment delivery is unavailable right now. Try again later.",
    503,
    true,
  );
}
