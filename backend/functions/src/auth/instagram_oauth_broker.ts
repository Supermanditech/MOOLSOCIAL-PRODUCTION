import { createHash, createHmac, randomBytes, timingSafeEqual } from "node:crypto";

import type { Firestore } from "firebase-admin/firestore";

const INSTAGRAM_AUTHORIZATION_ENDPOINT =
  "https://www.instagram.com/oauth/authorize";
const INSTAGRAM_TOKEN_ENDPOINT =
  "https://api.instagram.com/oauth/access_token";
const INSTAGRAM_IDENTITY_ENDPOINT = "https://graph.instagram.com/me";
const INSTAGRAM_REVOCATION_ENDPOINT =
  "https://graph.instagram.com/me/permissions";
const INSTAGRAM_SCOPE = "instagram_business_basic";
const DEFAULT_ATTEMPT_TTL_MS = 5 * 60 * 1000;
const MAX_CALLBACK_URI_LENGTH = 4096;
const MAX_PROVIDER_VALUE_LENGTH = 8192;

export type InstagramPublicAuthErrorCode =
  | "invalid_request"
  | "app_check_required"
  | "attempt_not_found"
  | "attempt_expired"
  | "attempt_replayed"
  | "authorization_denied"
  | "account_ineligible"
  | "provider_unavailable"
  | "identity_unavailable"
  | "token_issue_failed"
  | "revocation_failed"
  | "internal";

export class InstagramPublicAuthError extends Error {
  constructor(
    readonly code: InstagramPublicAuthErrorCode,
    message: string,
    readonly httpStatus: number,
    readonly retryable: boolean,
  ) {
    super(message);
    this.name = "InstagramPublicAuthError";
  }
}

export interface InstagramPendingAttempt {
  readonly stateDigest: string;
  readonly createdAtMs: number;
  readonly expiresAtMs: number;
}

export type InstagramAttemptConsumeResult =
  | { readonly kind: "consumed"; readonly attempt: InstagramPendingAttempt }
  | { readonly kind: "missing" }
  | { readonly kind: "expired" }
  | { readonly kind: "replayed" };

export interface InstagramAttemptStore {
  create(attempt: InstagramPendingAttempt): Promise<void>;
  consume(
    stateDigest: string,
    nowMs: number,
  ): Promise<InstagramAttemptConsumeResult>;
}

export interface InstagramProviderIdentity {
  readonly subject: string;
  readonly accountType: string;
}

export interface InstagramTokenGrant {
  readonly accessToken: string;
  readonly refreshTokenPresent: boolean;
}

export interface InstagramProviderTransport {
  exchangeCode(input: {
    readonly clientId: string;
    readonly redirectUri: string;
    readonly code: string;
  }): Promise<InstagramTokenGrant>;
  readIdentity(accessToken: string): Promise<InstagramProviderIdentity>;
  revokeAccessToken(accessToken: string): Promise<void>;
}

export interface InstagramSubjectProjector {
  project(subject: string): string;
}

export interface InstagramFirebaseTokenIssuer {
  issue(firebaseUid: string): Promise<string>;
}

export interface InstagramRandomSource {
  bytes(length: number): Uint8Array;
}

export type InstagramPublicAuthRequest =
  | { readonly operation: "begin" }
  | { readonly operation: "complete"; readonly callbackUri: string };

export type InstagramPublicAuthResult =
  | {
      readonly operation: "begin";
      readonly authorizationUrl: string;
      readonly expiresAt: string;
    }
  | {
      readonly operation: "complete";
      readonly firebaseCustomToken: string;
    };

export interface InstagramPublicAuthBrokerOptions {
  readonly clientId: string;
  readonly redirectUri: string;
  readonly attemptStore: InstagramAttemptStore;
  readonly transport: InstagramProviderTransport;
  readonly subjectProjector: InstagramSubjectProjector;
  readonly tokenIssuer: InstagramFirebaseTokenIssuer;
  readonly now?: () => number;
  readonly random?: InstagramRandomSource;
  readonly attemptTtlMs?: number;
}

function invalidRequest(): never {
  throw new InstagramPublicAuthError(
    "invalid_request",
    "The Instagram sign-in request is invalid.",
    400,
    false,
  );
}

function objectValue(value: unknown): Record<string, unknown> | undefined {
  return typeof value === "object" && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : undefined;
}

