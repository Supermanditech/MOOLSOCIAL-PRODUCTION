import { mkdir } from "node:fs/promises";
import { resolve } from "node:path";

import { chromium, expect } from "@playwright/test";

const cycle = process.argv[2] ?? "1";
const evidenceDirectory = resolve("../../artifacts/quality/superadmin");
const evidencePath = resolve(
  evidenceDirectory,
  `oppo-business-funded-reel-cycle-${cycle}.png`,
);

const browser = await chromium.connectOverCDP("http://127.0.0.1:9222");
const context = browser.contexts()[0];
if (!context) {
  throw new Error("OPPO Chrome did not expose a browser context.");
}

const pages = context.pages();
const page =
  pages.find((candidate) => candidate.url().startsWith("http://127.0.0.1:3100")) ??
  pages.find((candidate) => candidate.url().startsWith("chrome-native://"));
if (!page) {
  throw new Error("OPPO Chrome did not expose a safe review page.");
}

await page.goto(
  `http://127.0.0.1:3100/admin/configuration?failure=once&deviceCycle=${cycle}`,
  { waitUntil: "networkidle" },
);
await expect(page.getByTestId("admin-screen-156")).toBeVisible();
await expect(page.getByRole("heading", { name: "Offering Provisioning and Launch" })).toBeVisible();

const horizontalOverflow = await page.evaluate(
  () => document.documentElement.scrollWidth > window.innerWidth,
);
expect(horizontalOverflow).toBe(false);

await page.getByTestId("offering-create").click();
await expect(page.getByTestId("offering-dialog")).toBeVisible();
await page.getByTestId("offering-review").click();
await expect(page.getByTestId("offering-form-error")).toContainText(
  "Complete target",
);

await page.getByTestId("offering-target").selectOption("Shorts Creator");
await page
  .getByTestId("offering-kind")
  .selectOption("Business-funded Reel");
await expect(page.getByTestId("offering-expiry").locator("option")).toHaveCount(
  8,
);
await page.getByTestId("offering-name").fill("Jodhpur grocery discovery Reel");
await page
  .getByTestId("offering-outcome")
  .fill("A disclosed sponsored Reel remains discoverable for 48 hours.");
await page
  .getByTestId("offering-eligibility")
  .fill("Verified creator, approved business, reserved pay and content rights.");
await page.getByTestId("offering-geography").fill("Jodhpur");
await page.getByTestId("offering-exposure").fill("₹25,000 maximum");
await page
  .getByTestId("offering-expiry")
  .selectOption("2 days (48 hours)");
await page
  .getByTestId("offering-owner")
  .fill("Creator Campaign Operations");
await page
  .getByTestId("offering-message")
  .fill(
    "Publish one sponsored Reel for 48 hours. Review reserved pay, disclosure and automatic expiry.",
  );
await page.getByTestId("offering-review").click();

await expect(page.getByText("Business-funded Reel", { exact: true })).toBeVisible();
await expect(page.getByText("2 days (48 hours)", { exact: true })).toBeVisible();
await page.getByTestId("offering-submit").click();
await expect(page.getByTestId("offering-error")).toContainText(
  "Confirm the user-facing",
);
await page.getByTestId("offering-confirm").check();
await page.getByTestId("offering-submit").click();
await expect(page.getByTestId("offering-error")).toContainText(
  "draft was not created",
);
await page.getByTestId("offering-submit").click();
await expect(page.getByTestId("offering-outcome-id")).toContainText(
  "OFR-DRAFT-156-0719",
);
await page.getByTestId("offering-submit").click();
await expect(page.getByTestId("offering-outcome-id")).toContainText(
  "no budget was charged",
);

await mkdir(evidenceDirectory, { recursive: true });
await page.screenshot({ path: evidencePath, fullPage: false });

process.stdout.write(
  `${JSON.stringify({
    cycle,
    device: "OPPO CPH2375",
    screen: 156,
    path: "Business-funded Reel > 2 days (48 hours) > approval draft",
    invalid: "passed",
    failedActionReplay: "passed",
    duplicateProtection: "passed",
    result: "OFR-DRAFT-156-0719",
    horizontalOverflow: false,
    evidencePath,
  })}\n`,
);

await browser.close();
