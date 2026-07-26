const fs = require("fs");
const path = require("path");
const { chromium } = require("../../../apps/admin/node_modules/playwright");

const url = "http://127.0.0.1:8765/screens/04-universal-focus-shell.html?founderReview=1&rail=capability&social=videos";
const outputDir = __dirname;
const viewports = [
  [320, 568],
  [360, 640],
  [360, 720],
  [375, 667],
  [390, 844],
  [412, 915],
  [430, 932],
];
const scales = [1, 1.4];
const checks = [];
const findings = [];
const consoleErrors = [];

function check(ok, message) {
  checks.push({ ok, message });
  if (!ok) findings.push(message);
}

async function visibleSurface(page, label) {
  const result = await page.evaluate(() => {
    const visible = (element) => {
      const box = element.getBoundingClientRect();
      const style = getComputedStyle(element);
      return box.width > 0 && box.height > 0 && style.display !== "none" && style.visibility !== "hidden";
    };
    const scope = document.querySelector("[data-app]") || document.body;
    const controls = [...scope.querySelectorAll("button,a,input,textarea,select")].filter(visible);
    const undersized = controls.map((element) => {
      const box = element.getBoundingClientRect();
      return {
        label: (element.getAttribute("aria-label") || element.textContent || "").trim().replace(/\s+/g, " ").slice(0, 90),
        width: Math.round(box.width * 10) / 10,
        height: Math.round(box.height * 10) / 10,
      };
    }).filter((item) => item.width < 43.5 || item.height < 43.5);
    const clipped = controls.filter((element) =>
      element.scrollWidth > element.clientWidth + 1 || element.scrollHeight > element.clientHeight + 1
    ).map((element) => (element.getAttribute("aria-label") || element.textContent || "").trim().replace(/\s+/g, " ").slice(0, 90));
    return {
      overflow: document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
      undersized,
      clipped,
      text: (document.body.innerText || "").replace(/\s+/g, " "),
    };
  });
  check(!result.overflow, `${label}: no horizontal page overflow`);
  check(result.undersized.length === 0, `${label}: all visible controls are at least 44x44 (${JSON.stringify(result.undersized)})`);
  check(result.clipped.length === 0, `${label}: visible control labels are not clipped (${JSON.stringify(result.clipped)})`);
  const forbidden = /\b(example|prototype|reviewer|founder|backend|state machine|dummy|placeholder|test data|sample data|lorem ipsum)\b/i;
  check(!forbidden.test(result.text), `${label}: no internal, review or example wording is visible`);
}

async function show(page, section) {
  await page.evaluate((name) => window.__MOOLSOCIAL_UNIVERSAL__.focusWorld("social", name), section);
  await page.waitForTimeout(40);
}