function exactKeys(
  value: Record<string, unknown>,
  expected: readonly string[],
): boolean {
  const actual = Object.keys(value).sort();
  const wanted = [...expected].sort();
  return actual.length === wanted.length &&
    actual.every((key, index) => key === wanted[index]);
}

function boundedText(value: unknown, maximum: number): string | undefined {
  return typeof value === "string" &&
    value.length > 0 &&
    value.length <= maximum &&
    !/[\u0000-\u001F\u007F]/u.test(value)
    ? value
    : undefined;
}

export function parseInstagramPublicAuthRequest(
  path: string,
  value: unknown,
): InstagramPublicAuthRequest {
  const body = objectValue(value);
  if (!body) invalidRequest();
  if (path === "/instagram/begin") {
    if (!exactKeys(body, [])) invalidRequest();
    return { operation: "begin" };
  }
  if (path === "/instagram/complete") {
    if (!exactKeys(body, ["callbackUri"])) invalidRequest();
    const callbackUri = boundedText(body.callbackUri, MAX_CALLBACK_URI_LENGTH);
    if (!callbackUri) invalidRequest();
    return { operation: "complete", callbackUri };
  }
  invalidRequest();
}

export class SystemInstagramRandomSource implements InstagramRandomSource {
  bytes(length: number): Uint8Array {
    return randomBytes(length);
  }
}

type StoredInstagramAttempt =
  | {
      readonly status: "pending";
      readonly createdAtMs: number;
      readonly expiresAtMs: number;
      readonly expiresAt: Date;
    }
  | {
      readonly status: "consumed";
      readonly createdAtMs: number;
      readonly expiresAtMs: number;
      readonly expiresAt: Date;
    };

function storedInstagramAttempt(
  value: unknown,
): StoredInstagramAttempt | undefined {
  const body = objectValue(value);
  if (
    !body ||
    !exactKeys(body, ["status", "createdAtMs", "expiresAtMs", "expiresAt"])
  ) {
    return undefined;
  }
  const createdAtMs = body.createdAtMs;
  const expiresAtMs = body.expiresAtMs;
  const expiresAtValue = body.expiresAt;
  let expiresAt: number | undefined;
  if (expiresAtValue instanceof Date) {
    expiresAt = expiresAtValue.getTime();
  } else if (
    typeof expiresAtValue === "object" &&
    expiresAtValue !== null &&
    "toMillis" in expiresAtValue &&
    typeof expiresAtValue.toMillis === "function"
  ) {
    try {
      expiresAt = expiresAtValue.toMillis();
    } catch {
      expiresAt = undefined;
    }
  }
  if (
    !Number.isSafeInteger(createdAtMs) ||
    !Number.isSafeInteger(expiresAtMs) ||
    !Number.isSafeInteger(expiresAt) ||
    expiresAt !== expiresAtMs ||
    (createdAtMs as number) < 0 ||
    (expiresAtMs as number) <= (createdAtMs as number) ||
    (body.status !== "pending" && body.status !== "consumed")
  ) {
    return undefined;
  }
  return {
    status: body.status,
    createdAtMs: createdAtMs as number,
    expiresAtMs: expiresAtMs as number,
    expiresAt: new Date(expiresAtMs as number),
  };
}

export class FirestoreInstagramAttemptStore implements InstagramAttemptStore {
  constructor(
    private readonly firestore: Firestore,
    private readonly collectionPath = "publicAuthInstagramOAuthAttempts",
  ) {}

  async create(attempt: InstagramPendingAttempt): Promise<void> {
    const reference = this.firestore
      .collection(this.collectionPath)
      .doc(attempt.stateDigest);
    await this.firestore.runTransaction(async (transaction) => {
      if ((await transaction.get(reference)).exists) {
        throw new InstagramPublicAuthError(
          "internal",
          "Instagram sign-in could not be started.",
          500,
          true,
        );
      }
      transaction.create(reference, {
        status: "pending",
        createdAtMs: attempt.createdAtMs,
        expiresAtMs: attempt.expiresAtMs,
        expiresAt: new Date(attempt.expiresAtMs),
      } satisfies StoredInstagramAttempt);
    });
  }

