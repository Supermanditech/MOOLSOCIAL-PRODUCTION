import { createHash, randomUUID } from "node:crypto";

import type { Bucket } from "@google-cloud/storage";

import {
  ChatError,
  type ChatPhotoAttachmentStore,
  type ChatPhotoContentType,
  type ChatPhotoUploadGrant,
  type ChatValidatedPhoto,
} from "./contracts.js";

export const CHAT_PHOTO_MAX_BYTES = 4 * 1024 * 1024;
export const CHAT_PHOTO_SIGNED_URL_SECONDS = 300;

const supportedTypes = new Set<ChatPhotoContentType>([
  "image/jpeg",
  "image/png",
  "image/webp",
]);

export class GoogleCloudStorageChatPhotoStore
implements ChatPhotoAttachmentStore {
  constructor(
    private readonly bucket: Bucket,
    private readonly now: () => Date = () => new Date(),
    private readonly createUploadId: () => string = () => randomUUID(),
  ) {}

  async prepare(input: {
    userId: string;
    threadId: string;
    fileName: string;
    contentType: ChatPhotoContentType;
    sizeBytes: number;
  }): Promise<ChatPhotoUploadGrant> {
    validatePhotoShape(input.contentType, input.sizeBytes);
    const uploadId = this.createUploadId();
    if (!isUploadId(uploadId)) {
      throw new ChatError(
        "internal",
        "Photo upload could not be prepared.",
        500,
        true,
      );
    }
    const expiresAt = new Date(
      this.now().getTime() + CHAT_PHOTO_SIGNED_URL_SECONDS * 1_000,
    );
    const requiredHeaders = signedUploadHeaders(input);
    try {
      const [uploadUrl] = await this.bucket
        .file(objectPath(uploadId))
        .getSignedUrl({
          action: "write",
          version: "v4",
          expires: expiresAt,
          contentType: input.contentType,
          extensionHeaders: Object.fromEntries(
            Object.entries(requiredHeaders).filter(
              ([name]) => name !== "content-type",
            ),
          ),
        });
      return {
        uploadId,
        uploadUrl,
        expiresAt: expiresAt.toISOString(),
        requiredHeaders,
      };
    } catch {
      throw new ChatError(
        "service_unavailable",
        "Photo upload is unavailable right now. Try again later.",
        503,
        true,
      );
    }
  }

  async validate(input: {
    userId: string;
    threadId: string;
    uploadId: string;
    fileName: string;
    contentType: ChatPhotoContentType;
    sizeBytes: number;
  }): Promise<ChatValidatedPhoto> {
    validatePhotoShape(input.contentType, input.sizeBytes);
    if (!isUploadId(input.uploadId)) throw invalidUpload();
    const path = objectPath(input.uploadId);
    const file = this.bucket.file(path);
    try {
      const [[metadata], [prefix]] = await Promise.all([
        file.getMetadata(),
        file.download({ start: 0, end: 15 }),
      ]);
      const custom = metadata.metadata && typeof metadata.metadata === "object"
        ? metadata.metadata as Record<string, unknown>
        : {};
      const storedSize = Number(metadata.size);
      const generation = String(metadata.generation ?? "").trim();
      if (
        metadata.contentType !== input.contentType ||
        storedSize !== input.sizeBytes ||
        generation.length === 0 ||
        custom["moolsocial-schema"] !== "chat-photo-v1" ||
        custom["moolsocial-owner"] !== digest(input.userId) ||
        custom["moolsocial-thread"] !== digest(input.threadId) ||
        custom["moolsocial-name"] !== digest(input.fileName) ||
        custom["moolsocial-size"] !== String(input.sizeBytes) ||
        !matchesFileSignature(prefix, input.contentType)
      ) {
        throw invalidUpload();
      }
      return {
        uploadId: input.uploadId,
        objectPath: path,
        generation,
        contentType: input.contentType,
        sizeBytes: input.sizeBytes,
      };
    } catch (error) {
      if (error instanceof ChatError) throw error;
      throw invalidUpload();
    }
  }

  async readUrl(input: {
    objectPath: string;
    generation: string;
  }): Promise<{ readUrl: string; expiresAt: string }> {
    if (!/^chat-private\/v1\/[0-9a-f-]{36}$/u.test(input.objectPath)) {
      throw invalidUpload();
    }
    const expiresAt = new Date(
      this.now().getTime() + CHAT_PHOTO_SIGNED_URL_SECONDS * 1_000,
    );
    try {
      const [readUrl] = await this.bucket
        .file(input.objectPath, { generation: input.generation })
        .getSignedUrl({
          action: "read",
          version: "v4",
          expires: expiresAt,
        });
      return { readUrl, expiresAt: expiresAt.toISOString() };
    } catch {
      throw new ChatError(
        "service_unavailable",
        "That photo is unavailable right now. Try again later.",
        503,
        true,
      );
    }
  }
}

function signedUploadHeaders(input: {
  userId: string;
  threadId: string;
  fileName: string;
  contentType: ChatPhotoContentType;
  sizeBytes: number;
}): Readonly<Record<string, string>> {
  return {
    "content-type": input.contentType,
    "content-length": String(input.sizeBytes),
    "x-goog-if-generation-match": "0",
    "x-goog-meta-moolsocial-schema": "chat-photo-v1",
    "x-goog-meta-moolsocial-owner": digest(input.userId),
    "x-goog-meta-moolsocial-thread": digest(input.threadId),
    "x-goog-meta-moolsocial-name": digest(input.fileName),
    "x-goog-meta-moolsocial-size": String(input.sizeBytes),
  };
}

function validatePhotoShape(
  contentType: ChatPhotoContentType,
  sizeBytes: number,
): void {
  if (
    !supportedTypes.has(contentType) ||
    !Number.isSafeInteger(sizeBytes) ||
    sizeBytes < 1 ||
    sizeBytes > CHAT_PHOTO_MAX_BYTES
  ) {
    throw new ChatError(
      "bad_request",
      "Choose a JPEG, PNG or WebP photo up to 4 MB.",
      400,
    );
  }
}

function matchesFileSignature(
  value: Buffer,
  contentType: ChatPhotoContentType,
): boolean {
  if (contentType === "image/jpeg") {
    return value.length >= 3 && value[0] === 0xff && value[1] === 0xd8 &&
      value[2] === 0xff;
  }
  if (contentType === "image/png") {
    return value.length >= 8 &&
      value.subarray(0, 8).equals(
        Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
      );
  }
  return value.length >= 12 && value.subarray(0, 4).toString("ascii") === "RIFF" &&
    value.subarray(8, 12).toString("ascii") === "WEBP";
}

function objectPath(uploadId: string): string {
  return `chat-private/v1/${uploadId}`;
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
    "That photo upload is invalid or expired. Choose the photo again.",
    400,
  );
}
