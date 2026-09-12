import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import test from "node:test";

import {
  FirebaseAdminXTokenIssuer,
  FetchXProviderTransport,
  HmacXSubjectProjector,
  parseXPublicAuthRequest,
  XPublicAuthBroker,
  XPublicAuthError,
  type XAttemptConsumeResult,
  type XAttemptStore,
  type XFirebaseTokenIssuer,
  type XPendingAttempt,
  type XProviderTransport,
  type XRandomSource,
  type XSubjectProjector,
  type XTokenGrant,
} from "./x_pkce_broker.js";

const NOW_MS = Date.UTC(2026, 7, 18, 0, 0, 0);
const REDIRECT_URI = "moolsocial://auth/x/callback";
const CLIENT_ID = "syntheticPublicClient";

test("Firebase token claim contains only provider and public X handle", async () => {
  let captured: { uid: string; claims: object | undefined } | undefined;
  const issuer = new FirebaseAdminXTokenIssuer({
    createCustomToken: async (uid, claims) => {
      captured = { uid, claims };
      return "synthetic-custom-token";
    },
  });
  assert.equal(
    await issuer.issue("x_projected_identity", "@vetonewsline"),
    "synthetic-custom-token",
  );
  assert.deepEqual(captured, {
    uid: "x_projected_identity",
    claims: {
      auth_provider: "x",
      auth_provider_account: "@vetonewsline",
    },
  });
  assert.throws(
    () => issuer.issue("x_projected_identity", "private token"),
    /handle is invalid/u,
  );
});

class MemoryAttemptStore implements XAttemptStore {
  attempt: XPendingAttempt | undefined;
  consumed = false;

  async create(attempt: XPendingAttempt): Promise<void> {
    assert.equal(this.attempt, undefined);
    this.attempt = attempt;
  }

  async consume(
    stateDigest: string,
    nowMs: number,
  ): Promise<XAttemptConsumeResult> {
    if (!this.attempt || this.attempt.stateDigest !== stateDigest) {
      return { kind: "missing" };
    }
    if (this.consumed) return { kind: "replayed" };
    this.consumed = true;
    if (nowMs >= this.attempt.expiresAtMs) return { kind: "expired" };
    return { kind: "consumed", attempt: this.attempt };
  }
}

class FixedRandom implements XRandomSource {
  calls = 0;

  bytes(length: number): Uint8Array {
    const offset = this.calls++ * length;
    return Uint8Array.from({ length }, (_, index) => (offset + index) % 256);
  }
}

class RecordingTransport implements XProviderTransport {
  grant: XTokenGrant = {
    accessToken: "synthetic-access-material",
    tokenType: "bearer",
    scopes: ["tweet.read", "users.read"],
    refreshTokenPresent: false,
  };
  subject = "123456789012345";
  exchangeError = false;
  identityError = false;
  revocationError = false;
  exchangeCount = 0;
  revocationCount = 0;
  exchangeInput: Parameters<XProviderTransport["exchangeCode"]>[0] | undefined;
  revokedInput:
    | Parameters<XProviderTransport["revokeAccessToken"]>[0]
    | undefined;

  async exchangeCode(
    input: Parameters<XProviderTransport["exchangeCode"]>[0],
  ): Promise<XTokenGrant> {
    this.exchangeCount += 1;
    this.exchangeInput = input;
    if (this.exchangeError) throw new Error("provider-authored-private-detail");
    return this.grant;
  }

  async readIdentity(accessToken: string) {
    assert.equal(accessToken, this.grant.accessToken);
    if (this.identityError) throw new Error("provider-authored-private-detail");
    return { subject: this.subject, username: "vetonewsline" };
  }

  async revokeAccessToken(
    input: Parameters<XProviderTransport["revokeAccessToken"]>[0],
  ): Promise<void> {
    this.revocationCount += 1;
    this.revokedInput = input;
    if (this.revocationError) throw new Error("provider-authored-private-detail");
  }
}

