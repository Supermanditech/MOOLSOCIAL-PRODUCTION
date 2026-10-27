import { createHash } from "node:crypto";

export class AccountProfileError extends Error {
  constructor(readonly code: string, readonly status: number, readonly uncertain = false) {
    super(code); this.name = "AccountProfileError";
  }
}
export interface AccountProfileActor {
  readonly uid: string;
  readonly projectId: string;
  readonly tenantId?: string;
}
export interface DeliveryAddress {
  readonly id: string; readonly kind: "home" | "work" | "thirdParty" | "other";
  readonly label: string; readonly recipient: string; readonly phone: string;
  readonly line: string; readonly area: string; readonly pinCode: string;
  readonly landmark: string;
}
export interface InvoiceProfile {
  readonly id: string; readonly legalName: string; readonly gstin: string;
  readonly billingAddress: string; readonly registration: "registered" | "unregistered";
}
export interface AccountProfile {
  readonly ownerUid: string; readonly revision: number; readonly updatedAt: string;
  readonly displayName: string | null; readonly addresses: readonly DeliveryAddress[];
  readonly selectedAddressId: string | null; readonly invoiceProfiles: readonly InvoiceProfile[];
}
export interface AccountProfileAccount {
  readonly uid: string; readonly status: "ACTIVE" | "RESTRICTED" | "DELETED";
  readonly profile: AccountProfile | null;
}
export interface AccountProfileReceipt {
  readonly ownerUid: string; readonly requestId: string; readonly fingerprint: string;
  readonly profile: AccountProfile;
}
export interface AccountProfileCommit {
  readonly ownerUid: string; readonly requestId: string; readonly fingerprint: string;
  readonly expectedRevision: number; readonly profile: AccountProfile;
}
export type AccountProfileCommitResult =
  | { readonly state: "applied" | "replayed"; readonly receipt: AccountProfileReceipt }
  | { readonly state: "conflict" | "restricted" | "missing" };
/** Implementations MUST atomically compare account state/revision, change only
 * Profile fields, and persist the immutable original mutation receipt. */
export interface AccountProfileRepository {
  readAccount(ownerUid: string): Promise<AccountProfileAccount | undefined>;
  readReceipt(ownerUid: string, requestId: string): Promise<AccountProfileReceipt | undefined>;
  commit(change: AccountProfileCommit): Promise<AccountProfileCommitResult>;
}
type Change =
  | { kind: "name"; displayName: string }
  | { kind: "delivery"; addresses: DeliveryAddress[]; selectedAddressId: string | null }
  | { kind: "invoices"; invoiceProfiles: InvoiceProfile[] };
