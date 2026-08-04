import { createHash } from "node:crypto";

import {
  CatalogueContractError,
  normalizeCatalogueCode,
  type CatalogueAggregate,
  type CatalogueCodeReference,
} from "./catalogue_contract.js";
import {
  isSupplyCapabilityActive,
  type SupplyActor,
  type SupplyParticipantWorkspace,
} from "./supply_participant_contract.js";

export const wholesalePackDimensions = ["count", "mass", "volume"] as const;
export type WholesalePackDimension = (typeof wholesalePackDimensions)[number];

/** Physical pack units only; TAX-003 owns any statutory invoice-UQC mapping. */
export const wholesalePackUqcCodes = ["EA", "NOS", "G", "KG", "ML", "L"] as const;
export type WholesalePackUqcCode = (typeof wholesalePackUqcCodes)[number];

export const logisticsLevelKinds = [
  "each",
  "weight",
  "volume",
  "inner",
  "case",
  "pallet",
] as const;
export type LogisticsLevelKind = (typeof logisticsLevelKinds)[number];

export const packEvidenceKinds = [
  "pack_configuration",
  "physical_measurement",
  "code_assignment",
  "traceability_policy",
] as const;
export type PackEvidenceKind = (typeof packEvidenceKinds)[number];

export type PackProfileReviewState = "pending_review" | "verified" | "rejected";
export type TraceabilityPolicy = "not_required" | "required";

export type WholesalePackContractErrorCode =
  | "invalid_input"
  | "unauthorized"
  | "tenant_mismatch"
  | "workspace_mismatch"
  | "version_conflict"
  | "idempotency_conflict"
  | "not_found"
  | "invalid_transition"
  | "capability_inactive"
  | "overlap_conflict";

export class WholesalePackContractError extends Error {
  constructor(
    readonly code: WholesalePackContractErrorCode,
    message: string,
  ) {
    super(message);
    this.name = "WholesalePackContractError";
  }
}

/** Exact positive decimal: value = coefficient * 10^-scale. */
export interface ExactPackQuantity {
  readonly coefficient: string;
  readonly scale: number;
}

export interface PackMeasure {
  readonly dimension: WholesalePackDimension;
  readonly uqc: WholesalePackUqcCode;
  readonly quantity: ExactPackQuantity;
}

export interface LogisticsPhysicalMeasurements {
  readonly lengthMillimetres: number;
  readonly widthMillimetres: number;
  readonly heightMillimetres: number;
  readonly grossWeightGrams: number;
  readonly netWeightGrams?: number;
}

export interface LogisticsUnitInput {
  readonly levelId: string;
  readonly kind: LogisticsLevelKind;
  readonly parentLevelId?: string;
  readonly containedBaseUnits: ExactPackQuantity;
  readonly codes: readonly CatalogueCodeReference[];
  readonly measurements: LogisticsPhysicalMeasurements;
}

export interface LogisticsUnitRecord {
  readonly levelId: string;
  readonly kind: LogisticsLevelKind;
  readonly parentLevelId?: string;
  readonly containedBaseUnits: ExactPackQuantity;
  readonly codes: readonly CatalogueCodeReference[];
  readonly measurements: LogisticsPhysicalMeasurements;
}

export interface PackEvidenceReference {
  readonly evidenceId: string;
  readonly kind: PackEvidenceKind;
  readonly sha256: string;
}

export interface WholesalePackProfileInput {
  readonly measure: PackMeasure;
  readonly levels: readonly LogisticsUnitInput[];
  readonly saleMultipleBaseUnits: ExactPackQuantity;
  readonly loadingMultipleBaseUnits: ExactPackQuantity;
  readonly batchPolicy: TraceabilityPolicy;
  readonly expiryPolicy: TraceabilityPolicy;
  readonly configurationSha256: string;
  readonly evidence: readonly PackEvidenceReference[];
}

