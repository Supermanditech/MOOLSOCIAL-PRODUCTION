import {createHash} from "node:crypto";
import sharp from "sharp";
import type {Bucket, File} from "@google-cloud/storage";
import {FieldPath, type Firestore, type Transaction} from "firebase-admin/firestore";
import {applyCatalogueCommand, createCatalogueAggregate, referencedOfferTermAt, reviewedCanonicalProduct,
  type CatalogueAggregate, type CatalogueCommand} from "../commerce/catalogue_contract.js";
import {isSupplyCapabilityActive, type SupplyActor,
  type SupplyCapabilityQuery, type SupplyParticipantWorkspace} from "../commerce/supply_participant_contract.js";
import {WorkspaceProfileError, type WorkspaceProfileRecord} from "./workspace_profile_service.js";
import {publicSupplierPolicySnapshot, type WorkspaceSupplierPolicyService} from "./workspace_supplier_policy_service.js";

export interface NormalizedStoreProductImage {
  bytes: Buffer;
  source: {sha256: string; byteLength: number; width: number; height: number; mimeType: string};
  file: {sha256: string; byteLength: number; width: number; height: number;
    mimeType: "image/png"; normalized: true; frameCount: 1};
  /** Descriptive source measurement only; never review, approval or publication. */
  meetsPublicSourceFloor: boolean;
}
const productImageByteLimit = 8 * 1024 * 1024;
let productImageDecodes = 0;
function invalidProductImage(): WorkspaceProfileError {
  return new WorkspaceProfileError("invalid_image", "Use one complete PNG, JPEG or WebP image within the image limits. Your saved photo is unchanged.", 400);
}
/** Structural animation/truncation checks supplement, never replace, full pixel decoding. */
function productImageContainer(bytes: Buffer): "png" | "jpeg" | "webp" {
  if (bytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))) {
    let position = 8, chunks = 0, hasPixels = false;
    while (position + 12 <= bytes.length) {
      const length = bytes.readUInt32BE(position), kind = bytes.toString("ascii", position + 4, position + 8);
      if (length > bytes.length - position - 12 || ++chunks > 10000 ||
          (chunks === 1 && (kind !== "IHDR" || length !== 13)) ||
          ["acTL", "fcTL", "fdAT"].includes(kind)) throw invalidProductImage();
      if (kind === "IDAT") hasPixels = true;
      position += 12 + length;
      if (kind === "IEND") {
        if (length !== 0 || position !== bytes.length || !hasPixels) throw invalidProductImage();
        return "png";
      }
    }
    throw invalidProductImage();
  }
  if (bytes.length >= 12 && bytes.toString("ascii", 0, 4) === "RIFF" && bytes.toString("ascii", 8, 12) === "WEBP") {
    if (bytes.readUInt32LE(4) !== bytes.length - 8) throw invalidProductImage();
    let position = 12;
    while (position + 8 <= bytes.length) {
      const kind = bytes.toString("ascii", position, position + 4), length = bytes.readUInt32LE(position + 4);
      if (length > bytes.length - position - 8 || kind === "ANIM" || kind === "ANMF" ||
          (kind === "VP8X" && length >= 1 && (bytes[position + 8]! & 2) !== 0)) throw invalidProductImage();
      position += 8 + length + (length % 2);
    }
    if (position !== bytes.length) throw invalidProductImage();
    return "webp";
  }
  if (bytes.length >= 4 && bytes[0] === 255 && bytes[1] === 216 &&
      bytes[bytes.length - 2] === 255 && bytes[bytes.length - 1] === 217) return "jpeg";
  throw invalidProductImage();
}
/** Private derivative only. Caller must bind actual bytes to immutable owner/submission/upload identity. */
export async function normalizeStoreProductImage(input: Buffer): Promise<NormalizedStoreProductImage> {
  if (!Buffer.isBuffer(input) || input.length === 0 || input.length > productImageByteLimit) throw invalidProductImage();
  if (productImageDecodes >= 2) {
    throw new WorkspaceProfileError("service_unavailable", "Image processing is busy. Retry this original upload shortly.", 503, true);
  }
  // Capture before the first await: caller mutation cannot substitute bytes after a hash/metadata check.
  const bytes = Buffer.from(input);
  productImageDecodes++;
  try {
    const format = productImageContainer(bytes);
    const image = sharp(bytes, {failOn: "warning", limitInputPixels: 16 * 1024 * 1024, sequentialRead: true});
    const metadata = await image.metadata();
    if (metadata.format !== format || !metadata.width || !metadata.height ||
        metadata.width > 16384 || metadata.height > 16384 ||
        metadata.width * metadata.height > 16 * 1024 * 1024 ||
        (metadata.pages ?? 1) !== 1 || (metadata.delay?.length ?? 0) > 1) throw invalidProductImage();
    // Default re-encoding strips EXIF/ICC/XMP/IPTC. Never retain metadata or upscale a small saved image.
    const output = await image.rotate().resize({width: 1024, height: 1024, fit: "inside", withoutEnlargement: true})
      .png({compressionLevel: 6}).timeout({seconds: 5}).toBuffer({resolveWithObject: true});
    if (output.info.format !== "png" || !output.info.width || !output.info.height ||
        output.info.width > 1024 || output.info.height > 1024 || output.data.length > productImageByteLimit) throw invalidProductImage();
    const hash = (value: Buffer) => createHash("sha256").update(value).digest("hex").toUpperCase();
    return {bytes: Buffer.from(output.data),
      source: {sha256: hash(bytes), byteLength: bytes.length, width: metadata.width, height: metadata.height,
        mimeType: `image/${format}`},
      file: {sha256: hash(output.data), byteLength: output.data.length, width: output.info.width,
        height: output.info.height, mimeType: "image/png", normalized: true, frameCount: 1},
      meetsPublicSourceFloor: metadata.width >= 512 && metadata.height >= 512};
  } catch (error) {
    if (error instanceof WorkspaceProfileError) throw error;
    // Decoder diagnostics can contain internal paths/metadata; return only the actionable public error.
    throw invalidProductImage();
  } finally {
    productImageDecodes--;
  }
}

/** Private processing protocol. None of these records constitutes a public media reference. */
export interface StoreProductMediaRequest {
  storeId: string; skuId: string; submissionRevision: number; submissionFingerprint: string;
  sourceSha256: string; sourceByteLength: number; sourceMimeType: "image/png" | "image/jpeg" | "image/webp";
  idempotencyKey: string;
}
export interface StoreProductMediaUpload extends StoreProductMediaRequest {
  schemaVersion: 1; realm: "evaluation" | "production"; ownerUserId: string;
  uploadId: string; fingerprint: string; preparedAt: string; expiresAt: string;
  grantIssuedAt?: string;
  processed: null | {assetId: string; originalGeneration: string; derivativeGeneration: string;
    processedAt: string; source: NormalizedStoreProductImage["source"]; file: NormalizedStoreProductImage["file"];
    meetsPublicSourceFloor: boolean};
}
export interface StoreProductMediaObjects {
  prepare(upload: StoreProductMediaUpload): Promise<{uploadUrl: string; requiredHeaders: Record<string, string>}>;
  read(upload: StoreProductMediaUpload): Promise<{bytes: Buffer; generation: string}>;
  save(upload: StoreProductMediaUpload, generation: string, image: NormalizedStoreProductImage): Promise<{assetId: string; generation: string}>;
}
function mediaUnavailable(): WorkspaceProfileError {
  return new WorkspaceProfileError("service_unavailable", "Product-image storage is unavailable. Keep your saved photo and retry the original request.", 503, true);
}
function mediaRequest(body: Readonly<Record<string, unknown>>): StoreProductMediaRequest {
  exact(body, ["productMediaVersion", "storeId", "skuId", "submissionRevision", "submissionFingerprint",
    "sourceSha256", "sourceByteLength", "sourceMimeType", "idempotencyKey"]);
  if (body.productMediaVersion !== 1 || typeof body.sourceMimeType !== "string" || !["image/png", "image/jpeg", "image/webp"].includes(body.sourceMimeType) ||
      typeof body.sourceSha256 !== "string" || !/^(?:[A-F0-9]{64}|[a-f0-9]{64})$/u.test(body.sourceSha256) ||
      typeof body.submissionFingerprint !== "string" || !/^[A-F0-9]{64}$/u.test(body.submissionFingerprint)) invalid();
  return {storeId: id(body.storeId), skuId: id(body.skuId), submissionRevision: integer(body.submissionRevision),
    submissionFingerprint: body.submissionFingerprint, sourceSha256: body.sourceSha256,
    sourceByteLength: integer(body.sourceByteLength, 1, productImageByteLimit),
    sourceMimeType: body.sourceMimeType as StoreProductMediaRequest["sourceMimeType"], idempotencyKey: id(body.idempotencyKey)};
}
function mediaObjectPath(upload: StoreProductMediaUpload): string {
  return `private/product-media/v1/${upload.realm}/${upload.uploadId}/original`;
}
function checkedMediaUpload(raw: unknown, asOf: string): StoreProductMediaUpload {
  const value = exact(raw, ["schemaVersion", "realm", "ownerUserId", "uploadId", "fingerprint", "preparedAt", "expiresAt", "processed",
    "storeId", "skuId", "submissionRevision", "submissionFingerprint", "sourceSha256", "sourceByteLength", "sourceMimeType", "idempotencyKey"], ["grantIssuedAt"]);
  const {schemaVersion, realm, ownerUserId, uploadId, fingerprint, preparedAt, expiresAt, processed, grantIssuedAt, ...request} = value;
  const input = mediaRequest({productMediaVersion: 1, ...request}), owner = id(ownerUserId);
  const iso = (v: unknown): string => {
    if (typeof v !== "string" || !Number.isFinite(Date.parse(v)) || new Date(v).toISOString() !== v) invalid();
    return v;
  };
  const prepared = iso(preparedAt), expires = iso(expiresAt);
  const issued = grantIssuedAt === undefined ? prepared : iso(grantIssuedAt);
  if (schemaVersion !== 1 || typeof realm !== "string" || !["evaluation", "production"].includes(realm) ||
      uploadId !== cataloguePayloadHash([realm, input.storeId, input.skuId, owner, input.idempotencyKey]) ||
      fingerprint !== cataloguePayloadHash({realm, ownerUserId: owner, ...input}) || prepared > issued || issued > asOf || Date.parse(expires) - Date.parse(issued) !== 300000) invalid();
  if (processed !== null) {
    const p = exact(processed, ["assetId", "originalGeneration", "derivativeGeneration", "processedAt", "source", "file", "meetsPublicSourceFloor"]);
    for (const g of [p.originalGeneration, p.derivativeGeneration]) if (typeof g !== "string" || !/^[1-9][0-9]*$/u.test(g)) invalid();
    const source = exact(p.source, ["sha256", "byteLength", "width", "height", "mimeType"]);
    const file = exact(p.file, ["sha256", "byteLength", "width", "height", "mimeType", "normalized", "frameCount"]);
    const width = integer(source.width, 1, 16384), height = integer(source.height, 1, 16384);
    if (width * height > 16 * 1024 * 1024 || source.sha256 !== input.sourceSha256.toUpperCase() ||
        source.byteLength !== input.sourceByteLength || source.mimeType !== input.sourceMimeType ||
        typeof file.sha256 !== "string" || !/^[A-F0-9]{64}$/u.test(file.sha256) ||
        file.mimeType !== "image/png" || file.normalized !== true || file.frameCount !== 1 ||
        integer(file.width, 1, 1024) * integer(file.height, 1, 1024) > width * height ||
        integer(file.byteLength, 1, productImageByteLimit) < 1 ||
        p.meetsPublicSourceFloor !== (width >= 512 && height >= 512) || Date.parse(iso(p.processedAt)) < Date.parse(prepared) || iso(p.processedAt) > asOf ||
        p.assetId !== cataloguePayloadHash({uploadId, generation: p.originalGeneration, sha256: file.sha256})) invalid();
  }
  return structuredClone(value) as unknown as StoreProductMediaUpload;
}
/** Actual GCS adapter, enabled only with explicit configuration and enforced private-bucket policy. */
export class GoogleCloudStoreProductMediaObjects implements StoreProductMediaObjects {
  constructor(private readonly bucket: Bucket) {}
  private async assertPrivate(): Promise<void> {
    const [metadata] = await this.bucket.getMetadata();
    if (metadata.iamConfiguration?.publicAccessPrevention !== "enforced" ||
        metadata.iamConfiguration?.uniformBucketLevelAccess?.enabled !== true) throw mediaUnavailable();
  }
  private tags(upload: StoreProductMediaUpload): Record<string, string> {
    return {"moolsocial-schema": "private-product-media-v1", "moolsocial-binding": upload.fingerprint,
      "moolsocial-owner": cataloguePayloadHash(upload.ownerUserId), "moolsocial-source": upload.sourceSha256};
  }
  async prepare(upload: StoreProductMediaUpload) {
    try {
      await this.assertPrivate();
      const requiredHeaders = {"content-type": upload.sourceMimeType, "content-length": String(upload.sourceByteLength),
        "x-goog-if-generation-match": "0", ...Object.fromEntries(Object.entries(this.tags(upload)).map(([k, v]) => [`x-goog-meta-${k}`, v]))};
      const [uploadUrl] = await this.bucket.file(mediaObjectPath(upload)).getSignedUrl({version: "v4", action: "write",
        expires: new Date(upload.expiresAt), contentType: upload.sourceMimeType,
        extensionHeaders: Object.fromEntries(Object.entries(requiredHeaders).filter(([k]) => k !== "content-type"))});
      return {uploadUrl, requiredHeaders};
    } catch {throw mediaUnavailable();}
  }
  private async boundedBytes(file: File): Promise<Buffer> {
    const stream = file.createReadStream({validation: "crc32c"});
    const timer = setTimeout(() => stream.destroy(mediaUnavailable()), 10000);
    timer.unref();
    const chunks: Buffer[] = []; let size = 0;
    try {
      for await (const raw of stream) {
        const chunk = Buffer.from(raw); size += chunk.length;
        if (size > productImageByteLimit) {stream.destroy(); throw invalidProductImage();}
        chunks.push(chunk);
      }
      return Buffer.concat(chunks, size);
    } finally {clearTimeout(timer); stream.destroy();}
  }
  async read(upload: StoreProductMediaUpload) {
    try {
      await this.assertPrivate();
      const path = mediaObjectPath(upload), [head] = await this.bucket.file(path).getMetadata();
      const generation = String(head.generation ?? "");
      if (!/^[1-9][0-9]*$/u.test(generation)) throw invalidProductImage();
      const pinned = this.bucket.file(path, {generation}), [metadata] = await pinned.getMetadata();
      const created = Date.parse(metadata.timeCreated ?? ""), custom = metadata.metadata ?? {};
      if (String(metadata.generation) !== generation || metadata.contentType !== upload.sourceMimeType ||
          Number(metadata.size) !== upload.sourceByteLength || !Number.isFinite(created) ||
          created < Date.parse(upload.preparedAt) || created > Date.parse(upload.expiresAt) ||
          Object.entries(this.tags(upload)).some(([k, v]) => custom[k] !== v) ||
          Object.hasOwn(custom, "firebaseStorageDownloadTokens")) throw invalidProductImage();
      const bytes = await this.boundedBytes(pinned);
      if (bytes.length !== upload.sourceByteLength) throw invalidProductImage();
      return {bytes, generation};
    } catch (error) {
      if (error instanceof WorkspaceProfileError) throw error;
      throw mediaUnavailable();
    }
  }
  async save(upload: StoreProductMediaUpload, generation: string, image: NormalizedStoreProductImage) {
    try {
      await this.assertPrivate();
      const assetId = cataloguePayloadHash({uploadId: upload.uploadId, generation, sha256: image.file.sha256});
      const path = `private/product-media/v1/${upload.realm}/${upload.uploadId}/derivatives/${assetId}.png`;
      const metadata = {...this.tags(upload), "moolsocial-original-generation": generation, "moolsocial-sha256": image.file.sha256};
      try {
        await this.bucket.file(path).save(image.bytes, {resumable: false, preconditionOpts: {ifGenerationMatch: 0},
          metadata: {contentType: "image/png", cacheControl: "private, no-store", metadata}});
      } catch (error) {if ((error as {code?: number}).code !== 412) throw error;}
      // Original-attempt recovery after an object write/receipt gap verifies the existing immutable derivative.
      const [head] = await this.bucket.file(path).getMetadata(), derivativeGeneration = String(head.generation ?? "");
      if (!/^[1-9][0-9]*$/u.test(derivativeGeneration)) throw invalidProductImage();
      const pinned = this.bucket.file(path, {generation: derivativeGeneration}), [stored] = await pinned.getMetadata();
      if (String(stored.generation) !== derivativeGeneration || stored.contentType !== "image/png" || Number(stored.size) !== image.bytes.length ||
          Object.entries(metadata).some(([k, v]) => stored.metadata?.[k] !== v) ||
          Object.hasOwn(stored.metadata ?? {}, "firebaseStorageDownloadTokens") ||
          createHash("sha256").update(await this.boundedBytes(pinned)).digest("hex").toUpperCase() !== image.file.sha256) throw invalidProductImage();
      return {assetId, generation: derivativeGeneration};
    } catch (error) {if (error instanceof WorkspaceProfileError) throw error; throw mediaUnavailable();}
  }
}

/** Publication mirror only. Never an inventory, order, payment or approval ledger. */
export interface StoreSkuContent {
  title: string; brand: string; variant: string; categoryId: string;
  description: string; highlights: string[];
  specifications: Array<{label: string; value: string}>;
  productFacts?: StoreSkuProductFacts;
  media: Array<{id: string; revision: string; url: string; storeId: string;
    skuId: string; canonicalProductId: string; publisherWorkspaceId: string;
    file: {mimeType: string; byteLength: number; width: number; height: number; normalized: boolean; frameCount?: number}}>;
}
/** Reviewed descriptive facts only; not regulatory approval or dispensing authority. */
export interface StoreSkuProductFacts {
  schemaVersion: 1;
  compliance: Record<"genericName" | "netQuantity" | "manufacturerName" | "manufacturerAddress" |
    "packerName" | "packerAddress" | "importerName" | "importerAddress" | "countryOfOrigin" |
    "manufacturedOrPackedOn" | "bestBeforeOrUseBy" | "fssaiLicenseNumber" | "consumerCare", string | null>;
  composition: string | null; regulatoryNote: string | null; requiresPrescription: boolean;
}
export interface StoreSkuPack {
  label: string; quantityMilli: number; unit: "kg" | "L" | "count"; unitsPerCase: number;
}
export interface StoreSkuChannel {
  kind: "retail" | "wholesale" | "bulk"; offerId: string;
  priceMinor: number; mrpMinor: number | null; minimumOrder: number;
  quantityStep: number; tiers: Array<{minimumQuantity: number; unitPriceMinor: number}>;
}
export interface StoreSkuInput {
  skuId: string; canonicalProductId: string; verifiedPackId: string; sku: string;
  publicListing: boolean; content: StoreSkuContent; pack: StoreSkuPack;
  channels: StoreSkuChannel[];
  provenance: {entryMethod: "catalogue" | "manual" | "csv"; sourceRecordId: string};
}
export interface StoreSkuRecord extends StoreSkuInput {
  schemaVersion: 1; storeId: string; revision: number; observedAt: string;
}
/** Owner-authored intent, not canonical/pack/offer identity or publication. */
export interface StoreProductSubmissionInput {
  schemaVersion: 1; skuId: string; sku: string; barcode: string;
  catalogueProductHint: string | null;
  content: Omit<StoreSkuContent, "media">; pack: StoreSkuPack;
  channels: Array<Omit<StoreSkuChannel, "offerId">>;
  provenance: StoreSkuInput["provenance"];
  mediaIntent: {pendingUpload: boolean; pendingSelectionSha256: string | null; publishedReferences: Array<{assetId: string; revision: string}>};
  variantIntent: {familyId: string; localRevision: number; selections: Record<string, string>} | null;
}
export interface StoreProductSubmissionRecord {
  schemaVersion: 1; realm: "evaluation" | "production"; storeId: string; skuId: string;
  revision: number; submittedAt: string; submittedBy: string; fingerprint: string;
  product: StoreProductSubmissionInput;
}
export interface StoreProductSubmissionCommand {
  ownerUserId: string; realm: StoreProductSubmissionRecord["realm"]; storeId: string;
  expectedRevision: number; idempotencyKey: string; submittedAt: string; fingerprint: string;
  product: StoreProductSubmissionInput;
}
export interface StoreProductSubmissionReceipt {fingerprint: string; record: StoreProductSubmissionRecord}
/** Server-issued listing identity. Original Store SKU/Stock identity is unchanged. */
export interface PublicCatalogueListingBinding {
  schemaVersion: 1; realm: "evaluation" | "production"; listingId: string;
  storeId: string; skuId: string; channel: StoreSkuChannel["kind"];
  canonicalProductId: string; verifiedPackId: string;
}
export interface CatalogueSave {
  ownerUserId: string; profile: WorkspaceProfileRecord; expectedRevision: number;
  idempotencyKey: string; fingerprint: string; input: StoreSkuInput; observedAt: string;
  reviewCandidate?: {revision: number; fingerprint: string};
}
export interface StoreReviewedProductCandidate {
  schemaVersion: 1; realm: "evaluation" | "production"; storeId: string; skuId: string;
  revision: number; fingerprint: string; source: CatalogueSubmissionReference;
  identity: CatalogueIdentity; sku: StoreSkuInput; expectedMirrorRevision: number;
  reviewedBy: string; reviewedAt: string; expiresAt: string;
  terms: Array<{kind: StoreSkuChannel["kind"]; offerId: string; termSnapshotId: string; termSnapshotSha256: string;
    effectiveFrom: string; expiresAt: string}>;
}
export interface StoreProductReviewReadback {
  record: StoreProductSubmissionRecord | null;
  review: {version: 1; state: "pending" | "awaiting_media" | "ready" | "bound" | "outdated" | "unavailable";
    candidate: StoreReviewedProductCandidate | null};
}
/** Explicitly public, descriptive owner text. Never upload private settings. */
export interface StorePublicDetailsInput {
  street: string; city: string; state: string; pinCode: string;
  publicContactPhone: string; openingTime: string; closingTime: string;
  businessType?: "" | "retailer" | "wholesaler" | "manufacturer" | "supplier";
}
export interface StorePublicDetailsRecord {
  schemaVersion: 1; realm: "evaluation" | "production"; storeId: string;
  revision: number; publishedAt: string; details: StorePublicDetailsInput;
}
export interface StorePublicDetailsCommand {
  ownerUserId: string; storeId: string; realm: StorePublicDetailsRecord["realm"];
  expectedRevision: number; idempotencyKey: string; fingerprint: string;
  publishedAt: string; details: StorePublicDetailsInput;
}
export interface StorePublicDetailsReceipt {fingerprint: string; record: StorePublicDetailsRecord}
export interface WorkspaceCatalogueRepository {
  readonly realm: "evaluation" | "production";
  store(storeId: string): Promise<WorkspaceProfileRecord | undefined>;
  save(command: CatalogueSave): Promise<StoreSkuRecord>;
  bindReviewed?(command: CatalogueSave, identity: CatalogueIdentity): Promise<StoreSkuRecord>;
  readSaveReceipt?(command: CatalogueSave): Promise<StoreSkuRecord | undefined>;
  page(profile: WorkspaceProfileRecord, ownerUserId: string | undefined,
    after: string | undefined, limit: number, skuId?: string): Promise<StoreSkuRecord[]>;
  catalogue(catalogueId: string): Promise<CatalogueAggregate | undefined>;
  submitProduct?(command: StoreProductSubmissionCommand): Promise<StoreProductSubmissionRecord>;
  reconcileProduct?(command: StoreProductSubmissionCommand): Promise<StoreProductSubmissionRecord | undefined>;
  readProductSubmission?(storeId: string, skuId: string, ownerUserId: string): Promise<StoreProductSubmissionRecord | undefined>;
  productMedia?(ownerUserId: string, action: "prepare" | "confirm" | "read", request: StoreProductMediaRequest): Promise<object>;
  readReviewedProductSubmission?(storeId: string, skuId: string, ownerUserId: string,
    identity: CatalogueIdentity): Promise<StoreProductReviewReadback>;
  /** Complete bounded directory, never public product facts or approval. */
  publicDiscoveryBindings?(): Promise<PublicCatalogueListingBinding[]>;
  publicListingBindings?(record: StoreSkuRecord): Promise<PublicCatalogueListingBinding[] | undefined>;
  confirmPublicListingSnapshot?(storeId: string, records: readonly StoreSkuRecord[],
    identity: CatalogueIdentity, catalogueFingerprint: string, detailsFingerprint?: string): Promise<WorkspaceProfileRecord | undefined>;
  publicCatalogueSource?(storeId: string, identity: CatalogueIdentity, includeFamilies?: boolean): Promise<PublicCatalogueSource | undefined>;
  readStorePublicDetails?(storeId: string, ownerUserId?: string): Promise<StorePublicDetailsRecord | undefined>;
  saveStorePublicDetails?(command: StorePublicDetailsCommand): Promise<StorePublicDetailsRecord>;
  reconcileStorePublicDetails?(command: StorePublicDetailsCommand): Promise<StorePublicDetailsRecord | undefined>;
  submitVariantFamily?(command: StoreVariantFamilySubmission): Promise<StoreVariantFamilyCandidate>;
  reconcileVariantFamily?(command: StoreVariantFamilySubmission): Promise<StoreVariantFamilyCandidate | undefined>;
  readVariantFamily?(storeId: string, familyId: string, ownerUserId: string): Promise<{
    candidate: StoreVariantFamilyCandidate | null; review: StoreVariantFamilyReview | null}>;
}