class RecordingProjector implements XSubjectProjector {
  subject: string | undefined;

  project(subject: string): string {
    this.subject = subject;
    return "x_projected_identity";
  }
}

class RecordingIssuer implements XFirebaseTokenIssuer {
  uid: string | undefined;
  accountHandle: string | undefined;
  shouldFail = false;

  async issue(firebaseUid: string, accountHandle: string): Promise<string> {
    this.uid = firebaseUid;
    this.accountHandle = accountHandle;
    if (this.shouldFail) throw new Error("firebase-private-detail");
    return "synthetic-firebase-custom-material";
  }
}

interface BrokerRig {
  readonly broker: XPublicAuthBroker;
  readonly store: MemoryAttemptStore;
  readonly transport: RecordingTransport;
  readonly projector: RecordingProjector;
  readonly issuer: RecordingIssuer;
  readonly setNow: (value: number) => void;
}

function brokerRig(): BrokerRig {
  const store = new MemoryAttemptStore();
  const transport = new RecordingTransport();
  const projector = new RecordingProjector();
  const issuer = new RecordingIssuer();
  let nowMs = NOW_MS;
  return {
    broker: new XPublicAuthBroker({
      clientId: CLIENT_ID,
      redirectUri: REDIRECT_URI,
      attemptStore: store,
      transport,
      subjectProjector: projector,
      tokenIssuer: issuer,
      now: () => nowMs,
      random: new FixedRandom(),
    }),
    store,
    transport,
    projector,
    issuer,
    setNow: (value: number) => {
      nowMs = value;
    },
  };
}

async function beginState(rig: BrokerRig): Promise<string> {
  const result = await rig.broker.begin();
  assert.equal(result.operation, "begin");
  return new URL(result.authorizationUrl).searchParams.get("state") ?? "";
}

function callbackUri(state: string, code = "synthetic-code"): string {
  const callback = new URL(REDIRECT_URI);
  callback.searchParams.set("state", state);
  callback.searchParams.set("code", code);
  return callback.toString();
}

test("begin stores only a state digest and emits exact public PKCE parameters", async () => {
  const rig = brokerRig();
  const result = await rig.broker.begin();
  assert.equal(result.operation, "begin");
  const authorization = new URL(result.authorizationUrl);
  assert.equal(authorization.origin, "https://x.com");
  assert.equal(authorization.pathname, "/i/oauth2/authorize");
  assert.deepEqual(
    [...new Set(authorization.searchParams.keys())].sort(),
    [
      "client_id",
      "code_challenge",
      "code_challenge_method",
      "redirect_uri",
      "response_type",
      "scope",
      "state",
    ],
  );
  assert.equal(authorization.searchParams.get("response_type"), "code");
  assert.equal(authorization.searchParams.get("client_id"), CLIENT_ID);
  assert.equal(authorization.searchParams.get("redirect_uri"), REDIRECT_URI);
  assert.equal(authorization.searchParams.get("scope"), "tweet.read users.read");
  assert.equal(authorization.searchParams.get("code_challenge_method"), "S256");
  assert.equal(authorization.searchParams.has("offline.access"), false);
  const state = authorization.searchParams.get("state");
  assert.match(state ?? "", /^[A-Za-z0-9_-]{43}$/u);
  assert.ok(rig.store.attempt);
  assert.equal(
    rig.store.attempt.stateDigest,
    createHash("sha256").update(state ?? "", "utf8").digest("hex"),
  );
  assert.equal(rig.store.attempt.stateDigest.includes(state ?? ""), false);
  assert.notEqual(rig.store.attempt.codeVerifier, state);
  assert.equal(result.expiresAt, new Date(NOW_MS + 5 * 60 * 1000).toISOString());
});

