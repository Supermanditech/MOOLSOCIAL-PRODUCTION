import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";

const dataSource = await readFile(
  new URL("../lib/admin-data.ts", import.meta.url),
  "utf8",
);
const consoleSource = await readFile(
  new URL("../components/AdminConsole.tsx", import.meta.url),
  "utf8",
);
const authSource = await readFile(
  new URL("../lib/admin-auth.ts", import.meta.url),
  "utf8",
);

const expectedScreens = [
  147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 163, 164,
];

test("all approved Superadmin screens have one production contract", () => {
  for (const screen of expectedScreens) {
    assert.match(dataSource, new RegExp(`screen: ${screen},`));
  }
  assert.equal(
    [...dataSource.matchAll(/screen: (?:14[7-9]|15[0-6]|16[34]),/g)].length,
    expectedScreens.length,
  );
});

test("all 42 approved cases have protected action contracts", () => {
  assert.equal([...dataSource.matchAll(/adminCase\(\{/g)].length, 42);
  assert.equal(
    [...dataSource.matchAll(/primaryOutcome:/g)].length,
    42,
  );
  assert.equal(
    [...dataSource.matchAll(/confirmation:/g)].length >= 8,
    true,
  );
});

test("dynamic offering provisioning keeps profile, result and approval boundaries", () => {
  for (const contractTerm of [
    "Target user or workspace",
    "Offering type",
    "Business-funded Reel",
    "Result the user receives",
    "Eligibility and readiness",
    "Maximum business exposure",
    "Duration, expiry or stop condition",
    "1 day \\(24 hours\\)",
    "2 days \\(48 hours\\)",
    "7 days",
    "User-facing message and next action",
    "Create approval draft",
    "no\\s+charge or launch occurs from this\\s+draft",
  ]) {
    assert.match(consoleSource, new RegExp(contractTerm, "i"));
  }
});

test("offering provisioning covers personal plus all 28 approved workspace profiles", () => {
  const profileBlock = dataSource.match(
    /export const adminProfileTargets = \[([\s\S]*?)\]\s+as const;/,
  );
  assert.ok(profileBlock);
  assert.equal(
    [...profileBlock[1].matchAll(/^\s+"[^"]+",?$/gm)].length,
    29,
  );
  for (const requiredProfile of [
    "Personal user",
    "FMCG Manufacturer",
    "Grocery / Kirana Shop",
    "Individual Doctor",
    "Delivery Partner",
    "Shorts Creator",
    "Long-Form Video Creator",
    "Multi-Format Creator",
    "Get It Done Provider",
  ]) {
    assert.match(profileBlock[1], new RegExp(requiredProfile.replace("/", "\\/")));
  }
});

test("production access denies by default and review access needs an environment switch", () => {
  assert.match(
    authSource,
    /MOOLSOCIAL_ADMIN_REVIEW_MODE === "true"/,
  );
  assert.match(authSource, /allowed: false/);
  assert.match(authSource, /Firebase session/);
});

test("customer-facing admin copy excludes prototype implementation language", () => {
  const forbidden = [
    "simulation",
    "review build",
    "workspace state",
    "raw listing approval",
  ];
  for (const phrase of forbidden) {
    assert.equal(
      dataSource.toLowerCase().includes(phrase),
      false,
      `forbidden phrase: ${phrase}`,
    );
  }
});