  async consume(
    stateDigest: string,
    nowMs: number,
  ): Promise<InstagramAttemptConsumeResult> {
    const reference = this.firestore
      .collection(this.collectionPath)
      .doc(stateDigest);
    return this.firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(reference);
      if (!snapshot.exists) return { kind: "missing" };
      const stored = storedInstagramAttempt(snapshot.data());
      if (!stored) {
        transaction.delete(reference);
        return { kind: "missing" };
      }
      if (stored.status === "consumed") {
        if (nowMs >= stored.expiresAtMs) transaction.delete(reference);
        return { kind: "replayed" };
      }
      transaction.set(reference, {
        status: "consumed",
        createdAtMs: stored.createdAtMs,
        expiresAtMs: stored.expiresAtMs,
        expiresAt: stored.expiresAt,
      } satisfies StoredInstagramAttempt);
      if (nowMs >= stored.expiresAtMs) return { kind: "expired" };
      return {
        kind: "consumed",
        attempt: {
          stateDigest,
          createdAtMs: stored.createdAtMs,
          expiresAtMs: stored.expiresAtMs,
        },
      };
    });
  }
}

function stateDigest(value: string): string {
  return createHash("sha256").update(value, "utf8").digest("hex");
}

function configuredRedirect(value: string): URL {
  let redirect: URL;
  try {
    redirect = new URL(value);
  } catch {
    throw new Error("Instagram redirect configuration is invalid.");
  }
  if (
    !["https:", "moolsocial:"].includes(redirect.protocol) ||
    redirect.username ||
    redirect.password ||
    redirect.search ||
    redirect.hash
  ) {
    throw new Error("Instagram redirect configuration is invalid.");
  }
  return redirect;
}

function redirectIdentity(value: URL): string {
  return [
    value.protocol,
    value.hostname.toLowerCase(),
    value.port,
    value.pathname,
  ].join("|");
}

function sameText(left: string, right: string): boolean {
  const leftBytes = Buffer.from(left, "utf8");
  const rightBytes = Buffer.from(right, "utf8");
  return leftBytes.length === rightBytes.length &&
    timingSafeEqual(leftBytes, rightBytes);
}

interface InstagramCallback {
  readonly state: string;
  readonly code?: string;
  readonly denied: boolean;
  readonly providerError?: string;
}

function parseCallback(
  callbackUri: string,
  redirect: URL,
): InstagramCallback {
  let callback: URL;
  try {
    callback = new URL(callbackUri);
  } catch {
    invalidRequest();
  }
  if (
    callback.username ||
    callback.password ||
    callback.hash ||
    !sameText(redirectIdentity(callback), redirectIdentity(redirect))
  ) {
    invalidRequest();
  }
  const allowed = new Set(["state", "code", "error", "error_reason", "error_description"]);
  const values = new Map<string, string[]>();
  for (const [key, value] of callback.searchParams.entries()) {
    if (!allowed.has(key)) invalidRequest();
    const prior = values.get(key) ?? [];
    prior.push(value);
    values.set(key, prior);
  }
  const one = (key: string): string | undefined => {
    const candidates = values.get(key) ?? [];
    if (candidates.length > 1) invalidRequest();
    return candidates[0];
  };
  const state = one("state");
  if (!state || !/^[A-Za-z0-9_-]{43}$/u.test(state)) invalidRequest();
  const code = one("code");
  const error = one("error");
  const errorReason = one("error_reason");
  const errorDescription = one("error_description");
  if (error !== undefined) {
    if (
      code !== undefined ||
      !boundedText(error, 128) ||
      !/^[A-Za-z0-9_:-]+$/u.test(error) ||
      (errorReason !== undefined && !boundedText(errorReason, 128)) ||
      (errorDescription !== undefined && !boundedText(errorDescription, 512))
    ) {
      invalidRequest();
    }
    return {
      state,
      denied: error === "access_denied" || error === "user_denied",
      providerError: error,
    };
  }
  if (errorReason !== undefined || errorDescription !== undefined) invalidRequest();
  const cleanCode = boundedText(code, 2048);
  if (!cleanCode) invalidRequest();
  return { state, code: cleanCode, denied: false };
}

function attemptFailure(
  result: Exclude<InstagramAttemptConsumeResult, { kind: "consumed" }>,
): never {
  const contract = {
    missing: ["attempt_not_found", "This Instagram sign-in request is no longer available. Start again.", 404],
    expired: ["attempt_expired", "This Instagram sign-in request expired. Start again.", 410],
    replayed: ["attempt_replayed", "This Instagram sign-in request was already used. Start again.", 409],
  } as const;
  const [code, message, status] = contract[result.kind];
  throw new InstagramPublicAuthError(code, message, status, true);
}

