import { createHash, randomBytes } from "node:crypto";

import type {
  HttpTransport,
  HttpTransportResponse,
  YouTubeTokenResponse,
} from "./types.js";

export const GOOGLE_OAUTH_AUTHORIZATION_ENDPOINT =
  "https://accounts.google.com/o/oauth2/v2/auth";
export const GOOGLE_OAUTH_TOKEN_ENDPOINT =
  "https://oauth2.googleapis.com/token";

export const YOUTUBE_READONLY_SCOPE =
  "https://www.googleapis.com/auth/youtube.readonly";
export const YOUTUBE_UPLOAD_SCOPE =
  "https://www.googleapis.com/auth/youtube.upload";
export const YOUTUBE_FORCE_SSL_SCOPE =
  "https://www.googleapis.com/auth/youtube.force-ssl";
export const YOUTUBE_MANAGE_SCOPE =
  "https://www.googleapis.com/auth/youtube";
export const YOUTUBE_ANALYTICS_READONLY_SCOPE =
  "https://www.googleapis.com/auth/yt-analytics.readonly";
export const YOUTUBE_MEMBERSHIPS_CREATOR_SCOPE =
  "https://www.googleapis.com/auth/youtube.channel-memberships.creator";

export const YOUTUBE_INCREMENTAL_SCOPE_SETS = Object.freeze({
  readonly: Object.freeze([YOUTUBE_READONLY_SCOPE]),
  write: Object.freeze([YOUTUBE_READONLY_SCOPE, YOUTUBE_FORCE_SSL_SCOPE]),
  creatorAssets: Object.freeze([YOUTUBE_FORCE_SSL_SCOPE]),
  live: Object.freeze([YOUTUBE_MANAGE_SCOPE]),
  liveMemberships: Object.freeze([YOUTUBE_MEMBERSHIPS_CREATOR_SCOPE]),
  upload: Object.freeze([YOUTUBE_READONLY_SCOPE, YOUTUBE_UPLOAD_SCOPE]),
  analytics: Object.freeze([
    YOUTUBE_READONLY_SCOPE,
    YOUTUBE_ANALYTICS_READONLY_SCOPE,
  ]),
});

export type YouTubeIncrementalScope =
  keyof typeof YOUTUBE_INCREMENTAL_SCOPE_SETS;

export interface PkcePair {
  readonly codeVerifier: string;
  readonly codeChallenge: string;
  readonly codeChallengeMethod: "S256";
}

export interface GoogleAuthorizationUrlInput {
  readonly clientId: string;
  readonly redirectUri: string;
  readonly state: string;
  readonly codeChallenge: string;
  readonly scopes: readonly string[];
  /**
   * Request a fresh consent decision only when the product intentionally needs
   * Google to return a refresh token again.
   */
  readonly promptForConsent?: boolean;
}

export interface AuthorizationCodeExchangeInput {
  readonly clientId: string;
  readonly clientSecret: string;
  readonly redirectUri: string;
  readonly code: string;
  readonly codeVerifier: string;
}

export interface RefreshAccessTokenInput {
  readonly clientId: string;
  readonly clientSecret: string;
  readonly refreshToken: string;
}

export class GoogleOAuthProtocolError extends Error {
  constructor(
    readonly code:
      | "invalid_request"
      | "provider_rejected"
      | "invalid_token_response",
    message: string,
    readonly httpStatus: number,
  ) {
    super(message);
    this.name = "GoogleOAuthProtocolError";
  }
}

function assertNonEmpty(value: string, field: string): void {
  if (value.trim().length === 0) {
    throw new GoogleOAuthProtocolError(
      "invalid_request",
      `${field} is required.`,
      400,
    );
  }
}

function encodeBase64Url(value: Uint8Array): string {
  return Buffer.from(value).toString("base64url");
}

/**
 * Generates a cryptographically random state value. The caller must retain it
 * in short-lived memory and compare it exactly on the provider return.
 */
export function createOAuthState(): string {
  return encodeBase64Url(randomBytes(32));
}

export function derivePkceChallenge(codeVerifier: string): string {
  assertNonEmpty(codeVerifier, "codeVerifier");
  if (
    codeVerifier.length < 43 ||
    codeVerifier.length > 128 ||
    !/^[A-Za-z0-9._~-]+$/.test(codeVerifier)
  ) {
    throw new GoogleOAuthProtocolError(
      "invalid_request",
      "codeVerifier must satisfy RFC 7636.",
      400,
    );
  }
  return createHash("sha256")
    .update(codeVerifier, "ascii")
    .digest("base64url");
}

/**
 * Uses 64 random bytes, producing an 86-character RFC 7636 verifier.
 */
export function createPkcePair(): PkcePair {
  const codeVerifier = encodeBase64Url(randomBytes(64));
  return {
    codeVerifier,
    codeChallenge: derivePkceChallenge(codeVerifier),
    codeChallengeMethod: "S256",
  };
}