/** Bounded whole-candidate read, including excluded/unlisted records. Never
 * expose this private envelope to clients; only reviewed projection is public. */
export interface PublicCatalogueSource {
  profile: WorkspaceProfileRecord; catalogue: CatalogueAggregate; records: StoreSkuRecord[];
  bindings: PublicCatalogueListingBinding[]; policy: unknown; publicDetails?: unknown;
  variantFamilies?: {revision: number; reviews: StoreVariantFamilyReview[]};
}

export function normalizeStorePublicDetails(raw: unknown): StorePublicDetailsInput {
  const value = exact(raw, ["street", "city", "state", "pinCode", "publicContactPhone", "openingTime", "closingTime"], ["businessType"]);
  const classified = Object.hasOwn(value, "businessType");
  if (classified && (typeof value.businessType !== "string" ||
      !["", "retailer", "wholesaler", "manufacturer", "supplier"].includes(value.businessType))) invalid();
  const details = {street: text(value.street, 2000), city: text(value.city), state: text(value.state),
    pinCode: text(value.pinCode, 6), publicContactPhone: text(value.publicContactPhone, 30, true),
    openingTime: text(value.openingTime, 16, true), closingTime: text(value.closingTime, 16, true)};
  const digits = details.publicContactPhone.replace(/[^0-9]/gu, "");
  const validTime = /^(?:(?:[01]?\d|2[0-3]):[0-5]\d|(?:0?[1-9]|1[0-2]):[0-5]\d\s*[AP]M)$/iu;
  if (!/^[1-9][0-9]{5}$/u.test(details.pinCode) ||
      details.publicContactPhone !== "" && (!/^\+?[0-9][0-9 ()-]*$/u.test(details.publicContactPhone) || digits.length < 7 || digits.length > 15) ||
      (details.openingTime !== "" || details.closingTime !== "") &&
        (!validTime.test(details.openingTime) || !validTime.test(details.closingTime))) invalid("Check public address, contact and hours.");
  return {...details, ...(classified ? {businessType: value.businessType as NonNullable<StorePublicDetailsInput["businessType"]>} : {})};
}
function publicDetailsRecord(raw: unknown, realm: string, storeId: string): StorePublicDetailsRecord {
  const value = exact(raw, ["schemaVersion", "realm", "storeId", "revision", "publishedAt", "details"]);
  if (value.schemaVersion !== 1 || value.realm !== realm || value.storeId !== storeId ||
      typeof value.publishedAt !== "string" || !Number.isFinite(Date.parse(value.publishedAt)) ||
      new Date(value.publishedAt).toISOString() !== value.publishedAt) invalid();
  return {schemaVersion: 1, realm: realm as StorePublicDetailsRecord["realm"], storeId,
    revision: integer(value.revision, 1, 1000000000), publishedAt: value.publishedAt,
    details: normalizeStorePublicDetails(value.details)};
}
function detailsCommand(ownerUserId: string, realm: StorePublicDetailsRecord["realm"], body: Readonly<Record<string, unknown>>, at: string): StorePublicDetailsCommand {
  exact(body, ["storeId", "expectedRevision", "idempotencyKey", "details"]);
  const storeId = id(body.storeId), user = id(ownerUserId), expectedRevision = integer(body.expectedRevision, 0, 999999999);
  const details = normalizeStorePublicDetails(body.details);
  return {ownerUserId: user, storeId, realm, expectedRevision, details, idempotencyKey: id(body.idempotencyKey),
    publishedAt: at, fingerprint: cataloguePayloadHash({ownerUserId: user, storeId, realm, expectedRevision, details})};
}
function originalPublicDetails(command: StorePublicDetailsCommand, receipt: StorePublicDetailsReceipt): StorePublicDetailsRecord {
  const record = publicDetailsRecord(receipt.record, command.realm, command.storeId);
  if (receipt.fingerprint !== command.fingerprint || record.revision !== command.expectedRevision + 1 ||
      cataloguePayloadHash(record.details) !== cataloguePayloadHash(command.details)) {
    throw new WorkspaceProfileError("conflict", "This public-details request changed. Check its original result.", 409);
  }
  return record;
}
function publicDetailsProjection(raw: unknown, realm: string, storeId: string, profile: WorkspaceProfileRecord, at: string,
  classificationRequested = false): object {
  const base = {schemaVersion: 1, realm, storeId, observedAt: at, locationVerified: false,
    publicAvailabilityConfirmed: false, area: typeof profile.area === "string" ? text(profile.area, 240, true) : null};
  if (raw === undefined) return {...base, state: "unavailable", revision: null, details: null};
  if (raw === null) return {...base, state: "none", revision: 0, details: null};
  try {
    const record = publicDetailsRecord(raw, realm, storeId);
    if (record.publishedAt > at) throw new Error("Future metadata");
    const {businessType, ...legacyDetails} = record.details;
    return {...base, state: "ready", revision: record.revision,
      details: classificationRequested ? record.details : legacyDetails};
  } catch { return {...base, state: "unavailable", revision: null, details: null}; }
}
export function planStorePublicDetailsSave(command: StorePublicDetailsCommand, profile: WorkspaceProfileRecord | undefined,
  current?: StorePublicDetailsRecord, receipt?: StorePublicDetailsReceipt): StorePublicDetailsRecord {
  requireStore(profile, command.storeId, command.ownerUserId);
  if (!["evaluation", "production"].includes(command.realm)) invalid();
  if (receipt) return originalPublicDetails(command, receipt);
  const previous = current && publicDetailsRecord(current, command.realm, command.storeId);
  if (previous?.details.businessType !== undefined && command.details.businessType === undefined) {
    invalid("Keep the public business type or explicitly choose not to show it.");
  }
  if ((previous?.revision ?? 0) !== command.expectedRevision) {
    throw new WorkspaceProfileError("revision_conflict", "Public Store details changed. Refresh before saving.", 409);
  }
  return publicDetailsRecord({schemaVersion: 1, realm: command.realm, storeId: command.storeId,
    revision: command.expectedRevision + 1, publishedAt: command.publishedAt,
    details: normalizeStorePublicDetails(command.details)}, command.realm, command.storeId);
}

/** Stable persisted identity, not a claim of publication, stock or eligibility. */
export function cataloguePublicListingBindings(realm: "evaluation" | "production", value: StoreSkuRecord): PublicCatalogueListingBinding[] {
  if (!["evaluation", "production"].includes(realm)) invalid();
  const record = normalizeRecord(value, id(value.storeId));
  return record.channels.map(channel => ({schemaVersion: 1, realm,
    listingId: `listing-${cataloguePayloadHash([1, realm, record.storeId, record.skuId, channel.kind]).toLowerCase()}`,
    storeId: record.storeId, skuId: record.skuId, channel: channel.kind,
    canonicalProductId: record.canonicalProductId, verifiedPackId: record.verifiedPackId}));
}
function checkedListingBinding(value: unknown, expected: PublicCatalogueListingBinding): PublicCatalogueListingBinding {
  const row = exact(value, ["schemaVersion", "realm", "listingId", "storeId", "skuId", "channel", "canonicalProductId", "verifiedPackId"]);
  if (cataloguePayloadHash(row) !== cataloguePayloadHash(expected)) invalid("Public listing identity conflicts with its saved SKU.");
  return structuredClone(expected);
}
function discoveryBinding(value: unknown, realm: WorkspaceCatalogueRepository["realm"]): PublicCatalogueListingBinding {
  const row = exact(value, ["schemaVersion", "realm", "listingId", "storeId", "skuId", "channel", "canonicalProductId", "verifiedPackId"]);
  if (row.schemaVersion !== 1 || row.realm !== realm || typeof row.channel !== "string" ||
      !["retail", "wholesale", "bulk"].includes(row.channel)) invalid("Listing directory is invalid.");
  const storeId = id(row.storeId), skuId = id(row.skuId), channel = row.channel as StoreSkuChannel["kind"];
  return checkedListingBinding(row, {schemaVersion: 1, realm, storeId, skuId, channel,
    canonicalProductId: id(row.canonicalProductId), verifiedPackId: id(row.verifiedPackId),
    listingId: `listing-${cataloguePayloadHash([1, realm, storeId, skuId, channel]).toLowerCase()}`});
}
export interface CatalogueIdentity {catalogueId: string; tenantId: string}

/** Server-owned grants, never accepted from an owner/client request. No grant writer. */
export interface CatalogueProducerAuthority {
  schemaVersion: 1; userId: string; revision: number; enabled: boolean;
  actor: SupplyActor; validFrom: string; expiresAt: string;
}
export interface CatalogueSubmissionReference {
  realm: "evaluation" | "production"; storeId: string; skuId: string;
  revision: number; fingerprint: string;
}
export interface CatalogueProductionReceipt {
  fingerprint: string; result: CatalogueAggregate; submission?: CatalogueSubmissionReference;
}
export interface CatalogueProduction {
  operatorUserId: string; identity: CatalogueIdentity;
  input: Readonly<Record<string, unknown>>; observedAt: string;
  submission?: CatalogueSubmissionReference;
}

function submissionReference(raw: unknown): CatalogueSubmissionReference {
  const value = exact(raw, ["realm", "storeId", "skuId", "revision", "fingerprint"]);
  if (!["evaluation", "production"].includes(String(value.realm)) ||
      typeof value.fingerprint !== "string" || !/^[A-F0-9]{64}$/u.test(value.fingerprint)) invalid();
  return {realm: value.realm as CatalogueSubmissionReference["realm"], storeId: id(value.storeId),
    skuId: id(value.skuId), revision: integer(value.revision, 1, 1000000000), fingerprint: value.fingerprint};
}

/** Derive facts from a saved source, never accept owner-supplied approval or hashes.
 * Media nominations need the separate verified asset producer; do not drop them.
 */
export function submittedCatalogueInput(source: StoreProductSubmissionRecord,
  raw: Readonly<Record<string, unknown>>): Record<string, unknown> {
  const saved = checkedProductSubmission(source, source.realm, source.storeId, source.skuId);
  if (saved.product.mediaIntent.pendingUpload || saved.product.mediaIntent.publishedReferences.length !== 0) {
    throw new WorkspaceProfileError("unavailable", "Product images must finish their review first.", 503);
  }
  const type = text(raw.type, 32), common = ["type", "commandId", "expectedVersion", "productId"];
  const contentSha256 = cataloguePayloadHash({...saved.product.content, media: []});
  if (type === "propose_product") {
    exact(raw, [...common, "brandId", "codes"]);
    return productionInput({...raw, categoryId: saved.product.content.categoryId, contentSha256});
  }
  if (type === "propose_product_revision") {
    exact(raw, [...common, "previousContentSha256"]);
    return productionInput({...raw, contentSha256});
  }
  if (type === "propose_pack") {
    exact(raw, [...common, "packId", "codes"]);
    return productionInput({...raw, descriptorSha256: cataloguePayloadHash(saved.product.pack)});
  }
  invalid("Saved submissions can only propose product facts or packs; independent review remains separate.");
}

function producerActor(operator: string, identity: CatalogueIdentity, at: string,
  authority: CatalogueProducerAuthority | undefined): SupplyActor {
  const deny = () => new WorkspaceProfileError("forbidden", "Catalogue authority is not available.", 403);
  if (!Number.isFinite(Date.parse(at)) || !authority || authority.schemaVersion !== 1 || authority.userId !== operator ||
      authority.enabled !== true || !Number.isSafeInteger(authority.revision) || authority.revision < 1 ||
      authority.actor?.actorId !== operator || authority.actor.tenantId !== identity.tenantId ||
      !Array.isArray(authority.actor.scopes) ||
      !Number.isFinite(Date.parse(authority.validFrom)) || !Number.isFinite(Date.parse(authority.expiresAt)) ||
      Date.parse(at) < Date.parse(authority.validFrom) || Date.parse(at) >= Date.parse(authority.expiresAt)) throw deny();
  return structuredClone(authority.actor);
}

function currentCapability(participant: SupplyParticipantWorkspace, query: SupplyCapabilityQuery): boolean {
  if (participant.schemaVersion !== 1 || !Array.isArray(participant.capabilities)) return false;
  const records = participant.capabilities.filter(c => c?.kind === query.capability);
  const capability = records[0];
  if (records.length !== 1 || !capability || !Number.isFinite(Date.parse(capability.effectiveFrom ?? "")) ||
      !Number.isFinite(Date.parse(capability.expiresAt ?? "")) ||
      Date.parse(capability.effectiveFrom!) >= Date.parse(capability.expiresAt!) ||
      !Array.isArray(capability.qualifiers?.categoryIds) || !Array.isArray(capability.qualifiers?.serviceAreaIds)) return false;
  return isSupplyCapabilityActive(participant, query);
}

function productionInput(raw: Readonly<Record<string, unknown>>): Record<string, unknown> {
  const type = text(raw.type, 32);
  const fields: Record<string, string[]> = {
    create: [],
    propose_product: ["productId", "categoryId", "brandId", "contentSha256", "codes"],
    review_product: ["productId", "decision", "reasonCode", "expectedContentSha256"],
    propose_product_revision: ["productId", "previousContentSha256", "contentSha256"],
    review_product_revision: ["productId", "revision", "previousContentSha256", "contentSha256", "decision", "reasonCode"],
    propose_pack: ["packId", "productId", "descriptorSha256", "codes"],
    review_pack: ["packId", "decision", "reasonCode", "expectedDescriptorSha256"],
    create_offer: ["offerId", "packId", "buyingContext", "serviceAreaIds", "termWindows"],
  };
  if (!Object.hasOwn(fields, type)) invalid("Unsupported catalogue operation.");
  exact(raw, ["type", "commandId", ...(type === "create" ? [] : ["expectedVersion"]), ...fields[type]!]);
  const input = structuredClone(raw) as Record<string, unknown>;
  input.commandId = id(input.commandId);
  if (type !== "create") input.expectedVersion = integer(input.expectedVersion, 1, 1_000_000_000);
  if (type === "review_product_revision") input.revision = integer(input.revision, 2, 101);
  for (const key of ["productId", "categoryId", "brandId", "packId", "offerId", "reasonCode"]) {
    if (key === "brandId" && input[key] === null && type === "propose_product" && input.categoryId === "fruits-vegetables") continue;
    if (key in input) input[key] = id(input[key]);
  }
  for (const key of ["contentSha256", "previousContentSha256", "descriptorSha256", "expectedContentSha256", "expectedDescriptorSha256"]) {
    if (key in input) {
      const hash = text(input[key], 64);
      if (!/^[A-Fa-f0-9]{64}$/u.test(hash)) invalid();
      input[key] = hash.toUpperCase();
    }
  }
  if ("decision" in input && (typeof input.decision !== "string" || !["verify", "reject"].includes(input.decision))) invalid();
  for (const key of ["codes", "serviceAreaIds", "termWindows"]) {
    if (key in input && !Array.isArray(input[key])) invalid();
  }
  // The shared contract validates code checksums, windows, capabilities and transitions.
  return input;
}

/** Pure transaction planner; input contains no actor, approval or client timestamp. */
export function planCatalogueProduction(command: CatalogueProduction,
  authority: CatalogueProducerAuthority | undefined,
  current?: CatalogueAggregate, participant?: SupplyParticipantWorkspace,
  profile?: WorkspaceProfileRecord, receipt?: CatalogueProductionReceipt,
  authorizationAt = command.observedAt):
  {aggregate: CatalogueAggregate; fingerprint: string; replayed: boolean} {
  const operator = id(command.operatorUserId);
  const identity = {catalogueId: id(command.identity.catalogueId), tenantId: id(command.identity.tenantId)};
  const input = productionInput(command.input);
  const at = command.observedAt;
  if (!Number.isFinite(Date.parse(at)) || new Date(at).toISOString() !== at) invalid();
  const deny = () => new WorkspaceProfileError("forbidden", "Catalogue authority is not available.", 403);
  const actor = producerActor(operator, identity, authorizationAt, authority);
  const validAggregate = (value: CatalogueAggregate) => value.schemaVersion === 1 &&
    value.catalogueId === identity.catalogueId && value.tenantId === identity.tenantId &&
    Number.isSafeInteger(value.version) && value.version >= 1;
  if (current && !validAggregate(current)) invalid("Catalogue identity changed.");
  const participantOperation = ["propose_product", "propose_product_revision", "propose_pack", "create_offer"].includes(String(input.type));
  if (!participantOperation) {
    if (!actor.scopes.includes("supply.catalogue.review")) throw deny();
  } else {
    if (!participant || participant.schemaVersion !== 1 || participant.status !== "registered" ||
        participant.tenantId !== identity.tenantId || actor.workspaceId !== participant.workspaceId ||
        !actor.scopes.includes("supply.workspace.admin")) throw deny();
    requireStore(profile, participant.workspaceId, operator);
    const productId = input.type === "create_offer"
      ? current?.packs.find(p => p.packId === input.packId)?.productId : input.productId;
    const categoryId = input.type === "propose_product" ? input.categoryId as string :
      current?.products.find(p => p.productId === productId)?.categoryId;
    const capability = input.type === "create_offer"
      ? (input.buyingContext === "consumer" ? "retail_fulfilment" : "wholesale_supply")
      : "product_master_stewardship";
    const areas = input.type === "create_offer" ? input.serviceAreaIds as string[] : [undefined];
    if (!categoryId || areas.length === 0 || areas.some(serviceAreaId => !currentCapability(participant, {
      capability, at: authorizationAt, categoryId, ...(serviceAreaId === undefined ? {} : {serviceAreaId}),
    }))) throw deny();
  }
  const submission = command.submission === undefined ? undefined : submissionReference(command.submission);
  if (submission && actor.workspaceId !== submission.storeId) throw deny();
  const fingerprint = cataloguePayloadHash({operator, identity, input, ...(submission ? {submission} : {})});
  if (receipt) {
    if (receipt.fingerprint !== fingerprint || !validAggregate(receipt.result) || !current ||
        receipt.result.version > current.version) {
      throw new WorkspaceProfileError("conflict", "Catalogue command changed. Use its original request.", 409);
    }
    return {aggregate: structuredClone(receipt.result), fingerprint, replayed: true};
  }
  let aggregate: CatalogueAggregate;
  if (input.type === "create") {
    if (current) throw new WorkspaceProfileError("conflict", "Catalogue already exists.", 409);
    aggregate = createCatalogueAggregate({commandId: input.commandId as string,
      ...identity, occurredAt: at, actor});
  } else {
    if (!current) throw new WorkspaceProfileError("not_found", "Catalogue is not available.", 404);
    const {expectedContentSha256, expectedDescriptorSha256, ...fields} = input;
    if (input.type === "review_product" && current.products.find(p => p.productId === input.productId)
      ?.contentSha256.toUpperCase() !== expectedContentSha256) invalid("Review content changed.");
    if (input.type === "review_pack" && current.packs.find(p => p.packId === input.packId)
      ?.descriptorSha256.toUpperCase() !== expectedDescriptorSha256) invalid("Review pack changed.");
    aggregate = applyCatalogueCommand(current, {...fields, catalogueId: identity.catalogueId,
      occurredAt: at, actor} as unknown as CatalogueCommand, participant);
  }
  return {aggregate, fingerprint, replayed: false};
}

/** Shared with the existing HTTP handler: internal review is never an operation. */
export function storeVariantFamilyOperation(operation: unknown): "submit" | "owner_read" | "public_read" | undefined {
  if (operation === "submitStoreVariantFamily") return "submit";
  if (operation === "readStoreVariantFamily" || operation === "reconcileStoreVariantFamily") return "owner_read";
  if (operation === "readPublicStoreVariantFamilies") return "public_read";
  return undefined;
}
export function storeProductSubmissionOperation(operation: unknown): "submit" | "read" | "reconcile" | undefined {
  if (operation === "submitStoreProduct") return "submit";
  if (operation === "readStoreProductSubmission") return "read";
  if (operation === "reconcileStoreProductSubmission") return "reconcile";
  return undefined;
}

export class WorkspaceCatalogueService {
  constructor(private readonly repository: WorkspaceCatalogueRepository,
    private readonly identity?: CatalogueIdentity,
    private readonly now: () => Date = () => new Date(),
    private readonly policyReader?: Pick<WorkspaceSupplierPolicyService, "forPublicSku">) {}

  async handleProductMedia(ownerUserId: string, operation: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    const action = operation === "prepareStoreProductMedia" ? "prepare" : operation === "confirmStoreProductMedia" ? "confirm"
      : operation === "readStoreProductMedia" ? "read" : undefined;
    if (!action) invalid();
    const request = mediaRequest(structuredClone(body));
    if (!this.repository.productMedia) throw mediaUnavailable();
    return this.repository.productMedia(id(ownerUserId), action, request);
  }

  async handleProductSubmission(ownerUserId: string, operation: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    const action = storeProductSubmissionOperation(operation);
    if (!action || body.productSubmissionVersion !== 1) invalid();
    const {productSubmissionVersion: _, productReviewVersion, ...request} = structuredClone(body);
    if (productReviewVersion !== undefined && (productReviewVersion !== 1 || action !== "read")) invalid();
    let review: StoreProductReviewReadback["review"] | undefined;
    let storeId: string, skuId: string, key: string | null = null, record: StoreProductSubmissionRecord | undefined;
    if (action === "read") {
      exact(request, ["storeId", "skuId"]);
      storeId = id(request.storeId); skuId = id(request.skuId);
      if (!this.repository.readProductSubmission) throw new WorkspaceProfileError("unavailable", "Product review is not connected.", 503);
      if (productReviewVersion === 1) {
        if (!this.identity || !this.repository.readReviewedProductSubmission) {
          throw new WorkspaceProfileError("unavailable", "Product review readback is not connected.", 503);
        }
        const result = await this.repository.readReviewedProductSubmission(storeId, skuId, id(ownerUserId), {...this.identity});
        record = result.record ?? undefined; review = result.review;
      } else record = await this.repository.readProductSubmission(storeId, skuId, id(ownerUserId));
    } else {
      const command = storeProductSubmission(ownerUserId, this.repository.realm, request, this.now().toISOString());
      storeId = command.storeId; skuId = command.product.skuId; key = command.idempotencyKey;
      if (!this.repository.submitProduct || !this.repository.reconcileProduct) throw new WorkspaceProfileError("unavailable", "Product review is not connected.", 503);
      record = action === "submit" ? await this.repository.submitProduct(command) : await this.repository.reconcileProduct(command);
    }
    return {schemaVersion: 1, productSubmissionVersion: 1, realm: this.repository.realm, storeId, skuId,
      observedAt: this.now().toISOString(), idempotencyKey: key,
      state: record ? record.product.mediaIntent.pendingUpload ? "awaiting_media" : "submitted" : action === "reconcile" ? "not_found" : "none",
      approved: false, publicationConfirmed: false, orderingAvailable: false, record: record ?? null,
      ...(review ? {productReviewVersion: 1, review} : {})};
  }

