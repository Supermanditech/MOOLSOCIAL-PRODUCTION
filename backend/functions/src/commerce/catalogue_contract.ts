import { createHash } from "node:crypto";

import {
  isSupplyCapabilityActive,
  type SupplyActor,
  type SupplyParticipantWorkspace,
} from "./supply_participant_contract.js";

export const catalogueCodeTypes = [
  "gtin",
  "ean",
  "upc",
  "manufacturer",
  "internal",
] as const;

export type CatalogueCodeType = (typeof catalogueCodeTypes)[number];
export type CatalogueReviewState =
  | "pending_review"
  | "verified"
  | "rejected";
export type CatalogueBuyingContext = "consumer" | "wholesale";

export type CatalogueContractErrorCode =
  | "invalid_input"
  | "unauthorized"
  | "tenant_mismatch"
  | "workspace_mismatch"
  | "version_conflict"
  | "idempotency_conflict"
  | "not_found"
  | "invalid_transition"
  | "capability_inactive"
  | "duplicate_candidate"
  | "active_offer_conflict";

export class CatalogueContractError extends Error {
  constructor(
    readonly code: CatalogueContractErrorCode,
    message: string,
  ) {
    super(message);
    this.name = "CatalogueContractError";
  }
}

export interface CatalogueCodeReference {
  readonly type: CatalogueCodeType;
  readonly value: string;
}

export interface CanonicalProductRecord {
  readonly productId: string;
  readonly categoryId: string;
  readonly brandId: string;
  readonly contentSha256: string;
  readonly codes: readonly CatalogueCodeReference[];
  readonly state: CatalogueReviewState | "merged";
  readonly proposedByWorkspaceId: string;
  readonly proposedAt: string;
  readonly reviewedBy?: string;
  readonly reviewedAt?: string;
  readonly reasonCode?: string;
  readonly mergedIntoProductId?: string;
}

export interface VerifiedPackRecord {
  readonly packId: string;
  readonly productId: string;
  readonly descriptorSha256: string;
  readonly codes: readonly CatalogueCodeReference[];
  readonly state: CatalogueReviewState;
  readonly proposedByWorkspaceId: string;
  readonly proposedAt: string;
  readonly reviewedBy?: string;
  readonly reviewedAt?: string;
  readonly reasonCode?: string;
}

export interface OfferTermWindow {
  readonly termSnapshotId: string;
  readonly termSnapshotSha256: string;
  readonly effectiveFrom: string;
  readonly expiresAt: string;
}

export interface ParticipantOfferRecord {
  readonly offerId: string;
  readonly workspaceId: string;
  readonly packId: string;
  readonly buyingContext: CatalogueBuyingContext;
  readonly serviceAreaIds: readonly string[];
  readonly termWindows: readonly OfferTermWindow[];
  readonly status: "active";
  readonly createdAt: string;
}

export interface CatalogueDuplicateDispute {
  readonly disputeId: string;
  readonly leftProductId: string;
  readonly rightProductId: string;
  readonly state: "open" | "resolved";
  readonly openedAt: string;
  readonly openedBy: string;
  readonly openedReasonCode: string;
  readonly resolvedAt?: string;
  readonly resolvedBy?: string;
  readonly resolution?:
    | "keep_separate"
    | "merge_left_into_right"
    | "merge_right_into_left";
  readonly resolutionReasonCode?: string;
}

export type CatalogueAuditEventType =
  | "catalogue_created"
  | "product_proposed"
  | "product_verified"
  | "product_rejected"
  | "pack_proposed"
  | "pack_verified"
  | "pack_rejected"
  | "offer_created"
  | "duplicate_dispute_opened"
  | "duplicate_dispute_resolved"
  | "product_merged";

export interface CatalogueAuditEvent {
  readonly eventId: string;
  readonly eventType: CatalogueAuditEventType;
  readonly aggregateVersion: number;
  readonly commandId: string;
  readonly catalogueId: string;
  readonly tenantId: string;
  readonly actorId: string;
  readonly occurredAt: string;
  readonly entityType: "catalogue" | "product" | "pack" | "offer" | "dispute";
  readonly entityId: string;
  readonly hashReferences: readonly string[];
}

export interface CatalogueCommandReceipt {
  readonly commandId: string;
  readonly commandFingerprint: string;
  readonly aggregateVersion: number;
}