export interface WholesalePackProfileRecord {
  readonly profileId: string;
  readonly packId: string;
  readonly productId: string;
  readonly measure: PackMeasure;
  readonly levels: readonly LogisticsUnitRecord[];
  readonly saleMultipleBaseUnits: ExactPackQuantity;
  readonly loadingMultipleBaseUnits: ExactPackQuantity;
  readonly batchPolicy: TraceabilityPolicy;
  readonly expiryPolicy: TraceabilityPolicy;
  readonly configurationSha256: string;
  readonly evidence: readonly PackEvidenceReference[];
  readonly profileSha256: string;
  readonly state: PackProfileReviewState;
  readonly proposedByWorkspaceId: string;
  readonly proposedByActorId: string;
  readonly proposedAt: string;
  readonly reviewedBy?: string;
  readonly reviewedAt?: string;
  readonly reasonCode?: string;
  readonly effectiveFrom?: string;
  readonly expiresAt?: string;
}

export type WholesalePackAuditEventType =
  | "pack_profile_set_created"
  | "pack_profile_proposed"
  | "pack_profile_verified"
  | "pack_profile_rejected";

export interface WholesalePackAuditEvent {
  readonly eventId: string;
  readonly eventType: WholesalePackAuditEventType;
  readonly aggregateVersion: number;
  readonly commandId: string;
  readonly profileSetId: string;
  readonly tenantId: string;
  readonly actorId: string;
  readonly occurredAt: string;
  readonly packId: string;
  readonly profileId?: string;
  readonly hashReferences: readonly string[];
}

export interface WholesalePackCommandReceipt {
  readonly commandId: string;
  readonly commandFingerprint: string;
  readonly aggregateVersion: number;
}

export interface WholesalePackProfileSet {
  readonly schemaVersion: 1;
  readonly profileSetId: string;
  readonly tenantId: string;
  readonly catalogueId: string;
  readonly sourceCatalogueVersion: number;
  readonly packId: string;
  readonly productId: string;
  readonly categoryId: string;
  readonly sourceProductContentSha256: string;
  readonly sourcePackDescriptorSha256: string;
  readonly version: number;
  readonly profiles: readonly WholesalePackProfileRecord[];
  readonly commandReceipts: readonly WholesalePackCommandReceipt[];
  readonly auditEvents: readonly WholesalePackAuditEvent[];
}

export interface CreateWholesalePackProfileSetCommand {
  readonly commandId: string;
  readonly profileSetId: string;
  readonly packId: string;
  readonly occurredAt: string;
  readonly actor: SupplyActor;
}

interface WholesalePackCommandBase {
  readonly commandId: string;
  readonly profileSetId: string;
  readonly expectedVersion: number;
  readonly occurredAt: string;
  readonly actor: SupplyActor;
}

export interface ProposeWholesalePackProfileCommand
  extends WholesalePackCommandBase,
    WholesalePackProfileInput {
  readonly type: "propose_profile";
  readonly profileId: string;
}

export interface ReviewWholesalePackProfileCommand
  extends WholesalePackCommandBase {
  readonly type: "review_profile";
  readonly profileId: string;
  readonly decision: "verify" | "reject";
  readonly reasonCode: string;
  readonly effectiveFrom?: string;
  readonly expiresAt?: string;
}

export type WholesalePackCommand =
  | ProposeWholesalePackProfileCommand
  | ReviewWholesalePackProfileCommand;

const IDENTIFIER_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$/u;
const SHA256_PATTERN = /^[A-Fa-f0-9]{64}$/u;
const WORKSPACE_ADMIN_SCOPE = "supply.workspace.admin";
const GOVERNANCE_SCOPE = "supply.catalogue.review";
const MAX_EXACT_COEFFICIENT = 999_999_999_999_999_999n;
const MAX_BASE_UNITS = 1_000_000_000n;