  /** Complete bounded discovery, not serviceability, Stock or ordering authority.
   * Directory rows are only candidates: every item uses the existing reviewed
   * projection. Above capacity fail honestly; never sort/count a truncated set.
   */
  async publicDiscovery(body: Readonly<Record<string, unknown>>): Promise<object> {
    exact(body, ["discoveryPageVersion", "query", "pageSize"], ["cursor", "resultKind", "storeId"]);
    if (body.discoveryPageVersion !== 1) invalid();
    const resultKind = body.resultKind === undefined ? "products" : body.resultKind;
    if (typeof resultKind !== "string" || !["products", "stores"].includes(resultKind)) invalid();
    const requestedStore = body.storeId === undefined ? null : id(body.storeId);
    const query = publicPageQuery(body.query), pageSize = integer(body.pageSize, 1, 50);
    const identity = this.identity && {...this.identity};
    if (!identity || !this.repository.publicDiscoveryBindings || !this.repository.publicCatalogueSource) {
      throw new WorkspaceProfileError("unavailable", "Public catalogue is not connected.", 503);
    }
    const unavailable = () => new WorkspaceProfileError("unavailable", "The complete public catalogue could not be confirmed.", 503);
    const directory = async () => {
      const raw = await this.repository.publicDiscoveryBindings!();
      if (!Array.isArray(raw) || raw.length > 500) throw unavailable();
      const bindings = raw.map(row => discoveryBinding(row, this.repository.realm))
        .sort((a, b) => a.listingId < b.listingId ? -1 : a.listingId === b.listingId ? 0 : 1);
      if (new Set(bindings.map(b => b.listingId)).size !== bindings.length) throw unavailable();
      return bindings;
    };
    const bindings = await directory(), storeIds = [...new Set(bindings.map(b => b.storeId))].sort();
    if (storeIds.length > 20) throw unavailable();
    const readSource = async (storeId: string) => {
      const profile = await this.repository.store(storeId);
      if (!profile || profile.workspaceId !== storeId || profile.familyId !== "products-trade" ||
          typeof profile.profileId !== "string" || !profile.profileId.startsWith("retailer-") ||
          !["pending", "approved", "rejected", "suspended", "live"].includes(profile.status) ||
          typeof profile.shopEnabled !== "boolean") throw unavailable();
      // Keep confirmed withdrawal in the snapshot. Undefined source also means
      // missing catalogue/duplicate profiles/tenant mismatch; it is NOT zero.
      if (profile.status !== "live" || profile.shopEnabled === false) return {profile, source: null};
      const source = await this.repository.publicCatalogueSource!(storeId, identity);
      if (!source || source.records.length > 500 || cataloguePayloadHash(source.profile) !== cataloguePayloadHash(profile)) throw unavailable();
      return {profile, source};
    };
    const sources: Array<{profile: WorkspaceProfileRecord; source: PublicCatalogueSource | null}> = [];
    for (const storeId of storeIds) sources.push(await readSource(storeId));
    const sourceHash = cataloguePayloadHash([identity, this.repository.realm, bindings, sources]);
    const project = async (at: string, values: typeof sources) => {
      const service = new WorkspaceCatalogueService(this.repository, identity, () => new Date(at), this.policyReader);
      const projections: Record<string, unknown>[] = [];
      for (let i = 0; i < storeIds.length; i++) {
        const source = values[i]!.source;
        if (!source) continue;
        const data = await service.publicCatalogue({storeId: storeIds[i], listingReadbackVersion: 1,
          productFactsReadbackVersion: 1, unbrandedProduceReadbackVersion: 1,
          storeDetailsReadbackVersion: 1, storeClassificationReadbackVersion: 1,
          mediaReadbackVersion: 1, policyReadbackVersion: 1}, source) as Record<string, unknown>;
        if (data.state === "unavailable" && (source.profile.status !== "live" || !source.profile.shopEnabled)) continue;
        if (data.state !== "ready" || data.listingCoverage !== "complete") throw unavailable();
        projections.push(data);
      }
      return projections;
    };
    const projections = await project(this.now().toISOString(), sources);
    // Final whole-directory and whole-source read detects inserted, withdrawn,
    // private, or excluded candidates, not just the visible returned page.
    if (cataloguePayloadHash(await directory()) !== cataloguePayloadHash(bindings)) {
      throw new WorkspaceProfileError("stale_snapshot", "Public catalogue changed. Refresh products.", 409);
    }
    const confirmed: typeof sources = [];
    for (const storeId of storeIds) confirmed.push(await readSource(storeId));
    if (cataloguePayloadHash(await directory()) !== cataloguePayloadHash(bindings)) {
      throw new WorkspaceProfileError("stale_snapshot", "Public catalogue changed. Refresh products.", 409);
    }
    if (cataloguePayloadHash([identity, this.repository.realm, bindings, confirmed]) !== sourceHash) {
      throw new WorkspaceProfileError("stale_snapshot", "Public catalogue changed. Refresh products.", 409);
    }
    const observedAt = this.now().toISOString(), finalProjections = await project(observedAt, confirmed);
    const stable = (values: typeof projections) => values.map(stablePublicProjection);
    if (cataloguePayloadHash(stable(finalProjections)) !== cataloguePayloadHash(stable(projections))) {
      throw new WorkspaceProfileError("stale_snapshot", "Public catalogue changed. Refresh products.", 409);
    }
    type Row = {skuId: string; content: StoreSkuContent; pack: StoreSkuPack;
      channels: Array<StoreSkuChannel & {revision: string; validUntil: string}>; listings: PublicCatalogueListingBinding[]};
    const selected: Array<{channel: StoreSkuChannel["kind"]; listing: Record<string, unknown>; listingId: string; price: number}> = [];
    for (const data of finalProjections) for (const row of data.items as Row[]) for (const channel of row.channels) {
      if (requestedStore !== null && data.storeId !== requestedStore) continue;
      if (query.destination === "shop" ? channel.kind !== "retail" : channel.kind === "retail") continue;
      if (query.tradeType !== null && channel.kind !== query.tradeType) continue;
      const binding = row.listings.find(b => b.channel === channel.kind)!;
      const candidate = bindings.find(b => b.listingId === binding.listingId);
      if (!candidate || cataloguePayloadHash(candidate) !== cataloguePayloadHash(binding)) throw unavailable();
      if (query.listingIds.length && !query.listingIds.includes(binding.listingId) ||
          query.categoryId !== "all" && row.content.categoryId !== query.categoryId ||
          query.brands.length && !query.brands.includes(row.content.brand) ||
          query.maximumPriceMinor !== null && channel.priceMinor > query.maximumPriceMinor ||
          query.search && ![row.content.title, row.content.brand, row.content.variant, row.pack.label]
            .join(" ").toLowerCase().replace(/\s+/gu, " ").includes(query.search)) continue;
      selected.push({channel: channel.kind, listingId: binding.listingId, price: channel.priceMinor,
        listing: {...data, items: [row], nextCursor: null}});
    }
    if (selected.length > 500 || new Set(selected.map(item => item.listingId)).size !== selected.length) throw unavailable();
    selected.sort((a, b) => (query.sort === "priceLowToHigh" ? a.price - b.price :
      query.sort === "priceHighToLow" ? b.price - a.price : 0) ||
      (a.listingId < b.listingId ? -1 : a.listingId === b.listingId ? 0 : 1));
    const resultItems = resultKind === "products" ? selected : selected.filter((value, i) =>
      selected.findIndex(other => other.listing.storeId === value.listing.storeId) === i);
    const queryHash = cataloguePayloadHash([identity, this.repository.realm, query, resultKind, requestedStore]).toLowerCase();
    const snapshotId = cataloguePayloadHash([sourceHash, stable(finalProjections)]).toLowerCase();
    let index = 0;
    if (body.cursor !== undefined) {
      const encoded = text(body.cursor, 2048);
      let cursor: Record<string, unknown>;
      try { cursor = exact(JSON.parse(Buffer.from(encoded, "base64url").toString("utf8")), ["v", "q", "s", "n", "i"]); }
      catch { invalid("Public catalogue cursor is invalid."); }
      if (Buffer.from(JSON.stringify(cursor)).toString("base64url") !== encoded || cursor.v !== 1 ||
          cursor.q !== queryHash || cursor.s !== snapshotId || cursor.n !== pageSize) {
        throw new WorkspaceProfileError("stale_cursor", "Public catalogue changed. Refresh products.", 409);
      }
      index = integer(cursor.i, 0, 500);
      if (index % pageSize || index >= resultItems.length) invalid("Public catalogue cursor is outside this snapshot.");
    }
    const cursorAt = (i: number) => Buffer.from(JSON.stringify({v: 1, q: queryHash, s: snapshotId, n: pageSize, i})).toString("base64url");
    const nextCursor = index + pageSize < resultItems.length ? cursorAt(index + pageSize) : null;
    const result = {schemaVersion: 1, discoveryPageVersion: 1, realm: this.repository.realm,
      state: "ready", coverage: "verified_public_only", directoryCoverage: "complete_bounded",
      orderingAvailable: false, observedAt, query, resultKind, requestedStore,
      items: resultItems.slice(index, index + pageSize).map(({channel, listing}) => ({channel, listing})),
      page: {snapshotId, startIndex: index, totalCount: resultItems.length,
        previousCursor: index === 0 ? null : cursorAt(Math.max(0, index - pageSize)), nextCursor}};
    if (Buffer.byteLength(JSON.stringify(result), "utf8") > 480 * 1024) throw unavailable();
    return result;
  }

  async handleStoreVariantFamily(ownerUserId: string, operation: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    const base = {schemaVersion: 1, realm: this.repository.realm, orderingAvailable: false};
    if (operation === "readStoreVariantFamily") {
      exact(body, ["storeId", "familyId"]);
      if (!this.repository.readVariantFamily) throw new WorkspaceProfileError("unavailable", "Product family connection is unavailable.", 503);
      const storeId = id(body.storeId), familyId = id(body.familyId);
      const result = await this.repository.readVariantFamily(storeId, familyId, id(ownerUserId));
      return {...base, storeId, familyId, ...result};
    }
    if (!["submitStoreVariantFamily", "reconcileStoreVariantFamily"].includes(operation)) invalid();
    const command = storeVariantFamilySubmission(ownerUserId, this.repository.realm, body, this.now().toISOString());
    if (!this.repository.submitVariantFamily || !this.repository.reconcileVariantFamily) {
      throw new WorkspaceProfileError("unavailable", "Product family submission is unavailable.", 503);
    }
    const record = operation === "submitStoreVariantFamily"
      ? await this.repository.submitVariantFamily(command) : await this.repository.reconcileVariantFamily(command);
    return {...base, storeId: command.storeId, familyId: command.family.familyId,
      state: record ? "submitted" : "not_found", candidate: record ?? null, approved: false};
  }

  async publicVariantFamilies(body: Readonly<Record<string, unknown>>): Promise<object> {
    exact(body, ["storeId", "listings"], ["familyId", "storeClassificationReadbackVersion"]);
    const classificationRequested = body.storeClassificationReadbackVersion === 1;
    if (Object.hasOwn(body, "storeClassificationReadbackVersion") && !classificationRequested) invalid();
    const storeId = id(body.storeId), familyId = body.familyId === undefined ? undefined : id(body.familyId);
    const requested = list(body.listings, 50).map(value => {
      const row = exact(value, ["listingId", "skuId", "channel"]);
      if (typeof row.listingId !== "string" || !/^listing-[a-f0-9]{64}$/u.test(row.listingId) ||
          typeof row.channel !== "string" || !["retail", "wholesale", "bulk"].includes(row.channel)) invalid();
      return {listingId: row.listingId, skuId: id(row.skuId), channel: row.channel as StoreSkuChannel["kind"]};
    });
    if (!requested.length || new Set(requested.map(row => row.listingId)).size !== requested.length ||
        familyId !== undefined && requested.length !== 1) invalid();
    const observedAt = this.now().toISOString();
    const base = {schemaVersion: 1, realm: this.repository.realm, storeId, observedAt, orderingAvailable: false,
      ...(classificationRequested ? {storeClassificationReadbackVersion: 1, storeDetailsReadbackVersion: 1} : {})};
    const unavailable = () => ({...base, state: "unavailable", memberships: [], family: null});
    if (!this.identity || !this.repository.publicCatalogueSource) return unavailable();
    const source = await this.repository.publicCatalogueSource(storeId, this.identity, true);
    if (!source?.variantFamilies) return unavailable();
    const revision = integer(source.variantFamilies.revision, 1, 1000000000);
    const reviews = source.variantFamilies.reviews.map(checkedFamilyReview);
    if (reviews.some(r => r.candidate.realm !== this.repository.realm || r.candidate.storeId !== storeId ||
        r.catalogueId !== this.identity!.catalogueId || r.tenantId !== this.identity!.tenantId || r.reviewedAt > observedAt) ||
        new Set(reviews.map(r => r.candidate.family.familyId)).size !== reviews.length) return unavailable();
    const approved = reviews.filter(r => r.decision === "verify");
    const relevant = new Set(requested.map(r => r.skuId));
    for (const review of approved) if (review.candidate.family.members.some(m => relevant.has(m.skuId))) {
      for (const member of review.candidate.family.members) relevant.add(member.skuId);
    }
    if (relevant.size > 500) return unavailable();
    const records = source.records.filter(r => relevant.has(r.skuId));
    const projection = await this.publicCatalogue({storeId, listingReadbackVersion: 1, policyReadbackVersion: 1,
      ...(classificationRequested ? {storeClassificationReadbackVersion: 1, storeDetailsReadbackVersion: 1} : {}),
      productFactsReadbackVersion: 1, mediaReadbackVersion: 1, unbrandedProduceReadbackVersion: 1},
    {...source, records}) as Record<string, unknown>;
    if (projection.state !== "ready" || projection.listingCoverage !== "complete") return unavailable();
    const items = projection.items as Array<Record<string, unknown>>;
    const matches = (row: typeof requested[number]) => items.filter(item => item.skuId === row.skuId &&
      (item.listings as PublicCatalogueListingBinding[]).some(listing => listing.listingId === row.listingId && listing.channel === row.channel));
    if (requested.some(row => matches(row).length !== 1)) return unavailable();
    // Revalidate every approved actual member, not just the selected discovery row.
    for (const review of approved.filter(r => r.candidate.family.members.some(m => relevant.has(m.skuId)))) {
      try { familyMembers(review.candidate, records); } catch { return unavailable(); }
      if (review.candidate.family.members.some(m => !items.some(item => item.skuId === m.skuId))) return unavailable();
    }
    const responseAt = this.now().toISOString();
    const deadlines = items.flatMap(item => (item.channels as Array<{validUntil: string}>).map(c => c.validUntil));
    const validUntil = [...deadlines, new Date(Date.parse(observedAt) + 5 * 60 * 1000).toISOString()].sort()[0]!;
    if (validUntil <= responseAt) return unavailable();
    const sourceId = `store-reviewed-variants:${this.repository.realm}:${storeId}`;
    const membership = (request: typeof requested[number]) => {
      const item = matches(request)[0]!;
      const families = approved.filter(r => r.candidate.family.members.some(m => m.skuId === request.skuId));
      if (families.length > 1) invalid("Reviewed family membership conflicts.");
      const review = families[0], family = review?.candidate.family;
      const member = family?.members.find(m => m.skuId === request.skuId);
      return {listing: (item.listings as PublicCatalogueListingBinding[]).find(b => b.listingId === request.listingId)!,
        skuRevision: item.revision, catalogueVersion: projection.catalogueVersion, familyId: family?.familyId ?? null,
        sourceId, revision, observedAt: responseAt, validUntil,
        attributes: member ? family!.options.filter(o => member.selections[o.dimensionId] === o.optionId) : []};
    };
    const memberships = requested.map(membership);
    let family: object | null = null;
    if (familyId !== undefined) {
      const selected = memberships[0]!, review = approved.find(r => r.candidate.family.familyId === familyId);
      if (selected.familyId !== familyId || !review) return unavailable();
      const channel = requested[0]!.channel;
      const members = review.candidate.family.members;
      const products = members.flatMap(member => {
        const item = items.find(row => row.skuId === member.skuId)!;
        const listings = (item.listings as PublicCatalogueListingBinding[]).filter(b => b.channel === channel);
        return listings.map(listing => ({product: item, membership: membership({listingId: listing.listingId, skuId: member.skuId, channel})}));
      });
      if (!products.length || !products.some(p => p.membership.listing.listingId === requested[0]!.listingId)) return unavailable();
      // No invented siblings in channels that this Store does not sell.
      family = {familyId, options: review.candidate.family.options, products};
    }
    const confirmed = await this.repository.publicCatalogueSource(storeId, this.identity, true);
    if (!confirmed || cataloguePayloadHash(confirmed) !== cataloguePayloadHash(source) || validUntil <= this.now().toISOString()) return unavailable();
    return {...base, observedAt: responseAt, state: "ready", catalogueVersion: projection.catalogueVersion,
      publicStore: projection.publicStore, sourceId, revision, validUntil, memberships, family};
  }

  async handleStorePublicDetails(ownerUserId: string, operation: string, raw: Readonly<Record<string, unknown>>): Promise<object> {
    const body: Record<string, unknown> = structuredClone(raw);
    if (Buffer.byteLength(JSON.stringify(body), "utf8") > 16000) invalid("Public Store details are too long.");
    const classificationRequested = body.storeClassificationReadbackVersion === 1;
    if (Object.hasOwn(body, "storeClassificationReadbackVersion") && !classificationRequested) invalid();
    delete body.storeClassificationReadbackVersion;
    if (!classificationRequested && typeof body.details === "object" && body.details !== null &&
        Object.hasOwn(body.details, "businessType")) invalid("Update MoolSocial to save public business type.");
    let record: StorePublicDetailsRecord | undefined;
    if (operation === "readStorePublicDetails") {
      exact(body, ["storeId"]);
      const storeId = id(body.storeId);
      requireStore(await this.repository.store(storeId), storeId, id(ownerUserId));
      if (!this.repository.readStorePublicDetails) throw new WorkspaceProfileError("unavailable", "Public details are not connected.", 503);
      record = await this.repository.readStorePublicDetails(storeId, ownerUserId);
    } else {
      const command = detailsCommand(ownerUserId, this.repository.realm, body, this.now().toISOString());
      requireStore(await this.repository.store(command.storeId), command.storeId, command.ownerUserId);
      if (operation === "saveStorePublicDetails" && this.repository.saveStorePublicDetails) {
        record = await this.repository.saveStorePublicDetails(command);
      } else if (operation === "reconcileStorePublicDetails" && this.repository.reconcileStorePublicDetails) {
        record = await this.repository.reconcileStorePublicDetails(command);
      } else throw new WorkspaceProfileError("unavailable", "Public details are not connected.", 503);
    }
    if (!classificationRequested && record?.details.businessType !== undefined) {
      throw new WorkspaceProfileError("unsupported_version", "Update MoolSocial to open these public Store details. Saved data is unchanged.", 409);
    }
    return {schemaVersion: 1, realm: this.repository.realm, storeId: id(body.storeId),
      ...(classificationRequested ? {storeClassificationReadbackVersion: 1} : {}),
      operation, idempotencyKey: operation === "readStorePublicDetails" ? null : id(body.idempotencyKey),
      record: record ? publicDetailsRecord(record, this.repository.realm, id(body.storeId)) : null,
      locationVerified: false, publicAvailabilityConfirmed: false};
  }

  async saveSku(ownerUserId: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    if (body.reviewCandidate !== undefined) invalid("A reviewed candidate needs explicit reviewed binding.");
    const command = await this.saveCommand(ownerUserId, body);
    const record = await this.repository.save(command);
    return this.savedResult(command.profile.workspaceId!, record);
  }

  /** Owner intent only. Server configuration and private review sources decide eligibility. */
  async bindReviewedSku(ownerUserId: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    if (!this.identity || !this.repository.bindReviewed) {
      throw new WorkspaceProfileError("service_unavailable", "Product publication is unavailable right now.", 503, true);
    }
    const identity = {...this.identity};
    const command = await this.saveCommand(ownerUserId, body);
    const record = await this.repository.bindReviewed(command, identity);
    return this.savedResult(command.profile.workspaceId!, record);
  }

  /** Historical receipt only. Missing receipt is unknown, never a reason to resend. */
  async reconcileBinding(ownerUserId: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    if (!this.repository.readSaveReceipt) {
      throw new WorkspaceProfileError("service_unavailable", "Listing updates are unavailable right now.", 503, true);
    }
    const command = await this.saveCommand(ownerUserId, body);
    const record = await this.repository.readSaveReceipt(command);
    return record ? this.savedResult(command.profile.workspaceId!, record) :
      {schemaVersion: 1, realm: this.repository.realm, storeId: command.profile.workspaceId!,
        saved: null, publicationConfirmed: false};
  }

  private async saveCommand(ownerUserId: string, body: Readonly<Record<string, unknown>>): Promise<CatalogueSave> {
    body = structuredClone(body);
    exact(body, ["storeId", "sku", "expectedRevision", "idempotencyKey"], ["reviewCandidate"]);
    const storeId = id(body.storeId);
    const input = normalizeSku(body.sku, storeId);
    const expectedRevision = integer(body.expectedRevision, 0, 1_000_000_000);
    const idempotencyKey = id(body.idempotencyKey);
    const profile = requireStore(await this.repository.store(storeId), storeId, ownerUserId);
    const reviewCandidate = body.reviewCandidate === undefined ? undefined : reviewedCandidateReference(body.reviewCandidate);
    return {ownerUserId, profile, input,
      expectedRevision, idempotencyKey,
      ...(reviewCandidate ? {reviewCandidate} : {}),
      fingerprint: cataloguePayloadHash({storeId, input, expectedRevision, ...(reviewCandidate ? {reviewCandidate} : {})}),
      observedAt: this.now().toISOString()};
  }

  private savedResult(storeId: string, record: StoreSkuRecord): object {
    return {schemaVersion: 1, realm: this.repository.realm, storeId, saved: normalizeRecord(record, storeId),
      publicationConfirmed: false};
  }