export interface CatalogueAggregate {
  readonly schemaVersion: 1;
  readonly catalogueId: string;
  readonly tenantId: string;
  readonly version: number;
  readonly products: readonly CanonicalProductRecord[];
  readonly packs: readonly VerifiedPackRecord[];
  readonly offers: readonly ParticipantOfferRecord[];
  readonly disputes: readonly CatalogueDuplicateDispute[];
  readonly commandReceipts: readonly CatalogueCommandReceipt[];
  readonly auditEvents: readonly CatalogueAuditEvent[];
}

export interface CreateCatalogueCommand {
  readonly commandId: string;
  readonly catalogueId: string;
  readonly tenantId: string;
  readonly occurredAt: string;
  readonly actor: SupplyActor;
}

interface CatalogueCommandBase {
  readonly commandId: string;
  readonly catalogueId: string;
  readonly expectedVersion: number;
  readonly occurredAt: string;
  readonly actor: SupplyActor;
}

export interface ProposeCanonicalProductCommand extends CatalogueCommandBase {
  readonly type: "propose_product";
  readonly productId: string;
  readonly categoryId: string;
  readonly brandId: string;
  readonly contentSha256: string;
  readonly codes: readonly CatalogueCodeReference[];
}

export interface ReviewCanonicalProductCommand extends CatalogueCommandBase {
  readonly type: "review_product";
  readonly productId: string;
  readonly decision: "verify" | "reject";
  readonly reasonCode: string;
}

export interface ProposeVerifiedPackCommand extends CatalogueCommandBase {
  readonly type: "propose_pack";
  readonly packId: string;
  readonly productId: string;
  readonly descriptorSha256: string;
  readonly codes: readonly CatalogueCodeReference[];
}

export interface ReviewVerifiedPackCommand extends CatalogueCommandBase {
  readonly type: "review_pack";
  readonly packId: string;
  readonly decision: "verify" | "reject";
  readonly reasonCode: string;
}

export interface CreateParticipantOfferCommand extends CatalogueCommandBase {
  readonly type: "create_offer";
  readonly offerId: string;
  readonly packId: string;
  readonly buyingContext: CatalogueBuyingContext;
  readonly serviceAreaIds: readonly string[];
  readonly termWindows: readonly OfferTermWindow[];
}

export interface OpenCatalogueDuplicateDisputeCommand
  extends CatalogueCommandBase {
  readonly type: "open_duplicate_dispute";
  readonly disputeId: string;
  readonly leftProductId: string;
  readonly rightProductId: string;
  readonly reasonCode: string;
}

export interface ResolveCatalogueDuplicateDisputeCommand
  extends CatalogueCommandBase {
  readonly type: "resolve_duplicate_dispute";
  readonly disputeId: string;
  readonly resolution:
    | "keep_separate"
    | "merge_left_into_right"
    | "merge_right_into_left";
  readonly reasonCode: string;
}

export type CatalogueCommand =
  | ProposeCanonicalProductCommand
  | ReviewCanonicalProductCommand
  | ProposeVerifiedPackCommand
  | ReviewVerifiedPackCommand
  | CreateParticipantOfferCommand
  | OpenCatalogueDuplicateDisputeCommand
  | ResolveCatalogueDuplicateDisputeCommand;

export type CatalogueMatchResult =
  | { readonly kind: "none" }
  | { readonly kind: "exact"; readonly id: string }
  | { readonly kind: "ambiguous"; readonly ids: readonly string[] };

const IDENTIFIER_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$/u;
const SHA256_PATTERN = /^[A-Fa-f0-9]{64}$/u;
const GOVERNANCE_SCOPE = "supply.catalogue.review";
const WORKSPACE_ADMIN_SCOPE = "supply.workspace.admin";

function fail(code: CatalogueContractErrorCode, message: string): never {
  throw new CatalogueContractError(code, message);
}

function identifier(value: string, label: string): string {
  if (!IDENTIFIER_PATTERN.test(value)) {
    fail("invalid_input", `${label} must be an identifier-safe value.`);
  }
  return value;
}

function timestamp(value: string, label: string): string {
  const parsed = Date.parse(value);
  if (!Number.isFinite(parsed)) {
    fail("invalid_input", `${label} must be a valid timestamp.`);
  }
  return new Date(parsed).toISOString();
}

