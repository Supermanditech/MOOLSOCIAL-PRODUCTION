import assert from "node:assert/strict";
import test from "node:test";

import { SocialContentError } from "./contracts.js";
import {
  verifySocialInvocation,
  type SocialRequestSecurityDependencies,
} from "./request_security.js";

const validHeaders = {
  "x-firebase-appcheck": "app-check-token",
  authorization: "Bearer firebase-id-token",
};

test("requires App Check before Firebase Auth", async () => {
  let authCalls = 0;
  const dependencies = deps({
    verifyIdToken: async () => {
      authCalls += 1;
      return { uid: "user-1" };
    },
  });
  await assert.rejects(
    verifySocialInvocation({ authorization: validHeaders.authorization }, dependencies, false),
    (error: unknown) => error instanceof SocialContentError && error.code === "permission_denied",
  );
  assert.equal(authCalls, 0);
});

test("requires a valid Firebase identity after App Check", async () => {
  await assert.rejects(
    verifySocialInvocation(
      { "x-firebase-appcheck": validHeaders["x-firebase-appcheck"] },
      deps(),
      false,
    ),
    (error: unknown) => error instanceof SocialContentError && error.code === "authentication_required",
  );
});

test("rejects a consumed limited-use App Check token for mutation", async () => {
  const dependencies = deps({
    verifyAppCheck: async () => ({ alreadyConsumed: true }),
  });
  await assert.rejects(
    verifySocialInvocation(validHeaders, dependencies, true),
    (error: unknown) => error instanceof SocialContentError && error.code === "permission_denied",
  );
});

test("returns only the verified Firebase uid", async () => {
  let consumed = false;
  const dependencies = deps({
    verifyAppCheck: async (_, consume) => {
      consumed = consume;
      return {};
    },
  });
  assert.equal(await verifySocialInvocation(validHeaders, dependencies, true), "user-1");
  assert.equal(consumed, true);
});

test("allows an App Check verified public read without Firebase Auth", async () => {
  let authCalls = 0;
  const dependencies = deps({
    verifyIdToken: async () => {
      authCalls += 1;
      return { uid: "user-1" };
    },
  });
  assert.equal(
    await verifySocialInvocation(
      { "x-firebase-appcheck": validHeaders["x-firebase-appcheck"] },
      dependencies,
      false,
      false,
    ),
    undefined,
  );
  assert.equal(authCalls, 0);
});

function deps(
  overrides: Partial<SocialRequestSecurityDependencies> = {},
): SocialRequestSecurityDependencies {
  return {
    verifyAppCheck: async () => ({}),
    verifyIdToken: async () => ({ uid: "user-1" }),
    ...overrides,
  };
}