  async listSkus(ownerUserId: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    const queryBody = structuredClone(body) as Record<string, unknown>;
    const produceRequested = queryBody.unbrandedProduceReadbackVersion === 1;
    if (Object.hasOwn(queryBody, "unbrandedProduceReadbackVersion") && !produceRequested) invalid();
    delete queryBody.unbrandedProduceReadbackVersion;
    const factsRequested = queryBody.productFactsReadbackVersion === 1;
    if (queryBody.productFactsReadbackVersion !== undefined && !factsRequested) invalid();
    delete queryBody.productFactsReadbackVersion;
    const mediaRequested = queryBody.mediaReadbackVersion === 1;
    if (queryBody.mediaReadbackVersion !== undefined && !mediaRequested) invalid();
    delete queryBody.mediaReadbackVersion;
    const query = pageQuery(queryBody);
    const profile = requireStore(await this.repository.store(query.storeId), query.storeId, ownerUserId);
    const records = await this.repository.page(profile, ownerUserId, query.after, query.limit, query.skuId);
    const items = records.map(r => normalizeRecord(r, query.storeId));
    if (!produceRequested && items.some(item => item.content.brand === "")) {
      throw new WorkspaceProfileError("unsupported_version", "Update MoolSocial to open these product details. Saved data is unchanged.", 409);
    }
    if (!factsRequested && items.some(item => item.content.productFacts !== undefined)) {
      throw new WorkspaceProfileError("unsupported_version", "Update MoolSocial to open these saved product details. Saved data is unchanged.", 409);
    }
    if (!mediaRequested && items.some(item => item.content.media.some(media => Object.hasOwn(media.file, "frameCount")))) {
      // An editable source must remain exact; never strip reviewed input facts
      // to satisfy an older decoder or silently omit its record from the page.
      throw new WorkspaceProfileError("unsupported_version", "Update MoolSocial to open these saved photo details. Saved data is unchanged.", 409);
    }
    return {schemaVersion: 1, realm: this.repository.realm, storeId: query.storeId, items,
      ...(produceRequested && items.some(item => item.content.brand === "") ? {unbrandedProduceReadbackVersion: 1} : {}),
      ...(factsRequested ? {productFactsReadbackVersion: 1} : {}),
      ...(mediaRequested ? {mediaReadbackVersion: 1} : {}),
      nextCursor: !query.skuId && items.length === query.limit ? items.at(-1)!.skuId : null};
  }

  private async publicCataloguePage(body: Readonly<Record<string, unknown>>): Promise<object> {
    exact(body, ["storeId", "cataloguePageVersion", "query", "pageSize"], ["cursor", "storeDetailsReadbackVersion", "productFactsReadbackVersion", "unbrandedProduceReadbackVersion", "storeClassificationReadbackVersion"]);
    const classificationRequested = body.storeClassificationReadbackVersion === 1;
    if (Object.hasOwn(body, "storeClassificationReadbackVersion") && !classificationRequested) invalid();
    const produceRequested = body.unbrandedProduceReadbackVersion === 1;
    if (Object.hasOwn(body, "unbrandedProduceReadbackVersion") && !produceRequested) invalid();
    const factsRequested = body.productFactsReadbackVersion === 1;
    if (body.productFactsReadbackVersion !== undefined && !factsRequested) invalid();
    const detailsRequested = body.storeDetailsReadbackVersion === 1;
    if (body.storeDetailsReadbackVersion !== undefined && !detailsRequested) invalid();
    if (classificationRequested && !detailsRequested) invalid();
    if (body.cataloguePageVersion !== 1 && body.cataloguePageVersion !== 2) invalid();
    const pageVersion = body.cataloguePageVersion, exactMoney = pageVersion === 2;
    const storeId = id(body.storeId), pageSize = integer(body.pageSize, 1, 50), query = publicPageQuery(body.query);
    if (!this.identity || !this.repository.publicCatalogueSource) {
      throw new WorkspaceProfileError("unavailable", "Store catalogue is not connected.", 503);
    }
    const source = await this.repository.publicCatalogueSource(storeId, this.identity);
    if (!source || source.records.length > 500) {
      throw new WorkspaceProfileError("unavailable", "The complete Store catalogue could not be confirmed.", 503);
    }
    const sourceHash = cataloguePayloadHash(source);
    const data = await this.publicCatalogue({storeId, listingReadbackVersion: 1,
      ...(classificationRequested ? {storeClassificationReadbackVersion: 1} : {}),
      ...(produceRequested ? {unbrandedProduceReadbackVersion: 1} : {}),
      ...(factsRequested ? {productFactsReadbackVersion: 1} : {}),
      ...(detailsRequested ? {storeDetailsReadbackVersion: 1} : {}),
      policyReadbackVersion: 1, mediaReadbackVersion: 1}, source) as Record<string, unknown>;
    if (data.state !== "ready" || data.listingCoverage !== "complete") {
      throw new WorkspaceProfileError("unavailable", "Store listings could not be confirmed.", 503);
    }
    const rows = data.items as Array<{skuId: string; content: StoreSkuContent; pack: StoreSkuPack;
      channels: Array<StoreSkuChannel & {revision: string; validUntil: string}>;
      listings: PublicCatalogueListingBinding[]; supplierPolicy: Record<string, unknown>}>;
    const selected: Array<{channel: StoreSkuChannel["kind"]; listingId: string; row: (typeof rows)[number]; price: number}> = [];
    for (const row of rows) for (const channel of row.channels) {
      if (query.destination === "shop" ? channel.kind !== "retail" : channel.kind === "retail") continue;
      if (query.tradeType !== null && channel.kind !== query.tradeType) continue;
      const binding = row.listings.find(value => value.channel === channel.kind)!;
      if (query.listingIds.length && !query.listingIds.includes(binding.listingId)) continue;
      if (query.categoryId !== "all" && row.content.categoryId !== query.categoryId ||
          query.brands.length && !query.brands.includes(row.content.brand) ||
          query.maximumPriceMinor !== null && channel.priceMinor > query.maximumPriceMinor ||
          query.search && ![row.content.title, row.content.brand, row.content.variant, row.pack.label]
            .join(" ").toLowerCase().replace(/\s+/gu, " ").includes(query.search)) continue;
      // Preserve legacy whole-INR readers; v2 explicitly supports integer paise.
      // Pack representability remains identical in both versions.
      const quantities = [BigInt(row.pack.quantityMilli), BigInt(row.pack.quantityMilli) * 1000n];
      const count = BigInt(row.pack.unitsPerCase);
      const amount = quantities.find((value, i) => (i === 0 || row.pack.unit !== "count") && value % count === 0n);
      if (!exactMoney && (channel.priceMinor % 100 || channel.mrpMinor !== null && channel.mrpMinor % 100 ||
          channel.tiers.some(tier => tier.unitPriceMinor % 100)) || amount === undefined ||
          row.pack.unit === "count" && amount / count % 1000n !== 0n) {
        throw new WorkspaceProfileError("unsupported_representation", "Update required to display exact Store prices or packs.", 409);
      }
      selected.push({channel: channel.kind, listingId: binding.listingId, row, price: channel.priceMinor});
    }
    selected.sort((a, b) => (query.sort === "priceLowToHigh" ? a.price - b.price :
      query.sort === "priceHighToLow" ? b.price - a.price : 0) ||
      (a.listingId < b.listingId ? -1 : a.listingId === b.listingId ? 0 : 1));
    const stableRows = stablePublicProjection(data);
    const queryHash = cataloguePayloadHash(exactMoney ? [storeId, query, pageVersion, 'paise'] : [storeId, query]).toLowerCase();
    const snapshotId = cataloguePayloadHash([sourceHash, stableRows]).toLowerCase();
    let index = 0;
    if (body.cursor !== undefined) {
      const encoded = text(body.cursor, 2048);
      let cursor: Record<string, unknown>;
      try { cursor = exact(JSON.parse(Buffer.from(encoded, "base64url").toString("utf8")), ["v", "q", "s", "n", "i"]); }
      catch { invalid("Catalogue cursor is invalid. Refresh the Store."); }
      if (Buffer.from(JSON.stringify(cursor)).toString("base64url") !== encoded || cursor.v !== pageVersion ||
          cursor.q !== queryHash || cursor.s !== snapshotId || cursor.n !== pageSize) {
        throw new WorkspaceProfileError("stale_cursor", "Store catalogue changed. Refresh the Store.", 409);
      }
      index = integer(cursor.i, 0, 1000);
      if (index % pageSize || index >= selected.length) invalid("Catalogue cursor is outside this snapshot.");
    }
    const current = await this.repository.publicCatalogueSource(storeId, this.identity);
    const responseAt = this.now().toISOString();
    if (!current || cataloguePayloadHash(current) !== sourceHash) {
      throw new WorkspaceProfileError("stale_snapshot", "Store catalogue changed. Refresh the Store.", 409);
    }
    // Pure re-projection at one final response time checks temporal membership
    // of ALL candidates, including offers which were not active on the first pass.
    const finalProjection = await new WorkspaceCatalogueService(this.repository, this.identity,
      () => new Date(responseAt), this.policyReader).publicCatalogue({storeId, listingReadbackVersion: 1,
      ...(classificationRequested ? {storeClassificationReadbackVersion: 1} : {}),
      ...(produceRequested ? {unbrandedProduceReadbackVersion: 1} : {}),
      ...(factsRequested ? {productFactsReadbackVersion: 1} : {}),
      ...(detailsRequested ? {storeDetailsReadbackVersion: 1} : {}),
      policyReadbackVersion: 1, mediaReadbackVersion: 1}, current) as Record<string, unknown>;
    if (cataloguePayloadHash(stablePublicProjection(finalProjection)) !== cataloguePayloadHash(stableRows)) {
      throw new WorkspaceProfileError("stale_snapshot", "Store catalogue changed. Refresh the Store.", 409);
    }
    const cursorAt = (offset: number) => Buffer.from(JSON.stringify(
      {v: pageVersion, q: queryHash, s: snapshotId, n: pageSize, i: offset})).toString("base64url");
    const previousCursor = index === 0 ? null : cursorAt(Math.max(0, index - pageSize));
    const nextCursor = index + pageSize < selected.length ? cursorAt(index + pageSize) : null;
    return {...data, observedAt: responseAt, cataloguePageVersion: pageVersion,
      ...(exactMoney ? {moneyUnit: 'paise'} : {}), query,
      items: selected.slice(index, index + pageSize).map(({channel, row}) => ({channel, row})),
      nextCursor, page: {snapshotId, startIndex: index, totalCount: selected.length, previousCursor, nextCursor}};
  }

  async publicCatalogue(body: Readonly<Record<string, unknown>>, source?: PublicCatalogueSource): Promise<object> {
    if (Object.hasOwn(body, "cataloguePageVersion")) return this.publicCataloguePage(body);
    const queryBody = structuredClone(body) as Record<string, unknown>;
    const classificationRequested = queryBody.storeClassificationReadbackVersion === 1;
    if (Object.hasOwn(queryBody, "storeClassificationReadbackVersion") && !classificationRequested) invalid();
    delete queryBody.storeClassificationReadbackVersion;
    const produceRequested = queryBody.unbrandedProduceReadbackVersion === 1;
    if (Object.hasOwn(queryBody, "unbrandedProduceReadbackVersion") && !produceRequested) invalid();
    delete queryBody.unbrandedProduceReadbackVersion;
    const factsRequested = queryBody.productFactsReadbackVersion === 1;
    if (queryBody.productFactsReadbackVersion !== undefined && !factsRequested) invalid();
    delete queryBody.productFactsReadbackVersion;
    const policyRequested = queryBody.policyReadbackVersion === 1;
    if (queryBody.policyReadbackVersion !== undefined && !policyRequested) invalid();
    delete queryBody.policyReadbackVersion;
    const listingsRequested = queryBody.listingReadbackVersion === 1;
    if (queryBody.listingReadbackVersion !== undefined && !listingsRequested) invalid();
    delete queryBody.listingReadbackVersion;
    const mediaRequested = queryBody.mediaReadbackVersion === 1;
    if (queryBody.mediaReadbackVersion !== undefined && !mediaRequested) invalid();
    delete queryBody.mediaReadbackVersion;
    const detailsRequested = queryBody.storeDetailsReadbackVersion === 1;
    if (queryBody.storeDetailsReadbackVersion !== undefined && !detailsRequested) invalid();
    delete queryBody.storeDetailsReadbackVersion;
    if (detailsRequested && !listingsRequested) invalid();
    if (classificationRequested && !detailsRequested) invalid();
    const query = pageQuery(queryBody);
    const profile = source ? source.profile : await this.repository.store(query.storeId);
    const observedAt = this.now().toISOString();
    const base = {schemaVersion: 1, realm: this.repository.realm, storeId: query.storeId, observedAt,
      orderingAvailable: false, coverage: "verified_public_only",
      ...(classificationRequested ? {storeClassificationReadbackVersion: 1} : {}),
      ...(factsRequested ? {productFactsReadbackVersion: 1} : {}),
      ...(mediaRequested ? {mediaReadbackVersion: 1} : {}),
      ...(detailsRequested ? {storeDetailsReadbackVersion: 1} : {}),
      ...(listingsRequested ? {listingReadbackVersion: 1, listingCoverage: "unavailable"} : {})};
    if (!profile || profile.workspaceId !== query.storeId || profile.status !== "live" ||
        profile.shopEnabled !== true || !this.identity) {
      return {...base, state: "unavailable", items: [], nextCursor: null};
    }
    const catalogue = source ? source.catalogue : await this.repository.catalogue(this.identity.catalogueId);
    if (!catalogue || catalogue.schemaVersion !== 1 ||
        catalogue.catalogueId !== this.identity.catalogueId || catalogue.tenantId !== this.identity.tenantId ||
        !Number.isSafeInteger(catalogue.version) || catalogue.version < 1) {
      return {...base, state: "unavailable", items: [], nextCursor: null};
    }
    const records = source ? source.records : await this.repository.page(profile, undefined, query.after, query.limit, query.skuId);
    const [freshCatalogue, freshStore] = source ? [source.catalogue, source.profile] : await Promise.all([
      this.repository.catalogue(this.identity.catalogueId), this.repository.store(query.storeId)]);
    if (!freshCatalogue || cataloguePayloadHash(freshCatalogue) !== cataloguePayloadHash(catalogue) ||
        freshStore?.workspaceId !== query.storeId || freshStore.status !== "live" || freshStore.shopEnabled !== true) {
      return {...base, state: "unavailable", items: [], nextCursor: null};
    }
    const readbackAt = this.now().toISOString();
    const rows = records.map(r => normalizeRecord(r, query.storeId));
    const items = rows.flatMap(record => {
      if (!record.publicListing || record.observedAt > readbackAt) return [];
      const product = reviewedCanonicalProduct(catalogue, record.canonicalProductId, cataloguePayloadHash(record.content));
      const pack = catalogue.packs.find(p => p.packId === record.verifiedPackId);
      if (product?.state !== "verified" || pack?.state !== "verified" ||
          pack.productId !== product.productId ||
          !canonicalContentMatches(product, record.content) ||
          product.contentSha256.toUpperCase() !== cataloguePayloadHash(record.content) ||
          pack.descriptorSha256.toUpperCase() !== cataloguePayloadHash(record.pack)) return [];
      const terms = record.channels.map(channel => {
        const offer = catalogue.offers.find(o => o.offerId === channel.offerId &&
          o.workspaceId === query.storeId && o.packId === pack.packId &&
          o.buyingContext === (channel.kind === "retail" ? "consumer" : "wholesale"));
        const window = offer && referencedOfferTermAt(offer, readbackAt);
        if (!window || window.termSnapshotSha256.toUpperCase() !== cataloguePayloadHash(channelTerms(channel))) return null;
        return {...channel, revision: window.termSnapshotId, validUntil: window.expiresAt};
      });
      // A saved trade type cannot silently become another channel or partial offer.
      if (terms.some(t => t === null)) return [];
      const publicContent = structuredClone(record.content);
      if (!produceRequested && publicContent.brand === "") {
        // Mixed pages fail as unsupported; never silently omit the produce SKU.
        throw new WorkspaceProfileError("unsupported_version", "Update MoolSocial to open these product details.", 409);
      }
      if (!factsRequested && publicContent.productFacts !== undefined) {
        // Never omit reviewed descriptive facts to make an older client decode.
        throw new WorkspaceProfileError("unsupported_version", "Update MoolSocial to open these product details.", 409);
      }
      // Compatibility projection only, after full reviewed-content validation.
      // Original source, immutable receipts and hashes are never edited here.
      if (!mediaRequested) for (const media of publicContent.media) delete media.file.frameCount;
      return [{skuId: record.skuId, canonicalProductId: record.canonicalProductId,
        verifiedPackId: record.verifiedPackId, sku: record.sku,
        revision: record.revision, observedAt: record.observedAt,
        content: publicContent, pack: record.pack, channels: terms}];
    });
    const publicItems = policyRequested ? await Promise.all(items.map(async item => {
      const unavailable = () => ({schemaVersion: 1 as const, realm: this.repository.realm,
        storeId: query.storeId, skuId: item.skuId, observedAt: this.now().toISOString(),
        state: "unavailable" as const, revision: null, requiresAcceptance: null, policy: null});
      try {
        if (!source && !this.policyReader) return {...item, supplierPolicy: unavailable()};
        const policy = source
          ? publicSupplierPolicySnapshot(source.policy, this.repository.realm, query.storeId, item.skuId, this.now().toISOString())
          : await this.policyReader!.forPublicSku(query.storeId, item.skuId);
        if (policy.schemaVersion !== 1 || policy.realm !== this.repository.realm ||
            policy.storeId !== query.storeId || policy.skuId !== item.skuId ||
            policy.policy !== null && (policy.policy.storeId !== query.storeId ||
              policy.policy.productIds.length !== 1 || policy.policy.productIds[0] !== item.skuId)) {
          return {...item, supplierPolicy: unavailable()};
        }
        return {...item, supplierPolicy: policy};
      } catch { return {...item, supplierPolicy: unavailable()}; }
    })) : items;
    if (listingsRequested) {
      const linked: Array<(typeof publicItems)[number] & {listings: PublicCatalogueListingBinding[]}> = [];
      for (const item of publicItems) {
        const record = rows.find(r => r.skuId === item.skuId)!;
        try {
          // No client-generated fallback or mutation during public readback.
          const bindings = source ? source.bindings.filter(b => b.skuId === record.skuId)
            : await this.repository.publicListingBindings?.(record);
          const expected = cataloguePublicListingBindings(this.repository.realm, record);
          if (!bindings || bindings.length !== expected.length) continue;
          const checked = expected.map(binding => checkedListingBinding(
            bindings.find(v => v.channel === binding.channel), binding));
          if (item.channels.some(c => c!.validUntil <= this.now().toISOString())) continue;
          linked.push({...item, listings: checked});
        } catch { /* Retain an unavailable/partial result, never guess identity. */ }
      }
      let details: unknown;
      if (detailsRequested) {
        try {
          details = source ? source.publicDetails : this.repository.readStorePublicDetails
            ? (await this.repository.readStorePublicDetails(query.storeId)) ?? null : undefined;
        } catch { details = undefined; }
      }
      let store: WorkspaceProfileRecord;
      try {
        if (!linked.length && publicItems.length) return {...base, listingCoverage: "partial", state: "unavailable", items: [], nextCursor: null};
        const currentStore = source ? source.profile : await this.repository.confirmPublicListingSnapshot?.(query.storeId,
          rows.filter(record => linked.some(item => item.skuId === record.skuId)), this.identity, cataloguePayloadHash(catalogue),
          detailsRequested && details !== undefined ? cataloguePayloadHash(details) : undefined);
        store = requireStore(currentStore, query.storeId);
        if (!store.shopEnabled) throw new Error("Store withdrawn");
        text(store.name, 240);
      } catch { return {...base, state: "unavailable", items: [], nextCursor: null}; }
      // All awaits are finished. Do not let a metadata/policy lookup extend
      // reviewed selling terms beyond their original expiry.
      const responseAt = this.now().toISOString();
      const liveLinked = linked.filter(item => item.channels.every(c => c!.validUntil > responseAt));
      const coverage = liveLinked.length === publicItems.length ? "complete" : "partial";
      return {...base, observedAt: responseAt,
        ...(produceRequested && liveLinked.some(item => item.content.brand === "") ? {unbrandedProduceReadbackVersion: 1} : {}),
        state: liveLinked.length === 0 && publicItems.length > 0 ? "unavailable" : "ready",
        catalogueVersion: catalogue.version, listingCoverage: coverage,
        publicStore: {id: store.workspaceId, name: store.name, profileId: store.profileId,
          ...(detailsRequested ? {details: publicDetailsProjection(details, this.repository.realm, query.storeId, store, responseAt, classificationRequested)} : {})},
        items: liveLinked, nextCursor: !query.skuId && rows.length === query.limit ? rows.at(-1)!.skuId : null};
    }
    return {...base, observedAt: readbackAt, state: "ready", catalogueVersion: catalogue.version, items: publicItems,
      ...(produceRequested && publicItems.some(item => item.content.brand === "") ? {unbrandedProduceReadbackVersion: 1} : {}),
      nextCursor: !query.skuId && rows.length === query.limit ? rows.at(-1)!.skuId : null};
  }
}

function canonicalContentMatches(product: CatalogueAggregate["products"][number], content: StoreSkuContent): boolean {
  if (product.categoryId !== content.categoryId) return false;
  // The proposal contains a hash, not content. Independently pin its declared
  // category/brand absence when actual content is bound, read or family-reviewed.
  return product.brandId === null
    ? product.categoryId === "fruits-vegetables" && content.brand === ""
    : typeof product.brandId === "string" && product.brandId.trim().length > 0;
}

function invalid(message = "Catalogue data is invalid."): never {
  throw new WorkspaceProfileError("invalid_input", message, 400);
}
function publicPageQuery(value: unknown) {
  const query = exact(value, ["destination", "search", "categoryId", "sort", "brands", "maximumPriceMinor", "tradeType", "listingIds"]);
  if (typeof query.destination !== "string" || !["shop", "wholesale"].includes(query.destination) ||
      typeof query.sort !== "string" || !["relevance", "priceLowToHigh", "priceHighToLow"].includes(query.sort) ||
      !Array.isArray(query.brands) || query.brands.length > 20 || !Array.isArray(query.listingIds) || query.listingIds.length > 50 ||
      query.tradeType !== null && (typeof query.tradeType !== "string" || !["wholesale", "bulk"].includes(query.tradeType)) ||
      query.destination === "shop" && query.tradeType !== null) invalid();
  const brands = (query.brands as unknown[]).map(value => text(value));
  const listingIds = (query.listingIds as unknown[]).map(value => text(value, 72));
  if (new Set(brands).size !== brands.length || new Set(listingIds).size !== listingIds.length ||
      listingIds.some(value => !/^listing-[a-f0-9]{64}$/u.test(value))) invalid();
  return {destination: String(query.destination), search: text(query.search, 240, true).toLowerCase().replace(/\s+/gu, " "),
    categoryId: id(query.categoryId), sort: String(query.sort), brands: brands.sort(),
    maximumPriceMinor: query.maximumPriceMinor === null ? null : integer(query.maximumPriceMinor, 0),
    tradeType: query.tradeType === null ? null : String(query.tradeType), listingIds: listingIds.sort()};
}
function stablePublicProjection(data: Record<string, unknown>): object {
  const store = data.publicStore as Record<string, unknown> | undefined;
  return {state: data.state, listingCoverage: data.listingCoverage, catalogueVersion: data.catalogueVersion,
    publicStore: store?.details ? {...store, details: Object.fromEntries(Object.entries(store.details as Record<string, unknown>)
      .filter(([key]) => key !== "observedAt"))} : store,
    items: (data.items as Array<Record<string, unknown>>).map(row => ({...row,
      supplierPolicy: Object.fromEntries(Object.entries(row.supplierPolicy as Record<string, unknown>)
        .filter(([key]) => key !== "observedAt"))}))};
}
function object(value: unknown): Record<string, unknown> {
  if (value === null || typeof value !== "object" || Array.isArray(value) ||
      ![Object.prototype, null].includes(Object.getPrototypeOf(value))) invalid();
  return value as Record<string, unknown>;
}
function exact(value: unknown, required: string[], optional: string[] = []): Record<string, unknown> {
  const result = object(value);
  if (required.some(k => !Object.hasOwn(result, k)) ||
      Object.keys(result).some(k => ![...required, ...optional].includes(k))) invalid();
  return result;
}
function text(value: unknown, max = 240, empty = false): string {
  if (typeof value !== "string" || value !== value.trim() || value.length > max ||
      (!empty && value.length === 0) || /[\u0000-\u0008\u000b\u000c\u000e-\u001f]/u.test(value)) invalid();
  return value;
}
function id(value: unknown): string {
  const result = text(value, 128);
  if (!/^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$/u.test(result)) invalid();
  return result;
}
function integer(value: unknown, minimum = 1, maximum = 100_000_000): number {
  if (!Number.isSafeInteger(value) || (value as number) < minimum || (value as number) > maximum) invalid();
  return value as number;
}
function boolean(value: unknown): boolean {if (typeof value !== "boolean") invalid(); return value;}
function list(value: unknown, max: number): unknown[] {
  if (!Array.isArray(value) || value.length > max) invalid(); return value;
}
function requireStore(profile: WorkspaceProfileRecord | undefined, storeId: string, owner?: string): WorkspaceProfileRecord {
  if (!profile || profile.workspaceId !== storeId ||
      (owner !== undefined && profile.ownerUserId !== id(owner))) {
    throw new WorkspaceProfileError("not_found", "That Store is unavailable.", 404);
  }
  if (profile.familyId !== "products-trade" || !profile.profileId.startsWith("retailer-") || profile.status !== "live") {
    throw new WorkspaceProfileError("invalid_state", "This Store is not active.", 409);
  }
  return profile;
}
function pageQuery(body: Readonly<Record<string, unknown>>) {
  exact(body, ["storeId"], ["after", "limit", "skuId"]);
  if (body.skuId !== undefined && (body.after !== undefined || body.limit !== undefined)) invalid();
  return {storeId: id(body.storeId), after: body.after === undefined ? undefined : id(body.after),
    skuId: body.skuId === undefined ? undefined : id(body.skuId),
    limit: body.skuId !== undefined ? 1 : body.limit === undefined ? 30 : integer(body.limit, 1, 50)};
}

