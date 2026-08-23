import {
  createHash,
  createHmac,
  randomBytes,
  timingSafeEqual,
} from "node:crypto";

import type { Firestore } from "firebase-admin/firestore";

const X_AUTHORIZATION_ENDPOINT = "https://x.com/i/oauth2/authorize";
const X_TOKEN_ENDPOINT = "https://api.x.com/2/oauth2/token";
const X_SUBJECT_ENDPOINT = "https://api.x.com/2/users/me";
const X_REVOCATION_ENDPOINT = "https://api.x.com/2/oauth2/revoke";
const X_SCOPES = ["tweet.read", "users.read"] as const;
const DEFAULT_ATTEMPT_TTL_MS = 5 * 60 * 1000;
const MAX_CALLBACK_URI_LENGTH = 4096;
const MAX_PROVIDER_VALUE_LENGTH = 8192;

export const X_PUBLIC_AUTH_MAX_REQUEST_BODY_BYTES = 8 * 1024;

export type XPublicAuthErrorCode =
  | "invalid_request"
  | "app_check_required"
  | "attempt_not_found"
  | "attempt_expired"
  | "attempt_replayed"
  | "authorization_denied"
  | "provider_unavailable"
  | "identity_unavailable"
  | "token_issue_failed"
  | "revocation_failed"
  | "internal";

export class XPublicAuthError extends Error {
  constructor(
    readonly code: XPublicAuthErrorCode,
    message: string,
    readonly httpStatus: number,
    readonly retryable: boolean,
  ) {
    super(message);
    this.name = "XPublicAuthError";
  }
}

export interface XPendingAttempt {
  readonly stateDigest: string;
  readonly codeVerifier: string;
  readonly createdAtMs: number;
  readonly expiresAtMs: number;
}

export type XAttemptConsumeResult =
  | { readonly kind: "consumed"; readonly attempt: XPendingAttempt }
  | { readonly kind: "missing" }
  | { readonly kind: "expired" }
  | { readonly kind: "replayed" };

export interface XAttemptStore {
  create(attempt: XPendingAttempt): Promise<void>;
  consume(stateDigest: string, nowMs: number): Promise<XAttemptConsumeResult>;
}

export interface XTokenGrant {
  readonly accessToken: string;
  readonly tokenType: string;
  readonly scopes: readonly string[];
  readonly refreshTokenPresent: boolean;
}

export interface XProviderTransport {
  exchangeCode(input: {
    readonly clientId: string;
    readonly redirectUri: string;
    readonly code: string;
    readonly codeVerifier: string;
  }): Promise<XTokenGrant>;
  readSubject(accessToken: string): Promise<string>;
  revokeAccessToken(input: {
    readonly clientId: string;
    readonly accessToken: string;
  }): Promise<void>;
}

export interface XSubjectProjector {
  project(subject: string): string;
}

export interface XFirebaseTokenIssuer {
  issue(firebaseUid: string): Promise<string>;
}

export interface XRandomSource {
  bytes(length: number): Uint8Array;
}

export type XPublicAuthRequest =
  | { readonly operation: "begin" }
  | { readonly operation: "complete"; readonly callbackUri: string };

export type XPublicAuthResult =
  | {
      readonly operation: "begin";
      readonly authorizationUrl: string;
      readonly expiresAt: string;
    }
  | {
      readonly operation: "complete";
      readonly firebaseCustomToken: string;
    };

export interface XPublicAuthBrokerOptions {
  readonly clientId: string;
  readonly redirectUri: string;
  readonly attemptStore: XAttemptStore;
  readonly transport: XProviderTransport;
  readonly subjectProjector: XSubjectProjector;
  readonly tokenIssuer: XFirebaseTokenIssuer;
  readonly now?: () => number;
  readonly random?: XRandomSource;
  readonly attemptTtlMs?: number;
}

function invalidRequest(message = "The X sign-in request is invalid."): never {
  throw new XPublicAuthError("invalid_request", message, 400, false);
}

function plainObject(value: unknown): Record<string, unknown> {
  if (
    typeof value !== "object" ||
    value === null ||
    Array.isArray(value) ||
    Object.getPrototypeOf(value) !== Object.prototype
  ) {
    invalidRequest();
  }
  return value as Record<string, unknown>;
}

