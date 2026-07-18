import assert from "node:assert/strict";
import { access, readFile } from "node:fs/promises";
import test from "node:test";

const appRoot = new URL("../app/", import.meta.url);

test("ships the MoolSocial early-access experience without starter UI", async () => {
  const [page, landing, layout, css, waitlistRoute] = await Promise.all([
    readFile(new URL("page.tsx", appRoot), "utf8"),
    readFile(new URL("LandingPage.tsx", appRoot), "utf8"),
    readFile(new URL("layout.tsx", appRoot), "utf8"),
    readFile(new URL("globals.css", appRoot), "utf8"),
    readFile(new URL("api/waitlist/route.ts", appRoot), "utf8"),
  ]);

  const product = `${page}\n${landing}\n${layout}\n${css}\n${waitlistRoute}`;
  assert.match(product, /MoolSocial/);
  assert.match(product, /More ways to live, earn and grow/);
  assert.match(product, /Join early access/i);
  assert.match(product, /Creators/);
  assert.match(product, /Workers & job seekers/);
  assert.match(product, /Businesses/);
  assert.match(product, /16 October 2026/);
  assert.match(product, /hello@moolsocial\.com/);
  assert.match(product, /Opportunities across India/);
  assert.match(product, /@MoolSocial/);
  assert.match(product, /waitlistLeads/);
  assert.doesNotMatch(product, /codex-preview|react-loading-skeleton/i);

  await assert.rejects(access(new URL("_sites-preview", appRoot)));
});