async function capture(page, name) {
  await page.screenshot({ path: path.join(outputDir, name), fullPage: true });
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  try {
    for (const [width, height] of viewports) {
      for (const scale of scales) {
        const page = await browser.newPage({ viewport: { width, height } });
        page.on("console", (message) => {
          if (message.type() === "error") consoleErrors.push(`${width}x${height}@${scale}: ${message.text()}`);
        });
        page.on("pageerror", (error) => consoleErrors.push(`${width}x${height}@${scale}: ${error.message}`));
        await page.goto(url, { waitUntil: "domcontentloaded" });
        if (scale !== 1) await page.addStyleTag({ content: `html{font-size:${scale * 100}% !important}` });
        const prefix = `${width}x${height}@${Math.round(scale * 100)}%`;

        check(await page.locator(".social-video-home-v2").count() === 1, `${prefix}: discovery surface renders`);
        check(await page.locator(".social-video-home-item-v2").count() >= 3, `${prefix}: media-first video choices render`);
        check(await page.locator(".social-watch-back,[data-social-video-home]").count() === 0, `${prefix}: rejected page-level Videos back control is absent`);
        check(await page.locator("[data-app].social-videos-compact").count() === 1, `${prefix}: Videos uses the compact media header`);
        check(await page.locator(".social-videos-compact .area-row:visible").count() === 0, `${prefix}: Videos does not expose serviceable area`);
        check(await page.locator(".social-videos-compact .command-bar:visible").count() === 0, `${prefix}: Videos does not expose the Universal command bar`);
        check(await page.locator("[data-social-video-search-toggle]:visible").count() === 1, `${prefix}: Videos exposes one compact search trigger`);
        await page.locator("[data-social-video-search-toggle]").click();
        check(await page.locator("[data-social-video-header-search]:visible").count() === 1, `${prefix}: compact video search expands in place`);
        await page.locator("[data-social-video-search-toggle]").click();
        await visibleSurface(page, `${prefix} discovery`);

        const scroll = await page.evaluate(() => {
          const element = document.querySelector("[data-content-scroll]");
          const target = Math.min(360, Math.max(0, element.scrollHeight - element.clientHeight));
          element.scrollTop = target;
          return target;
        });
        await page.locator('.social-video-home-item-v2[data-social-video="yt-morning-mobility"]').click();
        check(await page.locator(".social-video-watch-v2").count() === 1, `${prefix}: video tap opens watch surface`);
        check(await page.locator(".youtube-comments-preview-v2").count() === 1, `${prefix}: comments preview renders`);
        check(await page.locator(".social-watch-back,[data-social-video-home]").count() === 0, `${prefix}: watch uses native history instead of a duplicate back pill`);
        await visibleSurface(page, `${prefix} watch`);

        await page.locator('[data-social-action="youtube-details"]').first().click();
        check(await page.locator('[data-sheet-layer]:not([hidden]) [data-sheet-title]').filter({ hasText: "Description" }).count() === 1, `${prefix}: details tap opens Description`);
        check(await page.locator(".youtube-detail-stats-v2").count() >= 1, `${prefix}: supported video metadata renders`);
        await visibleSurface(page, `${prefix} details`);

        await page.locator('[data-sheet-layer]:not([hidden]) [data-social-action="youtube-channel"]').click();
        check(await page.locator('[data-sheet-layer]:not([hidden]) [data-sheet-title]').filter({ hasText: "Move With Asha" }).count() === 1, `${prefix}: channel tap opens channel details`);
        check(await page.locator('[data-sheet-layer]:not([hidden]) .youtube-channel-card-v2').count() === 1, `${prefix}: channel identity renders once`);
        await visibleSurface(page, `${prefix} channel`);

        if (width === 390 && height === 844 && scale === 1) await capture(page, "04-videos-channel-390x844.png");
        await page.goBack();
        check(await page.locator('[data-sheet-layer]:not([hidden]) [data-sheet-title]').filter({ hasText: "Description" }).count() === 1, `${prefix}: native Back restores Description`);
        if (width === 390 && height === 844 && scale === 1) await capture(page, "03-videos-description-390x844.png");
        await page.goBack();
        await page.waitForTimeout(50);
        check(await page.locator(".social-video-watch-v2").count() === 1, `${prefix}: native Back restores watch surface`);
        if (width === 390 && height === 844 && scale === 1) await capture(page, "02-videos-watch-390x844.png");
        await page.goBack();
        await page.waitForTimeout(50);
        check(await page.locator(".social-video-home-v2").count() === 1, `${prefix}: native Back restores discovery`);
        const restoredScroll = await page.evaluate(() => document.querySelector("[data-content-scroll]").scrollTop);
        check(scroll <= 10 || Math.abs(restoredScroll - scroll) <= 2, `${prefix}: meaningful discovery scroll position restores (${scroll} -> ${restoredScroll})`);
        if (width === 390 && height === 844 && scale === 1) await capture(page, "01-videos-discovery-390x844.png");

        for (const mode of ["all", "popular", "live", "learning", "local", "business"]) {
          await page.locator(`[data-social-video-mode="${mode}"]`).click();
          check(await page.locator(`[data-social-video-mode="${mode}"][aria-pressed="true"]`).count() === 1, `${prefix}: ${mode} video mode becomes active`);
          check(await page.locator(".social-video-home-item-v2").count() >= 1, `${prefix}: ${mode} video mode has content`);
        }

        await show(page, "shorts");
        check(await page.locator('.social-reels-view[aria-label="MoolSocial Reels and verified YouTube Shorts"]').count() === 1, `${prefix}: Shorts surface renders`);
        await visibleSurface(page, `${prefix} Shorts`);
        if (width === 390 && height === 844 && scale === 1) await capture(page, "05-shorts-390x844.png");

        await show(page, "feed");
        check(await page.locator('.social-feed-compose[aria-label="Create a post in Feed"]').count() === 1, `${prefix}: Feed provides an immediate composer`);
        const feedComposerPosition = await page.evaluate(() => {
          const app = document.querySelector("[data-app]").getBoundingClientRect();
          const composer = document.querySelector(".social-feed-compose-bottom").getBoundingClientRect();
          return { appHeight: app.height, composerBottom: composer.bottom - app.top };
        });
        check(feedComposerPosition.composerBottom >= feedComposerPosition.appHeight * .68,
          `${prefix}: Feed composer stays in the lower thumb zone`);
        await visibleSurface(page, `${prefix} Feed`);
        if (width === 390 && height === 844 && scale === 1) await capture(page, "06-feed-390x844.png");

        await show(page, "create");
        check(await page.locator('[aria-label="Create on MoolSocial"]').count() >= 1, `${prefix}: direct Create workbench renders`);
        const createText = await page.locator("[data-world-panel]").innerText();
        for (const label of ["Reel", "Carousel", "Post", "Image", "Image Poll", "Quick Poll", "Quiz"]) {
          check(createText.includes(label), `${prefix}: Create exposes ${label}`);
        }
        const createDockPosition = await page.evaluate(() => {
          const app = document.querySelector("[data-app]").getBoundingClientRect();
          const dock = document.querySelector(".social-create-thumb-dock").getBoundingClientRect();
          return { appHeight: app.height, dockBottom: dock.bottom - app.top };
        });
        check(createDockPosition.dockBottom >= createDockPosition.appHeight * .68,
          `${prefix}: Create workbench stays in the lower thumb zone`);
        await page.locator('[data-social-create-tool="text-poll"]').click();
        check(await page.locator('.social-poll-builder[aria-label="Create Quick Poll"]').count() === 1,
          `${prefix}: Quick Poll opens directly inside Create`);
        await page.locator('[data-social-create-tool="quiz"]').click();
        check(await page.locator('.social-poll-builder[aria-label="Create Quiz"]').count() === 1,
          `${prefix}: Quiz opens directly inside Create`);
        await visibleSurface(page, `${prefix} Create`);
        if (width === 390 && height === 844 && scale === 1) await capture(page, "07-create-390x844.png");
        await page.close();
      }
    }
  } finally {
    await browser.close();
  }

  check(consoleErrors.length === 0, `no console or page errors (${JSON.stringify(consoleErrors)})`);
  const result = {
    url,
    checkedAt: new Date().toISOString(),
    viewports,
    textScales: scales,
    assertions: checks.length,
    passed: checks.filter((item) => item.ok).length,
    findings,
    consoleErrors,
  };
  fs.writeFileSync(path.join(outputDir, "screen04-social-final-mission-audit-result.json"), `${JSON.stringify(result, null, 2)}\n`);
  process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
  if (findings.length) process.exitCode = 1;
})().catch((error) => {
  process.stderr.write(`${error.stack || error}\n`);
  process.exitCode = 1;
});
