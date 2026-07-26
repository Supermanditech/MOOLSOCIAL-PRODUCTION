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
  assert.match(product, /India Ka Social Commerce App/);
  assert.match(product, /One connected experience/);
  assert.match(product, /built around real life/);
  assert.match(product, /Reserve my early access/i);
  assert.match(product, /Creators/);
  assert.match(product, /Workers & job seekers/);
  assert.match(product, /Businesses/);
  assert.match(product, /24 October 2026/);
  assert.match(product, /hello@moolsocial\.com/);
  assert.match(product, /Opportunities across India/);
  assert.match(product, /X, YouTube, Instagram, Facebook and LinkedIn/);
  assert.match(product, /social-brand-icon-linkedin/);
  assert.match(product, /100\+ upcoming/);
  assert.match(product, /Designed across platforms/);
  assert.match(product, /MoolSocial moves with you/);
  assert.match(product, /launchTarget/);
  assert.match(product, /getLaunchCountdown/);
  assert.match(product, /Months/);
  assert.match(product, /Minutes/);
  assert.match(product, /Seconds/);
  assert.match(product, /hero-showcase/);
  assert.doesNotMatch(product, /<figcaption>/);
  assert.doesNotMatch(product, />\s*(?:iPhone|Android)(?:\s*·|\s*<)/);
  assert.match(product, /phone-platform-ios/);
  assert.match(product, /phone-platform-android/);
  assert.match(product, /showcase-stage/);
  assert.match(product, /motion-tap/);
  assert.match(product, /@keyframes app-tap-tour/);
  assert.match(product, /productViewSets/);
  assert.match(product, /showcase-set/);
  assert.match(product, /showcase-phone-card/);
  assert.match(product, /@keyframes showcase-set-cycle/);
  assert.match(product, /@keyframes showcase-phone-center/);
  assert.match(product, /@keyframes showcase-side-left/);
  assert.match(product, /@keyframes showcase-side-right/);
  assert.match(product, /@keyframes showcase-ribbon-sweep/);
  assert.match(product, /@keyframes countdown-cell-depth/);
  assert.match(product, /\.phone-platform-ios::before/);
  assert.match(product, /\.phone-platform-android::after/);
  assert.match(product, /@keyframes nav-cluster-float/);
  assert.match(product, /@keyframes nav-link-sweep/);
  assert.match(product, /@media \(max-width:\s*1180px\)/);
  assert.match(product, /@media \(max-width:\s*420px\)/);
  assert.match(product, /@media \(min-width:\s*1440px\)/);
  assert.match(product, /@keyframes brand-word-depth/);
  assert.match(product, /app-preview-universal-actions\.webp/);
  assert.match(product, /app-preview-social-video\.webp/);
  assert.match(product, /Social/);
  assert.match(product, /Shorts/);
  assert.match(product, /Videos/);
  assert.match(product, /Ride/);
  assert.match(product, /Pay/);
  assert.doesNotMatch(product, /B2B2C/i);
  assert.doesNotMatch(product, /Ninety days|90 days|days remaining/i);
  assert.doesNotMatch(product, /Motion shows what happens after every action/i);
  assert.doesNotMatch(product, /Choose an action|One tap → clear outcome/i);
  assert.doesNotMatch(product, /Concept capability previews|Illustrative action flow/i);
  assert.doesNotMatch(product, /Manage connected services|Delete account or data/i);
  assert.doesNotMatch(product, /placeholder="you@example\.com"/i);
  assert.match(product, /waitlistLeads/);
  assert.doesNotMatch(product, /codex-preview|react-loading-skeleton/i);

  await assert.rejects(access(new URL("_sites-preview", appRoot)));
});