test("complete exchanges as a public client, verifies identity, mints and revokes", async () => {
  const rig = brokerRig();
  const state = await beginState(rig);
  const result = await rig.broker.complete(callbackUri(state));
  assert.deepEqual(result, {
    operation: "complete",
    firebaseCustomToken: "synthetic-firebase-custom-material",
  });
  assert.deepEqual(rig.transport.exchangeInput, {
    clientId: CLIENT_ID,
    redirectUri: REDIRECT_URI,
    code: "synthetic-code",
    codeVerifier: rig.store.attempt?.codeVerifier,
  });
  assert.equal(rig.projector.subject, rig.transport.subject);
  assert.equal(rig.issuer.uid, "x_projected_identity");
  assert.equal(rig.issuer.accountHandle, "@vetonewsline");
  assert.deepEqual(rig.transport.revokedInput, {
    clientId: CLIENT_ID,
    accessToken: "synthetic-access-material",
  });
});

test("request parser requires exact paths and exact body keys", () => {
  assert.deepEqual(parseXPublicAuthRequest("/x/begin", {}), {
    operation: "begin",
  });
  assert.deepEqual(
    parseXPublicAuthRequest("/x/complete", { callbackUri: REDIRECT_URI }),
    { operation: "complete", callbackUri: REDIRECT_URI },
  );
  for (const input of [
    ["/x/begin", { extra: true }],
    ["/x/complete", {}],
    ["/x/complete", { callbackUri: REDIRECT_URI, extra: true }],
    ["/x/unknown", {}],
  ] as const) {
    assert.throws(
      () => parseXPublicAuthRequest(input[0], input[1]),
      (error: unknown) =>
        error instanceof XPublicAuthError && error.code === "invalid_request",
    );
  }
});

test("wrong redirect and duplicate callback parameters fail before exchange", async () => {
  const rig = brokerRig();
  const state = await beginState(rig);
  const wrong = new URL("moolsocial://auth/x/other");
  wrong.searchParams.set("state", state);
  wrong.searchParams.set("code", "synthetic-code");
  await assert.rejects(
    rig.broker.complete(wrong.toString()),
    (error: unknown) =>
      error instanceof XPublicAuthError && error.code === "invalid_request",
  );
  const duplicate = `${callbackUri(state)}&state=${encodeURIComponent(state)}`;
  await assert.rejects(
    rig.broker.complete(duplicate),
    (error: unknown) =>
      error instanceof XPublicAuthError && error.code === "invalid_request",
  );
  assert.equal(rig.transport.exchangeInput, undefined);
});

test("attempt replay and expiry are distinct and never exchange twice", async () => {
  const replayRig = brokerRig();
  const replayState = await beginState(replayRig);
  await replayRig.broker.complete(callbackUri(replayState));
  await assert.rejects(
    replayRig.broker.complete(callbackUri(replayState, "second-code")),
    (error: unknown) =>
      error instanceof XPublicAuthError && error.code === "attempt_replayed",
  );
  assert.equal(replayRig.transport.exchangeCount, 1);

  const expiredRig = brokerRig();
  const expiredState = await beginState(expiredRig);
  expiredRig.setNow(NOW_MS + 5 * 60 * 1000);
  await assert.rejects(
    expiredRig.broker.complete(callbackUri(expiredState)),
    (error: unknown) =>
      error instanceof XPublicAuthError && error.code === "attempt_expired",
  );
  assert.equal(expiredRig.transport.exchangeCount, 0);
});

test("provider denial consumes the attempt without exchanging a code", async () => {
  const rig = brokerRig();
  const state = await beginState(rig);
  const denied = new URL(REDIRECT_URI);
  denied.searchParams.set("state", state);
  denied.searchParams.set("error", "access_denied");
  denied.searchParams.set("error_description", "provider-private-copy");
  await assert.rejects(
    rig.broker.complete(denied.toString()),
    (error: unknown) =>
      error instanceof XPublicAuthError &&
      error.code === "authorization_denied" &&
      !error.message.includes("provider-private-copy"),
  );
  assert.equal(rig.transport.exchangeCount, 0);
  await assert.rejects(
    rig.broker.complete(denied.toString()),
    (error: unknown) =>
      error instanceof XPublicAuthError && error.code === "attempt_replayed",
  );
});