function sha256(value: string, label: string): string {
  if (!SHA256_PATTERN.test(value)) {
    fail("invalid_input", `${label} must be a SHA-256 reference.`);
  }
  return value.toUpperCase();
}

function identifierList(values: readonly string[], label: string): string[] {
  const result = values.map((value) => identifier(value, label)).sort();
  if (new Set(result).size !== result.length) {
    fail("invalid_input", `${label} must not contain duplicates.`);
  }
  return result;
}

function hasGs1CheckDigit(value: string): boolean {
  const digits = [...value].map(Number);
  const checkDigit = digits.pop();
  if (checkDigit === undefined) return false;
  let sum = 0;
  for (let index = digits.length - 1, position = 0; index >= 0; index--, position++) {
    sum += (digits[index] ?? 0) * (position % 2 === 0 ? 3 : 1);
  }
  return (10 - (sum % 10)) % 10 === checkDigit;
}

export function normalizeCatalogueCode(
  code: CatalogueCodeReference,
): CatalogueCodeReference {
  if (!catalogueCodeTypes.includes(code.type)) {
    fail("invalid_input", "catalogue code type is not supported.");
  }
  if (code.type === "manufacturer" || code.type === "internal") {
    const value = code.value.trim().toUpperCase();
    if (!/^[A-Z0-9][A-Z0-9._:/-]{2,63}$/u.test(value)) {
      fail("invalid_input", `${code.type} code is invalid.`);
    }
    return { type: code.type, value };
  }
  const value = code.value.replace(/[ -]/gu, "");
  const allowedLengths =
    code.type === "gtin" ? [8, 12, 13, 14] : code.type === "ean" ? [8, 13] : [12];
  if (
    !/^\d+$/u.test(value) ||
    !allowedLengths.includes(value.length) ||
    !hasGs1CheckDigit(value)
  ) {
    fail("invalid_input", `${code.type} code is invalid.`);
  }
  return { type: code.type, value };
}

function normalizeCodes(
  codes: readonly CatalogueCodeReference[],
): CatalogueCodeReference[] {
  if (codes.length === 0 || codes.length > 20) {
    fail("invalid_input", "one to twenty catalogue codes are required.");
  }
  const normalized = codes.map(normalizeCatalogueCode);
  const keys = normalized.map((code) => `${code.type}:${code.value}`);
  if (new Set(keys).size !== keys.length) {
    fail("invalid_input", "catalogue codes must not contain duplicates.");
  }
  return normalized.sort((left, right) =>
    `${left.type}:${left.value}`.localeCompare(`${right.type}:${right.value}`),
  );
}

function normalizeTermWindows(
  windows: readonly OfferTermWindow[],
): OfferTermWindow[] {
  if (windows.length === 0 || windows.length > 50) {
    fail("invalid_input", "one to fifty offer term windows are required.");
  }
  const normalized = windows
    .map((window) => {
      const effectiveFrom = timestamp(window.effectiveFrom, "effectiveFrom");
      const expiresAt = timestamp(window.expiresAt, "expiresAt");
      if (Date.parse(expiresAt) <= Date.parse(effectiveFrom)) {
        fail("invalid_input", "offer term expiry must follow its start.");
      }
      return {
        termSnapshotId: identifier(window.termSnapshotId, "term snapshot id"),
        termSnapshotSha256: sha256(
          window.termSnapshotSha256,
          "term snapshot",
        ),
        effectiveFrom,
        expiresAt,
      };
    })
    .sort((left, right) => left.effectiveFrom.localeCompare(right.effectiveFrom));
  for (let index = 1; index < normalized.length; index++) {
    const previous = normalized[index - 1];
    const current = normalized[index];
    if (
      previous !== undefined &&
      current !== undefined &&
      Date.parse(current.effectiveFrom) < Date.parse(previous.expiresAt)
    ) {
      fail("invalid_input", "offer term windows must not overlap.");
    }
  }
  const ids = normalized.map((window) => window.termSnapshotId);
  if (new Set(ids).size !== ids.length) {
    fail("invalid_input", "term snapshot ids must be unique per offer.");
  }
  return normalized;
}

