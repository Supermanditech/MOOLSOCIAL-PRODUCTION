import { createHash, randomUUID } from "node:crypto";

import type { Bucket } from "@google-cloud/storage";
import type { Firestore } from "firebase-admin/firestore";

import { WorkspaceProfileError } from "./workspace_profile_service.js";

export interface WorkspaceProofUploadGrant {
  uploadId: string;
  uploadUrl: string;
  expiresAt: string;
  requiredHeaders: Readonly<Record<string, string>>;
}

export interface WorkspaceProofStore {
  prepare(input: WorkspaceProofInput): Promise<WorkspaceProofUploadGrant>;
  confirm(input: WorkspaceProofInput & { uploadId: string }): Promise<string>;
  assertOwned(
    ownerUserId: string,
    proofId: string,
    proofReference: string,
  ): Promise<void>;
}

export interface WorkspaceProofInput {
  ownerUserId: string;
  proofId: string;
  fileName: string;
  contentType: string;
  sizeBytes: number;
}

const signedUrlSeconds = 300;
const maximumBytes = 10 * 1024 * 1024;
const contentTypes = new Set([
  "application/pdf",
  "image/jpeg",
  "image/png",
  "image/webp",
]);

export class GoogleCloudStorageWorkspaceProofStore implements WorkspaceProofStore {
  constructor(
    private readonly bucket: Bucket,
    private readonly firestore: Firestore,
    private readonly now: () => Date = () => new Date(),
    private readonly createUploadId: () => string = randomUUID,
  ) {}

  async prepare(input: WorkspaceProofInput): Promise<WorkspaceProofUploadGrant> {
    validateShape(input);
    const uploadId = this.createUploadId();
    if (!isUploadId(uploadId)) throw unavailable();
    const expiresAt = new Date(this.now().getTime() + signedUrlSeconds * 1_000);
    const headers = signedHeaders(input);
    try {
      const [uploadUrl] = await this.bucket.file(objectPath(uploadId)).getSignedUrl({
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

  async confirm(input: WorkspaceProofInput & { uploadId: string }): Promise<string> {
    validateShape(input);
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
      const generation = String(metadata.generation ?? "").trim();
      if (
        metadata.contentType !== input.contentType ||
        Number(metadata.size) !== input.sizeBytes ||
        !generation ||
        custom["moolsocial-schema"] !== "workspace-proof-v1" ||
        custom["moolsocial-owner"] !== digest(input.ownerUserId) ||
        custom["moolsocial-proof"] !== digest(input.proofId) ||
        custom["moolsocial-name"] !== digest(input.fileName) ||
        custom["moolsocial-size"] !== String(input.sizeBytes) ||
        !matchesSignature(prefix, input.contentType)
      ) {
        throw invalidUpload();
      }
      const proofReference = `proof_${digest(`${path}:${generation}`).slice(0, 32)}`;
      await this.firestore.collection("workspaceProofReferences")
        .doc(proofReference)
        .set({
          schemaVersion: 1,
          ownerUserId: input.ownerUserId,
          proofId: input.proofId,
          objectPath: path,
          generation,
          contentType: input.contentType,
          sizeBytes: input.sizeBytes,
          status: "received",
          receivedAt: this.now().toISOString(),
        }, { merge: false });
      return proofReference;
    } catch (error) {
      if (error instanceof WorkspaceProfileError) throw error;
      throw invalidUpload();
    }
  }

  async assertOwned(
    ownerUserId: string,
    proofId: string,
    proofReference: string,
  ): Promise<void> {
    if (proofId === "personal-kyc" && proofReference === "ACCOUNT-KYC") {
      const identity = await this.firestore.collection("identityVerifications")
        .doc(ownerUserId)
        .get();
      if (identity.exists && identity.get("status") === "verified") return;
      throw new WorkspaceProfileError(
        "verification_required",
        "Complete personal identity verification before submitting this Workspace.",
        409,
      );
    }
    const snapshot = await this.firestore.collection("workspaceProofReferences")
      .doc(proofReference)
      .get();
    if (
      !snapshot.exists ||
      snapshot.get("ownerUserId") !== ownerUserId ||
      snapshot.get("proofId") !== proofId ||
      snapshot.get("status") !== "received"
    ) {
      throw invalidUpload();
    }
  }
}

function signedHeaders(input: WorkspaceProofInput): Readonly<Record<string, string>> {
  return {
    "content-type": input.contentType,
    "content-length": String(input.sizeBytes),
    "x-goog-if-generation-match": "0",
    "x-goog-meta-moolsocial-schema": "workspace-proof-v1",
    "x-goog-meta-moolsocial-owner": digest(input.ownerUserId),
    "x-goog-meta-moolsocial-proof": digest(input.proofId),
    "x-goog-meta-moolsocial-name": digest(input.fileName),
    "x-goog-meta-moolsocial-size": String(input.sizeBytes),
  };
}

function validateShape(input: WorkspaceProofInput): void {
  if (
    !/^[a-z][a-z0-9-]{1,39}$/u.test(input.proofId) ||
    input.fileName.trim().length < 3 ||
    input.fileName.length > 180 ||
    !contentTypes.has(input.contentType) ||
    !Number.isSafeInteger(input.sizeBytes) ||
    input.sizeBytes < 1 ||
    input.sizeBytes > maximumBytes
  ) {
    throw new WorkspaceProfileError(
      "invalid_input",
      "Choose a PDF, JPG, PNG or WebP proof document up to 10 MB.",
      400,
    );
  }
}

function matchesSignature(prefix: Buffer, contentType: string): boolean {
  if (contentType === "application/pdf") {
    return prefix.length >= 5 && prefix.subarray(0, 5).toString("ascii") === "%PDF-";
  }
  if (contentType === "image/jpeg") {
    return prefix.length >= 3 && prefix[0] === 0xff && prefix[1] === 0xd8 && prefix[2] === 0xff;
  }
  if (contentType === "image/png") {
    return prefix.length >= 8 && prefix.subarray(0, 8).equals(
      Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    );
  }
  return prefix.length >= 12 &&
    prefix.subarray(0, 4).toString("ascii") === "RIFF" &&
    prefix.subarray(8, 12).toString("ascii") === "WEBP";
}

function objectPath(uploadId: string): string {
  return `workspace-private/v1/proofs/${uploadId}`;
}

function isUploadId(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/u.test(value);
}

function digest(value: string): string {
  return createHash("sha256").update(value).digest("hex");
}

function invalidUpload(): WorkspaceProfileError {
  return new WorkspaceProfileError(
    "invalid_proof_upload",
    "That proof upload could not be verified. Choose the document again.",
    400,
  );
}

function unavailable(): WorkspaceProfileError {
  return new WorkspaceProfileError(
    "service_unavailable",
    "Proof upload is unavailable right now. Try again later.",
    503,
    true,
  );
}