function providerFailure(): InstagramPublicAuthError {
  return new InstagramPublicAuthError(
    "provider_unavailable",
    "Instagram sign-in is temporarily unavailable. Try again.",
    503,
    true,
  );
}

export class HmacInstagramSubjectProjector
  implements InstagramSubjectProjector
{
  private readonly projectId: string;
  private readonly key: Buffer;

  constructor(projectId: string, key: string | Uint8Array) {
    const cleanProjectId = projectId.trim();
    const keyBytes = typeof key === "string"
      ? Buffer.from(key, "base64url")
      : Buffer.from(key);
    if (!/^[a-z][a-z0-9-]{4,62}$/u.test(cleanProjectId) || keyBytes.length < 32) {
      throw new Error("Instagram subject projection configuration is invalid.");
    }
    this.projectId = cleanProjectId;
    this.key = keyBytes;
  }

  project(subject: string): string {
    if (!/^[0-9]{1,32}$/u.test(subject)) {
      throw new InstagramPublicAuthError(
        "identity_unavailable",
        "The Instagram account identity could not be verified.",
        502,
        true,
      );
    }
    const digest = createHmac("sha256", this.key)
      .update("moolsocial-public-auth\0", "utf8")
      .update(this.projectId, "utf8")
      .update("\0instagram\0", "utf8")
      .update(subject, "utf8")
      .digest("base64url");
    return `instagram_${digest}`;
  }
}

interface FirebaseCustomTokenCreator {
  createCustomToken(uid: string, developerClaims?: object): Promise<string>;
}

export class FirebaseAdminInstagramTokenIssuer
  implements InstagramFirebaseTokenIssuer
{
  constructor(private readonly auth: FirebaseCustomTokenCreator) {}

  issue(firebaseUid: string): Promise<string> {
    return this.auth.createCustomToken(firebaseUid, {
      auth_provider: "instagram",
    });
  }
}

export class InstagramPublicAuthBroker {
  private readonly clientId: string;
  private readonly redirectUri: string;
  private readonly redirect: URL;
  private readonly attemptStore: InstagramAttemptStore;
  private readonly transport: InstagramProviderTransport;
  private readonly subjectProjector: InstagramSubjectProjector;
  private readonly tokenIssuer: InstagramFirebaseTokenIssuer;
  private readonly now: () => number;
  private readonly random: InstagramRandomSource;
  private readonly attemptTtlMs: number;

  constructor(options: InstagramPublicAuthBrokerOptions) {
    const clientId = boundedText(options.clientId.trim(), 256);
    const attemptTtlMs = options.attemptTtlMs ?? DEFAULT_ATTEMPT_TTL_MS;
    if (
      !clientId ||
      !/^[A-Za-z0-9_-]+$/u.test(clientId) ||
      !Number.isSafeInteger(attemptTtlMs) ||
      attemptTtlMs < 60_000 ||
      attemptTtlMs > 10 * 60 * 1000
    ) {
      throw new Error("Instagram public-client configuration is invalid.");
    }
    this.clientId = clientId;
    this.redirect = configuredRedirect(options.redirectUri);
    this.redirectUri = this.redirect.toString();
    this.attemptStore = options.attemptStore;
    this.transport = options.transport;
    this.subjectProjector = options.subjectProjector;
    this.tokenIssuer = options.tokenIssuer;
    this.now = options.now ?? Date.now;
    this.random = options.random ?? new SystemInstagramRandomSource();
    this.attemptTtlMs = attemptTtlMs;
  }

  execute(
    request: InstagramPublicAuthRequest,
  ): Promise<InstagramPublicAuthResult> {
    return request.operation === "begin"
      ? this.begin()
      : this.complete(request.callbackUri);
  }