function canonicalize(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(canonicalize);
  if (value !== null && typeof value === "object") {
    const record = value as Record<string, unknown>;
    return Object.fromEntries(
      Object.keys(record)
        .sort()
        .filter((key) => record[key] !== undefined)
        .map((key) => [key, canonicalize(record[key])]),
    );
  }
  return value;
}

function fingerprint(value: unknown): string {
  return createHash("sha256")
    .update(JSON.stringify(canonicalize(value)))
    .digest("hex")
    .toUpperCase();
}

function deepFreeze<T>(value: T): T {
  if (value !== null && typeof value === "object" && !Object.isFrozen(value)) {
    Object.freeze(value);
    for (const child of Object.values(value as Record<string, unknown>)) {
      deepFreeze(child);
    }
  }
  return value;
}

function requireGovernance(catalogue: CatalogueAggregate, actor: SupplyActor): void {
  identifier(actor.actorId, "actor id");
  if (actor.tenantId !== catalogue.tenantId) {
    fail("tenant_mismatch", "actor tenant does not own this catalogue.");
  }
  if (!actor.scopes.includes(GOVERNANCE_SCOPE)) {
    fail("unauthorized", `actor lacks required scope ${GOVERNANCE_SCOPE}.`);
  }
}

function requireWorkspaceActor(
  catalogue: CatalogueAggregate,
  actor: SupplyActor,
  workspace: SupplyParticipantWorkspace | undefined,
): SupplyParticipantWorkspace {
  if (workspace === undefined) {
    fail("unauthorized", "participant workspace context is required.");
  }
  if (actor.tenantId !== catalogue.tenantId || workspace.tenantId !== catalogue.tenantId) {
    fail("tenant_mismatch", "actor, workspace and catalogue tenant must match.");
  }
  if (
    actor.workspaceId !== workspace.workspaceId ||
    !actor.scopes.includes(WORKSPACE_ADMIN_SCOPE)
  ) {
    fail("workspace_mismatch", "actor is not an administrator of this workspace.");
  }
  return workspace;
}

function assertEnvelope(
  catalogue: CatalogueAggregate,
  command: CatalogueCommand,
): CatalogueAggregate | undefined {
  identifier(command.commandId, "command id");
  identifier(command.catalogueId, "catalogue id");
  timestamp(command.occurredAt, "occurredAt");
  if (command.catalogueId !== catalogue.catalogueId) {
    fail("invalid_input", "command targets a different catalogue.");
  }
  const receipt = catalogue.commandReceipts.find(
    (item) => item.commandId === command.commandId,
  );
  if (receipt !== undefined) {
    if (receipt.commandFingerprint !== fingerprint(command)) {
      fail("idempotency_conflict", "command id has a conflicting payload.");
    }
    return catalogue;
  }
  if (command.expectedVersion !== catalogue.version) {
    fail("version_conflict", "catalogue aggregate version is stale.");
  }
  return undefined;
}

function commit(
  catalogue: CatalogueAggregate,
  command: CatalogueCommand,
  event: Omit<
    CatalogueAuditEvent,
    | "eventId"
    | "aggregateVersion"
    | "commandId"
    | "catalogueId"
    | "tenantId"
    | "actorId"
    | "occurredAt"
  >,
  patch: Partial<
    Pick<CatalogueAggregate, "products" | "packs" | "offers" | "disputes">
  >,
): CatalogueAggregate {
  const version = catalogue.version + 1;
  const auditEvent: CatalogueAuditEvent = {
    eventId: `${catalogue.catalogueId}:${version}`,
    aggregateVersion: version,
    commandId: command.commandId,
    catalogueId: catalogue.catalogueId,
    tenantId: catalogue.tenantId,
    actorId: command.actor.actorId,
    occurredAt: timestamp(command.occurredAt, "occurredAt"),
    ...event,
  };
  return deepFreeze({
    ...catalogue,
    ...patch,
    version,
    commandReceipts: [
      ...catalogue.commandReceipts,
      {
        commandId: command.commandId,
        commandFingerprint: fingerprint(command),
        aggregateVersion: version,
      },
    ],
    auditEvents: [...catalogue.auditEvents, auditEvent],
  });
}

function productById(
  catalogue: CatalogueAggregate,
  productId: string,
): CanonicalProductRecord {
  const product = catalogue.products.find((item) => item.productId === productId);
  if (product === undefined) fail("not_found", "canonical product was not found.");
  return product;
}