function hasExactKeys(
  value: Record<string, unknown>,
  expected: readonly string[],
): boolean {
  const actual = Object.keys(value).sort();
  const sortedExpected = [...expected].sort();
  return (
    actual.length === sortedExpected.length &&
    actual.every((key, index) => key === sortedExpected[index])
  );
}

function boundedText(
  value: unknown,
  maximumLength: number,
): string | undefined {
  if (typeof value !== "string" || value.length === 0) return undefined;
  if (value.length > maximumLength || /[\u0000-\u001F\u007F]/u.test(value)) {
    return undefined;
  }
  return value;
}

export function parseXPublicAuthRequest(
  path: string,
  value: unknown,
): XPublicAuthRequest {
  const body = plainObject(value);
  if (path === "/x/begin") {
    if (!hasExactKeys(body, [])) invalidRequest();
    return { operation: "begin" };
  }
  if (path === "/x/complete") {
    if (!hasExactKeys(body, ["callbackUri"])) invalidRequest();
    const callbackUri = boundedText(
      body.callbackUri,
      MAX_CALLBACK_URI_LENGTH,
    );
    if (!callbackUri) invalidRequest();
    return { operation: "complete", callbackUri };
  }
  invalidRequest();
}

export class SystemXRandomSource implements XRandomSource {
  bytes(length: number): Uint8Array {
    return randomBytes(length);
  }
}

type StoredAttempt =
  | {
      readonly status: "pending";
      readonly codeVerifier: string;
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

function finiteTimestamp(value: unknown): number | undefined {
  return Number.isSafeInteger(value) && (value as number) >= 0
    ? (value as number)
    : undefined;
}

function firestoreTimestamp(value: unknown): number | undefined {
  if (value instanceof Date) return finiteTimestamp(value.getTime());
  if (
    typeof value !== "object" ||
    value === null ||
    !("toMillis" in value) ||
    typeof value.toMillis !== "function"
  ) {
    return undefined;
  }
  try {
    return finiteTimestamp(value.toMillis());
  } catch {
    return undefined;
  }
}

function normalizeStoredAttempt(value: unknown): StoredAttempt | undefined {
  if (
    typeof value !== "object" ||
    value === null ||
    Array.isArray(value) ||
    Object.getPrototypeOf(value) !== Object.prototype
  ) {
    return undefined;
  }
  const body = value as Record<string, unknown>;
  const createdAtMs = finiteTimestamp(body.createdAtMs);
  const expiresAtMs = finiteTimestamp(body.expiresAtMs);
  const expiresAt = firestoreTimestamp(body.expiresAt);
  if (
    createdAtMs === undefined ||
    expiresAtMs === undefined ||
    expiresAt === undefined ||
    expiresAt !== expiresAtMs ||
    expiresAtMs <= createdAtMs
  ) {
    return undefined;
  }
  if (body.status === "pending") {
    if (!hasExactKeys(body, ["status", "codeVerifier", "createdAtMs", "expiresAtMs", "expiresAt"])) {
      return undefined;
    }
    const codeVerifier = boundedText(body.codeVerifier, 128);
    if (!codeVerifier || !/^[A-Za-z0-9_-]{43,128}$/u.test(codeVerifier)) {
      return undefined;
    }
    return {
      status: "pending",
      codeVerifier,
      createdAtMs,
      expiresAtMs,
      expiresAt: new Date(expiresAtMs),
    };
  }
  if (body.status === "consumed") {
    if (!hasExactKeys(body, ["status", "createdAtMs", "expiresAtMs", "expiresAt"])) {
      return undefined;
    }
    return {
      status: "consumed",
      createdAtMs,
      expiresAtMs,
      expiresAt: new Date(expiresAtMs),
    };
  }
  return undefined;
}

export class FirestoreXAttemptStore implements XAttemptStore {
  constructor(
    private readonly firestore: Firestore,
    private readonly collectionPath = "publicAuthXPKCEAttempts",
  ) {}

  async create(attempt: XPendingAttempt): Promise<void> {
    const reference = this.firestore
      .collection(this.collectionPath)
      .doc(attempt.stateDigest);
    await this.firestore.runTransaction(async (transaction) => {
      const existing = await transaction.get(reference);
      if (existing.exists) {
        throw new XPublicAuthError(
          "internal",
          "X sign-in could not be started.",
          500,
          true,
        );
      }
      transaction.create(reference, {
        status: "pending",
        codeVerifier: attempt.codeVerifier,
        createdAtMs: attempt.createdAtMs,
        expiresAtMs: attempt.expiresAtMs,
        expiresAt: new Date(attempt.expiresAtMs),
      } satisfies StoredAttempt);
    });
  }

  async consume(
    stateDigest: string,
    nowMs: number,
  ): Promise<XAttemptConsumeResult> {
    const reference = this.firestore
      .collection(this.collectionPath)
      .doc(stateDigest);
    return this.firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(reference);
      if (!snapshot.exists) return { kind: "missing" };
      const stored = normalizeStoredAttempt(snapshot.data());
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
      } satisfies StoredAttempt);
      if (nowMs >= stored.expiresAtMs) return { kind: "expired" };
      return {
        kind: "consumed",
        attempt: { stateDigest, ...stored },
      };
    });
  }
}