  async begin(): Promise<InstagramPublicAuthResult> {
    const nowMs = this.now();
    if (!Number.isSafeInteger(nowMs) || nowMs < 0) {
      throw new InstagramPublicAuthError(
        "internal",
        "Instagram sign-in could not be started.",
        500,
        true,
      );
    }
    const state = Buffer.from(this.random.bytes(32)).toString("base64url");
    if (!/^[A-Za-z0-9_-]{43}$/u.test(state)) {
      throw new InstagramPublicAuthError(
        "internal",
        "Instagram sign-in could not be started.",
        500,
        true,
      );
    }
    const expiresAtMs = nowMs + this.attemptTtlMs;
    try {
      await this.attemptStore.create({
        stateDigest: stateDigest(state),
        createdAtMs: nowMs,
        expiresAtMs,
      });
    } catch (error) {
      if (error instanceof InstagramPublicAuthError) throw error;
      throw new InstagramPublicAuthError(
        "internal",
        "Instagram sign-in could not be started.",
        500,
        true,
      );
    }
    const authorizationUrl = new URL(INSTAGRAM_AUTHORIZATION_ENDPOINT);
    authorizationUrl.searchParams.set("response_type", "code");
    authorizationUrl.searchParams.set("client_id", this.clientId);
    authorizationUrl.searchParams.set("redirect_uri", this.redirectUri);
    authorizationUrl.searchParams.set("scope", INSTAGRAM_SCOPE);
    authorizationUrl.searchParams.set("state", state);
    return {
      operation: "begin",
      authorizationUrl: authorizationUrl.toString(),
      expiresAt: new Date(expiresAtMs).toISOString(),
    };
  }

  async complete(callbackUri: string): Promise<InstagramPublicAuthResult> {
    const callback = parseCallback(callbackUri, this.redirect);
    let consumed: InstagramAttemptConsumeResult;
    try {
      consumed = await this.attemptStore.consume(
        stateDigest(callback.state),
        this.now(),
      );
    } catch {
      throw new InstagramPublicAuthError(
        "internal",
        "Instagram sign-in could not be completed.",
        500,
        true,
      );
    }
    if (consumed.kind !== "consumed") attemptFailure(consumed);
    if (callback.denied) {
      throw new InstagramPublicAuthError(
        "authorization_denied",
        "Instagram sign-in was not approved.",
        403,
        true,
      );
    }
    if (callback.providerError) throw providerFailure();
    if (!callback.code) invalidRequest();

    let grant: InstagramTokenGrant;
    try {
      grant = await this.transport.exchangeCode({
        clientId: this.clientId,
        redirectUri: this.redirectUri,
        code: callback.code,
      });
    } catch {
      throw providerFailure();
    }
    const accessToken = boundedText(
      grant.accessToken,
      MAX_PROVIDER_VALUE_LENGTH,
    );
    if (!accessToken) throw providerFailure();

    let completionError: InstagramPublicAuthError | undefined;
    let customToken: string | undefined;
    try {
      if (grant.refreshTokenPresent) throw providerFailure();
      let identity: InstagramProviderIdentity;
      try {
        identity = await this.transport.readIdentity(accessToken);
      } catch {
        throw new InstagramPublicAuthError(
          "identity_unavailable",
          "The Instagram account identity could not be verified.",
          502,
          true,
        );
      }
      if (!["BUSINESS", "MEDIA_CREATOR"].includes(identity.accountType)) {
        throw new InstagramPublicAuthError(
          "account_ineligible",
          "Instagram sign-in requires an eligible professional account.",
          403,
          false,
        );
      }
      const firebaseUid = this.subjectProjector.project(identity.subject);
      try {
        customToken = await this.tokenIssuer.issue(firebaseUid);
      } catch {
        throw new InstagramPublicAuthError(
          "token_issue_failed",
          "MoolSocial could not finish Instagram sign-in. Try again.",
          503,
          true,
        );
      }
      if (!boundedText(customToken, MAX_PROVIDER_VALUE_LENGTH)) {
        throw new InstagramPublicAuthError(
          "token_issue_failed",
          "MoolSocial could not finish Instagram sign-in. Try again.",
          503,
          true,
        );
      }
    } catch (error) {
      completionError = error instanceof InstagramPublicAuthError
        ? error
        : providerFailure();
    }

    try {
      await this.transport.revokeAccessToken(accessToken);
    } catch {
      throw new InstagramPublicAuthError(
        "revocation_failed",
        "Instagram sign-in could not be secured. Start again.",
        503,
        true,
      );
    }
    if (completionError) throw completionError;
    if (!customToken) {
      throw new InstagramPublicAuthError(
        "internal",
        "Instagram sign-in could not be completed.",
        500,
        true,
      );
    }
    return { operation: "complete", firebaseCustomToken: customToken };
  }
}

