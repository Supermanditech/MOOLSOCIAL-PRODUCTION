import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import test from "node:test";

import {
  FirebaseAdminInstagramTokenIssuer,
  FetchInstagramProviderTransport,
  HmacInstagramSubjectProjector,
  InstagramPublicAuthBroker,
  InstagramPublicAuthError,
  parseInstagramPublicAuthRequest,
  type InstagramAttemptConsumeResult,
  type InstagramAttemptStore,
  type InstagramFirebaseTokenIssuer,
  type InstagramPendingAttempt,
  type InstagramProviderIdentity,
  type InstagramProviderTransport,
  type InstagramRandomSource,
  type InstagramSubjectProjector,
  type InstagramTokenGrant,
} from "./instagram_oauth_broker.js";

const NOW_MS = Date.UTC(2026, 7, 18, 1, 0, 0);
const REDIRECT_URI = "moolsocial://auth/instagram/callback";
const CLIENT_ID = "syntheticInstagramClient";

test(
  "Firebase token claim contains only provider and public Instagram handle",
  async () => {
    let captured: { uid: string; claims: object | undefined } | undefined;
    const issuer = new FirebaseAdminInstagramTokenIssuer({
      createCustomToken: async (uid, claims) => {
        captured = { uid, claims };
        return "synthetic-custom-token";
      },
    });
    assert.equal(
      await issuer.issue("instagram_projected_identity", "@vetonews.live"),
      "synthetic-custom-token",
    );
    assert.deepEqual(captured, {
      uid: "instagram_projected_identity",
      claims: {
        auth_provider: "instagram",
        auth_provider_account: "@vetonews.live",
      },
    });
    assert.throws(
      () => issuer.issue("instagram_projected_identity", "private token"),
      /handle is invalid/u,
    );
  },
);

class MemoryInstagramAttemptStore implements InstagramAttemptStore {
  attempt: InstagramPendingAttempt | undefined;
  consumed = false;

  async create(attempt: InstagramPendingAttempt): Promise<void> {
    assert.equal(this.attempt, undefined);
    this.attempt = attempt;
  }

  async consume(
    stateDigest: string,
    nowMs: number,
  ): Promise<InstagramAttemptConsumeResult> {
    if (!this.attempt || this.attempt.stateDigest !== stateDigest) {
      return { kind: "missing" };
    }
    if (this.consumed) return { kind: "replayed" };
    this.consumed = true;
    if (nowMs >= this.attempt.expiresAtMs) return { kind: "expired" };
    return { kind: "consumed", attempt: this.attempt };
  }
}

class FixedInstagramRandom implements InstagramRandomSource {
  bytes(length: number): Uint8Array {
    return Uint8Array.from({ length }, (_, index) => (index + 91) % 256);
  }
}

class RecordingInstagramTransport implements InstagramProviderTransport {
  accessToken = "synthetic-instagram-access-material";
  refreshTokenPresent = false;
  identity: InstagramProviderIdentity = {
    subject: "9988776655443322",
    accountType: "BUSINESS",
    username: "vetonewslive",
  };
  exchangeError = false;
  identityError = false;
  revocationError = false;
  exchangeCount = 0;
  revocationCount = 0;
  exchangeInput:
    | Parameters<InstagramProviderTransport["exchangeCode"]>[0]
    | undefined;

  async exchangeCode(
    input: Parameters<InstagramProviderTransport["exchangeCode"]>[0],
  ): Promise<InstagramTokenGrant> {
    this.exchangeCount += 1;
    this.exchangeInput = input;
    if (this.exchangeError) throw new Error("provider-authored-private-detail");
    return {
      accessToken: this.accessToken,
      refreshTokenPresent: this.refreshTokenPresent,
    };
  }

  async readIdentity(accessToken: string): Promise<InstagramProviderIdentity> {
    assert.equal(accessToken, this.accessToken);
    if (this.identityError) throw new Error("provider-authored-private-detail");
    return this.identity;
  }

  async revokeAccessToken(accessToken: string): Promise<void> {
    assert.equal(accessToken, this.accessToken);
    this.revocationCount += 1;
    if (this.revocationError) throw new Error("provider-authored-private-detail");
  }
}

class RecordingInstagramProjector implements InstagramSubjectProjector {
  subject: string | undefined;

  project(subject: string): string {
    this.subject = subject;
    return "instagram_projected_identity";
  }
}

class RecordingInstagramIssuer implements InstagramFirebaseTokenIssuer {
  uid: string | undefined;
  accountHandle: string | undefined;
  shouldFail = false;

  async issue(firebaseUid: string, accountHandle: string): Promise<string> {
    this.uid = firebaseUid;
    this.accountHandle = accountHandle;
    if (this.shouldFail) throw new Error("firebase-private-detail");
    return "synthetic-instagram-firebase-material";
  }
}