export function channelTerms(channel: StoreSkuChannel): object {
  const {offerId: _, ...terms} = channel;
  return {currency: "INR", ...terms};
}

function authoredText(c: Record<string, unknown>): Omit<StoreSkuContent, "media" | "productFacts"> {
  return {title: text(c.title), brand: text(c.brand, 240, c.categoryId === "fruits-vegetables"), variant: text(c.variant, 240, true),
    categoryId: id(c.categoryId), description: text(c.description, 4000, true),
    highlights: list(c.highlights, 20).map(h => text(h, 500)),
    specifications: list(c.specifications, 40).map(s => {
      const row = exact(s, ["label", "value"]); return {label: text(row.label), value: text(row.value, 1000)};
    })};
}
function authoredPack(value: unknown): StoreSkuPack {
  const p = exact(value, ["label", "quantityMilli", "unit", "unitsPerCase"]);
  if (typeof p.unit !== "string" || !["kg", "L", "count"].includes(p.unit)) invalid();
  return {label: text(p.label), quantityMilli: integer(p.quantityMilli), unit: p.unit as StoreSkuPack["unit"], unitsPerCase: integer(p.unitsPerCase)};
}
function authoredChannel(a: Record<string, unknown>): Omit<StoreSkuChannel, "offerId"> {
  if (typeof a.kind !== "string" || !["retail", "wholesale", "bulk"].includes(a.kind)) invalid();
  const priceMinor = integer(a.priceMinor), minimumOrder = integer(a.minimumOrder), quantityStep = integer(a.quantityStep);
  const mrpMinor = a.mrpMinor === null ? null : integer(a.mrpMinor, priceMinor);
  const tiers = list(a.tiers, 20).map(t => {
    const row = exact(t, ["minimumQuantity", "unitPriceMinor"]);
    return {minimumQuantity: integer(row.minimumQuantity), unitPriceMinor: integer(row.unitPriceMinor)};
  });
  if ((tiers.length && (tiers[0]!.minimumQuantity !== minimumOrder || tiers[0]!.unitPriceMinor !== priceMinor)) ||
      tiers.some((t, i) => (t.minimumQuantity - minimumOrder) % quantityStep !== 0 || i > 0 &&
        (t.minimumQuantity <= tiers[i - 1]!.minimumQuantity || t.unitPriceMinor > tiers[i - 1]!.unitPriceMinor))) invalid();
  return {kind: a.kind as StoreSkuChannel["kind"], priceMinor, mrpMinor, minimumOrder, quantityStep, tiers};
}
function authoredChannelsValid(channels: Array<{kind: StoreSkuChannel["kind"]}>): void {
  if (!channels.length || new Set(channels.map(c => c.kind)).size !== channels.length ||
      channels.some(c => c.kind === "wholesale") && channels.some(c => c.kind === "bulk")) invalid();
}

export function normalizeSku(value: unknown, storeId: string): StoreSkuInput {
  const v = exact(value, ["skuId", "canonicalProductId", "verifiedPackId", "sku", "publicListing",
    "content", "pack", "channels", "provenance"]);
  const skuId = id(v.skuId), canonicalProductId = id(v.canonicalProductId);
  const c = exact(v.content, ["title", "brand", "variant", "categoryId", "description", "highlights", "specifications", "media"], ["productFacts"]);
  const pack = authoredPack(v.pack);
  const provenance = exact(v.provenance, ["entryMethod", "sourceRecordId"]);
  if (!["catalogue", "manual", "csv"].includes(String(provenance.entryMethod))) invalid();
  const media = list(c.media, 10).map(value => {
    const m = exact(value, ["id", "revision", "url", "storeId", "skuId", "canonicalProductId", "publisherWorkspaceId", "file"]);
    const url = text(m.url, 2048); let parsed: URL;
    try {parsed = new URL(url);} catch {return invalid();}
    if (parsed.protocol !== "https:" || !parsed.hostname || parsed.username || parsed.password ||
        parsed.search || parsed.hash || m.storeId !== storeId || m.skuId !== skuId ||
        m.canonicalProductId !== canonicalProductId) invalid("Product image identity is invalid.");
    const file = exact(m.file, ["mimeType", "byteLength", "width", "height", "normalized"], ["frameCount"]);
    if (!["image/jpeg", "image/png", "image/webp"].includes(String(file.mimeType))) invalid();
    return {id: id(m.id), revision: id(m.revision), url, storeId, skuId, canonicalProductId,
      publisherWorkspaceId: id(m.publisherWorkspaceId),
      file: {mimeType: String(file.mimeType), byteLength: integer(file.byteLength, 1, 10 * 1024 * 1024),
        width: integer(file.width, 1, 8192), height: integer(file.height, 1, 8192), normalized: boolean(file.normalized),
        ...(Object.hasOwn(file, "frameCount") ? {frameCount: integer(file.frameCount, 1, 1)} : {})}};
  });
  if (new Set(media.map(m => m.id)).size !== media.length) invalid();
  const channels = list(v.channels, 2).map(value => {
    const a = exact(value, ["kind", "offerId", "priceMinor", "mrpMinor", "minimumOrder", "quantityStep", "tiers"]);
    const terms = authoredChannel(a);
    return {kind: terms.kind, offerId: id(a.offerId), priceMinor: terms.priceMinor, mrpMinor: terms.mrpMinor,
      minimumOrder: terms.minimumOrder, quantityStep: terms.quantityStep, tiers: terms.tiers};
  });
  authoredChannelsValid(channels);
  return {skuId, canonicalProductId, verifiedPackId: id(v.verifiedPackId), sku: text(v.sku, 80),
    publicListing: boolean(v.publicListing),
    content: {...authoredText(c), media, ...(Object.hasOwn(c, "productFacts") ? {productFacts: normalizeProductFacts(c.productFacts)} : {})},
    pack, channels,
    provenance: {entryMethod: provenance.entryMethod as StoreSkuInput["provenance"]["entryMethod"],
      sourceRecordId: id(provenance.sourceRecordId)}};
}

export function normalizeSubmittedProduct(value: unknown): StoreProductSubmissionInput {
  const p = exact(value, ["schemaVersion", "skuId", "sku", "barcode", "catalogueProductHint", "content", "pack", "channels",
    "provenance", "mediaIntent", "variantIntent"]);
  if (p.schemaVersion !== 1) invalid();
  const skuId = id(p.skuId), c = exact(p.content, ["title", "brand", "variant", "categoryId", "description", "highlights", "specifications"], ["productFacts"]);
  const channels = list(p.channels, 2).map(raw => authoredChannel(exact(raw,
    ["kind", "priceMinor", "mrpMinor", "minimumOrder", "quantityStep", "tiers"])));
  authoredChannelsValid(channels);
  const origin = exact(p.provenance, ["entryMethod", "sourceRecordId"]);
  if (typeof origin.entryMethod !== "string" || !["catalogue", "manual", "csv"].includes(origin.entryMethod) || origin.sourceRecordId !== skuId) invalid();
  const m = exact(p.mediaIntent, ["pendingUpload", "pendingSelectionSha256", "publishedReferences"]);
  const pendingUpload = boolean(m.pendingUpload);
  // A nomination/change fence only: never a verified asset hash or public image.
  if (pendingUpload ? typeof m.pendingSelectionSha256 !== "string" || !/^[A-F0-9]{64}$/u.test(m.pendingSelectionSha256)
    : m.pendingSelectionSha256 !== null) invalid();
  const references = list(m.publishedReferences, 10).map(raw => {
    const asset = exact(raw, ["assetId", "revision"]); return {assetId: id(asset.assetId), revision: id(asset.revision)};
  });
  if (new Set(references.map(asset => asset.assetId)).size !== references.length) invalid();
  let variant: StoreProductSubmissionInput["variantIntent"] = null;
  if (p.variantIntent !== null) {
    const v = exact(p.variantIntent, ["familyId", "localRevision", "selections"]), selections = object(v.selections);
    if (!Object.keys(selections).length || Object.keys(selections).length > 6) invalid();
    variant = {familyId: id(v.familyId), localRevision: integer(v.localRevision, 1, 1000000000),
      selections: Object.fromEntries(Object.entries(selections).map(([dimension, option]) => [id(dimension), id(option)]))};
  }
  const result: StoreProductSubmissionInput = {schemaVersion: 1, skuId, sku: text(p.sku, 80), barcode: text(p.barcode, 128, true),
    catalogueProductHint: p.catalogueProductHint === null ? null : id(p.catalogueProductHint),
    content: {...authoredText(c), ...(Object.hasOwn(c, "productFacts") ? {productFacts: normalizeProductFacts(c.productFacts)} : {})},
    pack: authoredPack(p.pack), channels, provenance: {entryMethod: origin.entryMethod as StoreSkuInput["provenance"]["entryMethod"], sourceRecordId: skuId},
    mediaIntent: {pendingUpload, pendingSelectionSha256: m.pendingSelectionSha256 as string | null, publishedReferences: references}, variantIntent: variant};
  if (Buffer.byteLength(JSON.stringify(result), "utf8") > 384 * 1024) invalid("Product details are too large to submit.");
  return result;
}
export function storeProductSubmission(ownerUserId: string, realm: StoreProductSubmissionRecord["realm"],
  body: Readonly<Record<string, unknown>>, at: string): StoreProductSubmissionCommand {
  exact(body, ["storeId", "expectedRevision", "idempotencyKey", "product"]);
  if (!["evaluation", "production"].includes(realm) || typeof at !== "string" || !Number.isFinite(Date.parse(at)) || new Date(at).toISOString() !== at) invalid();
  const command = {ownerUserId: id(ownerUserId), realm, storeId: id(body.storeId), expectedRevision: integer(body.expectedRevision, 0, 999999999),
    idempotencyKey: id(body.idempotencyKey), submittedAt: at, product: normalizeSubmittedProduct(body.product)};
  return {...command, fingerprint: cataloguePayloadHash({ownerUserId: command.ownerUserId, realm, storeId: command.storeId,
    expectedRevision: command.expectedRevision, product: command.product})};
}
function checkedProductSubmission(raw: unknown, realm: StoreProductSubmissionRecord["realm"], storeId: string, skuId: string): StoreProductSubmissionRecord {
  const r = exact(raw, ["schemaVersion", "realm", "storeId", "skuId", "revision", "submittedAt", "submittedBy", "fingerprint", "product"]);
  const original = storeProductSubmission(id(r.submittedBy), realm, {storeId, expectedRevision: integer(r.revision, 1, 1000000000) - 1,
    idempotencyKey: "validation-only", product: r.product}, text(r.submittedAt, 32));
  if (r.schemaVersion !== 1 || r.realm !== realm || r.storeId !== storeId || r.skuId !== skuId ||
      original.product.skuId !== skuId || r.fingerprint !== original.fingerprint) invalid("Saved product submission is invalid.");
  return {schemaVersion: 1, realm, storeId, skuId, revision: original.expectedRevision + 1, submittedAt: original.submittedAt,
    submittedBy: original.ownerUserId, fingerprint: original.fingerprint, product: original.product};
}
export function planStoreProductSubmission(command: StoreProductSubmissionCommand, profile: WorkspaceProfileRecord | undefined,
  current?: StoreProductSubmissionRecord, receipt?: StoreProductSubmissionReceipt): StoreProductSubmissionRecord {
  requireStore(profile, command.storeId, command.ownerUserId);
  const normalized = storeProductSubmission(command.ownerUserId, command.realm, {storeId: command.storeId,
    expectedRevision: command.expectedRevision, idempotencyKey: command.idempotencyKey, product: command.product}, command.submittedAt);
  if (normalized.fingerprint !== command.fingerprint) invalid();
  if (receipt) {
    const record = checkedProductSubmission(receipt.record, command.realm, command.storeId, command.product.skuId);
    if (receipt.fingerprint !== command.fingerprint || record.fingerprint !== command.fingerprint) {
      throw new WorkspaceProfileError("conflict", "The saved submission request changed. Check its original result.", 409);
    }
    return record;
  }
  const previous = current && checkedProductSubmission(current, command.realm, command.storeId, command.product.skuId);
  if ((previous?.revision ?? 0) !== command.expectedRevision) throw new WorkspaceProfileError("revision_conflict", "Product submission changed. Refresh before submitting.", 409);
  if (previous && command.submittedAt < previous.submittedAt) invalid("Submission time precedes the saved request.");
  return {schemaVersion: 1, realm: command.realm, storeId: command.storeId, skuId: command.product.skuId,
    revision: command.expectedRevision + 1, submittedAt: command.submittedAt, submittedBy: command.ownerUserId,
    fingerprint: command.fingerprint, product: normalized.product};
}

function reviewedCandidateReference(raw: unknown): {revision: number; fingerprint: string} {
  const value = exact(raw, ["revision", "fingerprint"]);
  if (typeof value.fingerprint !== "string" || !/^[A-F0-9]{64}$/u.test(value.fingerprint)) invalid();
  return {revision: integer(value.revision, 1, 1000000000), fingerprint: value.fingerprint};
}
function candidateSku(source: StoreProductSubmissionRecord, productId: string, packId: string,
  rawOffers: unknown): StoreSkuInput {
  // Reuse the media-wait check, without inventing an approved asset from a nomination.
  submittedCatalogueInput(source, {type: "propose_pack", commandId: "candidate-validation",
    expectedVersion: 1, productId, packId, codes: []});
  const offers = list(rawOffers, 2).map(raw => {
    const row = exact(raw, ["kind", "offerId"]);
    if (typeof row.kind !== "string" || !["retail", "wholesale", "bulk"].includes(row.kind)) invalid();
    return {kind: row.kind, offerId: id(row.offerId)};
  });
  if (offers.length !== source.product.channels.length || new Set(offers.map(o => o.kind)).size !== offers.length) invalid();
  return normalizeSku({skuId: source.skuId, sku: source.product.sku, canonicalProductId: id(productId),
    verifiedPackId: id(packId), publicListing: true, content: {...source.product.content, media: []}, pack: source.product.pack,
    provenance: source.product.provenance, channels: source.product.channels.map(channel => {
      const offer = offers.find(o => o.kind === channel.kind); if (!offer) invalid();
      return {...channel, offerId: offer.offerId};
    })}, source.storeId);
}
function independentProductReview(catalogue: CatalogueAggregate, sku: StoreSkuInput, author: string): void {
  const hash = cataloguePayloadHash(sku.content), product = catalogue.products.find(p => p.productId === sku.canonicalProductId);
  const revision = product?.contentRevisions?.find(r => r.state === "verified" && r.contentSha256 === hash);
  const original = product?.contentSha256.toUpperCase() === hash;
  const reviewer = original ? product?.reviewedBy : revision?.reviewedBy;
  const requireEvidence = (entityId: string, fingerprint: string, reviewedBy: string | undefined,
    proposalType: "product_proposed" | "product_content_revision_proposed" | "pack_proposed",
    reviewType: "product_verified" | "product_content_revision_verified" | "pack_verified",
    proposedAt: string | undefined, reviewedAt: string | undefined, proposedBy?: string) => {
    const review = catalogue.auditEvents.filter(event => event.eventType === reviewType && event.entityId === entityId &&
      event.hashReferences.at(-1)?.toUpperCase() === fingerprint && event.actorId === reviewedBy && event.occurredAt === reviewedAt);
    const approved = review.length === 1 ? review[0] : undefined;
    // Same content may be rejected and reproposed. Bind the approval to its
    // immediate preceding proposal by audit version, not global hash uniqueness.
    const proposal = approved && catalogue.auditEvents.filter(event => event.eventType === proposalType && event.entityId === entityId &&
      event.hashReferences.at(-1)?.toUpperCase() === fingerprint && event.aggregateVersion < approved.aggregateVersion)
      .sort((a, b) => b.aggregateVersion - a.aggregateVersion)[0];
    if (!reviewedBy || reviewedBy === author || !approved || !proposal || proposal.actorId === reviewedBy ||
        proposal.occurredAt !== proposedAt || proposedBy !== undefined && proposal.actorId !== proposedBy) {
      throw new WorkspaceProfileError("forbidden", "Independent product and pack review is required.", 403);
    }
  };
  requireEvidence(sku.canonicalProductId, hash, reviewer, original ? "product_proposed" : "product_content_revision_proposed",
    original ? "product_verified" : "product_content_revision_verified", original ? product?.proposedAt : revision?.proposedAt,
    original ? product?.reviewedAt : revision?.reviewedAt, original ? undefined : revision?.proposedByActorId);
  const pack = catalogue.packs.find(p => p.packId === sku.verifiedPackId);
  requireEvidence(sku.verifiedPackId, cataloguePayloadHash(sku.pack), pack?.reviewedBy, "pack_proposed", "pack_verified", pack?.proposedAt, pack?.reviewedAt);
}
function checkedReviewedCandidate(raw: unknown): StoreReviewedProductCandidate {
  const value = exact(raw, ["schemaVersion", "realm", "storeId", "skuId", "revision", "fingerprint", "source", "identity",
    "sku", "expectedMirrorRevision", "reviewedBy", "reviewedAt", "expiresAt", "terms"]);
  const reference = reviewedCandidateReference({revision: value.revision, fingerprint: value.fingerprint});
  const source = submissionReference(value.source), identity = exact(value.identity, ["catalogueId", "tenantId"]);
  const reviewedAt = text(value.reviewedAt, 32), expiresAt = text(value.expiresAt, 32);
  if (value.schemaVersion !== 1 || value.realm !== source.realm || value.storeId !== source.storeId || value.skuId !== source.skuId ||
      !Number.isFinite(Date.parse(reviewedAt)) || new Date(reviewedAt).toISOString() !== reviewedAt ||
      !Number.isFinite(Date.parse(expiresAt)) || new Date(expiresAt).toISOString() !== expiresAt || expiresAt <= reviewedAt) invalid();
  const sku = normalizeSku(value.sku, source.storeId);
  if (sku.skuId !== source.skuId || !sku.publicListing) invalid();
  const terms = list(value.terms, 2).map(rawTerm => {
    const term = exact(rawTerm, ["kind", "offerId", "termSnapshotId", "termSnapshotSha256", "effectiveFrom", "expiresAt"]);
    const channel = sku.channels.find(c => c.kind === term.kind && c.offerId === term.offerId);
    if (!channel || term.termSnapshotSha256 !== cataloguePayloadHash(channelTerms(channel))) invalid();
    const effectiveFrom = text(term.effectiveFrom, 32), until = text(term.expiresAt, 32);
    if (!Number.isFinite(Date.parse(effectiveFrom)) || new Date(effectiveFrom).toISOString() !== effectiveFrom ||
        !Number.isFinite(Date.parse(until)) || new Date(until).toISOString() !== until || effectiveFrom > reviewedAt || until < expiresAt) invalid();
    return {kind: channel.kind, offerId: channel.offerId, termSnapshotId: id(term.termSnapshotId),
      termSnapshotSha256: term.termSnapshotSha256 as string, effectiveFrom, expiresAt: until};
  });
  if (terms.length !== sku.channels.length || new Set(terms.map(t => t.kind)).size !== terms.length) invalid();
  const candidate = {schemaVersion: 1 as const, realm: source.realm, storeId: source.storeId, skuId: source.skuId,
    revision: reference.revision, source, identity: {catalogueId: id(identity.catalogueId), tenantId: id(identity.tenantId)},
    sku, expectedMirrorRevision: integer(value.expectedMirrorRevision, 0, 1000000000),
    reviewedBy: id(value.reviewedBy), reviewedAt, expiresAt, terms};
  if (cataloguePayloadHash(candidate) !== reference.fingerprint) invalid("Saved review candidate is invalid.");
  return {...candidate, fingerprint: reference.fingerprint};
}
function validateReviewedCandidate(candidate: StoreReviewedProductCandidate, source: StoreProductSubmissionRecord,
  profile: WorkspaceProfileRecord, catalogue: CatalogueAggregate | undefined, authority: CatalogueProducerAuthority | undefined,
  participant: SupplyParticipantWorkspace | undefined, current: StoreSkuRecord | undefined, at: string): void {
  if (!catalogue || candidate.source.fingerprint !== source.fingerprint || candidate.source.revision !== source.revision ||
      candidate.storeId !== source.storeId || candidate.skuId !== source.skuId || candidate.realm !== source.realm ||
      candidate.reviewedBy === source.submittedBy || at < candidate.reviewedAt || at >= candidate.expiresAt ||
      cataloguePayloadHash(candidate.sku) !== cataloguePayloadHash(candidateSku(source, candidate.sku.canonicalProductId,
        candidate.sku.verifiedPackId, candidate.sku.channels.map(c => ({kind: c.kind, offerId: c.offerId}))))) {
    invalid("Reviewed product source or terms changed.");
  }
  independentProductReview(catalogue, candidate.sku, source.submittedBy);
  for (const term of candidate.terms) {
    const offer = catalogue.offers.find(o => o.offerId === term.offerId), currentTerm = offer && referencedOfferTermAt(offer, at);
    if (!currentTerm || cataloguePayloadHash(currentTerm) !== cataloguePayloadHash({termSnapshotId: term.termSnapshotId,
      termSnapshotSha256: term.termSnapshotSha256, effectiveFrom: term.effectiveFrom, expiresAt: term.expiresAt})) invalid("Reviewed offer window changed.");
  }
  const fingerprint = cataloguePayloadHash({storeId: candidate.storeId, input: candidate.sku, expectedRevision: candidate.expectedMirrorRevision});
  planReviewedCatalogueSave({ownerUserId: source.submittedBy, profile, expectedRevision: candidate.expectedMirrorRevision,
    idempotencyKey: "validate-reviewed-candidate", fingerprint, input: candidate.sku, observedAt: at}, candidate.identity,
  catalogue, authority, participant, current, undefined, at);
}

