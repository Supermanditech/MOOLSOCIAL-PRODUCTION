import { expect, test } from "@playwright/test";

import { adminProfileTargets, adminScreens } from "../lib/admin-data";

function withQuery(path: string, query: string) {
  return path.includes("?") ? `${path}&${query}` : `${path}?${query}`;
}

for (const screen of adminScreens) {
  test(`screen ${screen.screen} completes filters, empty recovery and every nested case action`, async ({
    page,
  }) => {
    await page.goto(withQuery(screen.path, "failure=once"));
    await expect(
      page.getByTestId(`admin-screen-${screen.screen}`),
    ).toBeVisible();
    await expect(page.getByRole("heading", { name: screen.title })).toBeVisible();

    for (const filter of screen.filters) {
      await page
        .getByTestId(`filter-${filter.toLowerCase().replaceAll(" ", "-")}`)
        .click();
    }

    const search = page.getByTestId("queue-search");
    await search.fill("a result that does not exist");
    await expect(page.getByTestId("queue-empty")).toBeVisible();
    await page.getByRole("button", { name: "Clear search and filters" }).click();
    await expect(page.getByTestId("queue-empty")).toHaveCount(0);

    for (const item of screen.items) {
      await page.getByTestId(`case-open-${item.id}`).click();
      await expect(page.getByTestId("case-dialog")).toBeVisible();

      await page.getByTestId("case-primary").click();
      await expect(page.getByTestId("case-error")).toContainText(
        "Confirm the evidence",
      );
      await page.getByTestId("case-confirm").check();

      await page.getByTestId("case-primary").click();
      await expect(page.getByTestId("case-error")).toContainText(
        "Nothing changed",
      );
      await page.getByTestId("case-primary").click();
      await expect(page.getByTestId("case-outcome")).toContainText(
        `ADM-${screen.screen}-${item.id}-primary`.toUpperCase(),
      );
      await page.getByTestId("case-primary").click();
      await expect(page.getByTestId("case-outcome")).toContainText(
        "No duplicate was created",
      );

      if (item.secondary) {
        await page.getByTestId("case-secondary").click();
        await expect(page.getByTestId("case-error")).toContainText(
          "Nothing changed",
        );
        await page.getByTestId("case-secondary").click();
        await expect(page.getByTestId("case-outcome")).toContainText(
          `ADM-${screen.screen}-${item.id}-secondary`.toUpperCase(),
        );
        await page.getByTestId("case-secondary").click();
        await expect(page.getByTestId("case-outcome")).toContainText(
          "No duplicate was created",
        );
      }

      await page.getByTestId("case-close").click();
      await expect(page.getByTestId("case-dialog")).toHaveCount(0);
    }
  });
}

test("screen 156 creates a profile-specific offering through invalid, failed, retry and duplicate states", async ({
  page,
}) => {
  await page.goto("/admin/configuration?failure=once");
  await page.getByTestId("offering-create").click();
  await expect(page.getByTestId("offering-dialog")).toBeVisible();

  await page.getByTestId("offering-review").click();
  await expect(page.getByTestId("offering-form-error")).toContainText(
    "Complete target",
  );

  await expect(page.getByTestId("offering-target").locator("option")).toHaveCount(
    30,
  );
  expect(adminProfileTargets).toHaveLength(29);
  await page
    .getByTestId("offering-target")
    .selectOption("Grocery / Kirana Shop");
  await page.getByTestId("offering-kind").selectOption("Guaranteed outcome");
  await page.getByTestId("offering-name").fill("100 monthly basket customers");
  await page
    .getByTestId("offering-outcome")
    .fill("100 retained household basket subscriptions confirmed for 30 days.");
  await page
    .getByTestId("offering-eligibility")
    .fill("Verified grocery retailer with live stock, delivery and refund readiness.");
  await page.getByTestId("offering-geography").fill("Jodhpur pilot area");
  await page.getByTestId("offering-exposure").fill("₹50,000 maximum");
  await page.getByTestId("offering-expiry").fill("30 days or budget reached");
  await page
    .getByTestId("offering-owner")
    .fill("Retail Growth Operations");
  await page
    .getByTestId("offering-message")
    .fill(
      "Get 100 monthly basket customers. Review readiness, qualifying result and maximum payable amount.",
    );
  await page.getByTestId("offering-review").click();

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
});

for (const mode of ["offline", "denied"] as const) {
  test(`protected commands preserve state when ${mode}`, async ({ page }) => {
    await page.goto(`/admin?mode=${mode}`);
    await page.getByTestId("case-open-payment-safety").click();
    await page.getByTestId("case-confirm").check();
    await page.getByTestId("case-primary").click();
    await expect(page.getByTestId("case-error")).toContainText(
      mode === "offline" ? "offline" : "cannot complete",
    );
    await expect(page.getByTestId("case-outcome")).toHaveCount(0);
  });
}

test("every navigation owner opens the intended governed screen", async ({
  page,
}) => {
  await page.goto("/admin");
  for (const screen of adminScreens) {
    const openNavigation = page.getByRole("button", {
      name: "Open navigation",
    });
    if (await openNavigation.isVisible()) {
      await openNavigation.click();
    }
    await page.getByTestId(`nav-${screen.screen}`).click();
    await expect(
      page.getByTestId(`admin-screen-${screen.screen}`),
    ).toBeVisible();
  }
});