function base64Url(value: Uint8Array): string {
  return Buffer.from(value).toString("base64url");
}

function sha256Base64Url(value: string): string {
  return createHash("sha256").update(value, "utf8").digest("base64url");
}

function sha256Hex(value: string): string {
  return createHash("sha256").update(value, "utf8").digest("hex");
}

function constantTimeTextEqual(left: string, right: string): boolean {
  const leftBytes = Buffer.from(left, "utf8");
  const rightBytes = Buffer.from(right, "utf8");
  return (
    leftBytes.byteLength === rightBytes.byteLength &&
    timingSafeEqual(leftBytes, rightBytes)
  );
}

function normalizedRedirect(value: string): URL {
  let redirect: URL;
  try {
    redirect = new URL(value);
  } catch {
    throw new Error("X redirect configuration is invalid.");
  }
  if (
    !["https:", "moolsocial:"].includes(redirect.protocol) ||
    redirect.username ||
    redirect.password ||
    redirect.search ||
    redirect.hash
  ) {
    throw new Error("X redirect configuration is invalid.");
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

interface XCallbackResult {
  readonly state: string;
  readonly code?: string;
  readonly denied: boolean;
  readonly providerError?: string;
}

function parseCallbackUri(
  callbackUri: string,
  configuredRedirect: URL,
): XCallbackResult {
  let callback: URL;
  try {
    callback = new URL(callbackUri);
  } catch {
    invalidRequest("The X sign-in response is invalid.");
  }
  if (
    callback.username ||
    callback.password ||
    callback.hash ||
    !constantTimeTextEqual(
      redirectIdentity(callback),
      redirectIdentity(configuredRedirect),
    )
  ) {
    invalidRequest("The X sign-in response is invalid.");
  }

  const allowed = new Set(["state", "code", "error", "error_description"]);
  const values = new Map<string, string[]>();
  for (const [key, value] of callback.searchParams.entries()) {
    if (!allowed.has(key)) invalidRequest("The X sign-in response is invalid.");
    const prior = values.get(key) ?? [];
    prior.push(value);
    values.set(key, prior);
  }
  const one = (name: string): string | undefined => {
    const candidates = values.get(name) ?? [];
    if (candidates.length > 1) {
      invalidRequest("The X sign-in response is invalid.");
    }
    return candidates[0];
  };
  const state = one("state");
  if (!state || !/^[A-Za-z0-9_-]{43}$/u.test(state)) {
    invalidRequest("The X sign-in response is invalid.");
  }
  const code = one("code");
  const providerError = one("error");
  const errorDescription = one("error_description");
  if (errorDescription !== undefined && !providerError) {
    invalidRequest("The X sign-in response is invalid.");
  }
  if (providerError !== undefined) {
    if (
      code !== undefined ||
      !boundedText(providerError, 128) ||
      !/^[A-Za-z0-9_:-]+$/u.test(providerError) ||
      (errorDescription !== undefined && !boundedText(errorDescription, 512))
    ) {
      invalidRequest("The X sign-in response is invalid.");
    }
    return {
      state,
      denied: providerError === "access_denied",
      providerError,
    };
  }
  const cleanCode = boundedText(code, 2048);
  if (!cleanCode || errorDescription !== undefined) {
    invalidRequest("The X sign-in response is invalid.");
  }
  return { state, code: cleanCode, denied: false };
}

function attemptFailure(result: Exclude<XAttemptConsumeResult, { kind: "consumed" }>): never {
  switch (result.kind) {
    case "missing":
      throw new XPublicAuthError(
        "attempt_not_found",
        "This X sign-in request is no longer available. Start again.",
        404,
        true,
      );
    case "expired":
      throw new XPublicAuthError(
        "attempt_expired",
        "This X sign-in request expired. Start again.",
        410,
        true,
      );
    case "replayed":
      throw new XPublicAuthError(
        "attempt_replayed",
        "This X sign-in request was already used. Start again.",
        409,
        true,
      );
  }
}

function providerFailure(): XPublicAuthError {
  return new XPublicAuthError(
    "provider_unavailable",
    "X sign-in is temporarily unavailable. Try again.",
    503,
    true,
  );
}

function validateExactGrant(grant: XTokenGrant): string {
  const accessToken = boundedText(grant.accessToken, MAX_PROVIDER_VALUE_LENGTH);
  if (!accessToken) throw providerFailure();
  const scopes = [...grant.scopes].sort();
  const required = [...X_SCOPES].sort();
  if (
    grant.tokenType.toLowerCase() !== "bearer" ||
    grant.refreshTokenPresent ||
    scopes.length !== required.length ||
    !scopes.every((scope, index) => scope === required[index])
  ) {
    throw providerFailure();
  }
  return accessToken;
}

export class HmacXSubjectProjector implements XSubjectProjector {
  private readonly projectId: string;
  private readonly key: Buffer;

  constructor(projectId: string, key: string | Uint8Array) {
    const cleanProjectId = projectId.trim();
    const keyBytes =
      typeof key === "string" ? Buffer.from(key, "base64url") : Buffer.from(key);
    if (!/^[a-z][a-z0-9-]{4,62}$/u.test(cleanProjectId) || keyBytes.length < 32) {
      throw new Error("X subject projection configuration is invalid.");
    }
    this.projectId = cleanProjectId;
    this.key = keyBytes;
  }

  project(subject: string): string {
    if (!/^[0-9]{1,32}$/u.test(subject)) {
      throw new XPublicAuthError(
        "identity_unavailable",
        "The X account identity could not be verified.",
        502,
        true,
      );
    }
    const digest = createHmac("sha256", this.key)
      .update("moolsocial-public-auth\0", "utf8")
      .update(this.projectId, "utf8")
      .update("\0x\0", "utf8")
      .update(subject, "utf8")
      .digest("base64url");
    return `x_${digest}`;
  }
}

interface FirebaseCustomTokenCreator {
  createCustomToken(
    uid: string,
    developerClaims?: object,
  ): Promise<string>;
}

export class FirebaseAdminXTokenIssuer implements XFirebaseTokenIssuer {
  constructor(private readonly auth: FirebaseCustomTokenCreator) {}

  issue(firebaseUid: string): Promise<string> {
    return this.auth.createCustomToken(firebaseUid, { auth_provider: "x" });
  }
}

export class XPublicAuthBroker {
  private readonly clientId: string;
  private readonly redirectUri: string;
  private readonly redirect: URL;
  private readonly attemptStore: XAttemptStore;
  private readonly transport: XProviderTransport;
  private readonly subjectProjector: XSubjectProjector;
  private readonly tokenIssuer: XFirebaseTokenIssuer;
  private readonly now: () => number;
  private readonly random: XRandomSource;
  private readonly attemptTtlMs: number;

  constructor(options: XPublicAuthBrokerOptions) {
    const clientId = boundedText(options.clientId.trim(), 256);
    const attemptTtlMs = options.attemptTtlMs ?? DEFAULT_ATTEMPT_TTL_MS;
    if (
      !clientId ||
      !/^[A-Za-z0-9_-]+$/u.test(clientId) ||
      !Number.isSafeInteger(attemptTtlMs) ||
      attemptTtlMs < 60_000 ||
      attemptTtlMs > 10 * 60 * 1000
    ) {
      throw new Error("X public-client configuration is invalid.");
    }
    this.clientId = clientId;
    this.redirect = normalizedRedirect(options.redirectUri);
    this.redirectUri = this.redirect.toString();
    this.attemptStore = options.attemptStore;
    this.transport = options.transport;
    this.subjectProjector = options.subjectProjector;
    this.tokenIssuer = options.tokenIssuer;
    this.now = options.now ?? Date.now;
    this.random = options.random ?? new SystemXRandomSource();
    this.attemptTtlMs = attemptTtlMs;
  }

  execute(request: XPublicAuthRequest): Promise<XPublicAuthResult> {
    return request.operation === "begin"
      ? this.begin()
      : this.complete(request.callbackUri);
  }

  async begin(): Promise<XPublicAuthResult> {
    const nowMs = this.now();
    if (!Number.isSafeInteger(nowMs) || nowMs < 0) {
      throw new XPublicAuthError(
        "internal",
        "X sign-in could not be started.",
        500,
        true,
      );
    }
    const state = base64Url(this.random.bytes(32));
    const codeVerifier = base64Url(this.random.bytes(32));
    if (
      !/^[A-Za-z0-9_-]{43}$/u.test(state) ||
      !/^[A-Za-z0-9_-]{43}$/u.test(codeVerifier)
    ) {
      throw new XPublicAuthError(
        "internal",
        "X sign-in could not be started.",
        500,
        true,
      );
    }
    const expiresAtMs = nowMs + this.attemptTtlMs;
    try {
      await this.attemptStore.create({
        stateDigest: sha256Hex(state),
        codeVerifier,
        createdAtMs: nowMs,
        expiresAtMs,
      });
    } catch (error) {
      if (error instanceof XPublicAuthError) throw error;
      throw new XPublicAuthError(
        "internal",
        "X sign-in could not be started.",
        500,
        true,
      );
    }
    const authorizationUrl = new URL(X_AUTHORIZATION_ENDPOINT);
    authorizationUrl.searchParams.set("response_type", "code");
    authorizationUrl.searchParams.set("client_id", this.clientId);
    authorizationUrl.searchParams.set("redirect_uri", this.redirectUri);
    authorizationUrl.searchParams.set("scope", X_SCOPES.join(" "));
    authorizationUrl.searchParams.set("state", state);
    authorizationUrl.searchParams.set(
      "code_challenge",
      sha256Base64Url(codeVerifier),
    );
    authorizationUrl.searchParams.set("code_challenge_method", "S256");
    return {
      operation: "begin",
      authorizationUrl: authorizationUrl.toString(),
      expiresAt: new Date(expiresAtMs).toISOString(),
    };
  }

  async complete(callbackUri: string): Promise<XPublicAuthResult> {
    const callback = parseCallbackUri(callbackUri, this.redirect);
    let consumed: XAttemptConsumeResult;
    try {
      consumed = await this.attemptStore.consume(
        sha256Hex(callback.state),
        this.now(),
      );
    } catch {
      throw new XPublicAuthError(
        "internal",
        "X sign-in could not be completed.",
        500,
        true,
      );
    }
    if (consumed.kind !== "consumed") attemptFailure(consumed);
    if (callback.denied) {
      throw new XPublicAuthError(
        "authorization_denied",
        "X sign-in was not approved.",
        403,
        true,
      );
    }
    if (callback.providerError) throw providerFailure();
    const code = callback.code;
    if (!code) invalidRequest("The X sign-in response is invalid.");

    let grant: XTokenGrant;
    try {
      grant = await this.transport.exchangeCode({
        clientId: this.clientId,
        redirectUri: this.redirectUri,
        code,
        codeVerifier: consumed.attempt.codeVerifier,
      });
    } catch {
      throw providerFailure();
    }
    const accessToken = boundedText(
      grant.accessToken,
      MAX_PROVIDER_VALUE_LENGTH,
    );
    if (!accessToken) throw providerFailure();

    let completionError: XPublicAuthError | undefined;
    let customToken: string | undefined;
    try {
      validateExactGrant(grant);
      let subject: string;
      try {
        subject = await this.transport.readSubject(accessToken);
      } catch {
        throw new XPublicAuthError(
          "identity_unavailable",
          "The X account identity could not be verified.",
          502,
          true,
        );
      }
      const firebaseUid = this.subjectProjector.project(subject);
      try {
        customToken = await this.tokenIssuer.issue(firebaseUid);
      } catch {
        throw new XPublicAuthError(
          "token_issue_failed",
          "MoolSocial could not finish X sign-in. Try again.",
          503,
          true,
        );
      }
      if (!boundedText(customToken, MAX_PROVIDER_VALUE_LENGTH)) {
        throw new XPublicAuthError(
          "token_issue_failed",
          "MoolSocial could not finish X sign-in. Try again.",
          503,
          true,
        );
      }
    } catch (error) {
      completionError =
        error instanceof XPublicAuthError ? error : providerFailure();
    }

    try {
      await this.transport.revokeAccessToken({
        clientId: this.clientId,
        accessToken,
      });
    } catch {
      throw new XPublicAuthError(
        "revocation_failed",
        "X sign-in could not be secured. Start again.",
        503,
        true,
      );
    }
    if (completionError) throw completionError;
    if (!customToken) {
      throw new XPublicAuthError(
        "internal",
        "X sign-in could not be completed.",
        500,
        true,
      );
    }
    return { operation: "complete", firebaseCustomToken: customToken };
  }
}

function providerObject(value: unknown): Record<string, unknown> | undefined {
  return typeof value === "object" && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : undefined;
}

async function readProviderJson(
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
    return providerObject(JSON.parse(text) as unknown);
  } catch {
    return undefined;
  }
}

export class FetchXProviderTransport implements XProviderTransport {
  constructor(
    private readonly fetchImplementation: typeof fetch = fetch,
    private readonly timeoutMs = 10_000,
  ) {
    if (
      !Number.isSafeInteger(timeoutMs) ||
      timeoutMs < 1_000 ||
      timeoutMs > 30_000
    ) {
      throw new Error("X provider timeout configuration is invalid.");
    }
  }

  async exchangeCode(input: {
    readonly clientId: string;
    readonly redirectUri: string;
    readonly code: string;
    readonly codeVerifier: string;
  }): Promise<XTokenGrant> {
    const form = new URLSearchParams();
    form.set("code", input.code);
    form.set("grant_type", "authorization_code");
    form.set("client_id", input.clientId);
    form.set("redirect_uri", input.redirectUri);
    form.set("code_verifier", input.codeVerifier);
    let response: Response;
    try {
      response = await this.fetchImplementation(X_TOKEN_ENDPOINT, {
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
    const body = await readProviderJson(response);
    const accessToken = boundedText(
      body?.access_token,
      MAX_PROVIDER_VALUE_LENGTH,
    );
    const tokenType = boundedText(body?.token_type, 32);
    const scope = boundedText(body?.scope, 256);
    if (!accessToken || !tokenType || !scope) throw providerFailure();
    const scopes = scope.split(/\s+/u).filter(Boolean);
    return {
      accessToken,
      tokenType,
      scopes,
      refreshTokenPresent: body !== undefined && "refresh_token" in body,
    };
  }

  async readSubject(accessToken: string): Promise<string> {
    let response: Response;
    try {
      response = await this.fetchImplementation(X_SUBJECT_ENDPOINT, {
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
    const body = await readProviderJson(response);
    const data = providerObject(body?.data);
    const subject = boundedText(data?.id, 32);
    if (!subject || !/^[0-9]{1,32}$/u.test(subject)) {
      throw new XPublicAuthError(
        "identity_unavailable",
        "The X account identity could not be verified.",
        502,
        true,
      );
    }
    return subject;
  }

  async revokeAccessToken(input: {
    readonly clientId: string;
    readonly accessToken: string;
  }): Promise<void> {
    const form = new URLSearchParams();
    form.set("token", input.accessToken);
    form.set("client_id", input.clientId);
    let response: Response;
    try {
      response = await this.fetchImplementation(X_REVOCATION_ENDPOINT, {
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
  }
}