function normalizeProductFacts(value: unknown): StoreSkuProductFacts {
  const facts = exact(value, ["schemaVersion", "compliance", "composition", "regulatoryNote", "requiresPrescription"]);
  if (facts.schemaVersion !== 1) invalid();
  const keys = ["genericName", "netQuantity", "manufacturerName", "manufacturerAddress", "packerName", "packerAddress",
    "importerName", "importerAddress", "countryOfOrigin", "manufacturedOrPackedOn", "bestBeforeOrUseBy",
    "fssaiLicenseNumber", "consumerCare"];
  const compliance = exact(facts.compliance, keys);
  const optionalText = (raw: unknown, maximum: number) => raw === null ? null : text(raw, maximum);
  return {schemaVersion: 1,
    compliance: Object.fromEntries(keys.map(key => [key, optionalText(compliance[key], 1000)])) as StoreSkuProductFacts["compliance"],
    composition: optionalText(facts.composition, 4000), regulatoryNote: optionalText(facts.regulatoryNote, 4000),
    requiresPrescription: boolean(facts.requiresPrescription)};
}

function normalizeRecord(value: unknown, storeId: string): StoreSkuRecord {
  const r = exact(value, ["schemaVersion", "storeId", "revision", "observedAt", "skuId", "canonicalProductId",
    "verifiedPackId", "sku", "publicListing", "content", "pack", "channels", "provenance"]);
  if (r.schemaVersion !== 1 || r.storeId !== storeId) invalid();
  const {schemaVersion: _, storeId: _s, revision, observedAt, ...input} = r;
  const timestamp = text(observedAt, 32);
  if (!Number.isFinite(Date.parse(timestamp)) || new Date(timestamp).toISOString() !== timestamp) invalid();
  return {...normalizeSku(input, storeId), schemaVersion: 1, storeId,
    revision: integer(revision, 1, 1_000_000_001), observedAt: timestamp};
}

export interface CatalogueSaveReceipt {fingerprint: string; record: StoreSkuRecord}

/** Store-owned descriptive grouping only. Each member remains one real SKU. */
export interface StoreVariantOption {
  dimensionId: string; dimensionLabel: string; optionId: string; optionLabel: string;
  kind: "colour" | "size" | "storage" | "pack" | "other"; swatchArgb: number | null;
}
export interface StoreVariantFamilyInput {
  familyId: string; localRevision: number; title: string; brand: string; categoryId: string;
  options: StoreVariantOption[];
  members: Array<{skuId: string; skuRevision: number; selections: Record<string, string>}>;
}
export interface StoreVariantFamilyCandidate {
  schemaVersion: 1; realm: "evaluation" | "production"; storeId: string;
  revision: number; submittedAt: string; submittedBy: string;
  fingerprint: string; family: StoreVariantFamilyInput;
}
export interface StoreVariantFamilySubmission {
  ownerUserId: string; realm: "evaluation" | "production"; storeId: string;
  expectedRevision: number; idempotencyKey: string; fingerprint: string;
  submittedAt: string; family: StoreVariantFamilyInput;
}
export interface StoreVariantFamilyReceipt {fingerprint: string; record: StoreVariantFamilyCandidate}
export interface StoreVariantFamilyReview {
  schemaVersion: 1; revision: number; decision: "verify" | "reject";
  reviewerUserId: string; reviewedAt: string; reasonCode: string;
  catalogueId: string; tenantId: string; candidate: StoreVariantFamilyCandidate;
}

export function normalizeStoreVariantFamily(value: unknown): StoreVariantFamilyInput {
  const raw = exact(value, ["familyId", "localRevision", "title", "brand", "categoryId", "options", "members"]);
  const options = list(raw.options, 128).map(value => {
    const row = exact(value, ["dimensionId", "dimensionLabel", "optionId", "optionLabel", "kind", "swatchArgb"]);
    if (typeof row.kind !== "string" || !["colour", "size", "storage", "pack", "other"].includes(row.kind) ||
        row.swatchArgb !== null && row.kind !== "colour") invalid("Check the family options.");
    return {dimensionId: id(row.dimensionId), dimensionLabel: text(row.dimensionLabel, 120),
      optionId: id(row.optionId), optionLabel: text(row.optionLabel, 120),
      kind: row.kind as StoreVariantOption["kind"],
      swatchArgb: row.swatchArgb === null ? null : integer(row.swatchArgb, 0, 0xffffffff)};
  });
  const dimensions = new Map<string, StoreVariantOption>();
  const optionIds = new Set<string>(), optionLabels = new Set<string>();
  for (const option of options) {
    const previous = dimensions.get(option.dimensionId);
    const key = JSON.stringify([option.dimensionId, option.optionId]);
    const label = JSON.stringify([option.dimensionId, option.optionLabel.toLowerCase()]);
    if (optionIds.has(key) || optionLabels.has(label) || previous &&
        (previous.dimensionLabel !== option.dimensionLabel || previous.kind !== option.kind)) invalid("Duplicate or inconsistent family option.");
    optionIds.add(key); optionLabels.add(label); dimensions.set(option.dimensionId, option);
  }
  if (!dimensions.size || dimensions.size > 8 ||
      new Set([...dimensions.values()].map(d => d.dimensionLabel.toLowerCase())).size !== dimensions.size) invalid();
  const skuIds = new Set<string>(), combinations = new Set<string>();
  const members = list(raw.members, 80).map(value => {
    const row = exact(value, ["skuId", "skuRevision", "selections"]);
    const selections = exact(row.selections, [...dimensions.keys()]);
    const normalized = Object.fromEntries([...dimensions.keys()].sort().map(d => [d, id(selections[d])]));
    if (Object.entries(normalized).some(([d, o]) => !optionIds.has(JSON.stringify([d, o])))) invalid("Choose an existing family option.");
    const skuId = id(row.skuId), combination = JSON.stringify(normalized);
    if (skuIds.has(skuId) || combinations.has(combination)) invalid("Each actual option combination needs one SKU.");
    skuIds.add(skuId); combinations.add(combination);
    return {skuId, skuRevision: integer(row.skuRevision, 1, 1000000000), selections: normalized};
  });
  if (!members.length) invalid("Choose the saved SKUs in this family.");
  const compare = (a: string, b: string) => a < b ? -1 : a > b ? 1 : 0;
  options.sort((a, b) => compare(a.dimensionId, b.dimensionId) || compare(a.optionId, b.optionId));
  members.sort((a, b) => compare(a.skuId, b.skuId));
  return {familyId: id(raw.familyId), localRevision: integer(raw.localRevision, 1, 2147483647),
    title: text(raw.title), brand: text(raw.brand, 240, true), categoryId: id(raw.categoryId), options, members};
}

export function storeVariantFamilySubmission(ownerUserId: string, realm: StoreVariantFamilySubmission["realm"],
  body: Readonly<Record<string, unknown>>, submittedAt: string): StoreVariantFamilySubmission {
  exact(body, ["storeId", "expectedRevision", "idempotencyKey", "family"]);
  if (!["evaluation", "production"].includes(realm) || typeof submittedAt !== "string" || !Number.isFinite(Date.parse(submittedAt)) ||
      new Date(submittedAt).toISOString() !== submittedAt) invalid();
  const original = {ownerUserId: id(ownerUserId), realm, storeId: id(body.storeId),
    expectedRevision: integer(body.expectedRevision, 0, 999999999), family: normalizeStoreVariantFamily(body.family)};
  return {...original, idempotencyKey: id(body.idempotencyKey), submittedAt,
    fingerprint: cataloguePayloadHash(original)};
}

function checkedFamilyCandidate(value: StoreVariantFamilyCandidate): StoreVariantFamilyCandidate {
  const raw = exact(value, ["schemaVersion", "realm", "storeId", "revision", "submittedAt", "submittedBy", "fingerprint", "family"]);
  const command = storeVariantFamilySubmission(id(raw.submittedBy), raw.realm as StoreVariantFamilySubmission["realm"],
    {storeId: raw.storeId, expectedRevision: integer(raw.revision, 1, 1000000000) - 1,
      idempotencyKey: "validation-only", family: raw.family}, text(raw.submittedAt, 32));
  if (raw.schemaVersion !== 1 || command.fingerprint !== raw.fingerprint) invalid("Family submission needs recovery.");
  return {schemaVersion: 1, realm: command.realm, storeId: command.storeId,
    revision: command.expectedRevision + 1, submittedAt: command.submittedAt,
    submittedBy: command.ownerUserId, fingerprint: command.fingerprint, family: command.family};
}

function familyMembers(candidate: StoreVariantFamilyCandidate, records: readonly StoreSkuRecord[]): StoreSkuRecord[] {
  return candidate.family.members.map(member => {
    const matching = records.filter(r => r.skuId === member.skuId && r.storeId === candidate.storeId);
    if (matching.length !== 1) invalid("A family SKU is unavailable.");
    const row = normalizeRecord(matching[0], candidate.storeId);
    if (row.revision !== member.skuRevision || row.observedAt > candidate.submittedAt ||
        row.content.title !== candidate.family.title || row.content.brand !== candidate.family.brand ||
        row.content.categoryId !== candidate.family.categoryId) invalid("Family SKU details changed. Refresh before submitting.");
    return row;
  });
}

function checkedFamilyReview(value: unknown): StoreVariantFamilyReview {
  const raw = exact(value, ["schemaVersion", "revision", "decision", "reviewerUserId", "reviewedAt",
    "reasonCode", "catalogueId", "tenantId", "candidate"]);
  const candidate = checkedFamilyCandidate(raw.candidate as StoreVariantFamilyCandidate);
  if (raw.schemaVersion !== 1 || typeof raw.decision !== "string" || !["verify", "reject"].includes(raw.decision) ||
      raw.reviewerUserId === candidate.submittedBy || typeof raw.reviewedAt !== "string" ||
      !Number.isFinite(Date.parse(raw.reviewedAt)) || new Date(raw.reviewedAt).toISOString() !== raw.reviewedAt ||
      raw.reviewedAt < candidate.submittedAt) invalid();
  return {schemaVersion: 1, revision: integer(raw.revision, 1, 1000000000),
    decision: raw.decision as StoreVariantFamilyReview["decision"], reviewerUserId: id(raw.reviewerUserId),
    reviewedAt: raw.reviewedAt, reasonCode: id(raw.reasonCode), catalogueId: id(raw.catalogueId), tenantId: id(raw.tenantId), candidate};
}

export function planStoreVariantFamilySubmission(command: StoreVariantFamilySubmission,
  profile: WorkspaceProfileRecord | undefined, records: readonly StoreSkuRecord[],
  current?: StoreVariantFamilyCandidate, receipt?: StoreVariantFamilyReceipt): StoreVariantFamilyCandidate {
  requireStore(profile, command.storeId, command.ownerUserId);
  const original = storeVariantFamilySubmission(command.ownerUserId, command.realm,
    {storeId: command.storeId, expectedRevision: command.expectedRevision, idempotencyKey: command.idempotencyKey,
      family: command.family}, command.submittedAt);
  if (original.fingerprint !== command.fingerprint) invalid();
  if (receipt) {
    const record = checkedFamilyCandidate(receipt.record);
    if (receipt.fingerprint !== original.fingerprint || record.fingerprint !== original.fingerprint ||
        record.revision !== original.expectedRevision + 1) {
      throw new WorkspaceProfileError("conflict", "This family request changed. Check its original result.", 409);
    }
    return record;
  }
  const previous = current && checkedFamilyCandidate(current);
  if (previous && (previous.realm !== original.realm || previous.storeId !== original.storeId ||
      previous.family.familyId !== original.family.familyId)) invalid();
  if ((previous?.revision ?? 0) !== original.expectedRevision) {
    throw new WorkspaceProfileError("revision_conflict", "The family submission changed. Refresh before submitting.", 409);
  }
  const candidate: StoreVariantFamilyCandidate = {schemaVersion: 1, realm: original.realm,
    storeId: original.storeId, revision: original.expectedRevision + 1, submittedAt: original.submittedAt,
    submittedBy: original.ownerUserId, fingerprint: original.fingerprint, family: original.family};
  familyMembers(candidate, records);
  return candidate;
}

/** Internal review only. Does not approve product facts, packs or selling rights. */
export function planStoreVariantFamilyReview(operatorUserId: string, identity: CatalogueIdentity,
  body: Readonly<Record<string, unknown>>, authority: CatalogueProducerAuthority | undefined,
  candidateValue: StoreVariantFamilyCandidate, records: readonly StoreSkuRecord[],
  catalogue: CatalogueAggregate | undefined, at: string, current?: StoreVariantFamilyReview): StoreVariantFamilyReview {
  exact(body, ["expectedCandidateRevision", "expectedCandidateFingerprint", "expectedReviewRevision", "decision", "reasonCode", "idempotencyKey"]);
  id(body.idempotencyKey);
  const actor = producerActor(id(operatorUserId), identity, at, authority);
  const candidate = checkedFamilyCandidate(candidateValue);
  if (current && (current.candidate.realm !== candidate.realm || current.candidate.storeId !== candidate.storeId ||
      current.candidate.family.familyId !== candidate.family.familyId || current.catalogueId !== identity.catalogueId ||
      current.tenantId !== identity.tenantId)) invalid();
  if (!actor.scopes.includes("supply.catalogue.review") || operatorUserId === candidate.submittedBy) {
    throw new WorkspaceProfileError("forbidden", "Independent catalogue review is required.", 403);
  }
  if (body.expectedCandidateRevision !== candidate.revision || body.expectedCandidateFingerprint !== candidate.fingerprint ||
      integer(body.expectedReviewRevision, 0, 999999999) !== (current?.revision ?? 0) ||
      typeof body.decision !== "string" || !["verify", "reject"].includes(body.decision) || candidate.submittedAt > at) invalid("The reviewed family changed.");
  if (typeof at !== "string" || !Number.isFinite(Date.parse(at)) || new Date(at).toISOString() !== at) invalid();
  if (body.decision === "verify") {
    if (!catalogue || catalogue.schemaVersion !== 1 || !Number.isSafeInteger(catalogue.version) || catalogue.version < 1 ||
        catalogue.catalogueId !== identity.catalogueId || catalogue.tenantId !== identity.tenantId) invalid();
    for (const record of familyMembers(candidate, records)) {
      const product = reviewedCanonicalProduct(catalogue, record.canonicalProductId, cataloguePayloadHash(record.content));
      const pack = catalogue.packs.find(p => p.packId === record.verifiedPackId);
      if (!record.publicListing || product?.state !== "verified" || pack?.state !== "verified" ||
          pack.productId !== product.productId || !canonicalContentMatches(product, record.content) ||
          product.contentSha256.toUpperCase() !== cataloguePayloadHash(record.content) ||
          pack.descriptorSha256.toUpperCase() !== cataloguePayloadHash(record.pack)) invalid("Publish each exact reviewed SKU before family approval.");
      for (const channel of record.channels) {
        const offer = catalogue.offers.find(o => o.offerId === channel.offerId && o.workspaceId === candidate.storeId &&
          o.packId === pack.packId && o.buyingContext === (channel.kind === "retail" ? "consumer" : "wholesale"));
        const term = offer && referencedOfferTermAt(offer, at);
        if (!term || term.termSnapshotSha256.toUpperCase() !== cataloguePayloadHash(channelTerms(channel))) invalid("Family selling terms changed.");
      }
    }
  }
  return {schemaVersion: 1, revision: (current?.revision ?? 0) + 1,
    decision: body.decision as StoreVariantFamilyReview["decision"], reviewerUserId: operatorUserId,
    reviewedAt: at, reasonCode: id(body.reasonCode), catalogueId: id(identity.catalogueId),
    tenantId: id(identity.tenantId), candidate};
}

/** Shared by the transaction adapter and isolated tests; no network side effects. */
export function planCatalogueSave(command: CatalogueSave, current?: StoreSkuRecord,
  receipt?: CatalogueSaveReceipt): StoreSkuRecord {
  const storeId = id(command.profile.workspaceId);
  requireStore(command.profile, storeId, command.ownerUserId);
  const input = normalizeSku(command.input, storeId);
  const reviewCandidate = command.reviewCandidate === undefined ? undefined : reviewedCandidateReference(command.reviewCandidate);
  const fingerprint = cataloguePayloadHash({storeId, input, expectedRevision: command.expectedRevision,
    ...(reviewCandidate ? {reviewCandidate} : {})});
  if (command.fingerprint !== fingerprint) invalid();
  const conflict = () => new WorkspaceProfileError("conflict", "This product changed. Refresh before saving again.", 409);
  if (receipt) {
    exact(receipt, ["fingerprint", "record"]);
    const prior = normalizeRecord(receipt.record, storeId);
    if (receipt.fingerprint !== fingerprint || prior.skuId !== input.skuId) throw conflict();
    return prior;
  }
  const prior = current && normalizeRecord(current, storeId);
  if (command.expectedRevision !== (prior?.revision ?? 0) || (prior &&
      (prior.skuId !== input.skuId || prior.canonicalProductId !== input.canonicalProductId ||
       prior.verifiedPackId !== input.verifiedPackId ||
       cataloguePayloadHash(prior.provenance) !== cataloguePayloadHash(input.provenance)))) throw conflict();
  return normalizeRecord({...input, schemaVersion: 1, storeId,
    revision: command.expectedRevision + 1, observedAt: command.observedAt}, storeId);
}

/** The saved mirror is the binding: never allocate a second SKU or Stock record. */
export function planReviewedCatalogueSave(command: CatalogueSave, identity: CatalogueIdentity,
  catalogue: CatalogueAggregate | undefined, authority: CatalogueProducerAuthority | undefined,
  participant: SupplyParticipantWorkspace | undefined, current?: StoreSkuRecord,
  receipt?: CatalogueSaveReceipt, authorizationAt = command.observedAt): StoreSkuRecord {
  const storeId = id(command.profile.workspaceId), at = command.observedAt;
  if (!Number.isFinite(Date.parse(at)) || new Date(at).toISOString() !== at) invalid();
  requireStore(command.profile, storeId, command.ownerUserId);
  const input = normalizeSku(command.input, storeId);
  // Owners may withdraw their exact existing mirror even after review/selling
  // authority expires. This grants no new content, price or publication rights.
  if (!input.publicListing && (current || receipt)) {
    if (receipt) return planCatalogueSave(command, current, receipt);
    const {schemaVersion: _v, storeId: _s, revision: _r, observedAt: _a, ...prior} = normalizeRecord(current, storeId);
    if (cataloguePayloadHash({...prior, publicListing: false}) !== cataloguePayloadHash(input)) {
      invalid("Withdraw the original listing without changing its product facts.");
    }
    return planCatalogueSave(command, current);
  }
  const actor = producerActor(id(command.ownerUserId), identity, authorizationAt, authority);
  if (actor.workspaceId !== storeId || !actor.scopes.includes("supply.workspace.admin") ||
      !participant || participant.schemaVersion !== 1 || participant.status !== "registered" ||
      participant.workspaceId !== storeId || participant.tenantId !== identity.tenantId) {
    throw new WorkspaceProfileError("forbidden", "Reviewed product binding is not available.", 403);
  }
  // Recovery is a historical result, not a new publication decision. Current
  // actor/Store access still applies, but an expired offer cannot erase a receipt.
  if (receipt) return planCatalogueSave(command, current, receipt);
  if (!catalogue || catalogue.schemaVersion !== 1 || catalogue.catalogueId !== identity.catalogueId ||
      catalogue.tenantId !== identity.tenantId) invalid("Reviewed catalogue is not available.");
  const product = reviewedCanonicalProduct(catalogue, input.canonicalProductId, cataloguePayloadHash(input.content));
  const pack = catalogue.packs.find(p => p.packId === input.verifiedPackId);
  if (product?.state !== "verified" || pack?.state !== "verified" || pack.productId !== product.productId ||
      !canonicalContentMatches(product, input.content) ||
      product.contentSha256.toUpperCase() !== cataloguePayloadHash(input.content) ||
      pack.descriptorSha256.toUpperCase() !== cataloguePayloadHash(input.pack)) {
    invalid("Product or pack does not match its reviewed version.");
  }
  for (const channel of input.channels) {
    const offer = catalogue.offers.find(o => o.offerId === channel.offerId && o.workspaceId === storeId &&
      o.packId === pack.packId && o.buyingContext === (channel.kind === "retail" ? "consumer" : "wholesale"));
    const term = offer && referencedOfferTermAt(offer, authorizationAt);
    if (!offer || !term || term.termSnapshotSha256.toUpperCase() !== cataloguePayloadHash(channelTerms(channel)) ||
        offer.serviceAreaIds.length === 0 || offer.serviceAreaIds.some(serviceAreaId =>
          !currentCapability(participant, {capability: channel.kind === "retail" ? "retail_fulfilment" : "wholesale_supply",
            at: authorizationAt, categoryId: product.categoryId, serviceAreaId}))) {
      invalid("Selling terms do not match an active reviewed offer.");
    }
  }
  return planCatalogueSave(command, current, receipt);
}

export class FirestoreWorkspaceCatalogueRepository implements WorkspaceCatalogueRepository {
  constructor(private readonly firestore: Firestore, readonly realm: "evaluation" | "production",
    private readonly now: () => Date = () => new Date(), private readonly mediaObjects?: StoreProductMediaObjects) {}