function fail(code = "invalid_profile_request", status = 400): never {
  throw new AccountProfileError(code, status);
}
function object(value: unknown, allowed: readonly string[]): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value) ||
    ![Object.prototype, null].includes(Object.getPrototypeOf(value))) fail();
  const record = value as Record<string, unknown>;
  if (Object.keys(record).some(key => !allowed.includes(key))) fail();
  return record;
}
function text(value: unknown, minimum = 1, maximum = 2000): string {
  if (typeof value !== "string") fail();
  const normalized = value.trim();
  if (normalized.length < minimum || normalized.length > maximum ||
      /[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/u.test(normalized)) fail();
  return normalized;
}
function identifier(value: unknown): string {
  const id = text(value, 1, 128);
  if (!/^[A-Za-z0-9][A-Za-z0-9._:-]*$/u.test(id)) fail();
  return id;
}
function revision(value: unknown): number {
  if (typeof value !== "number" || !Number.isSafeInteger(value) || value < 0 ||
      value >= Number.MAX_SAFE_INTEGER) fail();
  return value;
}
function list<T>(value: unknown, decode: (value: unknown) => T): T[] {
  if (!Array.isArray(value)) fail();
  return value.map(decode);
}
function unique(values: readonly { id: string }[]): void {
  if (new Set(values.map(value => value.id)).size !== values.length) fail();
}
function address(value: unknown): DeliveryAddress {
  const v = object(value, ["id", "kind", "label", "recipient", "phone", "line", "area", "pinCode", "landmark"]);
  if (v.kind !== "home" && v.kind !== "work" && v.kind !== "thirdParty" && v.kind !== "other") fail();
  const phone = text(v.phone, 7, 32);
  if (!/^[+\d() -]+$/u.test(phone)) fail();
  const pinCode = text(v.pinCode, 6, 6);
  if (!/^[1-9]\d{5}$/u.test(pinCode)) fail();
  return { id: identifier(v.id), kind: v.kind, label: text(v.label, 1, 120),
    recipient: text(v.recipient, 1, 200), phone, line: text(v.line),
    area: text(v.area, 1, 512), pinCode, landmark: text(v.landmark ?? "", 0, 1000) };
}
function invoice(value: unknown): InvoiceProfile {
  const v = object(value, ["id", "legalName", "gstin", "billingAddress", "registration"]);
  if (v.registration !== "registered" && v.registration !== "unregistered") fail();
  const gstin = text(v.gstin, 0, 15).toUpperCase();
  if (v.registration === "registered" && !/^\d{2}[A-Z]{5}\d{4}[A-Z][1-9A-Z]Z[0-9A-Z]$/u.test(gstin)) fail();
  if (v.registration === "unregistered" && gstin !== "") fail();
  // Registration is the user's invoice classification, never GST verification.
  return { id: identifier(v.id), registration: v.registration,
    legalName: text(v.legalName, 1, 200), gstin, billingAddress: text(v.billingAddress) };
}
function change(value: unknown): Change {
  if (!value || typeof value !== "object") fail();
  const kind = (value as Record<string, unknown>).kind;
  if (kind === "name") {
    const v = object(value, ["kind", "displayName"]);
    return { kind, displayName: text(v.displayName).replace(/\s+/gu, " ") };
  }
  if (kind === "delivery") {
    const v = object(value, ["kind", "addresses", "selectedAddressId"]);
    const addresses = list(v.addresses, address); unique(addresses);
    const selectedAddressId = v.selectedAddressId === null ? null : identifier(v.selectedAddressId);
    if (selectedAddressId !== null && !addresses.some(v => v.id === selectedAddressId)) fail();
    return { kind, addresses, selectedAddressId };
  }
  if (kind === "invoices") {
    const v = object(value, ["kind", "invoiceProfiles"]);
    const invoiceProfiles = list(v.invoiceProfiles, invoice); unique(invoiceProfiles);
    return { kind, invoiceProfiles };
  }
  return fail();
}
/** Reject malformed durable data rather than treating it as a new/empty Profile. */
export function decodeStoredAccountProfile(value: unknown, owner: string, expectedRevision: number): AccountProfile {
  try {
    const v = object(value, ["ownerUid", "revision", "updatedAt", "displayName", "addresses", "selectedAddressId", "invoiceProfiles"]);
    if (v.ownerUid !== owner || revision(v.revision) !== expectedRevision) fail();
    const updatedAt = text(v.updatedAt);
    if (!Number.isFinite(Date.parse(updatedAt)) || new Date(updatedAt).toISOString() !== updatedAt) fail();
    const delivery = change({kind:"delivery",addresses:v.addresses,selectedAddressId:v.selectedAddressId});
    const billing = change({kind:"invoices",invoiceProfiles:v.invoiceProfiles});
    if (delivery.kind !== "delivery" || billing.kind !== "invoices") fail();
    return {ownerUid:owner,revision:expectedRevision,updatedAt,
      displayName:v.displayName === null ? null : text(v.displayName,0,120),
      addresses:delivery.addresses,selectedAddressId:delivery.selectedAddressId,invoiceProfiles:billing.invoiceProfiles};
  } catch { throw new AccountProfileError("profile_record_unavailable",503); }
}
export class AccountProfileService {
  constructor(private readonly repository: AccountProfileRepository,
    private readonly projectId: string, private readonly now: () => Date = () => new Date()) {}

  private owner(actor: AccountProfileActor): string {
    if (actor.projectId !== this.projectId || actor.tenantId !== undefined ||
        typeof actor.uid !== "string" || !actor.uid || actor.uid.length > 128 ||
        /[\u0000-\u001f\u007f]/u.test(actor.uid)) fail("account_scope_mismatch", 403);
    return actor.uid;
  }
  private async account(owner: string): Promise<AccountProfile> {
    const account = await this.repository.readAccount(owner);
    if (!account) fail("account_not_ready", 409);
    if (account.uid !== owner) fail("account_scope_mismatch", 403);
    if (account.status !== "ACTIVE") fail("account_restricted", 403);
    if (!account.profile) fail("profile_record_unavailable", 503);
    if (account.profile.ownerUid !== owner) fail("account_scope_mismatch", 403);
    revision(account.profile.revision);
    return structuredClone(account.profile);
  }
  async read(actor: AccountProfileActor): Promise<AccountProfile> {
    return this.account(this.owner(actor));
  }
  private receipt(value: AccountProfileReceipt, owner: string, key: string, fingerprint?: string): AccountProfileReceipt {
    if (value.ownerUid !== owner || value.requestId !== key || value.profile.ownerUid !== owner) {
      fail("account_scope_mismatch", 403);
    }
    if (fingerprint !== undefined && value.fingerprint !== fingerprint) fail("profile_request_conflict", 409);
    return structuredClone(value);
  }
  async reconcile(actor: AccountProfileActor, raw: unknown): Promise<AccountProfileReceipt | null> {
    const owner = this.owner(actor);
    const v = object(raw, ["requestId"]); const key = identifier(v.requestId);
    await this.account(owner);
    const receipt = await this.repository.readReceipt(owner, key);
    return receipt ? this.receipt(receipt, owner, key) : null;
  }
  async save(actor: AccountProfileActor, raw: unknown): Promise<AccountProfileReceipt> {
    // Defensive transport bound; it is not a business limit on item/address count.
    if (Buffer.byteLength(JSON.stringify(raw) ?? "", "utf8") > 65536) fail("profile_request_too_large", 413);
    const owner = this.owner(actor);
    const v = object(raw, ["requestId", "expectedRevision", "change"]);
    const requestId = identifier(v.requestId); const expectedRevision = revision(v.expectedRevision);
    const delta = change(v.change);
    if (delta.kind === "name" && (delta.displayName.length < 2 || delta.displayName.length > 60)) fail();
    const fingerprint = createHash("sha256").update(JSON.stringify({expectedRevision, change: delta})).digest("hex");
    const current = await this.account(owner);
    const previous = await this.repository.readReceipt(owner, requestId);
    if (previous) return this.receipt(previous, owner, requestId, fingerprint);
    if (current.revision !== expectedRevision) fail("profile_revision_conflict", 409);
    const updatedAt = this.now().toISOString();
    const profile: AccountProfile = { ...current, revision: expectedRevision + 1, updatedAt,
      ...(delta.kind === "name" ? {displayName: delta.displayName} : {}),
      ...(delta.kind === "delivery" ? {addresses: delta.addresses, selectedAddressId: delta.selectedAddressId} : {}),
      ...(delta.kind === "invoices" ? {invoiceProfiles: delta.invoiceProfiles} : {}) };
    try {
      const result = await this.repository.commit({ ownerUid: owner, requestId, fingerprint, expectedRevision, profile });
      if (result.state === "applied" || result.state === "replayed") {
        return this.receipt(result.receipt, owner, requestId, fingerprint);
      }
      if (result.state === "restricted") fail("account_restricted", 403);
      if (result.state === "missing") fail("account_not_ready", 409);
      fail("profile_revision_conflict", 409);
    } catch (error) {
      if (error instanceof AccountProfileError) throw error;
      // A transport failure does not prove a failed write. Reconcile only the
      // original identity; never create a second mutation or invent success.
      try {
        const receipt = await this.repository.readReceipt(owner, requestId);
        if (receipt) return this.receipt(receipt, owner, requestId, fingerprint);
      } catch (readError) {
        if (readError instanceof AccountProfileError) throw readError;
      }
      throw new AccountProfileError("profile_outcome_unknown", 503, true);
    }
  }
}