function normalizedScopes(scopes: readonly string[]): readonly string[] {
  const unique = new Set<string>();
  for (const scope of scopes) {
    const normalized = scope.trim();
    if (normalized.length > 0) {
      unique.add(normalized);
    }
  }
  if (unique.size === 0) {
    throw new GoogleOAuthProtocolError(
      "invalid_request",
      "At least one OAuth scope is required.",
      400,
    );
  }
  return [...unique].sort();
}

/**
 * Builds the URL that the native app opens in the operating system browser.
 * MoolSocial never collects or processes a user's Google password.
 */
export function buildGoogleAuthorizationUrl(
  input: GoogleAuthorizationUrlInput,
): string {
  assertNonEmpty(input.clientId, "clientId");
  assertNonEmpty(input.redirectUri, "redirectUri");
  assertNonEmpty(input.state, "state");
  assertNonEmpty(input.codeChallenge, "codeChallenge");

  const url = new URL(GOOGLE_OAUTH_AUTHORIZATION_ENDPOINT);
  url.searchParams.set("client_id", input.clientId);
  url.searchParams.set("redirect_uri", input.redirectUri);
  url.searchParams.set("response_type", "code");
  url.searchParams.set("scope", normalizedScopes(input.scopes).join(" "));
  url.searchParams.set("state", input.state);
  url.searchParams.set("code_challenge", input.codeChallenge);
  url.searchParams.set("code_challenge_method", "S256");
  url.searchParams.set("access_type", "offline");
  url.searchParams.set("include_granted_scopes", "true");
  if (input.promptForConsent === true) {
    url.searchParams.set("prompt", "consent");
  }
  return url.toString();
}

function formBody(fields: Readonly<Record<string, string>>): string {
  const body = new URLSearchParams();
  for (const [key, value] of Object.entries(fields)) {
    assertNonEmpty(value, key);
    body.set(key, value);
  }
  return body.toString();
}

async function parseTokenResponse(
  response: HttpTransportResponse,
): Promise<YouTubeTokenResponse> {
  if (response.status < 200 || response.status >= 300) {
    throw new GoogleOAuthProtocolError(
      "provider_rejected",
      "Google could not complete the channel authorization.",
      response.status,
    );
  }

  let value: unknown;
  try {
    value = JSON.parse(response.body);
  } catch {
    throw new GoogleOAuthProtocolError(
      "invalid_token_response",
      "Google returned an invalid authorization response.",
      502,
    );
  }

  if (typeof value !== "object" || value === null) {
    throw new GoogleOAuthProtocolError(
      "invalid_token_response",
      "Google returned an invalid authorization response.",
      502,
    );
  }

  const token = value as Partial<YouTubeTokenResponse>;
  if (
    typeof token.access_token !== "string" ||
    token.access_token.length === 0 ||
    typeof token.expires_in !== "number" ||
    !Number.isFinite(token.expires_in) ||
    token.expires_in <= 0 ||
    typeof token.token_type !== "string" ||
    token.token_type.length === 0 ||
    (token.refresh_token !== undefined &&
      typeof token.refresh_token !== "string") ||
    (token.scope !== undefined && typeof token.scope !== "string")
  ) {
    throw new GoogleOAuthProtocolError(
      "invalid_token_response",
      "Google returned an invalid authorization response.",
      502,
    );
  }

  return token as YouTubeTokenResponse;
}

async function sendTokenRequest(
  transport: HttpTransport,
  body: string,
): Promise<YouTubeTokenResponse> {
  const response = await transport.send({
    url: GOOGLE_OAUTH_TOKEN_ENDPOINT,
    method: "POST",
    headers: {
      accept: "application/json",
      "content-type": "application/x-www-form-urlencoded",
    },
    body,
  });
  return parseTokenResponse(response);
}

/**
 * Exchanges the one-time authorization code using PKCE from the privileged
 * backend. The confidential web-server client secret never enters Flutter.
 */
export async function exchangeAuthorizationCode(
  transport: HttpTransport,
  input: AuthorizationCodeExchangeInput,
): Promise<YouTubeTokenResponse> {
  return sendTokenRequest(
    transport,
    formBody({
      client_id: input.clientId,
      client_secret: input.clientSecret,
      redirect_uri: input.redirectUri,
      code: input.code,
      code_verifier: input.codeVerifier,
      grant_type: "authorization_code",
    }),
  );
}

/**
 * Refreshes a short-lived access token. The refresh token should be supplied
 * only after decrypting it inside the privileged server boundary.
 */
export async function refreshAccessToken(
  transport: HttpTransport,
  input: RefreshAccessTokenInput,
): Promise<YouTubeTokenResponse> {
  return sendTokenRequest(
    transport,
    formBody({
      client_id: input.clientId,
      client_secret: input.clientSecret,
      refresh_token: input.refreshToken,
      grant_type: "refresh_token",
    }),
  );
}
