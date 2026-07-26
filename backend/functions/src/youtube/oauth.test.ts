import assert from "node:assert/strict";
import test from "node:test";

import type {
  HttpTransport,
  HttpTransportRequest,
  HttpTransportResponse,
} from "./types.js";
import {
  GOOGLE_OAUTH_AUTHORIZATION_ENDPOINT,
  GOOGLE_OAUTH_TOKEN_ENDPOINT,
  GoogleOAuthProtocolError,
  YOUTUBE_ANALYTICS_READONLY_SCOPE,
  YOUTUBE_FORCE_SSL_SCOPE,
  YOUTUBE_INCREMENTAL_SCOPE_SETS,
  YOUTUBE_MANAGE_SCOPE,
  YOUTUBE_MEMBERSHIPS_CREATOR_SCOPE,
  YOUTUBE_READONLY_SCOPE,
  YOUTUBE_UPLOAD_SCOPE,
  buildGoogleAuthorizationUrl,
  createOAuthState,
  createPkcePair,
  derivePkceChallenge,
  exchangeAuthorizationCode,
  refreshAccessToken,
} from "./oauth.js";

class RecordingTransport implements HttpTransport {
  request?: HttpTransportRequest;

  constructor(readonly response: HttpTransportResponse) {}

  async send(request: HttpTransportRequest): Promise<HttpTransportResponse> {
    this.request = request;
    return this.response;
  }
}

test("OAuth state and PKCE values use cryptographic base64url material", () => {
  const firstState = createOAuthState();
  const secondState = createOAuthState();
  assert.match(firstState, /^[A-Za-z0-9_-]{43}$/);
  assert.notEqual(firstState, secondState);

  const pair = createPkcePair();
  assert.match(pair.codeVerifier, /^[A-Za-z0-9_-]{86}$/);
  assert.equal(pair.codeChallengeMethod, "S256");
  assert.equal(
    pair.codeChallenge,
    derivePkceChallenge(pair.codeVerifier),
  );
});

test("PKCE challenge matches the RFC 7636 S256 example", () => {
  const verifier =
    "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk";
  assert.equal(
    derivePkceChallenge(verifier),
    "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM",
  );
});

test("authorization URL uses Google's system-browser endpoint and incremental scopes", () => {
  assert.deepEqual(YOUTUBE_INCREMENTAL_SCOPE_SETS.readonly, [
    YOUTUBE_READONLY_SCOPE,
  ]);
  assert.deepEqual(YOUTUBE_INCREMENTAL_SCOPE_SETS.upload, [
    YOUTUBE_READONLY_SCOPE,
    YOUTUBE_UPLOAD_SCOPE,
  ]);
  assert.deepEqual(YOUTUBE_INCREMENTAL_SCOPE_SETS.write, [
    YOUTUBE_READONLY_SCOPE,
    YOUTUBE_FORCE_SSL_SCOPE,
  ]);
  assert.deepEqual(YOUTUBE_INCREMENTAL_SCOPE_SETS.creatorAssets, [
    YOUTUBE_FORCE_SSL_SCOPE,
  ]);
  assert.deepEqual(YOUTUBE_INCREMENTAL_SCOPE_SETS.live, [
    YOUTUBE_MANAGE_SCOPE,
  ]);
  assert.deepEqual(YOUTUBE_INCREMENTAL_SCOPE_SETS.liveMemberships, [
    YOUTUBE_MEMBERSHIPS_CREATOR_SCOPE,
  ]);
  assert.deepEqual(YOUTUBE_INCREMENTAL_SCOPE_SETS.analytics, [
    YOUTUBE_READONLY_SCOPE,
    YOUTUBE_ANALYTICS_READONLY_SCOPE,
  ]);

  const authorizationUrl = buildGoogleAuthorizationUrl({
    clientId: "web-client.apps.googleusercontent.com",
    redirectUri: "https://dev.moolsocial.com/google-callback/youtube",
    state: "state-token",
    codeChallenge: "challenge-token",
    scopes: [
      YOUTUBE_UPLOAD_SCOPE,
      YOUTUBE_READONLY_SCOPE,
      YOUTUBE_READONLY_SCOPE,
    ],
    promptForConsent: true,
  });
  const url = new URL(authorizationUrl);

  assert.equal(url.origin + url.pathname, GOOGLE_OAUTH_AUTHORIZATION_ENDPOINT);
  assert.equal(
    url.searchParams.get("client_id"),
    "web-client.apps.googleusercontent.com",
  );
  assert.equal(
    url.searchParams.get("redirect_uri"),
    "https://dev.moolsocial.com/google-callback/youtube",
  );
  assert.equal(url.searchParams.get("response_type"), "code");
  assert.equal(url.searchParams.get("state"), "state-token");
  assert.equal(url.searchParams.get("code_challenge"), "challenge-token");
  assert.equal(url.searchParams.get("code_challenge_method"), "S256");
  assert.equal(url.searchParams.get("access_type"), "offline");
  assert.equal(url.searchParams.get("include_granted_scopes"), "true");
  assert.equal(url.searchParams.get("prompt"), "consent");
  assert.deepEqual(
    url.searchParams.get("scope")?.split(" "),
    [YOUTUBE_READONLY_SCOPE, YOUTUBE_UPLOAD_SCOPE].sort(),
  );
  assert.equal(url.searchParams.has("client_secret"), false);
});