test("provider server errors are not misreported as user denial", async () => {
  const rig = brokerRig();
  const state = await beginState(rig);
  const failed = new URL(REDIRECT_URI);
  failed.searchParams.set("state", state);
  failed.searchParams.set("error", "server_error");
  failed.searchParams.set("error_description", "provider-private-copy");
  await assert.rejects(
    rig.broker.complete(failed.toString()),
    (error: unknown) =>
      error instanceof XPublicAuthError &&
      error.code === "provider_unavailable" &&
      !error.message.includes("provider-private-copy"),
  );
  assert.equal(rig.transport.exchangeCount, 0);
});

test("exchange errors are sanitized and cannot leak provider details", async () => {
  const rig = brokerRig();
  rig.transport.exchangeError = true;
  const state = await beginState(rig);
  await assert.rejects(
    rig.broker.complete(callbackUri(state)),
    (error: unknown) =>
      error instanceof XPublicAuthError &&
      error.code === "provider_unavailable" &&
      !error.message.includes("provider-authored-private-detail"),
  );
  assert.equal(rig.transport.revocationCount, 0);
});

test("identity and Firebase issuance failures still revoke transient access", async () => {
  const identityRig = brokerRig();
  identityRig.transport.identityError = true;
  const identityState = await beginState(identityRig);
  await assert.rejects(
    identityRig.broker.complete(callbackUri(identityState)),
    (error: unknown) =>
      error instanceof XPublicAuthError &&
      error.code === "identity_unavailable" &&
      !error.message.includes("provider-authored-private-detail"),
  );
  assert.equal(identityRig.transport.revocationCount, 1);

  const issuerRig = brokerRig();
  issuerRig.issuer.shouldFail = true;
  const issuerState = await beginState(issuerRig);
  await assert.rejects(
    issuerRig.broker.complete(callbackUri(issuerState)),
    (error: unknown) =>
      error instanceof XPublicAuthError &&
      error.code === "token_issue_failed" &&
      !error.message.includes("firebase-private-detail"),
  );
  assert.equal(issuerRig.transport.revocationCount, 1);
});

test("overbroad or refresh-bearing grants fail closed and are revoked", async () => {
  const invalidGrants: XTokenGrant[] = [
    {
      accessToken: "synthetic-access-material",
      tokenType: "bearer",
      scopes: ["tweet.read", "users.read", "offline.access"],
      refreshTokenPresent: false,
    },
    {
      accessToken: "synthetic-access-material",
      tokenType: "bearer",
      scopes: ["tweet.read", "users.read"],
      refreshTokenPresent: true,
    },
    {
      accessToken: "synthetic-access-material",
      tokenType: "mac",
      scopes: ["tweet.read", "users.read"],
      refreshTokenPresent: false,
    },
  ];
  for (const grant of invalidGrants) {
    const rig = brokerRig();
    rig.transport.grant = grant;
    const state = await beginState(rig);
    await assert.rejects(
      rig.broker.complete(callbackUri(state)),
      (error: unknown) =>
        error instanceof XPublicAuthError &&
        error.code === "provider_unavailable",
    );
    assert.equal(rig.transport.revocationCount, 1);
    assert.equal(rig.issuer.uid, undefined);
  }
});

test("revocation failure prevents returning an already minted custom token", async () => {
  const rig = brokerRig();
  rig.transport.revocationError = true;
  const state = await beginState(rig);
  await assert.rejects(
    rig.broker.complete(callbackUri(state)),
    (error: unknown) =>
      error instanceof XPublicAuthError &&
      error.code === "revocation_failed" &&
      !error.message.includes("provider-authored-private-detail"),
  );
  assert.equal(rig.issuer.uid, "x_projected_identity");
  assert.equal(rig.transport.revocationCount, 1);
});

