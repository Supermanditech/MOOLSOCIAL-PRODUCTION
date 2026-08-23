import assert from "node:assert/strict";
import { createHmac } from "node:crypto";
import test from "node:test";

import {
  FacebookMetaCallbackError,
  FacebookMetaCallbackService,
} from "./facebook_meta_callbacks.js";

const APP_SECRET = "facebook-meta-callback-test-secret";
const SUBJECT = "1122334455667788";

function signedRequest(
  payload: Record<string, unknown> = {
    algorithm: "HMAC-SHA256",
    user_id: SUBJECT,
  },
  secret = APP_SECRET,
): string {
  const encoded = Buffer.from(JSON.stringify(payload), "utf8").toString(
    "base64url",
  );
  const signature = createHmac("sha256", secret)
    .update(encoded, "utf8")
    .digest("base64url");
  return `${signature}.${encoded}`;
}

function form(value = signedRequest()): Buffer {
  return Buffer.from(
    new URLSearchParams({ signed_request: value }).toString(),
    "utf8",
  );
}

function rig(cleanupError?: unknown, erasureError?: unknown): {
  service: FacebookMetaCallbackService;
  subjects: string[];
  erasures: Array<readonly [string, string]>;
} {
  const subjects: string[] = [];
  const erasures: Array<readonly [string, string]> = [];
  return {
    service: new FacebookMetaCallbackService({
      appSecret: APP_SECRET,
      accountCleaner: {
        async removeProviderAccess(providerUid: string): Promise<void> {
          subjects.push(providerUid);
          if (cleanupError) throw cleanupError;
        },
      },
      accountEraser: {
        async requestAccountErasure(
          providerUid: string,
          confirmationCode: string,
        ): Promise<void> {
          erasures.push([providerUid, confirmationCode]);
          if (erasureError) throw erasureError;
        },
      },
    }),
    subjects,
    erasures,
  };
}

test("accepts a signed deauthorization request and removes provider access", async () => {
  const target = rig();
  const result = await target.service.execute(
    "/facebook/deauthorize",
    form(),
    "application/x-www-form-urlencoded; charset=utf-8",
  );
  assert.deepEqual(result, { operation: "deauthorize" });
  assert.deepEqual(target.subjects, [SUBJECT]);
});

test("returns a bounded data-deletion status response", async () => {
  const target = rig();
  const result = await target.service.execute(
    "/facebook/data-deletion",
    form(),
    "application/x-www-form-urlencoded",
  );
  assert.equal(result.operation, "data_deletion");
  if (result.operation !== "data_deletion") return;
  assert.match(result.confirmationCode, /^[A-Za-z0-9_-]{32}$/u);
  const status = new URL(result.statusUrl);
  assert.equal(status.origin, "https://moolsocial.com");
  assert.equal(status.pathname, "/delete-account/");
  assert.equal(
    status.searchParams.get("confirmation_code"),
    result.confirmationCode,
  );
  assert.deepEqual(target.subjects, []);
  assert.deepEqual(target.erasures, [[SUBJECT, result.confirmationCode]]);
});

test("rejects a signed request from another app secret", async () => {
  const target = rig();
  await assert.rejects(
    target.service.execute(
      "/facebook/deauthorize",
      form(signedRequest(undefined, "another-valid-app-secret")),
      "application/x-www-form-urlencoded",
    ),
    (error: unknown) =>
      error instanceof FacebookMetaCallbackError &&
      error.code === "invalid_signature" &&
      error.httpStatus === 403,
  );
  assert.deepEqual(target.subjects, []);
});

test("rejects malformed algorithm subject content type and extra form keys", async () => {
  const target = rig();
  const cases: Array<readonly [Buffer, string]> = [
    [
      form(signedRequest({ algorithm: "none", user_id: SUBJECT })),
      "application/x-www-form-urlencoded",
    ],
    [
      form(signedRequest({ algorithm: "HMAC-SHA256", user_id: "invalid" })),
      "application/x-www-form-urlencoded",
    ],
    [form(), "application/json"],
    [
      Buffer.from(`${form().toString("utf8")}&extra=value`, "utf8"),
      "application/x-www-form-urlencoded",
    ],
  ];
  for (const [body, contentType] of cases) {
    await assert.rejects(
      target.service.execute("/facebook/deauthorize", body, contentType),
      (error: unknown) =>
        error instanceof FacebookMetaCallbackError &&
        error.code === "invalid_request",
    );
  }
  assert.deepEqual(target.subjects, []);
});

test("rejects unknown callback routes", async () => {
  const target = rig();
  await assert.rejects(
    target.service.execute(
      "/facebook/unknown",
      form(),
      "application/x-www-form-urlencoded",
    ),
    FacebookMetaCallbackError,
  );
});

test("sanitizes provider-account cleanup failures", async () => {
  const target = rig(new Error(`cleanup failed for ${SUBJECT}`));
  await assert.rejects(
    target.service.execute(
      "/facebook/deauthorize",
      form(),
      "application/x-www-form-urlencoded",
    ),
    (error: unknown) => {
      assert.ok(error instanceof FacebookMetaCallbackError);
      assert.equal(error.code, "account_cleanup_failed");
      assert.equal(error.httpStatus, 503);
      assert.equal(error.retryable, true);
      assert.doesNotMatch(error.message, new RegExp(SUBJECT, "u"));
      return true;
    },
  );
});

test("sanitizes durable account-erasure failures", async () => {
  const target = rig(undefined, new Error(`erasure failed for ${SUBJECT}`));
  await assert.rejects(
    target.service.execute(
      "/facebook/data-deletion",
      form(),
      "application/x-www-form-urlencoded",
    ),
    (error: unknown) => {
      assert.ok(error instanceof FacebookMetaCallbackError);
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
      new FacebookMetaCallbackService({
        appSecret: "short",
        accountCleaner: { removeProviderAccess: async () => undefined },
        accountEraser: { requestAccountErasure: async () => undefined },
      }),
    /configuration is invalid/u,
  );
});