interface InstagramRig {
  readonly broker: InstagramPublicAuthBroker;
  readonly store: MemoryInstagramAttemptStore;
  readonly transport: RecordingInstagramTransport;
  readonly projector: RecordingInstagramProjector;
  readonly issuer: RecordingInstagramIssuer;
  readonly setNow: (value: number) => void;
}

function instagramRig(): InstagramRig {
  const store = new MemoryInstagramAttemptStore();
  const transport = new RecordingInstagramTransport();
  const projector = new RecordingInstagramProjector();
  const issuer = new RecordingInstagramIssuer();
  let nowMs = NOW_MS;
  return {
    broker: new InstagramPublicAuthBroker({
      clientId: CLIENT_ID,
      redirectUri: REDIRECT_URI,
      attemptStore: store,
      transport,
      subjectProjector: projector,
      tokenIssuer: issuer,
      now: () => nowMs,
      random: new FixedInstagramRandom(),
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

async function beginState(rig: InstagramRig): Promise<string> {
  const result = await rig.broker.begin();
  assert.equal(result.operation, "begin");
  return new URL(result.authorizationUrl).searchParams.get("state") ?? "";
}

function callbackUri(state: string, code = "synthetic-instagram-code"): string {
  const callback = new URL(REDIRECT_URI);
  callback.searchParams.set("state", state);
  callback.searchParams.set("code", code);
  return callback.toString();
}

test("begin emits the direct professional-login minimum scope and stores a digest", async () => {
  const rig = instagramRig();
  const result = await rig.broker.begin();
  assert.equal(result.operation, "begin");
  const authorization = new URL(result.authorizationUrl);
  assert.equal(authorization.origin, "https://www.instagram.com");
  assert.equal(authorization.pathname, "/oauth/authorize");
  assert.deepEqual([...authorization.searchParams.keys()].sort(), [
    "client_id",
    "force_reauth",
    "redirect_uri",
    "response_type",
    "scope",
    "state",
  ]);
  assert.equal(
    authorization.searchParams.get("scope"),
    "instagram_business_basic",
  );
  assert.equal(authorization.searchParams.get("client_id"), CLIENT_ID);
  assert.equal(authorization.searchParams.get("force_reauth"), "true");
  assert.equal(authorization.searchParams.get("redirect_uri"), REDIRECT_URI);
  const state = authorization.searchParams.get("state") ?? "";
  assert.match(state, /^[A-Za-z0-9_-]{43}$/u);
  assert.ok(rig.store.attempt);
  assert.equal(
    rig.store.attempt.stateDigest,
    createHash("sha256").update(state, "utf8").digest("hex"),
  );
  assert.equal(rig.store.attempt.stateDigest.includes(state), false);
});

test("eligible professional identity mints Firebase material then revokes access", async () => {
  const rig = instagramRig();
  const state = await beginState(rig);
  const result = await rig.broker.complete(callbackUri(state));
  assert.deepEqual(result, {
    operation: "complete",
    firebaseCustomToken: "synthetic-instagram-firebase-material",
  });
  assert.deepEqual(rig.transport.exchangeInput, {
    clientId: CLIENT_ID,
    redirectUri: REDIRECT_URI,
    code: "synthetic-instagram-code",
  });
  assert.equal(rig.projector.subject, rig.transport.identity.subject);
  assert.equal(rig.issuer.uid, "instagram_projected_identity");
  assert.equal(rig.issuer.accountHandle, "@vetonewslive");
  assert.equal(rig.transport.revocationCount, 1);
});

test("request parser and callback require exact paths, keys and redirect", async () => {
  assert.deepEqual(parseInstagramPublicAuthRequest("/instagram/begin", {}), {
    operation: "begin",
  });
  assert.throws(
    () => parseInstagramPublicAuthRequest("/instagram/begin", { extra: true }),
    (error: unknown) =>
      error instanceof InstagramPublicAuthError &&
      error.code === "invalid_request",
  );
  const rig = instagramRig();
  const state = await beginState(rig);
  const wrong = new URL("moolsocial://auth/instagram/other");
  wrong.searchParams.set("state", state);
  wrong.searchParams.set("code", "synthetic-instagram-code");
  await assert.rejects(
    rig.broker.complete(wrong.toString()),
    (error: unknown) =>
      error instanceof InstagramPublicAuthError &&
      error.code === "invalid_request",
  );
  const duplicate = `${callbackUri(state)}&state=${encodeURIComponent(state)}`;
  await assert.rejects(
    rig.broker.complete(duplicate),
    (error: unknown) =>
      error instanceof InstagramPublicAuthError &&
      error.code === "invalid_request",
  );
  assert.equal(rig.transport.exchangeCount, 0);
});

test("replay, expiry and denial are distinct one-time outcomes", async () => {
  const replayRig = instagramRig();
  const replayState = await beginState(replayRig);
  await replayRig.broker.complete(callbackUri(replayState));
  await assert.rejects(
    replayRig.broker.complete(callbackUri(replayState, "second-code")),
    (error: unknown) =>
      error instanceof InstagramPublicAuthError &&
      error.code === "attempt_replayed",
  );

  const expiredRig = instagramRig();
  const expiredState = await beginState(expiredRig);
  expiredRig.setNow(NOW_MS + 5 * 60 * 1000);
  await assert.rejects(
    expiredRig.broker.complete(callbackUri(expiredState)),
    (error: unknown) =>
      error instanceof InstagramPublicAuthError &&
      error.code === "attempt_expired",
  );
  assert.equal(expiredRig.transport.exchangeCount, 0);

  const deniedRig = instagramRig();
  const deniedState = await beginState(deniedRig);
  const denied = new URL(REDIRECT_URI);
  denied.searchParams.set("state", deniedState);
  denied.searchParams.set("error", "access_denied");
  denied.searchParams.set("error_description", "provider-private-copy");
  await assert.rejects(
    deniedRig.broker.complete(denied.toString()),
    (error: unknown) =>
      error instanceof InstagramPublicAuthError &&
      error.code === "authorization_denied" &&
      !error.message.includes("provider-private-copy"),
  );
  assert.equal(deniedRig.transport.exchangeCount, 0);
});

test("provider server errors are not misreported as user denial", async () => {
  const rig = instagramRig();
  const state = await beginState(rig);
  const failed = new URL(REDIRECT_URI);
  failed.searchParams.set("state", state);
  failed.searchParams.set("error", "server_error");
  failed.searchParams.set("error_description", "provider-private-copy");
  await assert.rejects(
    rig.broker.complete(failed.toString()),
    (error: unknown) =>
      error instanceof InstagramPublicAuthError &&
      error.code === "provider_unavailable" &&
      !error.message.includes("provider-private-copy"),
  );
  assert.equal(rig.transport.exchangeCount, 0);
});

test("personal or unknown account class is truthful and revoked", async () => {
  const rig = instagramRig();
  rig.transport.identity = {
    subject: "9988776655443322",
    accountType: "PERSONAL",
    username: "vetonewslive",
  };
  const state = await beginState(rig);
  await assert.rejects(
    rig.broker.complete(callbackUri(state)),
    (error: unknown) =>
      error instanceof InstagramPublicAuthError &&
      error.code === "account_ineligible",
  );
  assert.equal(rig.issuer.uid, undefined);
  assert.equal(rig.transport.revocationCount, 1);
});

test("exchange, identity and Firebase failures are sanitized", async () => {
  const exchangeRig = instagramRig();
  exchangeRig.transport.exchangeError = true;
  const exchangeState = await beginState(exchangeRig);
  await assert.rejects(
    exchangeRig.broker.complete(callbackUri(exchangeState)),
    (error: unknown) =>
      error instanceof InstagramPublicAuthError &&
      error.code === "provider_unavailable" &&
      !error.message.includes("provider-authored-private-detail"),
  );
  assert.equal(exchangeRig.transport.revocationCount, 0);

  const identityRig = instagramRig();
  identityRig.transport.identityError = true;
  const identityState = await beginState(identityRig);
  await assert.rejects(
    identityRig.broker.complete(callbackUri(identityState)),
    (error: unknown) =>
      error instanceof InstagramPublicAuthError &&
      error.code === "identity_unavailable" &&
      !error.message.includes("provider-authored-private-detail"),
  );
  assert.equal(identityRig.transport.revocationCount, 1);

  const issuerRig = instagramRig();
  issuerRig.issuer.shouldFail = true;
  const issuerState = await beginState(issuerRig);
  await assert.rejects(
    issuerRig.broker.complete(callbackUri(issuerState)),
    (error: unknown) =>
      error instanceof InstagramPublicAuthError &&
      error.code === "token_issue_failed" &&
      !error.message.includes("firebase-private-detail"),
  );
  assert.equal(issuerRig.transport.revocationCount, 1);
});

test("revocation failure prevents returning minted Firebase material", async () => {
  const rig = instagramRig();
  rig.transport.revocationError = true;
  const state = await beginState(rig);
  await assert.rejects(
    rig.broker.complete(callbackUri(state)),
    (error: unknown) =>
      error instanceof InstagramPublicAuthError &&
      error.code === "revocation_failed" &&
      !error.message.includes("provider-authored-private-detail"),
  );
  assert.equal(rig.issuer.uid, "instagram_projected_identity");
  assert.equal(rig.transport.revocationCount, 1);
});

test("unexpected refresh material fails closed after revoking transient access", async () => {
  const rig = instagramRig();
  rig.transport.refreshTokenPresent = true;
  const state = await beginState(rig);
  await assert.rejects(
    rig.broker.complete(callbackUri(state)),
    (error: unknown) =>
      error instanceof InstagramPublicAuthError &&
      error.code === "provider_unavailable",
  );
  assert.equal(rig.transport.revocationCount, 1);
  assert.equal(rig.projector.subject, undefined);
  assert.equal(rig.issuer.uid, undefined);
});

test("Instagram subject projection is deterministic and project-scoped", () => {
  const key = Buffer.alloc(32, 11);
  const first = new HmacInstagramSubjectProjector(
    "moolsocial-dev-503018",
    key,
  );
  const same = new HmacInstagramSubjectProjector(
    "moolsocial-dev-503018",
    key,
  );
  const other = new HmacInstagramSubjectProjector(
    "moolsocial-staging-503018",
    key,
  );
  const uid = first.project("9988776655443322");
  assert.match(uid, /^instagram_[A-Za-z0-9_-]{43}$/u);
  assert.equal(uid, same.project("9988776655443322"));
  assert.notEqual(uid, other.project("9988776655443322"));
  assert.equal(uid.includes("9988776655443322"), false);
  assert.throws(
    () => first.project("personal-name"),
    (error: unknown) =>
      error instanceof InstagramPublicAuthError &&
      error.code === "identity_unavailable",
  );
});

test("fetch transport confines the server secret and provider access material", async () => {
  const calls: Array<{ input: string | URL | Request; init?: RequestInit }> = [];
  const fakeFetch = (async (
    input: string | URL | Request,
    init?: RequestInit,
  ): Promise<Response> => {
    calls.push(init === undefined ? { input } : { input, init });
    const url = input instanceof Request ? input.url : input.toString();
    if (url.includes("api.instagram.com/oauth/access_token")) {
      return Response.json({
        access_token: "synthetic-instagram-access-material",
        user_id: 9988776655443322,
      });
    }
    if (url.includes("graph.instagram.com/me?")) {
      return Response.json({
        id: "9988776655443322",
        account_type: "MEDIA_CREATOR",
        username: "vetonewslive",
      });
    }
    return Response.json({ success: true });
  }) as typeof fetch;
  const transport = new FetchInstagramProviderTransport(
    "synthetic-server-exchange-material",
    fakeFetch,
  );
  const grant = await transport.exchangeCode({
    clientId: CLIENT_ID,
    redirectUri: REDIRECT_URI,
    code: "synthetic-instagram-code",
  });
  assert.equal(grant.refreshTokenPresent, false);
  const identity = await transport.readIdentity(grant.accessToken);
  await transport.revokeAccessToken(grant.accessToken);
  assert.equal(identity.accountType, "MEDIA_CREATOR");
  assert.equal(identity.username, "vetonewslive");
  assert.equal(calls.length, 3);

  const exchange = calls[0];
  assert.ok(exchange?.init);
  assert.equal(new Headers(exchange.init.headers).has("authorization"), false);
  const exchangeForm = new URLSearchParams(exchange.init.body as string);
  assert.deepEqual([...exchangeForm.keys()].sort(), [
    "client_id",
    "client_secret",
    "code",
    "grant_type",
    "redirect_uri",
  ]);
  assert.equal(exchangeForm.get("grant_type"), "authorization_code");

  const identityCall = calls[1];
  assert.ok(identityCall?.init);
  const identityUrl = new URL(identityCall.input.toString());
  assert.equal(
    identityUrl.searchParams.get("fields"),
    "id,account_type,username",
  );
  assert.equal(identityUrl.searchParams.has("access_token"), false);
  assert.equal(
    new Headers(identityCall.init.headers).get("authorization"),
    "Bearer synthetic-instagram-access-material",
  );

  const revoke = calls[2];
  assert.ok(revoke?.init);
  assert.equal(revoke.init.method, "DELETE");
  assert.equal(new URL(revoke.input.toString()).search, "");
  assert.equal(
    new Headers(revoke.init.headers).get("authorization"),
    "Bearer synthetic-instagram-access-material",
  );
});

test("fetch transport rejects an oversized provider body before parsing", async () => {
  const fakeFetch = (async (): Promise<Response> =>
    new Response("x".repeat(64 * 1024 + 1), { status: 200 })) as typeof fetch;
  const transport = new FetchInstagramProviderTransport(
    "synthetic-server-exchange-material",
    fakeFetch,
  );

  await assert.rejects(
    transport.exchangeCode({
      clientId: CLIENT_ID,
      redirectUri: REDIRECT_URI,
      code: "synthetic-instagram-code",
    }),
    (error: unknown) =>
      error instanceof InstagramPublicAuthError &&
      error.code === "provider_unavailable",
  );
});