function packById(
  catalogue: CatalogueAggregate,
  packId: string,
): VerifiedPackRecord {
  const pack = catalogue.packs.find((item) => item.packId === packId);
  if (pack === undefined) fail("not_found", "verified pack was not found.");
  return pack;
}

function hasKeepSeparateResolution(
  catalogue: CatalogueAggregate,
  leftProductId: string,
  rightProductId: string,
): boolean {
  return catalogue.disputes.some(
    (dispute) =>
      dispute.state === "resolved" &&
      dispute.resolution === "keep_separate" &&
      ((dispute.leftProductId === leftProductId &&
        dispute.rightProductId === rightProductId) ||
        (dispute.leftProductId === rightProductId &&
          dispute.rightProductId === leftProductId)),
  );
}

function codeKey(code: CatalogueCodeReference): string {
  const normalized = normalizeCatalogueCode(code);
  return `${normalized.type}:${normalized.value}`;
}

export function createCatalogueAggregate(
  command: CreateCatalogueCommand,
): CatalogueAggregate {
  const catalogueId = identifier(command.catalogueId, "catalogue id");
  const tenantId = identifier(command.tenantId, "tenant id");
  identifier(command.commandId, "command id");
  identifier(command.actor.actorId, "actor id");
  if (command.actor.tenantId !== tenantId) {
    fail("tenant_mismatch", "actor tenant cannot create this catalogue.");
  }
  if (!command.actor.scopes.includes(GOVERNANCE_SCOPE)) {
    fail("unauthorized", `actor lacks required scope ${GOVERNANCE_SCOPE}.`);
  }
  const occurredAt = timestamp(command.occurredAt, "occurredAt");
  return deepFreeze({
    schemaVersion: 1,
    catalogueId,
    tenantId,
    version: 1,
    products: [],
    packs: [],
    offers: [],
    disputes: [],
    commandReceipts: [
      {
        commandId: command.commandId,
        commandFingerprint: fingerprint(command),
        aggregateVersion: 1,
      },
    ],
    auditEvents: [
      {
        eventId: `${catalogueId}:1`,
        eventType: "catalogue_created",
        aggregateVersion: 1,
        commandId: command.commandId,
        catalogueId,
        tenantId,
        actorId: command.actor.actorId,
        occurredAt,
        entityType: "catalogue",
        entityId: catalogueId,
        hashReferences: [],
      },
    ],
  });
}

