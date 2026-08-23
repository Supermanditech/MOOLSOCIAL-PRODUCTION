import assert from "node:assert/strict";
import { createHmac } from "node:crypto";
import test from "node:test";

import {
  InstagramMetaCallbackError,
  InstagramMetaCallbackService,
} from "./instagram_meta_callbacks.js";

const APP_SECRET = "instagram-meta-callback-test-secret";
const SUBJECT = "9988776655443322";
const PROJECTED_SUBJECT = "instagram_projected_subject";

function signedRequest(
  payload: Record<string, unknown> = {
    algorithm: "HMAC-SHA256",
    user_id: SUBJECT,
    issued_at: 1_787_200_000,
  },
  secret = APP_SECRET,
): string {
  const encodedPayload = Buffer.from(JSON.stringify(payload), "utf8").toString(
    "base64url",
  );
  const signature = createHmac("sha256", secret)
    .update(encodedPayload, "utf8")
    .digest("base64url");
  return `${signature}.${encodedPayload}`;
}

function formBody(value = signedRequest()): Buffer {
  return Buffer.from(
    new URLSearchParams({ signed_request: value }).toString(),
    "utf8",
  );
}

interface Rig {
  readonly service: InstagramMetaCallbackService;
  readonly projected: string[];
  readonly deleted: string[];
  readonly erasures: Array<readonly [string, string]>;
}

function rig(deleteError?: unknown, erasureError?: unknown): Rig {
  const projected: string[] = [];
  const deleted: string[] = [];
  const erasures: Array<readonly [string, string]> = [];
  return {
    service: new InstagramMetaCallbackService({
      appSecret: APP_SECRET,
      subjectProjector: {
        project(subject: string): string {
          projected.push(subject);
          return PROJECTED_SUBJECT;
        },
      },
      firebaseUserDeleter: {
        async deleteUser(uid: string): Promise<void> {
          deleted.push(uid);
          if (deleteError) throw deleteError;
        },
      },
      accountEraser: {
        async requestAccountErasure(
          firebaseUid: string,
          confirmationCode: string,
        ): Promise<void> {
          erasures.push([firebaseUid, confirmationCode]);
          if (erasureError) throw erasureError;
        },
      },
    }),
    projected,
    deleted,
    erasures,
  };
}

test("accepts a signed deauthorization callback and deletes the projected user", async () => {
  const target = rig();
  const result = await target.service.execute(
    "/instagram/deauthorize",
    formBody(),
    "application/x-www-form-urlencoded; charset=utf-8",
  );
  assert.deepEqual(result, { operation: "deauthorize" });
  assert.deepEqual(target.projected, [SUBJECT]);
  assert.deepEqual(target.deleted, [PROJECTED_SUBJECT]);
  assert.deepEqual(target.erasures, []);
});

test("returns a bounded deletion status URL and confirmation code", async () => {
  const target = rig();
  const result = await target.service.execute(
    "/instagram/data-deletion",
    formBody(),
    "application/x-www-form-urlencoded",
  );
  assert.equal(result.operation, "data_deletion");
  if (result.operation !== "data_deletion") return;
  assert.match(result.confirmationCode, /^[A-Za-z0-9_-]{32}$/u);
  const statusUrl = new URL(result.statusUrl);
  assert.equal(statusUrl.origin, "https://moolsocial.com");
  assert.equal(statusUrl.pathname, "/delete-account/");
  assert.equal(
    statusUrl.searchParams.get("confirmation_code"),
    result.confirmationCode,
  );
  assert.deepEqual(target.deleted, []);
  assert.deepEqual(target.erasures, [[PROJECTED_SUBJECT, result.confirmationCode]]);
});

test("treats an already absent Firebase user as an idempotent success", async () => {
  const target = rig({ code: "auth/user-not-found" });
  const result = await target.service.execute(
    "/instagram/deauthorize",
    formBody(),
    "application/x-www-form-urlencoded",
  );
  assert.deepEqual(result, { operation: "deauthorize" });
});

test("rejects a signature created with another app secret", async () => {
  const target = rig();
  await assert.rejects(
    target.service.execute(
      "/instagram/deauthorize",
      formBody(signedRequest(undefined, "another-valid-app-secret")),
      "application/x-www-form-urlencoded",
    ),
    (error: unknown) =>
      error instanceof InstagramMetaCallbackError &&
      error.code === "invalid_signature" &&
      error.httpStatus === 403,
  );
  assert.deepEqual(target.deleted, []);
});

test("rejects an unsupported signed-request algorithm", async () => {
  const target = rig();
  await assert.rejects(
    target.service.execute(
      "/instagram/deauthorize",
      formBody(signedRequest({ algorithm: "none", user_id: SUBJECT })),
      "application/x-www-form-urlencoded",
    ),
    (error: unknown) =>
      error instanceof InstagramMetaCallbackError &&
      error.code === "invalid_request",
  );
});

test("rejects non-form and ambiguous callback bodies", async () => {
  const target = rig();
  await assert.rejects(
    target.service.execute(
      "/instagram/deauthorize",
      formBody(),
      "application/json",
    ),
    InstagramMetaCallbackError,
  );
  await assert.rejects(
    target.service.execute(
      "/instagram/deauthorize",
      Buffer.from(
        `${formBody().toString("utf8")}&unexpected=value`,
        "utf8",
      ),
      "application/x-www-form-urlencoded",
    ),
    InstagramMetaCallbackError,
  );
  assert.deepEqual(target.deleted, []);
});

test("rejects an unrecognized callback route", async () => {
  const target = rig();
  await assert.rejects(
    target.service.execute(
      "/instagram/unknown",
      formBody(),
      "application/x-www-form-urlencoded",
    ),
    (error: unknown) =>
      error instanceof InstagramMetaCallbackError &&
      error.code === "invalid_request",
  );
});

test("surfaces retryable Firebase deletion failures without identifiers", async () => {
  const target = rig(new Error(`delete failed for ${SUBJECT}`));
  await assert.rejects(
    target.service.execute(
      "/instagram/deauthorize",
      formBody(),
      "application/x-www-form-urlencoded",
    ),
    (error: unknown) => {
      assert.ok(error instanceof InstagramMetaCallbackError);
      assert.equal(error.code, "account_deletion_failed");
      assert.equal(error.httpStatus, 503);
      assert.equal(error.retryable, true);
      assert.doesNotMatch(error.message, new RegExp(SUBJECT, "u"));
      return true;
    },
  );
});

test("surfaces retryable durable erasure failures without identifiers", async () => {
  const target = rig(undefined, new Error(`erase failed for ${SUBJECT}`));
  await assert.rejects(
    target.service.execute(
      "/instagram/data-deletion",
      formBody(),
      "application/x-www-form-urlencoded",
    ),
    (error: unknown) => {
      assert.ok(error instanceof InstagramMetaCallbackError);
      assert.equal(error.code, "account_erasure_failed");
      assert.equal(error.httpStatus, 503);
      assert.equal(error.retryable, true);
      assert.doesNotMatch(error.message, new RegExp(SUBJECT, "u"));
      return true;
    },
  );
});

test("rejects weak callback configuration", () => {
  assert.throws(
    () =>
      new InstagramMetaCallbackService({
        appSecret: "short",
        subjectProjector: { project: () => PROJECTED_SUBJECT },
        firebaseUserDeleter: { deleteUser: async () => undefined },
        accountEraser: { requestAccountErasure: async () => undefined },
      }),
    /configuration is invalid/u,
  );
});