function fail(code: WholesalePackContractErrorCode, message: string): never {
  throw new WholesalePackContractError(code, message);
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

function reasonCode(value: string): string {
  return identifier(value, "reason code");
}

export function normalizeExactPackQuantity(
  input: ExactPackQuantity,
): ExactPackQuantity {
  if (
    !Number.isInteger(input.scale) ||
    input.scale < 0 ||
    input.scale > 6 ||
    !/^\d{1,18}$/u.test(input.coefficient)
  ) {
    fail("invalid_input", "exact quantity must use 1-18 digits and scale 0-6.");
  }
  let coefficient = input.coefficient.replace(/^0+(?=\d)/u, "");
  let scale = input.scale;
  while (scale > 0 && coefficient.endsWith("0")) {
    coefficient = coefficient.slice(0, -1);
    scale--;
  }
  const numeric = BigInt(coefficient);
  if (numeric <= 0n || numeric > MAX_EXACT_COEFFICIENT) {
    fail("invalid_input", "exact quantity must be positive and bounded.");
  }
  return { coefficient, scale };
}

function exactInteger(
  input: ExactPackQuantity,
  label: string,
): ExactPackQuantity {
  const normalized = normalizeExactPackQuantity(input);
  if (normalized.scale !== 0) {
    fail("invalid_input", `${label} must be a whole number of base units.`);
  }
  if (BigInt(normalized.coefficient) > MAX_BASE_UNITS) {
    fail("invalid_input", `${label} exceeds the supported bound.`);
  }
  return normalized;
}

function integerValue(quantity: ExactPackQuantity): bigint {
  return BigInt(quantity.coefficient);
}

function normalizeMeasure(measure: PackMeasure): PackMeasure {
  if (!wholesalePackDimensions.includes(measure.dimension)) {
    fail("invalid_input", "pack measure dimension is not supported.");
  }
  if (!wholesalePackUqcCodes.includes(measure.uqc)) {
    fail("invalid_input", "pack UQC is not supported.");
  }
  const permitted: Record<WholesalePackDimension, readonly WholesalePackUqcCode[]> = {
    count: ["EA", "NOS"],
    mass: ["G", "KG"],
    volume: ["ML", "L"],
  };
  if (!permitted[measure.dimension].includes(measure.uqc)) {
    fail("invalid_input", "pack UQC is incompatible with its dimension.");
  }
  const quantity = normalizeExactPackQuantity(measure.quantity);
  if (measure.dimension === "count" && quantity.scale !== 0) {
    fail("invalid_input", "count measure must be a whole EA or NOS quantity.");
  }
  return {
    dimension: measure.dimension,
    uqc: measure.uqc,
    quantity,
  };
}

function positiveBoundedInteger(value: number, label: string, max: number): number {
  if (!Number.isSafeInteger(value) || value <= 0 || value > max) {
    fail("invalid_input", `${label} must be a positive bounded integer.`);
  }
  return value;
}

function normalizeMeasurements(
  input: LogisticsPhysicalMeasurements,
): LogisticsPhysicalMeasurements {
  const lengthMillimetres = positiveBoundedInteger(
    input.lengthMillimetres,
    "length millimetres",
    100_000,
  );
  const widthMillimetres = positiveBoundedInteger(
    input.widthMillimetres,
    "width millimetres",
    100_000,
  );
  const heightMillimetres = positiveBoundedInteger(
    input.heightMillimetres,
    "height millimetres",
    100_000,
  );
  const grossWeightGrams = positiveBoundedInteger(
    input.grossWeightGrams,
    "gross weight grams",
    100_000_000,
  );
  if (input.netWeightGrams === undefined) {
    return {
      lengthMillimetres,
      widthMillimetres,
      heightMillimetres,
      grossWeightGrams,
    };
  }
  const netWeightGrams = positiveBoundedInteger(
    input.netWeightGrams,
    "net weight grams",
    100_000_000,
  );
  if (netWeightGrams > grossWeightGrams) {
    fail("invalid_input", "net weight cannot exceed gross weight.");
  }
  return {
    lengthMillimetres,
    widthMillimetres,
    heightMillimetres,
    grossWeightGrams,
    netWeightGrams,
  };
}

function normalizeCodes(
  input: readonly CatalogueCodeReference[],
): CatalogueCodeReference[] {
  if (input.length > 20) {
    fail("invalid_input", "a logistics level may contain at most twenty codes.");
  }
  const normalized = input.map((code) => {
    try {
      return normalizeCatalogueCode(code);
    } catch (error) {
      if (error instanceof CatalogueContractError) {
        fail("invalid_input", "logistics-level code is invalid.");
      }
      throw error;
    }
  });
  const keys = normalized.map((code) => `${code.type}:${code.value}`);
  if (new Set(keys).size !== keys.length) {
    fail("invalid_input", "logistics-level codes must not contain duplicates.");
  }
  return normalized.sort((left, right) =>
    `${left.type}:${left.value}`.localeCompare(`${right.type}:${right.value}`),
  );
}

function baseKindFor(dimension: WholesalePackDimension): LogisticsLevelKind {
  if (dimension === "mass") return "weight";
  if (dimension === "volume") return "volume";
  return "each";
}

function normalizeLevels(
  input: readonly LogisticsUnitInput[],
  dimension: WholesalePackDimension,
): LogisticsUnitRecord[] {
  if (input.length === 0 || input.length > 4) {
    fail("invalid_input", "one to four logistics levels are required.");
  }
  const levels = input.map((level) => {
    const levelId = identifier(level.levelId, "logistics level id");
    if (!logisticsLevelKinds.includes(level.kind)) {
      fail("invalid_input", "logistics level kind is not supported.");
    }
    return {
      levelId,
      kind: level.kind,
      ...(level.parentLevelId === undefined
        ? {}
        : { parentLevelId: identifier(level.parentLevelId, "parent level id") }),
      containedBaseUnits: exactInteger(
        level.containedBaseUnits,
        "contained base units",
      ),
      codes: normalizeCodes(level.codes),
      measurements: normalizeMeasurements(level.measurements),
    } satisfies LogisticsUnitRecord;
  });
  if (
    new Set(levels.map((level) => level.levelId)).size !== levels.length ||
    new Set(levels.map((level) => level.kind)).size !== levels.length
  ) {
    fail("invalid_input", "logistics level ids and kinds must be unique.");
  }
  const codeKeys = levels.flatMap((level) =>
    level.codes.map((code) => `${code.type}:${code.value}`),
  );
  if (new Set(codeKeys).size !== codeKeys.length) {
    fail("invalid_input", "a code cannot identify multiple logistics levels.");
  }
  levels.sort((left, right) =>
    Number(integerValue(left.containedBaseUnits) - integerValue(right.containedBaseUnits)),
  );
  const first = levels[0];
  if (
    first === undefined ||
    first.kind !== baseKindFor(dimension) ||
    first.parentLevelId !== undefined ||
    integerValue(first.containedBaseUnits) !== 1n
  ) {
    fail("invalid_input", "the first level must be the dimension's one-unit base.");
  }
  const rank: Record<LogisticsLevelKind, number> = {
    each: 0,
    weight: 0,
    volume: 0,
    inner: 1,
    case: 2,
    pallet: 3,
  };
  for (let index = 1; index < levels.length; index++) {
    const previous = levels[index - 1];
    const current = levels[index];
    if (previous === undefined || current === undefined) continue;
    const previousUnits = integerValue(previous.containedBaseUnits);
    const currentUnits = integerValue(current.containedBaseUnits);
    if (
      current.parentLevelId !== previous.levelId ||
      rank[current.kind] <= rank[previous.kind] ||
      currentUnits <= previousUnits ||
      currentUnits % previousUnits !== 0n
    ) {
      fail(
        "invalid_input",
        "logistics levels must form one increasing divisible parent chain.",
      );
    }
  }
  const baseNetWeight = first.measurements.netWeightGrams;
  if (baseNetWeight !== undefined) {
    for (const level of levels) {
      if (level.measurements.netWeightGrams === undefined) continue;
      const expected = BigInt(baseNetWeight) * integerValue(level.containedBaseUnits);
      if (BigInt(level.measurements.netWeightGrams) !== expected) {
        fail(
          "invalid_input",
          "known net weights must equal base net weight times contained units.",
        );
      }
    }
  }
  return levels;
}

function normalizeEvidence(
  input: readonly PackEvidenceReference[],
): PackEvidenceReference[] {
  if (input.length === 0 || input.length > 20) {
    fail("invalid_input", "one to twenty pack evidence references are required.");
  }
  const normalized = input.map((evidence) => {
    if (!packEvidenceKinds.includes(evidence.kind)) {
      fail("invalid_input", "pack evidence kind is not supported.");
    }
    return {
      evidenceId: identifier(evidence.evidenceId, "evidence id"),
      kind: evidence.kind,
      sha256: sha256(evidence.sha256, "evidence"),
    };
  });
  if (
    new Set(normalized.map((evidence) => evidence.evidenceId)).size !==
    normalized.length
  ) {
    fail("invalid_input", "pack evidence ids must be unique.");
  }
  return normalized.sort((left, right) =>
    left.evidenceId.localeCompare(right.evidenceId),
  );
}

function normalizeTraceability(value: TraceabilityPolicy, label: string): TraceabilityPolicy {
  if (value !== "not_required" && value !== "required") {
    fail("invalid_input", `${label} is not supported.`);
  }
  return value;
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

function requireWorkspaceIdentity(
  tenantId: string,
  actor: SupplyActor,
  workspace: SupplyParticipantWorkspace | undefined,
): SupplyParticipantWorkspace {
  identifier(actor.actorId, "actor id");
  if (workspace === undefined) {
    fail("unauthorized", "participant workspace context is required.");
  }
  if (actor.tenantId !== tenantId || workspace.tenantId !== tenantId) {
    fail("tenant_mismatch", "actor, workspace and pack profile tenant must match.");
  }
  if (
    actor.workspaceId !== workspace.workspaceId ||
    !actor.scopes.includes(WORKSPACE_ADMIN_SCOPE)
  ) {
    fail("workspace_mismatch", "actor is not an administrator of this workspace.");
  }
  identifier(workspace.workspaceId, "workspace id");
  return workspace;
}

function requireProductMasterCapability(
  workspace: SupplyParticipantWorkspace,
  categoryId: string,
  at: string,
): void {
  if (!isSupplyCapabilityActive(workspace, {
    capability: "product_master_stewardship",
    at,
    categoryId,
  })) {
    fail("capability_inactive", "product-master capability is inactive.");
  }
}

function requireWorkspaceActor(
  tenantId: string,
  categoryId: string,
  at: string,
  actor: SupplyActor,
  workspace: SupplyParticipantWorkspace | undefined,
): SupplyParticipantWorkspace {
  const participant = requireWorkspaceIdentity(tenantId, actor, workspace);
  requireProductMasterCapability(participant, categoryId, at);
  return participant;
}

function requireGovernance(
  aggregate: WholesalePackProfileSet,
  actor: SupplyActor,
): void {
  identifier(actor.actorId, "actor id");
  if (actor.tenantId !== aggregate.tenantId) {
    fail("tenant_mismatch", "actor tenant does not own this pack profile set.");
  }
  if (!actor.scopes.includes(GOVERNANCE_SCOPE)) {
    fail("unauthorized", `actor lacks required scope ${GOVERNANCE_SCOPE}.`);
  }
}

function assertEnvelope(
  aggregate: WholesalePackProfileSet,
  command: WholesalePackCommand,
): WholesalePackProfileSet | undefined {
  identifier(command.commandId, "command id");
  identifier(command.profileSetId, "profile set id");
  timestamp(command.occurredAt, "occurredAt");
  if (command.profileSetId !== aggregate.profileSetId) {
    fail("invalid_input", "command targets a different pack profile set.");
  }
  const receipt = aggregate.commandReceipts.find(
    (item) => item.commandId === command.commandId,
  );
  if (receipt !== undefined) {
    if (receipt.commandFingerprint !== fingerprint(command)) {
      fail("idempotency_conflict", "command id has a conflicting payload.");
    }
    return aggregate;
  }
  const latestEvent = aggregate.auditEvents.at(-1);
  if (
    latestEvent !== undefined &&
    Date.parse(command.occurredAt) < Date.parse(latestEvent.occurredAt)
  ) {
    fail("invalid_input", "new commands cannot precede the latest audit event.");
  }
  if (command.expectedVersion !== aggregate.version) {
    fail("version_conflict", "pack profile aggregate version is stale.");
  }
  return undefined;
}

function commit(
  aggregate: WholesalePackProfileSet,
  command: WholesalePackCommand,
  event: Omit<
    WholesalePackAuditEvent,
    | "eventId"
    | "aggregateVersion"
    | "commandId"
    | "profileSetId"
    | "tenantId"
    | "actorId"
    | "occurredAt"
    | "packId"
  >,
  profiles: readonly WholesalePackProfileRecord[],
): WholesalePackProfileSet {
  const version = aggregate.version + 1;
  return deepFreeze({
    ...aggregate,
    version,
    profiles,
    commandReceipts: [
      ...aggregate.commandReceipts,
      {
        commandId: command.commandId,
        commandFingerprint: fingerprint(command),
        aggregateVersion: version,
      },
    ],
    auditEvents: [
      ...aggregate.auditEvents,
      {
        eventId: `${aggregate.profileSetId}:${version}`,
        aggregateVersion: version,
        commandId: command.commandId,
        profileSetId: aggregate.profileSetId,
        tenantId: aggregate.tenantId,
        actorId: command.actor.actorId,
        occurredAt: timestamp(command.occurredAt, "occurredAt"),
        packId: aggregate.packId,
        ...event,
      },
    ],
  });
}

export function createWholesalePackProfileSet(
  command: CreateWholesalePackProfileSetCommand,
  catalogue: CatalogueAggregate,
  workspace?: SupplyParticipantWorkspace,
): WholesalePackProfileSet {
  const commandId = identifier(command.commandId, "command id");
  const profileSetId = identifier(command.profileSetId, "profile set id");
  const packId = identifier(command.packId, "pack id");
  const occurredAt = timestamp(command.occurredAt, "occurredAt");
  identifier(catalogue.catalogueId, "catalogue id");
  identifier(catalogue.tenantId, "tenant id");
  const participant = requireWorkspaceIdentity(
    catalogue.tenantId,
    command.actor,
    workspace,
  );
  const pack = catalogue.packs.find((item) => item.packId === packId);
  if (pack === undefined) fail("not_found", "source verified pack was not found.");
  if (pack.state !== "verified") {
    fail("invalid_transition", "source pack must be verified.");
  }
  const product = catalogue.products.find(
    (item) => item.productId === pack.productId,
  );
  if (product === undefined) fail("not_found", "source canonical product was not found.");
  if (product.state !== "verified") {
    fail("invalid_transition", "source canonical product must be verified.");
  }
  requireProductMasterCapability(participant, product.categoryId, occurredAt);
  const aggregate: WholesalePackProfileSet = {
    schemaVersion: 1,
    profileSetId,
    tenantId: catalogue.tenantId,
    catalogueId: catalogue.catalogueId,
    sourceCatalogueVersion: positiveBoundedInteger(
      catalogue.version,
      "source catalogue version",
      Number.MAX_SAFE_INTEGER,
    ),
    packId,
    productId: product.productId,
    categoryId: product.categoryId,
    sourceProductContentSha256: sha256(
      product.contentSha256,
      "source product content",
    ),
    sourcePackDescriptorSha256: sha256(
      pack.descriptorSha256,
      "source pack descriptor",
    ),
    version: 1,
    profiles: [],
    commandReceipts: [
      {
        commandId,
        commandFingerprint: fingerprint(command),
        aggregateVersion: 1,
      },
    ],
    auditEvents: [
      {
        eventId: `${profileSetId}:1`,
        eventType: "pack_profile_set_created",
        aggregateVersion: 1,
        commandId,
        profileSetId,
        tenantId: catalogue.tenantId,
        actorId: command.actor.actorId,
        occurredAt,
        packId,
        hashReferences: [
          sha256(product.contentSha256, "source product content"),
          sha256(pack.descriptorSha256, "source pack descriptor"),
        ],
      },
    ],
  };
  if (participant.workspaceId !== command.actor.workspaceId) {
    fail("workspace_mismatch", "workspace identity changed during validation.");
  }
  return deepFreeze(aggregate);
}

function normalizedProfile(
  aggregate: WholesalePackProfileSet,
  command: ProposeWholesalePackProfileCommand,
  workspace: SupplyParticipantWorkspace,
): WholesalePackProfileRecord {
  if (aggregate.profiles.length >= 100) {
    fail("invalid_input", "pack profile history has reached its bounded limit.");
  }
  const profileId = identifier(command.profileId, "profile id");
  if (aggregate.profiles.some((profile) => profile.profileId === profileId)) {
    fail("invalid_input", "profile id already exists.");
  }
  const measure = normalizeMeasure(command.measure);
  const levels = normalizeLevels(command.levels, measure.dimension);
  const saleMultipleBaseUnits = exactInteger(
    command.saleMultipleBaseUnits,
    "sale multiple",
  );
  const loadingMultipleBaseUnits = exactInteger(
    command.loadingMultipleBaseUnits,
    "loading multiple",
  );
  const sale = integerValue(saleMultipleBaseUnits);
  const loading = integerValue(loadingMultipleBaseUnits);
  if (loading % sale !== 0n) {
    fail("invalid_input", "loading multiple must be divisible by sale multiple.");
  }
  const declaredUnits = new Set(
    levels.map((level) => integerValue(level.containedBaseUnits).toString()),
  );
  if (!declaredUnits.has(sale.toString()) || !declaredUnits.has(loading.toString())) {
    fail("invalid_input", "sale and loading multiples must identify declared levels.");
  }
  const batchPolicy = normalizeTraceability(command.batchPolicy, "batch policy");
  const expiryPolicy = normalizeTraceability(command.expiryPolicy, "expiry policy");
  const evidence = normalizeEvidence(command.evidence);
  const evidenceKinds = new Set(evidence.map((item) => item.kind));
  if (
    !evidenceKinds.has("pack_configuration") ||
    !evidenceKinds.has("physical_measurement")
  ) {
    fail(
      "invalid_input",
      "pack configuration and physical measurement evidence are required.",
    );
  }
  if (
    levels.some((level) => level.codes.length > 0) &&
    !evidenceKinds.has("code_assignment")
  ) {
    fail("invalid_input", "governed logistics codes need assignment evidence.");
  }
  if (
    (batchPolicy === "required" || expiryPolicy === "required") &&
    !evidenceKinds.has("traceability_policy")
  ) {
    fail("invalid_input", "required traceability needs policy evidence.");
  }
  if (measure.dimension === "mass") {
    const base = levels[0];
    const netWeightGrams = base?.measurements.netWeightGrams;
    if (netWeightGrams === undefined) {
      fail("invalid_input", "mass packs require a known base net weight.");
    }
    const multiplier = measure.uqc === "KG" ? 1_000n : 1n;
    const numerator = BigInt(measure.quantity.coefficient) * multiplier;
    const denominator = 10n ** BigInt(measure.quantity.scale);
    if (
      numerator % denominator !== 0n ||
      numerator / denominator !== BigInt(netWeightGrams)
    ) {
      fail("invalid_input", "mass UQC quantity must equal base net weight.");
    }
  }
  const configurationSha256 = sha256(
    command.configurationSha256,
    "pack configuration",
  );
  const profileCore = {
    profileId,
    packId: aggregate.packId,
    productId: aggregate.productId,
    measure,
    levels,
    saleMultipleBaseUnits,
    loadingMultipleBaseUnits,
    batchPolicy,
    expiryPolicy,
    configurationSha256,
    evidence,
  };
  return {
    ...profileCore,
    profileSha256: fingerprint(profileCore),
    state: "pending_review",
    proposedByWorkspaceId: workspace.workspaceId,
    proposedByActorId: command.actor.actorId,
    proposedAt: timestamp(command.occurredAt, "occurredAt"),
  };
}

function windowsOverlap(
  leftStart: string,
  leftEnd: string,
  rightStart: string,
  rightEnd: string,
): boolean {
  return Date.parse(leftStart) < Date.parse(rightEnd) &&
    Date.parse(rightStart) < Date.parse(leftEnd);
}

export function applyWholesalePackCommand(
  aggregate: WholesalePackProfileSet,
  command: WholesalePackCommand,
  workspace?: SupplyParticipantWorkspace,
): WholesalePackProfileSet {
  const participant = command.type === "propose_profile"
    ? requireWorkspaceActor(
        aggregate.tenantId,
        aggregate.categoryId,
        command.occurredAt,
        command.actor,
        workspace,
      )
    : undefined;
  if (command.type === "review_profile") {
    requireGovernance(aggregate, command.actor);
  }
  const replay = assertEnvelope(aggregate, command);
  if (replay !== undefined) return replay;

  switch (command.type) {
    case "propose_profile": {
      if (participant === undefined) fail("unauthorized", "workspace is required.");
      const profile = normalizedProfile(aggregate, command, participant);
      return commit(
        aggregate,
        command,
        {
          eventType: "pack_profile_proposed",
          profileId: profile.profileId,
          hashReferences: [
            profile.profileSha256,
            ...profile.evidence.map((item) => item.sha256),
          ],
        },
        [...aggregate.profiles, profile],
      );
    }
    case "review_profile": {
      const profileId = identifier(command.profileId, "profile id");
      const profile = aggregate.profiles.find((item) => item.profileId === profileId);
      if (profile === undefined) fail("not_found", "pack profile was not found.");
      if (profile.state !== "pending_review") {
        fail("invalid_transition", "only a pending pack profile can be reviewed.");
      }
      if (profile.proposedByActorId === command.actor.actorId) {
        fail("unauthorized", "the proposer cannot review the same pack profile.");
      }
      const reviewedAt = timestamp(command.occurredAt, "occurredAt");
      const normalizedReason = reasonCode(command.reasonCode);
      if (command.decision === "reject") {
        if (command.effectiveFrom !== undefined || command.expiresAt !== undefined) {
          fail("invalid_input", "a rejected profile cannot have an effective window.");
        }
        const rejected: WholesalePackProfileRecord = {
          ...profile,
          state: "rejected",
          reviewedBy: command.actor.actorId,
          reviewedAt,
          reasonCode: normalizedReason,
        };
        return commit(
          aggregate,
          command,
          {
            eventType: "pack_profile_rejected",
            profileId,
            hashReferences: [profile.profileSha256],
          },
          aggregate.profiles.map((item) =>
            item.profileId === profileId ? rejected : item,
          ),
        );
      }
      if (command.decision !== "verify") {
        fail("invalid_input", "pack profile review decision is not supported.");
      }
      if (command.effectiveFrom === undefined || command.expiresAt === undefined) {
        fail("invalid_input", "a verified profile requires an effective window.");
      }
      const effectiveFrom = timestamp(command.effectiveFrom, "effectiveFrom");
      const expiresAt = timestamp(command.expiresAt, "expiresAt");
      if (
        Date.parse(effectiveFrom) < Date.parse(reviewedAt) ||
        Date.parse(expiresAt) <= Date.parse(effectiveFrom)
      ) {
        fail("invalid_input", "profile effective window is backdated or empty.");
      }
      const overlap = aggregate.profiles.some(
        (item) =>
          item.state === "verified" &&
          item.effectiveFrom !== undefined &&
          item.expiresAt !== undefined &&
          windowsOverlap(
            effectiveFrom,
            expiresAt,
            item.effectiveFrom,
            item.expiresAt,
          ),
      );
      if (overlap) {
        fail("overlap_conflict", "verified pack profile windows cannot overlap.");
      }
      const verified: WholesalePackProfileRecord = {
        ...profile,
        state: "verified",
        reviewedBy: command.actor.actorId,
        reviewedAt,
        reasonCode: normalizedReason,
        effectiveFrom,
        expiresAt,
      };
      return commit(
        aggregate,
        command,
        {
          eventType: "pack_profile_verified",
          profileId,
          hashReferences: [profile.profileSha256],
        },
        aggregate.profiles.map((item) =>
          item.profileId === profileId ? verified : item,
        ),
      );
    }
  }
}

/**
 * Returns only the governed stored profile. Callers must separately revalidate
 * supplier capability, offer terms, inventory, destination and serviceability.
 */
export function referencedWholesalePackProfileAt(
  aggregate: WholesalePackProfileSet,
  at: string,
): WholesalePackProfileRecord | undefined {
  const instant = Date.parse(at);
  if (!Number.isFinite(instant)) return undefined;
  return aggregate.profiles.find(
    (profile) =>
      profile.state === "verified" &&
      profile.effectiveFrom !== undefined &&
      profile.expiresAt !== undefined &&
      instant >= Date.parse(profile.effectiveFrom) &&
      instant < Date.parse(profile.expiresAt),
  );
}