test("subject projection is deterministic, project-scoped and rejects malformed IDs", () => {
  const key = Buffer.alloc(32, 7);
  const first = new HmacXSubjectProjector("moolsocial-dev-503018", key);
  const same = new HmacXSubjectProjector("moolsocial-dev-503018", key);
  const otherProject = new HmacXSubjectProjector("moolsocial-staging-503018", key);
  const firstUid = first.project("123456789012345");
  assert.match(firstUid, /^x_[A-Za-z0-9_-]{43}$/u);
  assert.equal(firstUid, same.project("123456789012345"));
  assert.notEqual(firstUid, otherProject.project("123456789012345"));
  assert.equal(firstUid.includes("123456789012345"), false);
  assert.throws(
    () => first.project("not-a-provider-subject"),
    (error: unknown) =>
      error instanceof XPublicAuthError &&
      error.code === "identity_unavailable",
  );
});

test("fetch transport uses exact public-client exchange, identity and revocation contracts", async () => {
  const calls: Array<{ input: string | URL | Request; init?: RequestInit }> = [];
  const fakeFetch = (async (
    input: string | URL | Request,
    init?: RequestInit,
  ): Promise<Response> => {
    calls.push(init === undefined ? { input } : { input, init });
    const url = input instanceof Request ? input.url : input.toString();
    if (url.endsWith("/2/oauth2/token")) {
      return Response.json({
        access_token: "synthetic-access-material",
        token_type: "bearer",
        scope: "tweet.read users.read",
      });
    }
    if (url.endsWith("/2/users/me")) {
      return Response.json({
        data: { id: "123456789012345", username: "vetonewsline" },
      });
    }
    return Response.json({ revoked: true });
  }) as typeof fetch;
  const transport = new FetchXProviderTransport(fakeFetch);
  const grant = await transport.exchangeCode({
    clientId: CLIENT_ID,
    redirectUri: REDIRECT_URI,
    code: "synthetic-code",
    codeVerifier: "v".repeat(43),
  });
  const providerIdentity = await transport.readIdentity(grant.accessToken);
  await transport.revokeAccessToken({
    clientId: CLIENT_ID,
    accessToken: grant.accessToken,
  });
  assert.deepEqual(providerIdentity, {
    subject: "123456789012345",
    username: "vetonewsline",
  });
  assert.equal(calls.length, 3);

  const exchange = calls[0];
  assert.ok(exchange?.init);
  assert.equal(exchange.init.method, "POST");
  assert.equal(new Headers(exchange.init.headers).has("authorization"), false);
  const exchangeForm = new URLSearchParams(exchange.init.body as string);
  assert.deepEqual([...exchangeForm.keys()].sort(), [
    "client_id",
    "code",
    "code_verifier",
    "grant_type",
    "redirect_uri",
  ]);
  assert.equal(exchangeForm.has("client_secret"), false);
  assert.equal(exchangeForm.get("grant_type"), "authorization_code");

  const identity = calls[1];
  assert.ok(identity?.init);
  assert.equal(identity.init.method, "GET");
  assert.equal(
    new Headers(identity.init.headers).get("authorization"),
    "Bearer synthetic-access-material",
  );

  const revocation = calls[2];
  assert.ok(revocation?.init);
  assert.equal(revocation.init.method, "POST");
  const revocationForm = new URLSearchParams(revocation.init.body as string);
  assert.deepEqual([...revocationForm.keys()].sort(), ["client_id", "token"]);
  assert.equal(revocationForm.get("client_id"), CLIENT_ID);
});

test("fetch transport rejects an oversized provider body before parsing", async () => {
  const fakeFetch = (async (): Promise<Response> =>
    new Response("x".repeat(64 * 1024 + 1), { status: 200 })) as typeof fetch;
  const transport = new FetchXProviderTransport(fakeFetch);

  await assert.rejects(
    transport.exchangeCode({
      clientId: CLIENT_ID,
      redirectUri: REDIRECT_URI,
      code: "synthetic-code",
      codeVerifier: "v".repeat(43),
    }),
    (error: unknown) =>
      error instanceof XPublicAuthError &&
      error.code === "provider_unavailable",
  );
});