  async productMedia(ownerUserId: string, action: "prepare" | "confirm" | "read", original: StoreProductMediaRequest): Promise<object> {
    const request = mediaRequest({productMediaVersion: 1, ...structuredClone(original)}), owner = id(ownerUserId);
    if (!["prepare", "confirm", "read"].includes(action)) invalid();
    const uploadId = cataloguePayloadHash([this.realm, request.storeId, request.skuId, owner, request.idempotencyKey]);
    const fingerprint = cataloguePayloadHash({realm: this.realm, ownerUserId: owner, ...request});
    const ref = this.root(request.storeId).collection("productMediaUploads").doc(uploadId);
    const head = this.productSubmissionHead(request.storeId, request.skuId);
    const immutableSource = head.collection("revisions").doc(String(request.submissionRevision));
    const matchesSource = (record: StoreProductSubmissionRecord | undefined) => !!record && record.submittedBy === owner &&
      record.revision === request.submissionRevision && record.fingerprint === request.submissionFingerprint &&
      record.product.mediaIntent.pendingUpload && record.product.mediaIntent.pendingSelectionSha256 ===
        cataloguePayloadHash({privateSha256: request.sourceSha256, skuId: request.skuId});
    const result = (record: StoreProductMediaUpload | null, current: boolean, grant?: {uploadUrl: string; requiredHeaders: Record<string, string>}) =>
      ({schemaVersion: 1, productMediaVersion: 1, realm: this.realm, storeId: request.storeId, skuId: request.skuId,
        idempotencyKey: request.idempotencyKey, uploadId, current,
        state: record?.processed ? "processed" : record ? "awaiting_upload" : "not_found",
        preparedAt: record?.preparedAt ?? null, expiresAt: record?.expiresAt ?? null,
        source: {revision: request.submissionRevision, fingerprint: request.submissionFingerprint},
        processed: record?.processed ?? null, approved: false, publicationConfirmed: false, ...(grant ?? {})});
    const loaded = await this.firestore.runTransaction(async transaction => {
      await this.productSubmissionOwner(transaction, request.storeId, owner);
      const [doc, sourceDoc, historicalDoc] = await transaction.getAll(ref, head, immutableSource);
      const source = sourceDoc?.exists ? checkedProductSubmission(sourceDoc.data(), this.realm, request.storeId, request.skuId) : undefined;
      const current = matchesSource(source);
      const historical = historicalDoc?.exists ? checkedProductSubmission(historicalDoc.data(), this.realm, request.storeId, request.skuId) : undefined;
      let record = doc?.exists ? checkedMediaUpload(doc.data(), this.now().toISOString()) : null;
      if (record && (record.fingerprint !== fingerprint || record.uploadId !== uploadId || record.ownerUserId !== owner ||
          record.realm !== this.realm || record.storeId !== request.storeId || record.skuId !== request.skuId)) {
        throw new WorkspaceProfileError("conflict", "This image request changed. Recover its original result.", 409);
      }
      if (record && !matchesSource(historical)) throw new WorkspaceProfileError("stale_snapshot", "The original saved image source cannot be verified.", 409);
      if (!record && action === "prepare") {
        if (!current) throw new WorkspaceProfileError("stale_snapshot", "The saved product or selected photo changed. Refresh before uploading.", 409);
        const preparedAt = this.now().toISOString(), expiresAt = new Date(Date.parse(preparedAt) + 300000).toISOString();
        record = {...request, schemaVersion: 1, realm: this.realm, ownerUserId: owner, uploadId, fingerprint, preparedAt, expiresAt, processed: null};
        transaction.create(ref, record);
      } else if (record && !record.processed && action === "prepare" && current && record.expiresAt <= this.now().toISOString()) {
        // A renewed grant still writes the original object with generation-match zero.
        // Never change the original body/key/source, or treat expiry as proof that its upload failed.
        record.grantIssuedAt = this.now().toISOString();
        record.expiresAt = new Date(Date.parse(record.grantIssuedAt) + 300000).toISOString();
        transaction.set(ref, checkedMediaUpload(record, this.now().toISOString()));
      }
      return {record, current};
    });
    if (!loaded.record || action === "read" || loaded.record.processed) return result(loaded.record, loaded.current);
    if (action === "prepare" && !loaded.current) throw new WorkspaceProfileError("stale_snapshot", "The saved product or selected photo changed. Its earlier upload cannot replace it.", 409);
    if (!this.mediaObjects) throw mediaUnavailable();
    const upload = loaded.record;
    if (action === "prepare") {
      if (upload.expiresAt <= this.now().toISOString()) throw new WorkspaceProfileError("upload_expired", "This upload grant expired. Keep the photo and start a new upload request.", 409);
      return result(upload, true, await this.mediaObjects.prepare(upload));
    }
    // Byte IO and decoding are outside retryable transaction callbacks.
    const originalBytes = await this.mediaObjects.read(upload);
    if (!/^[1-9][0-9]*$/u.test(originalBytes.generation) || !Buffer.isBuffer(originalBytes.bytes) ||
        originalBytes.bytes.length !== request.sourceByteLength ||
        createHash("sha256").update(originalBytes.bytes).digest("hex").toUpperCase() !== request.sourceSha256.toUpperCase()) throw invalidProductImage();
    const image = await normalizeStoreProductImage(originalBytes.bytes);
    if (image.source.mimeType !== request.sourceMimeType) throw invalidProductImage();
    const derivative = await this.mediaObjects.save(upload, originalBytes.generation, image);
    const assetId = cataloguePayloadHash({uploadId, generation: originalBytes.generation, sha256: image.file.sha256});
    if (derivative.assetId !== assetId || !/^[1-9][0-9]*$/u.test(derivative.generation)) throw mediaUnavailable();
    const completed = await this.firestore.runTransaction(async transaction => {
      await this.productSubmissionOwner(transaction, request.storeId, owner);
      const [doc, sourceDoc, historicalDoc] = await transaction.getAll(ref, head, immutableSource);
      const record = doc?.exists ? checkedMediaUpload(doc.data(), this.now().toISOString()) : undefined;
      if (!record || record.fingerprint !== fingerprint) throw new WorkspaceProfileError("conflict", "Recover the original image request.", 409);
      if (!matchesSource(historicalDoc?.exists ? checkedProductSubmission(historicalDoc.data(), this.realm, request.storeId, request.skuId) : undefined)) {
        throw new WorkspaceProfileError("stale_snapshot", "The original saved image source cannot be verified.", 409);
      }
      const current = matchesSource(sourceDoc?.exists ? checkedProductSubmission(sourceDoc.data(), this.realm, request.storeId, request.skuId) : undefined);
      // Concurrent confirms must agree with the same immutable source generation and output.
      if (record.processed) {
        if (record.processed.assetId !== assetId || record.processed.originalGeneration !== originalBytes.generation ||
            record.processed.derivativeGeneration !== derivative.generation) throw invalidProductImage();
        return {record, current};
      }
      // Preserve the historical result even after a source edit; never write it into the newer submission/head.
      record.processed = {assetId, originalGeneration: originalBytes.generation, derivativeGeneration: derivative.generation,
        processedAt: this.now().toISOString(), source: image.source, file: image.file, meetsPublicSourceFloor: image.meetsPublicSourceFloor};
      transaction.set(ref, checkedMediaUpload(record, this.now().toISOString()));
      return {record, current};
    });
    return result(completed.record, completed.current);
  }

  /** Internal only: resolves private authority inside the committing transaction.
   * No HTTP operation, automatic grants, approval shortcut or runtime seeds.
   */
  async produceCatalogue(operatorUserId: string, identity: CatalogueIdentity,
    input: Readonly<Record<string, unknown>>): Promise<CatalogueAggregate> {
    return this.produceCatalogueCommand(operatorUserId, identity, input);
  }
  /** Internal proposal bridge. No HTTP review operation or automatic publication. */
  async proposeSubmittedCatalogue(operatorUserId: string, identity: CatalogueIdentity,
    source: CatalogueSubmissionReference, input: Readonly<Record<string, unknown>>): Promise<CatalogueAggregate> {
    return this.produceCatalogueCommand(operatorUserId, identity, input, source);
  }
  private async produceCatalogueCommand(operatorUserId: string, identity: CatalogueIdentity,
    input: Readonly<Record<string, unknown>>, source?: CatalogueSubmissionReference): Promise<CatalogueAggregate> {
    const operator = id(operatorUserId), catalogueId = id(identity.catalogueId);
    const original = structuredClone(input), pinned = source === undefined ? undefined : submissionReference(source);
    if (pinned && pinned.realm !== this.realm) invalid("Submission realm changed.");
    const resolvedIdentity = {catalogueId, tenantId: id(identity.tenantId)}, observedAt = this.now().toISOString();
    const commandId = id(original.commandId);
    const root = this.firestore.collection("workspaceCatalogues").doc(this.realm);
    const aggregateRef = root.collection("canonicalCatalogues").doc(catalogueId);
    const receiptRef = aggregateRef.collection("producerReceipts")
      .doc(cataloguePayloadHash([operator, commandId]));
    const authorityRef = root.collection("producerAuthorities").doc(operator);
    return this.firestore.runTransaction(async transaction => {
      const [authorityDoc, aggregateDoc, receiptDoc] = await transaction.getAll(authorityRef, aggregateRef, receiptRef);
      let normalized: Record<string, unknown>;
      if (pinned) {
        const saved = await transaction.get(this.productSubmissionHead(pinned.storeId, pinned.skuId)
          .collection("revisions").doc(String(pinned.revision)));
        if (!saved.exists) throw new WorkspaceProfileError("not_found", "Saved product submission is not available.", 404);
        const record = checkedProductSubmission(saved.data(), this.realm, pinned.storeId, pinned.skuId);
        if (record.revision !== pinned.revision || record.fingerprint !== pinned.fingerprint) {
          throw new WorkspaceProfileError("conflict", "Saved product source changed.", 409);
        }
        if (record.submittedBy !== operator) throw new WorkspaceProfileError("forbidden", "Use the original Store owner submission.", 403);
        normalized = submittedCatalogueInput(record, original);
        const aggregate = aggregateDoc?.data() as CatalogueAggregate | undefined;
        if (!receiptDoc?.exists && normalized.type === "propose_pack" && (!aggregate || !reviewedCanonicalProduct(aggregate, String(normalized.productId),
          cataloguePayloadHash({...record.product.content, media: []})))) {
          invalid("Pack proposal requires this exact reviewed product content.");
        }
      } else normalized = productionInput(original);
      const command: CatalogueProduction = {operatorUserId: operator, identity: resolvedIdentity,
        input: normalized, observedAt, ...(pinned ? {submission: pinned} : {})};
      const authority = authorityDoc?.data() as CatalogueProducerAuthority | undefined;
      let participant: SupplyParticipantWorkspace | undefined, profile: WorkspaceProfileRecord | undefined;
      if (["propose_product", "propose_product_revision", "propose_pack", "create_offer"].includes(String(normalized.type)) &&
          authority?.actor?.workspaceId) {
        const workspaceId = id(authority.actor.workspaceId);
        const [participantDoc, stores] = await Promise.all([
          transaction.get(root.collection("participants").doc(workspaceId)),
          transaction.get(this.firestore.collection("workspaceProfiles").where("workspaceId", "==", workspaceId).limit(2)),
        ]);
        participant = participantDoc.data() as SupplyParticipantWorkspace | undefined;
        if (stores.docs.length === 1 && stores.docs[0]!.get("caseId") === stores.docs[0]!.id) {
          profile = stores.docs[0]!.data() as WorkspaceProfileRecord;
        }
      }
      const result = planCatalogueProduction(command, authority,
        aggregateDoc?.data() as CatalogueAggregate | undefined, participant, profile,
        receiptDoc?.data() as CatalogueProductionReceipt | undefined, this.now().toISOString());
      if (!result.replayed) {
        transaction.set(aggregateRef, result.aggregate);
        transaction.create(aggregateRef.collection("revisions").doc(String(result.aggregate.version)), result.aggregate);
        transaction.create(receiptRef, {fingerprint: result.fingerprint, result: result.aggregate,
          ...(pinned ? {submission: pinned} : {})});
      }
      return result.aggregate;
    });
  }