export function applyCatalogueCommand(
  catalogue: CatalogueAggregate,
  command: CatalogueCommand,
  participantWorkspace?: SupplyParticipantWorkspace,
): CatalogueAggregate {
  const participantCommand =
    command.type === "propose_product" ||
    command.type === "propose_pack" ||
    command.type === "create_offer";
  const workspace = participantCommand
    ? requireWorkspaceActor(catalogue, command.actor, participantWorkspace)
    : undefined;
  if (!participantCommand) requireGovernance(catalogue, command.actor);
  const duplicate = assertEnvelope(catalogue, command);
  if (duplicate !== undefined) return duplicate;

  switch (command.type) {
    case "propose_product": {
      if (workspace === undefined) fail("unauthorized", "workspace is required.");
      const productId = identifier(command.productId, "product id");
      const categoryId = identifier(command.categoryId, "category id");
      if (catalogue.products.some((item) => item.productId === productId)) {
        fail("duplicate_candidate", "canonical product id already exists.");
      }
      if (
        !isSupplyCapabilityActive(workspace, {
          capability: "product_master_stewardship",
          at: command.occurredAt,
          categoryId,
        })
      ) {
        fail("capability_inactive", "product-master stewardship is not active.");
      }
      const product: CanonicalProductRecord = {
        productId,
        categoryId,
        brandId: identifier(command.brandId, "brand id"),
        contentSha256: sha256(command.contentSha256, "product content"),
        codes: normalizeCodes(command.codes),
        state: "pending_review",
        proposedByWorkspaceId: workspace.workspaceId,
        proposedAt: timestamp(command.occurredAt, "occurredAt"),
      };
      return commit(
        catalogue,
        command,
        {
          eventType: "product_proposed",
          entityType: "product",
          entityId: productId,
          hashReferences: [product.contentSha256],
        },
        { products: [...catalogue.products, product] },
      );
    }
    case "review_product": {
      const product = productById(catalogue, command.productId);
      if (product.state !== "pending_review") {
        fail("invalid_transition", "product must be pending review.");
      }
      const reasonCode = identifier(command.reasonCode, "reason code");
      if (command.decision === "verify") {
        const productCodes = new Set(product.codes.map(codeKey));
        for (const other of catalogue.products) {
          if (
            other.productId === product.productId ||
            other.state === "rejected" ||
            other.state === "merged"
          ) {
            continue;
          }
          if (
            other.codes.some((code) => productCodes.has(codeKey(code))) &&
            !hasKeepSeparateResolution(
              catalogue,
              product.productId,
              other.productId,
            )
          ) {
            fail(
              "duplicate_candidate",
              "product code collision requires a resolved duplicate dispute.",
            );
          }
        }
      }
      const reviewed: CanonicalProductRecord = {
        ...product,
        state: command.decision === "verify" ? "verified" : "rejected",
        reviewedBy: command.actor.actorId,
        reviewedAt: timestamp(command.occurredAt, "occurredAt"),
        reasonCode,
      };
      return commit(
        catalogue,
        command,
        {
          eventType:
            command.decision === "verify" ? "product_verified" : "product_rejected",
          entityType: "product",
          entityId: product.productId,
          hashReferences: [product.contentSha256],
        },
        {
          products: catalogue.products.map((item) =>
            item.productId === product.productId ? reviewed : item,
          ),
        },
      );
    }
    case "propose_pack": {
      if (workspace === undefined) fail("unauthorized", "workspace is required.");
      const packId = identifier(command.packId, "pack id");
      if (catalogue.packs.some((item) => item.packId === packId)) {
        fail("duplicate_candidate", "pack id already exists.");
      }
      const product = productById(catalogue, command.productId);
      if (product.state !== "verified") {
        fail("invalid_transition", "pack requires a verified canonical product.");
      }
      if (
        !isSupplyCapabilityActive(workspace, {
          capability: "product_master_stewardship",
          at: command.occurredAt,
          categoryId: product.categoryId,
        })
      ) {
        fail("capability_inactive", "product-master stewardship is not active.");
      }
      const pack: VerifiedPackRecord = {
        packId,
        productId: product.productId,
        descriptorSha256: sha256(command.descriptorSha256, "pack descriptor"),
        codes: normalizeCodes(command.codes),
        state: "pending_review",
        proposedByWorkspaceId: workspace.workspaceId,
        proposedAt: timestamp(command.occurredAt, "occurredAt"),
      };
      return commit(
        catalogue,
        command,
        {
          eventType: "pack_proposed",
          entityType: "pack",
          entityId: packId,
          hashReferences: [pack.descriptorSha256],
        },
        { packs: [...catalogue.packs, pack] },
      );
    }
    case "review_pack": {
      const pack = packById(catalogue, command.packId);
      if (pack.state !== "pending_review") {
        fail("invalid_transition", "pack must be pending review.");
      }
      const reviewed: VerifiedPackRecord = {
        ...pack,
        state: command.decision === "verify" ? "verified" : "rejected",
        reviewedBy: command.actor.actorId,
        reviewedAt: timestamp(command.occurredAt, "occurredAt"),
        reasonCode: identifier(command.reasonCode, "reason code"),
      };
      return commit(
        catalogue,
        command,
        {
          eventType: command.decision === "verify" ? "pack_verified" : "pack_rejected",
          entityType: "pack",
          entityId: pack.packId,
          hashReferences: [pack.descriptorSha256],
        },
        {
          packs: catalogue.packs.map((item) =>
            item.packId === pack.packId ? reviewed : item,
          ),
        },
      );
    }
    case "create_offer": {
      if (workspace === undefined) fail("unauthorized", "workspace is required.");
      const offerId = identifier(command.offerId, "offer id");
      if (catalogue.offers.some((item) => item.offerId === offerId)) {
        fail("duplicate_candidate", "offer id already exists.");
      }
      const pack = packById(catalogue, command.packId);
      if (pack.state !== "verified") {
        fail("invalid_transition", "offer requires a verified pack.");
      }
      const product = productById(catalogue, pack.productId);
      if (product.state !== "verified") {
        fail("invalid_transition", "offer requires a verified canonical product.");
      }
      if (command.buyingContext !== "consumer" && command.buyingContext !== "wholesale") {
        fail("invalid_input", "buying context is not supported.");
      }
      const serviceAreaIds = identifierList(
        command.serviceAreaIds,
        "service-area id",
      );
      if (serviceAreaIds.length === 0) {
        fail("invalid_input", "offer requires at least one service area.");
      }
      const capability =
        command.buyingContext === "consumer"
          ? "retail_fulfilment"
          : "wholesale_supply";
      const termWindows = normalizeTermWindows(command.termWindows);
      const createdAt = timestamp(command.occurredAt, "occurredAt");
      if (
        termWindows.some(
          (window) => Date.parse(window.effectiveFrom) < Date.parse(createdAt),
        )
      ) {
        fail("invalid_input", "a new offer cannot backdate its term window.");
      }
      for (const serviceAreaId of serviceAreaIds) {
        const requiredInstants = [
          command.occurredAt,
          ...termWindows.flatMap((window) => [
            window.effectiveFrom,
            new Date(Date.parse(window.expiresAt) - 1).toISOString(),
          ]),
        ];
        for (const at of requiredInstants) {
          if (
            !isSupplyCapabilityActive(workspace, {
              capability,
              at,
              categoryId: product.categoryId,
              serviceAreaId,
            })
          ) {
            fail(
              "capability_inactive",
              `${capability} does not cover the complete offer term window.`,
            );
          }
        }
      }
      const offer: ParticipantOfferRecord = {
        offerId,
        workspaceId: workspace.workspaceId,
        packId: pack.packId,
        buyingContext: command.buyingContext,
        serviceAreaIds,
        termWindows,
        status: "active",
        createdAt,
      };
      return commit(
        catalogue,
        command,
        {
          eventType: "offer_created",
          entityType: "offer",
          entityId: offerId,
          hashReferences: termWindows.map((window) => window.termSnapshotSha256),
        },
        { offers: [...catalogue.offers, offer] },
      );
    }
    case "open_duplicate_dispute": {
      const disputeId = identifier(command.disputeId, "dispute id");
      if (catalogue.disputes.some((item) => item.disputeId === disputeId)) {
        fail("duplicate_candidate", "dispute id already exists.");
      }
      const left = productById(catalogue, command.leftProductId);
      const right = productById(catalogue, command.rightProductId);
      if (left.productId === right.productId) {
        fail("invalid_input", "duplicate dispute requires two products.");
      }
      if (
        catalogue.disputes.some(
          (item) =>
            item.state === "open" &&
            ((item.leftProductId === left.productId &&
              item.rightProductId === right.productId) ||
              (item.leftProductId === right.productId &&
                item.rightProductId === left.productId)),
        )
      ) {
        fail("duplicate_candidate", "an open dispute already owns this pair.");
      }
      const dispute: CatalogueDuplicateDispute = {
        disputeId,
        leftProductId: left.productId,
        rightProductId: right.productId,
        state: "open",
        openedAt: timestamp(command.occurredAt, "occurredAt"),
        openedBy: command.actor.actorId,
        openedReasonCode: identifier(command.reasonCode, "reason code"),
      };
      return commit(
        catalogue,
        command,
        {
          eventType: "duplicate_dispute_opened",
          entityType: "dispute",
          entityId: disputeId,
          hashReferences: [],
        },
        { disputes: [...catalogue.disputes, dispute] },
      );
    }
    case "resolve_duplicate_dispute": {
      const dispute = catalogue.disputes.find(
        (item) => item.disputeId === command.disputeId,
      );
      if (dispute === undefined) fail("not_found", "duplicate dispute was not found.");
      if (dispute.state !== "open") {
        fail("invalid_transition", "duplicate dispute is already resolved.");
      }
      const resolvedAt = timestamp(command.occurredAt, "occurredAt");
      const reasonCode = identifier(command.reasonCode, "reason code");
      const resolved: CatalogueDuplicateDispute = {
        ...dispute,
        state: "resolved",
        resolvedAt,
        resolvedBy: command.actor.actorId,
        resolution: command.resolution,
        resolutionReasonCode: reasonCode,
      };
      let products = catalogue.products;
      let eventType: CatalogueAuditEventType = "duplicate_dispute_resolved";
      let entityType: CatalogueAuditEvent["entityType"] = "dispute";
      let entityId = dispute.disputeId;
      if (command.resolution !== "keep_separate") {
        const sourceId =
          command.resolution === "merge_left_into_right"
            ? dispute.leftProductId
            : dispute.rightProductId;
        const targetId =
          command.resolution === "merge_left_into_right"
            ? dispute.rightProductId
            : dispute.leftProductId;
        const source = productById(catalogue, sourceId);
        const target = productById(catalogue, targetId);
        if (target.state !== "verified" || source.state === "merged") {
          fail("invalid_transition", "merge requires a verified target and live source.");
        }
        const mergeAt = Date.parse(resolvedAt);
        const sourcePackIds = new Set(
          catalogue.packs
            .filter((pack) => pack.productId === source.productId)
            .map((pack) => pack.packId),
        );
        const hasUnexpiredOffer = catalogue.offers.some(
          (offer) =>
            sourcePackIds.has(offer.packId) &&
            offer.status === "active" &&
            offer.termWindows.some((window) => Date.parse(window.expiresAt) > mergeAt),
        );
        if (hasUnexpiredOffer) {
          fail("active_offer_conflict", "source product has an active or scheduled offer.");
        }
        const merged: CanonicalProductRecord = {
          ...source,
          state: "merged",
          mergedIntoProductId: target.productId,
          reviewedBy: command.actor.actorId,
          reviewedAt: resolvedAt,
          reasonCode,
        };
        products = catalogue.products.map((item) =>
          item.productId === source.productId ? merged : item,
        );
        eventType = "product_merged";
        entityType = "product";
        entityId = source.productId;
      }
      return commit(
        catalogue,
        command,
        {
          eventType,
          entityType,
          entityId,
          hashReferences: [],
        },
        {
          products,
          disputes: catalogue.disputes.map((item) =>
            item.disputeId === dispute.disputeId ? resolved : item,
          ),
        },
      );
    }
  }
}

