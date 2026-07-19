import { expect, test } from "@playwright/test";

import { adminScreens } from "../lib/admin-data";

async function prepareVisual(page: import("@playwright/test").Page) {
  await page.addStyleTag({
    content: "nextjs-portal { display: none !important; }",
  });
  const hasHorizontalOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > window.innerWidth,
  );
  expect(hasHorizontalOverflow).toBe(false);
}

async function completeBusinessReelDraft(
  page: import("@playwright/test").Page,
) {
  await page.getByTestId("offering-target").selectOption("Shorts Creator");
  await page
    .getByTestId("offering-kind")
    .selectOption("Business-funded Reel");
  await page
    .getByTestId("offering-name")
    .fill("Jodhpur grocery discovery Reel");
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
}

for (const screen of adminScreens) {
  test(`screen ${screen.screen} responsive visual baseline`, async ({ page }) => {
    await page.goto(screen.path);
    await expect(
      page.getByTestId(`admin-screen-${screen.screen}`),
    ).toBeVisible();
    await prepareVisual(page);
    await expect(page).toHaveScreenshot(`admin-${screen.screen}.png`, {
      animations: "disabled",
      fullPage: true,
      maxDiffPixelRatio: 0.003,
    });
  });
}

test("nested case action is responsive", async ({ page }) => {
  await page.goto("/admin");
  await page.getByTestId("case-open-payment-safety").click();
  await expect(page.getByTestId("case-dialog")).toBeVisible();
  await prepareVisual(page);
  await expect(page).toHaveScreenshot("admin-case-action.png", {
    animations: "disabled",
    maxDiffPixelRatio: 0.003,
  });
});

test("business-funded Reel composer is responsive", async ({ page }) => {
  await page.goto("/admin/configuration");
  await page.getByTestId("offering-create").click();
  await expect(page.getByTestId("offering-dialog")).toBeVisible();
  await completeBusinessReelDraft(page);
  await prepareVisual(page);
  await expect(page).toHaveScreenshot("admin-reel-composer.png", {
    animations: "disabled",
    maxDiffPixelRatio: 0.003,
  });
});

test("business-funded Reel review is responsive", async ({ page }) => {
  await page.goto("/admin/configuration");
  await page.getByTestId("offering-create").click();
  await completeBusinessReelDraft(page);
  await page.getByTestId("offering-review").click();
  await expect(page.getByText("Review offering promise")).toBeVisible();
  await prepareVisual(page);
  await expect(page).toHaveScreenshot("admin-reel-review.png", {
    animations: "disabled",
    maxDiffPixelRatio: 0.003,
  });
});