  private root(storeId: string) {
    return this.firestore.collection("workspaceCatalogues").doc(this.realm)
      .collection("stores").doc(id(storeId));
  }
  private productSubmissionHead(storeId: string, skuId: string) {
    return this.root(storeId).collection("productSubmissions").doc(id(skuId));
  }
  private checkedProductCommand(original: StoreProductSubmissionCommand): StoreProductSubmissionCommand {
    const command = storeProductSubmission(original.ownerUserId, original.realm, {storeId: original.storeId,
      expectedRevision: original.expectedRevision, idempotencyKey: original.idempotencyKey, product: original.product}, original.submittedAt);
    if (command.realm !== this.realm || command.fingerprint !== original.fingerprint) invalid();
    return command;
  }
  private async productSubmissionOwner(transaction: Transaction, storeId: string, owner: string): Promise<WorkspaceProfileRecord> {
    const profiles = await transaction.get(this.firestore.collection("workspaceProfiles").where("workspaceId", "==", storeId).limit(2));
    const profile = profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get("caseId")
      ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined;
    return requireStore(profile, storeId, owner);
  }
  async submitProduct(original: StoreProductSubmissionCommand): Promise<StoreProductSubmissionRecord> {
    const command = this.checkedProductCommand(original), head = this.productSubmissionHead(command.storeId, command.product.skuId);
    const receiptRef = head.collection("receipts").doc(cataloguePayloadHash([command.ownerUserId, command.idempotencyKey]));
    return this.firestore.runTransaction(async transaction => {
      const profile = await this.productSubmissionOwner(transaction, command.storeId, command.ownerUserId);
      const [current, receipt] = await transaction.getAll(head, receiptRef);
      const result = planStoreProductSubmission(command, profile,
        current?.exists ? current.data() as StoreProductSubmissionRecord : undefined,
        receipt?.exists ? receipt.data() as StoreProductSubmissionReceipt : undefined);
      if (!receipt?.exists) {
        transaction.set(head, result);
        transaction.create(head.collection("revisions").doc(String(result.revision)), result);
        transaction.create(receiptRef, {fingerprint: command.fingerprint, record: result});
      }
      return result;
    });
  }
  async reconcileProduct(original: StoreProductSubmissionCommand): Promise<StoreProductSubmissionRecord | undefined> {
    const command = this.checkedProductCommand(original), head = this.productSubmissionHead(command.storeId, command.product.skuId);
    const receiptRef = head.collection("receipts").doc(cataloguePayloadHash([command.ownerUserId, command.idempotencyKey]));
    return this.firestore.runTransaction(async transaction => {
      const profile = await this.productSubmissionOwner(transaction, command.storeId, command.ownerUserId);
      const receipt = await transaction.get(receiptRef);
      return receipt.exists ? planStoreProductSubmission(command, profile, undefined, receipt.data() as StoreProductSubmissionReceipt) : undefined;
    });
  }
  async readProductSubmission(storeId: string, skuId: string, ownerUserId: string): Promise<StoreProductSubmissionRecord | undefined> {
    storeId = id(storeId); skuId = id(skuId); ownerUserId = id(ownerUserId);
    const head = this.productSubmissionHead(storeId, skuId);
    return this.firestore.runTransaction(async transaction => {
      await this.productSubmissionOwner(transaction, storeId, ownerUserId);
      const doc = await transaction.get(head);
      return doc.exists ? checkedProductSubmission(doc.data(), this.realm, storeId, skuId) : undefined;
    });
  }
  /** Trusted resolution only; creates a PRIVATE candidate, never a Store mirror. */
  async resolveProductReview(operatorUserId: string, identity: CatalogueIdentity,
    raw: Readonly<Record<string, unknown>>): Promise<StoreReviewedProductCandidate> {
    const body = structuredClone(raw);
    exact(body, ["source", "expectedReviewRevision", "idempotencyKey", "canonicalProductId", "verifiedPackId", "offers"]);
    const source = submissionReference(body.source), operator = id(operatorUserId), key = id(body.idempotencyKey);
    if (source.realm !== this.realm) invalid();
    const expectedRevision = integer(body.expectedReviewRevision, 0, 999999999);
    identity = {catalogueId: id(identity.catalogueId), tenantId: id(identity.tenantId)};
    const fingerprint = cataloguePayloadHash({operator, identity, body});
    const root = this.root(source.storeId), catalogueRoot = this.firestore.collection("workspaceCatalogues").doc(this.realm);
    const head = root.collection("productReviews").doc(source.skuId);
    const receipt = head.collection("receipts").doc(cataloguePayloadHash([operator, key]));
    return this.firestore.runTransaction(async transaction => {
      const [authority, catalogueDoc, profiles, currentReview, receiptDoc, submissionDoc, currentSubmission, currentSku, participant] = await Promise.all([
        transaction.get(catalogueRoot.collection("producerAuthorities").doc(operator)),
        transaction.get(catalogueRoot.collection("canonicalCatalogues").doc(identity.catalogueId)),
        transaction.get(this.firestore.collection("workspaceProfiles").where("workspaceId", "==", source.storeId).limit(2)),
        transaction.get(head), transaction.get(receipt),
        transaction.get(this.productSubmissionHead(source.storeId, source.skuId).collection("revisions").doc(String(source.revision))),
        transaction.get(this.productSubmissionHead(source.storeId, source.skuId)),
        transaction.get(root.collection("skus").doc(source.skuId)),
        transaction.get(catalogueRoot.collection("participants").doc(source.storeId))]);
      const at = this.now().toISOString(), actor = producerActor(operator, identity, at, authority.data() as CatalogueProducerAuthority | undefined);
      if (!actor.scopes.includes("supply.catalogue.review")) throw new WorkspaceProfileError("forbidden", "Product review authority is required.", 403);
      const profile = requireStore(profiles.size === 1 && profiles.docs[0]!.get("caseId") === profiles.docs[0]!.id
        ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined, source.storeId);
      if (receiptDoc.exists) {
        const saved = exact(receiptDoc.data(), ["fingerprint", "record"]), candidate = checkedReviewedCandidate(saved.record);
        if (saved.fingerprint !== fingerprint || cataloguePayloadHash(candidate.source) !== cataloguePayloadHash(source) ||
            cataloguePayloadHash(candidate.identity) !== cataloguePayloadHash(identity) || candidate.reviewedBy !== operator) {
          throw new WorkspaceProfileError("conflict", "Product review request changed. Recover its original result.", 409);
        }
        return candidate;
      }
      if ((currentReview.exists ? checkedReviewedCandidate(currentReview.data()).revision : 0) !== expectedRevision) {
        throw new WorkspaceProfileError("revision_conflict", "Product review changed. Refresh its original source.", 409);
      }
      if (!submissionDoc.exists || !currentSubmission.exists) invalid("Saved product source is unavailable.");
      const submission = checkedProductSubmission(submissionDoc.data(), this.realm, source.storeId, source.skuId);
      const latest = checkedProductSubmission(currentSubmission.data(), this.realm, source.storeId, source.skuId);
      if (submission.fingerprint !== source.fingerprint || submission.revision !== source.revision ||
          latest.fingerprint !== source.fingerprint || latest.revision !== source.revision) {
        throw new WorkspaceProfileError("conflict", "Saved product source changed before review resolution.", 409);
      }
      requireStore(profile, source.storeId, submission.submittedBy);
      if (operator === submission.submittedBy) throw new WorkspaceProfileError("forbidden", "Independent product review is required.", 403);
      const ownerAuthority = await transaction.get(catalogueRoot.collection("producerAuthorities").doc(submission.submittedBy));
      const sku = candidateSku(submission, id(body.canonicalProductId), id(body.verifiedPackId), body.offers);
      const catalogue = catalogueDoc.data() as CatalogueAggregate | undefined;
      if (!catalogue) invalid("Reviewed catalogue is unavailable.");
      const terms = sku.channels.map(channel => {
        const offer = catalogue.offers.find(o => o.offerId === channel.offerId), term = offer && referencedOfferTermAt(offer, at);
        if (!term) invalid("Reviewed selling terms are unavailable.");
        return {kind: channel.kind, offerId: channel.offerId, ...term};
      });
      const candidateData = {schemaVersion: 1 as const, realm: this.realm, storeId: source.storeId, skuId: source.skuId,
        revision: expectedRevision + 1, source, identity, sku, expectedMirrorRevision: currentSku.exists ? normalizeRecord(currentSku.data(), source.storeId).revision : 0,
        reviewedBy: operator, reviewedAt: at, expiresAt: terms.map(t => t.expiresAt).sort()[0]!, terms};
      const candidate = checkedReviewedCandidate({...candidateData, fingerprint: cataloguePayloadHash(candidateData)});
      validateReviewedCandidate(candidate, submission, profile, catalogue, ownerAuthority.data() as CatalogueProducerAuthority | undefined,
        participant.data() as SupplyParticipantWorkspace | undefined, currentSku.exists ? normalizeRecord(currentSku.data(), source.storeId) : undefined, at);
      transaction.set(head, candidate);
      transaction.create(head.collection("revisions").doc(String(candidate.revision)), candidate);
      transaction.create(receipt, {fingerprint, record: candidate});
      return candidate;
    });
  }
  async readReviewedProductSubmission(storeId: string, skuId: string, ownerUserId: string,
    identity: CatalogueIdentity): Promise<StoreProductReviewReadback> {
    storeId = id(storeId); skuId = id(skuId); ownerUserId = id(ownerUserId);
    identity = {catalogueId: id(identity.catalogueId), tenantId: id(identity.tenantId)};
    const root = this.root(storeId), catalogueRoot = this.firestore.collection("workspaceCatalogues").doc(this.realm);
    return this.firestore.runTransaction(async transaction => {
      const profile = await this.productSubmissionOwner(transaction, storeId, ownerUserId);
      const [source, resolved, current, catalogue, authority, participant] = await transaction.getAll(
        this.productSubmissionHead(storeId, skuId), root.collection("productReviews").doc(skuId), root.collection("skus").doc(skuId),
        catalogueRoot.collection("canonicalCatalogues").doc(identity.catalogueId),
        catalogueRoot.collection("producerAuthorities").doc(ownerUserId), catalogueRoot.collection("participants").doc(storeId));
      const record = source?.exists ? checkedProductSubmission(source.data(), this.realm, storeId, skuId) : null;
      const result = (state: StoreProductReviewReadback["review"]["state"], candidate: StoreReviewedProductCandidate | null = null): StoreProductReviewReadback =>
        ({record, review: {version: 1, state, candidate}});
      if (!record) return result("pending");
      if (record.product.mediaIntent.pendingUpload || record.product.mediaIntent.publishedReferences.length !== 0) return result("awaiting_media");
      if (!resolved?.exists) return result("pending");
      const candidate = checkedReviewedCandidate(resolved.data());
      if (candidate.storeId !== storeId || candidate.skuId !== skuId || candidate.realm !== this.realm ||
          cataloguePayloadHash(candidate.identity) !== cataloguePayloadHash(identity)) invalid("Product review scope changed.");
      if (candidate.source.fingerprint !== record.fingerprint || candidate.source.revision !== record.revision) return result("outdated");
      const mirror = current?.exists ? normalizeRecord(current.data(), storeId) : undefined;
      if (mirror && mirror.revision === candidate.expectedMirrorRevision + 1) {
        const {schemaVersion: _v, storeId: _s, revision: _r, observedAt: _a, ...input} = mirror;
        if (cataloguePayloadHash(input) === cataloguePayloadHash(candidate.sku)) return result("bound", candidate);
      }
      if ((mirror?.revision ?? 0) !== candidate.expectedMirrorRevision) return result("outdated");
      try {
        validateReviewedCandidate(candidate, record, profile, catalogue?.data() as CatalogueAggregate | undefined,
          authority?.data() as CatalogueProducerAuthority | undefined, participant?.data() as SupplyParticipantWorkspace | undefined,
          mirror, this.now().toISOString());
        return result("ready", candidate);
      } catch (error) {
        if (error instanceof WorkspaceProfileError) return result("unavailable");
        throw error;
      }
    });
  }
  async submitVariantFamily(original: StoreVariantFamilySubmission): Promise<StoreVariantFamilyCandidate> {
    const command = structuredClone(original);
    if (command.realm !== this.realm) invalid();
    command.family = normalizeStoreVariantFamily(command.family);
    const root = this.root(command.storeId), head = root.collection("variantFamilies").doc(command.family.familyId);
    const receipt = head.collection("receipts").doc(cataloguePayloadHash([command.ownerUserId, command.idempotencyKey]));
    return this.firestore.runTransaction(async transaction => {
      const [profiles, current, saved] = await Promise.all([
        transaction.get(this.firestore.collection("workspaceProfiles").where("workspaceId", "==", command.storeId).limit(2)),
        transaction.get(head), transaction.get(receipt)]);
      const profile = profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get("caseId")
        ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined;
      // Historical replay requires current owner access, not current member content.
      const records = saved.exists ? [] : await transaction.getAll(...command.family.members.map(member => root.collection("skus").doc(member.skuId)));
      const record = planStoreVariantFamilySubmission(command, profile,
        records.filter(doc => doc.exists).map(doc => {
          const row = normalizeRecord(doc.data(), command.storeId);
          if (row.skuId !== doc.id) invalid();
          return row;
        }), current.exists ? current.data() as StoreVariantFamilyCandidate : undefined,
        saved.exists ? saved.data() as StoreVariantFamilyReceipt : undefined);
      if (!saved.exists) {
        transaction.set(head, record);
        transaction.create(head.collection("revisions").doc(String(record.revision)), record);
        transaction.create(receipt, {fingerprint: command.fingerprint, record});
      }
      return record;
    });
  }
  async reconcileVariantFamily(original: StoreVariantFamilySubmission): Promise<StoreVariantFamilyCandidate | undefined> {
    const command = structuredClone(original);
    if (command.realm !== this.realm) invalid();
    command.family = normalizeStoreVariantFamily(command.family);
    const receipt = this.root(command.storeId).collection("variantFamilies").doc(command.family.familyId)
      .collection("receipts").doc(cataloguePayloadHash([command.ownerUserId, command.idempotencyKey]));
    return this.firestore.runTransaction(async transaction => {
      const [profiles, saved] = await Promise.all([
        transaction.get(this.firestore.collection("workspaceProfiles").where("workspaceId", "==", command.storeId).limit(2)),
        transaction.get(receipt)]);
      const profile = requireStore(profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get("caseId")
        ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined, command.storeId, command.ownerUserId);
      return saved.exists ? planStoreVariantFamilySubmission(command, profile, [], undefined,
        saved.data() as StoreVariantFamilyReceipt) : undefined;
    });
  }
  async readVariantFamily(storeId: string, familyId: string, ownerUserId: string): Promise<{
    candidate: StoreVariantFamilyCandidate | null; review: StoreVariantFamilyReview | null}> {
    storeId = id(storeId); familyId = id(familyId); ownerUserId = id(ownerUserId);
    return this.firestore.runTransaction(async transaction => {
      const [profiles, candidate, review] = await Promise.all([
        transaction.get(this.firestore.collection("workspaceProfiles").where("workspaceId", "==", storeId).limit(2)),
        transaction.get(this.root(storeId).collection("variantFamilies").doc(familyId)),
        transaction.get(this.root(storeId).collection("variantFamilyReviews").doc(familyId))]);
      requireStore(profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get("caseId")
        ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined, storeId, ownerUserId);
      const pending = candidate.exists ? checkedFamilyCandidate(candidate.data() as StoreVariantFamilyCandidate) : null;
      const reviewed = review.exists ? checkedFamilyReview(review.data()) : null;
      for (const row of [pending, reviewed?.candidate]) {
        if (row && (row.realm !== this.realm || row.storeId !== storeId || row.family.familyId !== familyId)) invalid();
      }
      return {candidate: pending, review: reviewed};
    });
  }
  /** Trusted internal entry only. Never dispatched from the owner HTTP API. */
  async reviewVariantFamily(operatorUserId: string, identity: CatalogueIdentity, storeId: string,
    familyId: string, raw: Readonly<Record<string, unknown>>): Promise<StoreVariantFamilyReview> {
    const operator = id(operatorUserId), store = id(storeId), family = id(familyId);
    identity = {catalogueId: id(identity.catalogueId), tenantId: id(identity.tenantId)};
    const body = structuredClone(raw), key = id(body.idempotencyKey);
    const root = this.root(store), catalogueRoot = this.firestore.collection("workspaceCatalogues").doc(this.realm);
    const reviewHead = root.collection("variantFamilyReviews").doc(family);
    const receipt = reviewHead.collection("receipts").doc(cataloguePayloadHash([operator, key]));
    const fingerprint = cataloguePayloadHash({operator, identity, store, family, body});
    return this.firestore.runTransaction(async transaction => {
      const [profiles, authorityDoc, candidateDoc, catalogueDoc, reviewDoc, receiptDoc, familyDocs, publicationDoc] = await Promise.all([
        transaction.get(this.firestore.collection("workspaceProfiles").where("workspaceId", "==", store).limit(2)),
        transaction.get(catalogueRoot.collection("producerAuthorities").doc(operator)),
        transaction.get(root.collection("variantFamilies").doc(family)),
        transaction.get(catalogueRoot.collection("canonicalCatalogues").doc(identity.catalogueId)),
        transaction.get(reviewHead), transaction.get(receipt),
        transaction.get(root.collection("variantFamilyReviews").limit(201)),
        transaction.get(root.collection("variantPublication").doc("current"))]);
      requireStore(profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get("caseId")
        ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined, store);
      const authority = authorityDoc.data() as CatalogueProducerAuthority | undefined;
      const at = this.now().toISOString(), actor = producerActor(operator, identity, at, authority);
      if (!actor.scopes.includes("supply.catalogue.review")) throw new WorkspaceProfileError("forbidden", "Catalogue review is required.", 403);
      if (receiptDoc.exists) {
        const saved = exact(receiptDoc.data(), ["fingerprint", "record"]), result = checkedFamilyReview(saved.record);
        if (saved.fingerprint !== fingerprint || result.reviewerUserId !== operator ||
            result.catalogueId !== identity.catalogueId || result.tenantId !== identity.tenantId ||
            result.candidate.realm !== this.realm || result.candidate.storeId !== store || result.candidate.family.familyId !== family) {
          throw new WorkspaceProfileError("conflict", "Review request changed. Use its original result.", 409);
        }
        return result;
      }
      if (!candidateDoc.exists || familyDocs.size > 200) invalid("Family review source is incomplete.");
      const candidate = checkedFamilyCandidate(candidateDoc.data() as StoreVariantFamilyCandidate);
      if (candidate.realm !== this.realm || candidate.storeId !== store || candidate.family.familyId !== family) invalid();
      const skuDocs = await transaction.getAll(...candidate.family.members.map(member => root.collection("skus").doc(member.skuId)));
      const records = skuDocs.filter(doc => doc.exists).map(doc => {
        const row = normalizeRecord(doc.data(), store); if (row.skuId !== doc.id) invalid(); return row;
      });
      const result = planStoreVariantFamilyReview(operator, identity, body, authority, candidate, records,
        catalogueDoc.data() as CatalogueAggregate | undefined, at, reviewDoc.exists ? checkedFamilyReview(reviewDoc.data()) : undefined);
      if (result.decision === "verify") for (const doc of familyDocs.docs) {
        const other = checkedFamilyReview(doc.data());
        if (other.candidate.storeId !== store || other.candidate.realm !== this.realm || other.candidate.family.familyId !== doc.id) invalid();
        if (doc.id !== family && other.decision === "verify" &&
            other.candidate.family.members.some(m => candidate.family.members.some(v => v.skuId === m.skuId))) {
          throw new WorkspaceProfileError("conflict", "A SKU already belongs to another reviewed family.", 409);
        }
      }
      transaction.set(reviewHead, result);
      transaction.create(reviewHead.collection("revisions").doc(String(result.revision)), result);
      transaction.create(receipt, {fingerprint, record: result});
      const publicationRevision = publicationDoc.exists ? integer(publicationDoc.get("revision"), 1, 999999999) : 1;
      transaction.set(root.collection("variantPublication").doc("current"), {schemaVersion: 1,
        realm: this.realm, storeId: store, revision: publicationRevision + 1});
      return result;
    });
  }
  private listingRoot() {
    return this.firestore.collection("workspaceCatalogues").doc(this.realm).collection("publicListingBindings");
  }
  async publicDiscoveryBindings(): Promise<PublicCatalogueListingBinding[]> {
    const snapshot = await this.listingRoot().orderBy(FieldPath.documentId()).limit(501).get();
    if (snapshot.size > 500) throw new WorkspaceProfileError("unavailable", "Public catalogue capacity requires a larger discovery source.", 503);
    return snapshot.docs.map(doc => {
      const binding = discoveryBinding(doc.data(), this.realm);
      if (binding.listingId !== doc.id) invalid("Listing directory identity changed.");
      return binding;
    });
  }
  private detailsHead(storeId: string) { return this.root(storeId).collection("publicDetails").doc("current"); }
  async readStorePublicDetails(storeId: string, ownerUserId?: string): Promise<StorePublicDetailsRecord | undefined> {
    storeId = id(storeId);
    return this.firestore.runTransaction(async transaction => {
      const profiles = await transaction.get(this.firestore.collection("workspaceProfiles").where("workspaceId", "==", storeId).limit(2));
      if (profiles.size !== 1 || profiles.docs[0]!.id !== profiles.docs[0]!.get("caseId")) requireStore(undefined, storeId, ownerUserId);
      const profile = requireStore(profiles.docs[0]!.data() as WorkspaceProfileRecord, storeId, ownerUserId);
      if (ownerUserId === undefined && !profile.shopEnabled) throw new WorkspaceProfileError("not_found", "Store is unavailable.", 404);
      const head = await transaction.get(this.detailsHead(storeId));
      return head.exists ? publicDetailsRecord(head.data(), this.realm, storeId) : undefined;
    });
  }
  async saveStorePublicDetails(original: StorePublicDetailsCommand): Promise<StorePublicDetailsRecord> {
    const command = structuredClone(original), head = this.detailsHead(command.storeId);
    if (command.realm !== this.realm) invalid();
    const receipt = head.collection("receipts").doc(cataloguePayloadHash([command.ownerUserId, command.idempotencyKey]));
    return this.firestore.runTransaction(async transaction => {
      const [profiles, current, saved] = await Promise.all([
        transaction.get(this.firestore.collection("workspaceProfiles").where("workspaceId", "==", command.storeId).limit(2)),
        transaction.get(head), transaction.get(receipt)]);
      const profile = profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get("caseId")
        ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined;
      const record = planStorePublicDetailsSave(command, profile,
        current.exists ? current.data() as StorePublicDetailsRecord : undefined,
        saved.exists ? saved.data() as StorePublicDetailsReceipt : undefined);
      if (!saved.exists) {
        transaction.set(head, record);
        transaction.create(head.collection("revisions").doc(String(record.revision)), record);
        transaction.create(receipt, {fingerprint: command.fingerprint, record});
      }
      return record;
    });
  }
  async reconcileStorePublicDetails(original: StorePublicDetailsCommand): Promise<StorePublicDetailsRecord | undefined> {
    const command = structuredClone(original);
    if (command.realm !== this.realm) invalid();
    const receipt = this.detailsHead(command.storeId).collection("receipts").doc(cataloguePayloadHash([command.ownerUserId, command.idempotencyKey]));
    return this.firestore.runTransaction(async transaction => {
      const [profiles, saved] = await Promise.all([
        transaction.get(this.firestore.collection("workspaceProfiles").where("workspaceId", "==", command.storeId).limit(2)),
        transaction.get(receipt)]);
      requireStore(profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get("caseId")
        ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined, command.storeId, command.ownerUserId);
      return saved.exists ? originalPublicDetails(command, saved.data() as StorePublicDetailsReceipt) : undefined;
    });
  }
  async store(storeId: string): Promise<WorkspaceProfileRecord | undefined> {
    const result = await this.firestore.collection("workspaceProfiles")
      .where("workspaceId", "==", id(storeId)).limit(2).get();
    if (result.docs.length !== 1) return undefined;
    const doc = result.docs[0]!;
    const profile = doc.data() as WorkspaceProfileRecord;
    // A duplicate/changed internal identity never silently selects another Store.
    return profile.caseId === doc.id ? profile : undefined;
  }
  async bindReviewed(command: CatalogueSave, identity: CatalogueIdentity): Promise<StoreSkuRecord> {
    return this.save(command, identity);
  }
  async readSaveReceipt(command: CatalogueSave): Promise<StoreSkuRecord | undefined> {
    command = structuredClone(command);
    const root = this.root(command.profile.workspaceId!);
    const receiptRef = root.collection("receipts").doc(cataloguePayloadHash([
      command.ownerUserId, command.input.skuId, command.idempotencyKey]));
    const profileRef = this.firestore.collection("workspaceProfiles").doc(command.profile.caseId);
    return this.firestore.runTransaction(async transaction => {
      const [profile, receipt] = await transaction.getAll(profileRef, receiptRef);
      const fresh = requireStore(profile?.data() as WorkspaceProfileRecord | undefined,
        command.profile.workspaceId!, command.ownerUserId);
      if (!receipt?.exists) return undefined;
      return planCatalogueSave({...command, profile: fresh}, undefined, receipt.data() as CatalogueSaveReceipt);
    });
  }
  async save(command: CatalogueSave, reviewedIdentity?: CatalogueIdentity): Promise<StoreSkuRecord> {
    // Freeze original intent before computing paths or yielding to a transaction.
    command = structuredClone(command);
    reviewedIdentity = reviewedIdentity && structuredClone(reviewedIdentity);
    if (command.reviewCandidate && !reviewedIdentity) invalid("Reviewed candidate identity is required.");
    const root = this.root(command.profile.workspaceId!);
    const head = root.collection("skus").doc(command.input.skuId);
    const receiptRef = root.collection("receipts").doc(cataloguePayloadHash([
      command.ownerUserId, command.input.skuId, command.idempotencyKey]));
    const profileRef = this.firestore.collection("workspaceProfiles").doc(command.profile.caseId);
    return this.firestore.runTransaction(async transaction => {
      const [profile, current, receipt] = await transaction.getAll(profileRef, head, receiptRef);
      const fresh = requireStore(profile?.data() as WorkspaceProfileRecord | undefined,
        command.profile.workspaceId!, command.ownerUserId);
      const prior = current?.exists ? current.data() as StoreSkuRecord : undefined;
      const original = receipt?.exists ? receipt.data() as CatalogueSaveReceipt : undefined;
      let result: StoreSkuRecord;
      if (reviewedIdentity) {
        const source = this.firestore.collection("workspaceCatalogues").doc(this.realm);
        const [catalogue, authority, participant] = await transaction.getAll(
          source.collection("canonicalCatalogues").doc(id(reviewedIdentity.catalogueId)),
          source.collection("producerAuthorities").doc(id(command.ownerUserId)),
          source.collection("participants").doc(id(fresh.workspaceId)));
        if (command.reviewCandidate && !original) {
          const reference = reviewedCandidateReference(command.reviewCandidate), reviewHead = root.collection("productReviews").doc(command.input.skuId);
          const [candidateDoc, latestReview, submission] = await transaction.getAll(
            reviewHead.collection("revisions").doc(String(reference.revision)), reviewHead,
            this.productSubmissionHead(fresh.workspaceId!, command.input.skuId));
          if (!candidateDoc?.exists || !latestReview?.exists || !submission?.exists) invalid("Reviewed product candidate is unavailable.");
          const candidate = checkedReviewedCandidate(candidateDoc.data()), latest = checkedReviewedCandidate(latestReview.data());
          if (candidate.fingerprint !== reference.fingerprint || candidate.revision !== reference.revision || latest.fingerprint !== candidate.fingerprint ||
              cataloguePayloadHash(candidate.identity) !== cataloguePayloadHash(reviewedIdentity) ||
              cataloguePayloadHash(candidate.sku) !== cataloguePayloadHash(command.input) ||
              candidate.expectedMirrorRevision !== command.expectedRevision) invalid("Reviewed product candidate changed.");
          validateReviewedCandidate(candidate, checkedProductSubmission(submission.data(), this.realm, fresh.workspaceId!, command.input.skuId),
            fresh, catalogue?.data() as CatalogueAggregate | undefined, authority?.data() as CatalogueProducerAuthority | undefined,
            participant?.data() as SupplyParticipantWorkspace | undefined, prior, this.now().toISOString());
        }
        result = planReviewedCatalogueSave({...command, profile: fresh}, reviewedIdentity,
          catalogue?.data() as CatalogueAggregate | undefined,
          authority?.data() as CatalogueProducerAuthority | undefined,
          participant?.data() as SupplyParticipantWorkspace | undefined, prior, original, this.now().toISOString());
      } else {
        result = planCatalogueSave({...command, profile: fresh}, prior, original);
      }
      if (!receipt?.exists) {
        const bindings = cataloguePublicListingBindings(this.realm, result);
        const refs = bindings.map(binding => this.listingRoot().doc(binding.listingId));
        const existing = await transaction.getAll(...refs);
        for (let i = 0; i < bindings.length; i++) {
          if (existing[i]!.exists) checkedListingBinding(existing[i]!.data(), bindings[i]!);
        }
        transaction.create(head.collection("revisions").doc(String(result.revision)), result);
        transaction.set(head, result);
        transaction.create(receiptRef, {fingerprint: command.fingerprint, record: result});
        for (let i = 0; i < bindings.length; i++) {
          if (!existing[i]!.exists) transaction.create(refs[i]!, bindings[i]!);
        }
      }
      return result;
    });
  }
  async page(profile: WorkspaceProfileRecord, owner: string | undefined,
    after: string | undefined, limit: number, skuId?: string): Promise<StoreSkuRecord[]> {
    return this.firestore.runTransaction(async transaction => {
      const doc = await transaction.get(this.firestore.collection("workspaceProfiles").doc(profile.caseId));
      const fresh = requireStore(doc.data() as WorkspaceProfileRecord | undefined, profile.workspaceId!, owner);
      if (owner === undefined && fresh.shopEnabled !== true) return [];
      let query = this.root(fresh.workspaceId!).collection("skus").orderBy(FieldPath.documentId()).limit(limit);
      if (after !== undefined) query = query.startAfter(id(after));
      if (skuId !== undefined) query = query.where(FieldPath.documentId(), "==", id(skuId));
      const snapshot = await transaction.get(query);
      return snapshot.docs.map(d => {
        const result = normalizeRecord(d.data(), fresh.workspaceId!);
        if (result.skuId !== d.id) invalid(); return result;
      });
    });
  }
  async catalogue(catalogueId: string): Promise<CatalogueAggregate | undefined> {
    const doc = await this.firestore.collection("workspaceCatalogues").doc(this.realm)
      .collection("canonicalCatalogues").doc(id(catalogueId)).get();
    // This adapter never invents/reviews a canonical catalogue or seeds offer terms.
    return doc.exists ? doc.data() as CatalogueAggregate : undefined;
  }
  async publicCatalogueSource(storeId: string, identity: CatalogueIdentity, includeFamilies = false): Promise<PublicCatalogueSource | undefined> {
    storeId = id(storeId);
    return this.firestore.runTransaction(async transaction => {
      const [profiles, catalogueDoc, skuDocs, policyDoc, detailsDoc] = await Promise.all([
        transaction.get(this.firestore.collection("workspaceProfiles").where("workspaceId", "==", storeId).limit(2)),
        transaction.get(this.firestore.collection("workspaceCatalogues").doc(this.realm).collection("canonicalCatalogues").doc(id(identity.catalogueId))),
        transaction.get(this.root(storeId).collection("skus").orderBy(FieldPath.documentId()).limit(501)),
        transaction.get(this.root(storeId).collection("supplierPolicies").doc("current")),
        transaction.get(this.detailsHead(storeId)),
      ]);
      if (profiles.size !== 1 || profiles.docs[0]!.id !== profiles.docs[0]!.get("caseId") ||
          skuDocs.size > 500 || !catalogueDoc.exists) return undefined;
      const profile = requireStore(profiles.docs[0]!.data() as WorkspaceProfileRecord, storeId);
      if (!profile.shopEnabled) return undefined;
      const catalogue = catalogueDoc.data() as CatalogueAggregate;
      if (catalogue.catalogueId !== identity.catalogueId || catalogue.tenantId !== identity.tenantId) return undefined;
      const records = skuDocs.docs.map(doc => {
        const row = normalizeRecord(doc.data(), storeId);
        if (row.skuId !== doc.id) invalid();
        return row;
      });
      const expected = records.flatMap(row => cataloguePublicListingBindings(this.realm, row));
      const docs = expected.length ? await transaction.getAll(...expected.map(row => this.listingRoot().doc(row.listingId))) : [];
      const bindings = docs.flatMap((doc, i) => doc.exists ? [checkedListingBinding(doc.data(), expected[i]!)] : []);
      let variantFamilies: PublicCatalogueSource["variantFamilies"];
      if (includeFamilies) {
        const [reviews, publication] = await Promise.all([
          transaction.get(this.root(storeId).collection("variantFamilyReviews").limit(201)),
          transaction.get(this.root(storeId).collection("variantPublication").doc("current"))]);
        if (reviews.size > 200 || reviews.size > 0 && !publication.exists) return undefined;
        if (publication.exists && (publication.get("schemaVersion") !== 1 || publication.get("realm") !== this.realm ||
            publication.get("storeId") !== storeId)) return undefined;
        variantFamilies = {revision: publication.exists ? integer(publication.get("revision"), 1, 1000000000) : 1,
          reviews: reviews.docs.map(doc => {
            const row = checkedFamilyReview(doc.data());
            if (row.candidate.family.familyId !== doc.id) invalid();
            return row;
          })};
      }
      return {profile, catalogue, records, bindings, policy: policyDoc.exists ? policyDoc.data()! : null,
        publicDetails: detailsDoc.exists ? detailsDoc.data()! : null, ...(variantFamilies ? {variantFamilies} : {})};
    });
  }
  async publicListingBindings(record: StoreSkuRecord): Promise<PublicCatalogueListingBinding[] | undefined> {
    record = structuredClone(record);
    const expected = cataloguePublicListingBindings(this.realm, record);
    return this.firestore.runTransaction(async transaction => {
      const profiles = await transaction.get(this.firestore.collection("workspaceProfiles")
        .where("workspaceId", "==", record.storeId).limit(2));
      if (profiles.size !== 1 || profiles.docs[0]!.id !== profiles.docs[0]!.get("caseId")) return undefined;
      const store = requireStore(profiles.docs[0]!.data() as WorkspaceProfileRecord, record.storeId);
      if (!store.shopEnabled) return undefined;
      const [head, ...bindings] = await transaction.getAll(this.root(record.storeId).collection("skus").doc(record.skuId),
        ...expected.map(binding => this.listingRoot().doc(binding.listingId)));
      if (!head?.exists) return undefined;
      const current = normalizeRecord(head.data(), record.storeId);
      if (!current.publicListing || cataloguePayloadHash(current) !== cataloguePayloadHash(record) ||
          bindings.some(binding => !binding.exists)) return undefined;
      return expected.map((binding, i) => checkedListingBinding(bindings[i]!.data(), binding));
    });
  }
  /** One final read transaction for the admitted page: earlier rows cannot be
   * withdrawn/rebound unnoticed while later per-SKU lookups are awaited. */
  async confirmPublicListingSnapshot(storeId: string, records: readonly StoreSkuRecord[],
    identity: CatalogueIdentity, catalogueFingerprint: string, detailsFingerprint?: string): Promise<WorkspaceProfileRecord | undefined> {
    storeId = id(storeId);
    const expected = records.map(record => normalizeRecord(structuredClone(record), storeId));
    const catalogueId = id(identity.catalogueId), tenantId = id(identity.tenantId);
    if (expected.length > 50 || new Set(expected.map(record => record.skuId)).size !== expected.length ||
        !/^[A-F0-9]{64}$/u.test(catalogueFingerprint) ||
        detailsFingerprint !== undefined && !/^[A-F0-9]{64}$/u.test(detailsFingerprint)) invalid();
    const bindings = expected.flatMap(record => cataloguePublicListingBindings(this.realm, record));
    return this.firestore.runTransaction(async transaction => {
      const profiles = await transaction.get(this.firestore.collection("workspaceProfiles")
        .where("workspaceId", "==", storeId).limit(2));
      if (profiles.size !== 1 || profiles.docs[0]!.id !== profiles.docs[0]!.get("caseId")) return undefined;
      const profile = requireStore(profiles.docs[0]!.data() as WorkspaceProfileRecord, storeId);
      if (!profile.shopEnabled) return undefined;
      const documents = await transaction.getAll(
        this.firestore.collection("workspaceCatalogues").doc(this.realm).collection("canonicalCatalogues").doc(catalogueId),
        ...expected.map(record => this.root(storeId).collection("skus").doc(record.skuId)),
        ...bindings.map(binding => this.listingRoot().doc(binding.listingId)),
        ...(detailsFingerprint === undefined ? [] : [this.detailsHead(storeId)]));
      const catalogue = documents[0]?.data() as CatalogueAggregate | undefined;
      if (!catalogue || catalogue.catalogueId !== catalogueId || catalogue.tenantId !== tenantId ||
          cataloguePayloadHash(catalogue) !== catalogueFingerprint) return undefined;
      for (let i = 0; i < expected.length; i++) {
        const current = documents[i + 1];
        if (!current?.exists || !expected[i]!.publicListing ||
            cataloguePayloadHash(normalizeRecord(current.data(), storeId)) !== cataloguePayloadHash(expected[i])) return undefined;
      }
      for (let i = 0; i < bindings.length; i++) {
        const doc = documents[1 + expected.length + i];
        if (!doc?.exists) return undefined;
        checkedListingBinding(doc.data(), bindings[i]!);
      }
      if (detailsFingerprint !== undefined) {
        const doc = documents[1 + expected.length + bindings.length];
        if (!doc || cataloguePayloadHash(doc.exists ? doc.data() : null) !== detailsFingerprint) return undefined;
      }
      return profile;
    });
  }
}

/** Canonical, cross-runtime digest of reviewed content/pack/term payloads. */
export function cataloguePayloadHash(value: unknown): string {
  function sorted(item: unknown): unknown {
    if (Array.isArray(item)) return item.map(sorted);
    if (item !== null && typeof item === "object") return Object.fromEntries(
      Object.keys(item).sort().map(k => [k, sorted((item as Record<string, unknown>)[k])]));
    return item;
  }
  return createHash("sha256").update(JSON.stringify(sorted(value))).digest("hex").toUpperCase();
}