test("authorization-code exchange sends PKCE fields and the server-held client secret", async () => {
  const transport = new RecordingTransport({
    status: 200,
    headers: {},
    body: JSON.stringify({
      access_token: "short-lived-access",
      expires_in: 3600,
      refresh_token: "server-refresh",
      scope: YOUTUBE_READONLY_SCOPE,
      token_type: "Bearer",
    }),
  });

  const token = await exchangeAuthorizationCode(transport, {
    clientId: "web-client",
    clientSecret: "server-held-secret",
    redirectUri: "https://dev.moolsocial.com/google-callback/youtube",
    code: "one-time-code",
    codeVerifier:
      "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk",
  });

  assert.equal(token.access_token, "short-lived-access");
  assert.equal(transport.request?.url, GOOGLE_OAUTH_TOKEN_ENDPOINT);
  assert.equal(transport.request?.method, "POST");
  assert.equal(
    transport.request?.headers?.["content-type"],
    "application/x-www-form-urlencoded",
  );
  const body = new URLSearchParams(transport.request?.body);
  assert.equal(body.get("grant_type"), "authorization_code");
  assert.equal(body.get("code"), "one-time-code");
  assert.equal(
    body.get("code_verifier"),
    "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk",
  );
  assert.equal(body.get("client_secret"), "server-held-secret");
});

test("refresh exchange uses only the privileged refresh-token grant", async () => {
  const transport = new RecordingTransport({
    status: 200,
    headers: {},
    body: JSON.stringify({
      access_token: "renewed-access",
      expires_in: 1800,
      token_type: "Bearer",
    }),
  });

  const token = await refreshAccessToken(transport, {
    clientId: "web-client",
    clientSecret: "server-held-secret",
    refreshToken: "decrypted-inside-server",
  });

  assert.equal(token.access_token, "renewed-access");
  const body = new URLSearchParams(transport.request?.body);
  assert.equal(body.get("grant_type"), "refresh_token");
  assert.equal(body.get("refresh_token"), "decrypted-inside-server");
  assert.equal(body.get("client_secret"), "server-held-secret");
});

test("provider rejection does not expose the provider response body", async () => {
  const transport = new RecordingTransport({
    status: 400,
    headers: {},
    body: JSON.stringify({
      error: "invalid_grant",
      error_description: "sensitive provider details",
    }),
  });

  await assert.rejects(
    exchangeAuthorizationCode(transport, {
      clientId: "web-client",
      clientSecret: "server-held-secret",
      redirectUri: "https://dev.moolsocial.com/google-callback/youtube",
      code: "expired-code",
      codeVerifier:
        "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk",
    }),
    (error: unknown) => {
      assert.ok(error instanceof GoogleOAuthProtocolError);
      assert.equal(error.code, "provider_rejected");
      assert.equal(error.httpStatus, 400);
      assert.doesNotMatch(error.message, /sensitive provider details/);
      return true;
    },
  );
});