function resolveMergedProductId(
  catalogue: CatalogueAggregate,
  product: CanonicalProductRecord,
): string {
  let current = product;
  const visited = new Set<string>();
  while (current.state === "merged" && current.mergedIntoProductId !== undefined) {
    if (visited.has(current.productId)) return current.productId;
    visited.add(current.productId);
    const next = catalogue.products.find(
      (item) => item.productId === current.mergedIntoProductId,
    );
    if (next === undefined) return current.productId;
    current = next;
  }
  return current.productId;
}

export function matchCanonicalProductByCode(
  catalogue: CatalogueAggregate,
  code: CatalogueCodeReference,
): CatalogueMatchResult {
  const key = codeKey(code);
  const ids = [
    ...new Set(
      catalogue.products
        .filter(
          (product) =>
            product.state !== "rejected" &&
            product.codes.some((candidate) => codeKey(candidate) === key),
        )
        .map((product) => resolveMergedProductId(catalogue, product)),
    ),
  ].sort();
  if (ids.length === 0) return { kind: "none" };
  if (ids.length === 1) return { kind: "exact", id: ids[0] ?? "" };
  return { kind: "ambiguous", ids };
}

export function matchVerifiedPackByCode(
  catalogue: CatalogueAggregate,
  productId: string,
  code: CatalogueCodeReference,
): CatalogueMatchResult {
  const key = codeKey(code);
  const ids = catalogue.packs
    .filter(
      (pack) =>
        pack.productId === productId &&
        pack.state === "verified" &&
        pack.codes.some((candidate) => codeKey(candidate) === key),
    )
    .map((pack) => pack.packId)
    .sort();
  if (ids.length === 0) return { kind: "none" };
  if (ids.length === 1) return { kind: "exact", id: ids[0] ?? "" };
  return { kind: "ambiguous", ids };
}

/**
 * Resolves only the immutable term reference stored on this offer. Callers
 * must still revalidate current capability, stock and serviceability before
 * any customer projection or commitment.
 */
export function referencedOfferTermAt(
  offer: ParticipantOfferRecord,
  at: string,
): OfferTermWindow | undefined {
  const instant = Date.parse(at);
  if (!Number.isFinite(instant) || offer.status !== "active") return undefined;
  return offer.termWindows.find(
    (window) =>
      instant >= Date.parse(window.effectiveFrom) &&
      instant < Date.parse(window.expiresAt),
  );
}