async function providerJson(
  response: Response,
): Promise<Record<string, unknown> | undefined> {
  const stream = response.body;
  if (!stream) return undefined;
  const reader = stream.getReader();
  const chunks: Buffer[] = [];
  let byteLength = 0;
  try {
    while (true) {
      const part = await reader.read();
      if (part.done) break;
      if (!part.value) return undefined;
      byteLength += part.value.byteLength;
      if (byteLength > 64 * 1024) {
        await reader.cancel().catch(() => undefined);
        return undefined;
      }
      chunks.push(Buffer.from(part.value));
    }
  } catch {
    return undefined;
  }
  const text = Buffer.concat(chunks, byteLength).toString("utf8");
  if (text.length === 0 || text.length > 64 * 1024) return undefined;
  try {
    return objectValue(JSON.parse(text) as unknown);
  } catch {
    return undefined;
  }
}

export class FetchInstagramProviderTransport
  implements InstagramProviderTransport
{
  private readonly clientSecret: string;

  constructor(
    clientSecret: string,
    private readonly fetchImplementation: typeof fetch = fetch,
    private readonly timeoutMs = 10_000,
  ) {
    const cleanSecret = boundedText(clientSecret.trim(), 512);
    if (
      !cleanSecret ||
      !Number.isSafeInteger(timeoutMs) ||
      timeoutMs < 1_000 ||
      timeoutMs > 30_000
    ) {
      throw new Error("Instagram provider configuration is invalid.");
    }
    this.clientSecret = cleanSecret;
  }

  async exchangeCode(input: {
    readonly clientId: string;
    readonly redirectUri: string;
    readonly code: string;
  }): Promise<InstagramTokenGrant> {
    const form = new URLSearchParams();
    form.set("client_id", input.clientId);
    form.set("client_secret", this.clientSecret);
    form.set("grant_type", "authorization_code");
    form.set("redirect_uri", input.redirectUri);
    form.set("code", input.code);
    let response: Response;
    try {
      response = await this.fetchImplementation(INSTAGRAM_TOKEN_ENDPOINT, {
        method: "POST",
        headers: {
          accept: "application/json",
          "content-type": "application/x-www-form-urlencoded",
        },
        body: form.toString(),
        redirect: "error",
        signal: AbortSignal.timeout(this.timeoutMs),
      });
    } catch {
      throw providerFailure();
    }
    if (!response.ok) throw providerFailure();
    const body = await providerJson(response);
    const accessToken = boundedText(
      body?.access_token,
      MAX_PROVIDER_VALUE_LENGTH,
    );
    if (!accessToken) throw providerFailure();
    return {
      accessToken,
      refreshTokenPresent: "refresh_token" in (body ?? {}),
    };
  }

  async readIdentity(accessToken: string): Promise<InstagramProviderIdentity> {
    const endpoint = new URL(INSTAGRAM_IDENTITY_ENDPOINT);
    endpoint.searchParams.set("fields", "id,account_type");
    let response: Response;
    try {
      response = await this.fetchImplementation(endpoint, {
        method: "GET",
        headers: {
          accept: "application/json",
          authorization: `Bearer ${accessToken}`,
        },
        redirect: "error",
        signal: AbortSignal.timeout(this.timeoutMs),
      });
    } catch {
      throw providerFailure();
    }
    if (!response.ok) throw providerFailure();
    const body = await providerJson(response);
    const subject = boundedText(body?.id, 32);
    const accountType = boundedText(body?.account_type, 32);
    if (!subject || !/^[0-9]{1,32}$/u.test(subject) || !accountType) {
      throw new InstagramPublicAuthError(
        "identity_unavailable",
        "The Instagram account identity could not be verified.",
        502,
        true,
      );
    }
    return { subject, accountType };
  }

  async revokeAccessToken(accessToken: string): Promise<void> {
    let response: Response;
    try {
      response = await this.fetchImplementation(INSTAGRAM_REVOCATION_ENDPOINT, {
        method: "DELETE",
        headers: {
          accept: "application/json",
          authorization: `Bearer ${accessToken}`,
        },
        redirect: "error",
        signal: AbortSignal.timeout(this.timeoutMs),
      });
    } catch {
      throw providerFailure();
    }
    if (!response.ok) throw providerFailure();
  }
}
