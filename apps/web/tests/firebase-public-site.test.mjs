import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { access, readFile } from "node:fs/promises";
import test from "node:test";

const publicRoot = new URL("../public/", import.meta.url);
const pages = {
  company: "index.html",
  privacy: "privacy/index.html",
  terms: "terms/index.html",
  support: "support/index.html",
  disconnect: "disconnect/index.html",
  deletion: "delete-account/index.html",
};

const canonicalUrls = {
  company: "https://moolsocial.com/",
  privacy: "https://moolsocial.com/privacy",
  terms: "https://moolsocial.com/terms",
  support: "https://moolsocial.com/support",
  disconnect: "https://moolsocial.com/disconnect",
  deletion: "https://moolsocial.com/delete-account",
};

const approvedCopyDigests = {
  company: "682c245968880b4e34e84720a737791348a4da32e1e1e14d526e70d1dd92576b",
  privacy: "647123836ff438a8f5d6a8e25d2bd999126c885262765fd5c7a57bd27207d8ab",
  terms: "9948a1d9b0e1d48e86a5f466d4f3414b875facf1a09e568390e281339a6d3559",
  support: "1cd3bcd1c934945b3e401ab95f7fa071c1321e1906e07a7afa6ed4596492e1ae",
  disconnect: "006abf94d94c80d7baa5d43743ddfb740f8e3bf9e751332642e920f03d90e17e",
  deletion: "dfded552130632b83675202c0d68a21aa5886b09a4b36bfe2306a78b664bc2b6",
};

async function readPage(path) {
  return readFile(new URL(path, publicRoot), "utf8");
}

function customerCopy(html) {
  const attributes = [...html.matchAll(/\b(?:aria-label|title|placeholder|alt)="([^"]*)"/gi)]
    .map((match) => match[1])
    .join(" ");
  const visible = html
    .replace(/<script\b[\s\S]*?<\/script>/gi, " ")
    .replace(/<style\b[\s\S]*?<\/style>/gi, " ")
    .replace(/<[^>]+>/g, " ");
  return `${visible} ${attributes}`.replace(/\s+/g, " ").trim();
}

function publicCopySurface(html) {
  const metadata = [...html.matchAll(/<meta\b([^>]*)>/gi)]
    .map((match) => match[1])
    .map((attributes) => {
      const key = attributes.match(/\b(?:name|property)="([^"]+)"/i)?.[1] ?? "";
      const content = attributes.match(/\bcontent="([^"]*)"/i)?.[1] ?? "";
      return /^(?:description|og:title|og:description|twitter:title|twitter:description)$/i.test(key)
        ? `${key}: ${content}`
        : "";
    })
    .filter(Boolean);
  const attributes = [...html.matchAll(/\b(?:aria-label|title|placeholder|alt)="([^"]*)"/gi)]
    .map((match) => match[1]);
  const destinations = [...html.matchAll(/<a\b[^>]*\bhref="([^"]+)"/gi)]
    .map((match) => match[1]);
  const visible = html
    .replace(/<script\b[\s\S]*?<\/script>/gi, " ")
    .replace(/<style\b[\s\S]*?<\/style>/gi, " ")
    .replace(/<[^>]+>/g, " ")
    .replace(/\s+/g, " ")
    .trim();
  return [...metadata, ...attributes, ...destinations, visible].join("\n");
}

function copyDigest(html) {
  return createHash("sha256").update(publicCopySurface(html), "utf8").digest("hex");
}

function repeatedMarketingBlocks(html) {
  const blocks = [...html.matchAll(/<(h[1-3]|p)\b[^>]*>([\s\S]*?)<\/\1>/gi)]
    .map((match) => match[2].replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim())
    .filter((text) => text.length >= 32);
  return blocks.filter((text, index) => blocks.indexOf(text) !== index);
}

test("locks every approved public-facing character, label and destination", async () => {
  for (const [name, path] of Object.entries(pages)) {
    const html = await readPage(path);
    assert.equal(
      copyDigest(html),
      approvedCopyDigests[name],
      `${name} public copy changed without a new character-level review`,
    );
    assert.doesNotMatch(html, /\uFFFD/, `${name} contains a replacement character`);
    assert.doesNotMatch(html, /<!--[\s\S]*?-->/, `${name} contains a public HTML comment`);
  }
});

test("ships the Firebase-ready MoolSocial company and compliance surface", async () => {
  const entries = await Promise.all(
    Object.entries(pages).map(async ([name, path]) => [name, await readPage(path)]),
  );
  const content = Object.fromEntries(entries);
  const product = Object.values(content).join("\n");

  assert.match(content.company, /AI-enabled social commerce platform/);
  assert.match(content.company, /social(?:-| )commerce/i);
  assert.match(content.company, /India Ka Social Commerce App/);
  assert.match(content.company, /action-universe/);
  assert.match(content.company, /<section class="hero">[\s\S]*?<p class="eyebrow">Designed across platforms<\/p>[\s\S]*?<h1>MoolSocial moves with you\.<\/h1>/);
  assert.match(content.company, /<section class="hero">[\s\S]*?class="showcase-stage hero-showcase"/);
  assert.match(content.company, /<section class="section preview-section"[\s\S]*?class="action-universe"/);
  assert.match(content.company, /About MoolSocial/);
  assert.match(content.company, /Indian technology company connecting people, businesses and opportunity/);
  assert.match(content.company, /<section class="section preview-section"[\s\S]*?<h2>One connected experience, built around real life\.<\/h2>/);
  assert.doesNotMatch(content.company, />\s*(?:iPhone|Android)(?:\s*·|\s*<)/);
  assert.equal((content.company.match(/phone-platform-ios/g) ?? []).length, 2);
  assert.equal((content.company.match(/phone-platform-android/g) ?? []).length, 4);
  assert.match(content.company, /showcase-stage/);
  assert.match(content.company, /motion-tap/);
  assert.equal((content.company.match(/class="showcase-set showcase-set-/g) ?? []).length, 2);
  assert.equal((content.company.match(/class="showcase-phone-card showcase-phone-/g) ?? []).length, 6);
  assert.doesNotMatch(content.company, /<figcaption>/);
  assert.equal((content.company.match(/class="universe-pulse/g) ?? []).length, 3);
  assert.doesNotMatch(content.company, /class="showcase-view"/);
  assert.doesNotMatch(content.company, /One intelligent ecosystem for people, work and commerce/);
  assert.match(content.company, /24 October 2026/);
  assert.match(content.company, /data-launch-target="2026-10-24T00:00:00\+05:30"/);
  assert.match(content.company, /data-countdown-months/);
  assert.match(content.company, /data-countdown-days/);
  assert.match(content.company, /data-countdown-hours/);
  assert.match(content.company, /data-countdown-minutes/);
  assert.match(content.company, /data-countdown-seconds/);
  assert.match(content.company, /src="\/site\.js\?v=20260726-6"/);
  assert.match(content.company, /100\+ planned roles/);
  assert.match(content.company, /freelancers/i);
  assert.match(content.company, /quick-commerce\s+operators and delivery partners/);
  assert.match(content.company, /X,\s+YouTube, Instagram, Facebook and\s+LinkedIn/);
  assert.match(content.company, /social-icon-x/);
  assert.match(content.company, /social-icon-youtube/);
  assert.match(content.company, /social-icon-instagram/);
  assert.match(content.company, /social-icon-facebook/);
  assert.match(content.company, /social-icon-linkedin/);
  assert.match(content.company, /app-preview-universal-actions\.webp/);
  assert.match(content.company, /app-preview-social-video\.webp/);
  assert.match(content.company, /app-preview-for-you\.webp/);
  assert.match(content.company, /app-preview-create-earn\.webp/);
  assert.match(content.company, /app-preview-shop-deliver\.webp/);
  assert.match(content.company, /app-preview-work-grow\.webp/);
  assert.match(content.company, /hello@moolsocial\.com/);
  assert.match(content.privacy, /uses YouTube API Services/);
  assert.match(content.privacy, /YouTube Terms of Service/);
  assert.match(content.privacy, /Google Privacy Policy/);
  assert.match(content.privacy, /Google API Services User Data Policy/);
  assert.match(content.privacy, /Limited Use requirements/);
  assert.match(content.privacy, /security\.google\.com\/settings\/security\/permissions/);
  assert.match(content.privacy, /within 7 calendar days/);
  assert.match(content.privacy, /Payment gateways, aggregators, banks or payment networks/);
  assert.match(content.privacy, /does not store full card details, CVV/);
  assert.match(content.privacy, /Social or content services, commerce partners, maps, mobility/);
  assert.match(content.terms, /External providers remain separate services/);
  assert.match(content.disconnect, /revoke/);
  assert.match(content.disconnect, /Manage connected accounts and services/);
  assert.match(content.deletion, /cannot delete data held independently by another provider/);
  assert.match(product, /SuperMandi Tech Pvt Ltd/);
  assert.doesNotMatch(product, /B2B2C/i);
  assert.doesNotMatch(product, /Ninety days|90 days|days remaining/i);
  assert.doesNotMatch(product, /lorem ipsum|placeholder|sample legal|TBD/i);
  assert.doesNotMatch(
    customerCopy(content.company),
    /\b(?:prototype|concept|preview|example|demo|mock|placeholder|implementation|workflow|state machine|endpoint|payload|backend|provider callback|for review|for testing)\b/i,
  );
  assert.doesNotMatch(customerCopy(content.company), /Motion shows|Choose an action|One tap|not final|may change/i);
  assert.doesNotMatch(customerCopy(content.company), /\b(?:roadmap|readiness|validate|validation|implementation|workflow|backend)\b|operating support|launch participation/i);
  assert.doesNotMatch(
    customerCopy(content.company),
    /meaningful action|shared digital environment|accountable execution|responsible execution|operating locations|field execution|act on what matters/i,
  );
  assert.doesNotMatch(customerCopy(content.company), /Scheduled public launch|Saturday,\s*24 October 2026/i);
  assert.equal((customerCopy(content.company).match(/24 October 2026/g) ?? []).length, 1);
  assert.deepEqual(repeatedMarketingBlocks(content.company), []);
  assert.doesNotMatch(content.company, /class="action-rail"/);
  assert.doesNotMatch(content.company, /Manage connected services|Delete account or data/);
  assert.doesNotMatch(content.company, /href="\/(?:disconnect|delete-account)\//);

  const header = content.company.match(/<header class="site-header">[\s\S]*?<\/header>/)?.[0] ?? "";
  const navigation = header.match(/<nav[\s\S]*?<\/nav>/)?.[0] ?? "";
  assert.match(navigation, />Our story</);
  assert.match(navigation, />Our vision</);
  assert.match(navigation, />Launch</);
  assert.match(navigation, />Join us</);
  assert.match(navigation, /href="mailto:hello@moolsocial\.com\?subject=MoolSocial%20contact">Contact</);
  assert.doesNotMatch(navigation, />Platform<|>MoolSocial<|>Privacy<|>Support</);

  const navigationContracts = [
    ["Our story", "about", /About MoolSocial[\s\S]*?Indian technology company/],
    ["Our vision", "vision", /AI with clear accountability[\s\S]*?Useful intelligence/],
    ["Launch", "launch", /Built in India[\s\S]*?Join MoolSocial from the beginning/],
    ["Join us", "opportunities", /Join MoolSocial[\s\S]*?Build your future with MoolSocial/],
  ];
  for (const [label, id, destinationCopy] of navigationContracts) {
    assert.match(navigation, new RegExp(`href="#${id}">${label}<`));
    const section = content.company.match(new RegExp(`<section\\b[^>]*\\bid="${id}"[^>]*>[\\s\\S]*?<\\/section>`))?.[0] ?? "";
    assert.match(section, destinationCopy, `${label} does not lead to the content it promises`);
  }

  const launchSection = content.company.match(/<section\b[^>]*\bid="launch"[^>]*>[\s\S]*?<\/section>/)?.[0] ?? "";
  const heroSection = content.company.match(/<section class="hero">[\s\S]*?<\/section>/)?.[0] ?? "";
  assert.doesNotMatch(heroSection, /data-launch-countdown|Register your interest|Contact MoolSocial/);
  assert.match(launchSection, /class="launch-date-card"/);
  assert.match(launchSection, /data-launch-countdown/);
  assert.match(launchSection, /24 October 2026/);
  assert.match(launchSection, /Register your interest/);
  assert.match(launchSection, /Contact MoolSocial/);
  assert.match(launchSection, /class="launch-roadmap"/);
  assert.equal((launchSection.match(/<li>/g) ?? []).length, 3);
  assert.match(launchSection, />Register now</);
  assert.match(launchSection, />Follow MoolSocial</);
  assert.match(launchSection, />Launch day</);
  assert.doesNotMatch(launchSection, /readiness|validate|operating support/i);
  assert.doesNotMatch(launchSection, /Coming to India/i);

  const css = await readFile(new URL("site.css", publicRoot), "utf8");
  assert.match(css, /perspective:\s*1800px/);
  assert.match(css, /@keyframes universe-spin-one/);
  assert.match(css, /@keyframes nav-cluster-float/);
  assert.match(css, /@keyframes nav-link-sweep/);
  assert.match(css, /@keyframes universe-colour-shift/);
  assert.match(css, /@keyframes ring-spectrum/);
  assert.match(css, /@keyframes tricolour-sweep/);
  assert.match(css, /@keyframes showcase-set-cycle/);
  assert.match(css, /@keyframes showcase-phone-center/);
  assert.match(css, /@keyframes showcase-side-left/);
  assert.match(css, /@keyframes showcase-side-right/);
  assert.match(css, /@keyframes showcase-ribbon-sweep/);
  assert.match(css, /@keyframes countdown-cell-depth/);
  assert.match(css, /\.hero-showcase\s*\{/);
  assert.match(css, /\.preview-section \.action-universe\s*\{/);
  assert.match(css, /\.phone-platform-ios::before/);
  assert.match(css, /\.phone-platform-android::after/);
  assert.match(css, /@keyframes ambient-orbit-a/);
  assert.match(css, /@keyframes surface-float/);
  assert.match(css, /@keyframes brand-word-depth/);
  assert.match(css, /@keyframes legal-orbit/);
  assert.match(css, /@keyframes app-tap-tour/);
  assert.match(css, /prefers-reduced-motion:\s*reduce/);
  assert.match(css, /@media \(max-width:\s*1180px\)/);
  assert.match(css, /@media \(max-width:\s*840px\)/);
  assert.match(css, /@media \(max-width:\s*620px\)/);
  assert.match(css, /@media \(max-width:\s*420px\)/);
  assert.match(css, /@media \(min-width:\s*1440px\)/);
  assert.doesNotMatch(css, /\.motion-tap\s*\{[^}]*display:\s*none/is);
  await access(new URL("og-2026-10-24.png", publicRoot));
  await access(new URL("app-preview-for-you.webp", publicRoot));
  await access(new URL("app-preview-universal-actions.webp", publicRoot));
  await access(new URL("app-preview-social-video.webp", publicRoot));
  await access(new URL("app-preview-create-earn.webp", publicRoot));
  await access(new URL("app-preview-shop-deliver.webp", publicRoot));
  await access(new URL("app-preview-work-grow.webp", publicRoot));
  await access(new URL("social-linkedin.png", publicRoot));
  const countdownScript = await readFile(new URL("site.js", publicRoot), "utf8");
  assert.match(countdownScript, /countdown\.dataset\.launchTarget/);
  assert.match(countdownScript, /window\.setInterval\(updateCountdown,\s*1000\)/);
  assert.match(countdownScript, /data-countdown-seconds/);
  assert.match(countdownScript, /data-countdown-minutes/);
  assert.match(countdownScript, /String\(seconds\)\.padStart\(2,\s*"0"\)/);
});

test("every public page exposes the official legal, support and contact paths", async () => {
  const content = Object.fromEntries(
    await Promise.all(
      Object.entries(pages).map(async ([name, path]) => [name, await readPage(path)]),
    ),
  );
  const requiredLinks = [
    'href="/privacy/"',
    'href="/terms/"',
    'href="/support/"',
    'href="mailto:hello@moolsocial.com?subject=MoolSocial%20contact"',
  ];

  for (const [name, page] of Object.entries(content)) {
    for (const link of requiredLinks) {
      assert.match(page, new RegExp(link.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")), `${name} is missing ${link}`);
    }
    const footer = page.match(/<footer class="site-footer">[\s\S]*?<\/footer>/)?.[0] ?? "";
    assert.doesNotMatch(footer, /Manage connected services|Delete account or data/);
  }

  for (const name of ["privacy", "support"]) {
    assert.match(content[name], /href="\/disconnect\/"/);
    assert.match(content[name], /href="\/delete-account\/"/);
  }
});

test("every public click has a real destination and every contact action emails MoolSocial", async () => {
  const content = Object.fromEntries(
    await Promise.all(
      Object.entries(pages).map(async ([name, path]) => [name, await readPage(path)]),
    ),
  );

  for (const [name, html] of Object.entries(content)) {
    assert.doesNotMatch(html, /<button\b/i, `${name} contains an unowned button`);
    const links = [...html.matchAll(/<a\b([^>]*)\bhref="([^"]+)"([^>]*)>([\s\S]*?)<\/a>/gi)];
    assert.ok(links.length > 0, `${name} has no links`);

    for (const [, beforeHref, href, afterHref, body] of links) {
      assert.notEqual(href, "#", `${name} contains an empty fragment link`);
      assert.doesNotMatch(href, /^javascript:/i, `${name} contains a script link`);
      const attributes = `${beforeHref} ${afterHref}`;
      const accessibleName = `${attributes.match(/\baria-label="([^"]+)"/i)?.[1] ?? ""} ${body.replace(/<[^>]+>/g, " ")}`.replace(/\s+/g, " ").trim();
      assert.ok(accessibleName.length > 0, `${name} contains an unnamed link to ${href}`);

      if (href.startsWith("mailto:")) {
        assert.match(href, /^mailto:hello@moolsocial\.com(?:\?|$)/i, `${name} contact does not use hello@moolsocial.com`);
        continue;
      }

      if (href.startsWith("#")) {
        const id = href.slice(1);
        assert.match(html, new RegExp(`\\bid="${id.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}"`), `${name} is missing ${href}`);
        continue;
      }

      if (href.startsWith("/")) {
        const path = href.split(/[?#]/, 1)[0];
        const file = path === "/"
          ? "index.html"
          : `${path.replace(/^\/|\/$/g, "")}/index.html`;
        await access(new URL(file, publicRoot));
        continue;
      }

      assert.match(href, /^https:\/\//i, `${name} contains a non-secure external link`);
    }
  }

  assert.doesNotMatch(
    content.company,
    /<a\b[^>]*class="[^"]*(?:showcase-stage|value-card|action-universe)[^"]*"/i,
    "decorative or informational surfaces must not open another page or email application",
  );

  const contactSurfaces = [
    ...content.company.matchAll(
      /<a\s+class="[^"]*button[^"]*"[^>]*href="([^"]+)"/gi,
    ),
  ];
  assert.ok(contactSurfaces.length >= 6);
  for (const [, href] of contactSurfaces) {
    assert.match(href, /^mailto:hello@moolsocial\.com(?:\?|$)/i);
  }

  const social = content.company.match(/<div class="social-grid"[\s\S]*?<\/div>/)?.[0] ?? "";
  const socialLinks = [...social.matchAll(/href="([^"]+)"/g)].map((match) => match[1]);
  assert.equal(socialLinks.length, 5);
  for (const href of socialLinks) {
    assert.match(href, /^mailto:hello@moolsocial\.com\?/i);
  }
});

test("every public page meets the structural go-live gate", async () => {
  for (const [name, path] of Object.entries(pages)) {
    const html = await readPage(path);
    assert.equal((html.match(/<title>[\s\S]*?<\/title>/gi) ?? []).length, 1, `${name} must have one title`);
    assert.equal((html.match(/<h1\b[\s\S]*?<\/h1>/gi) ?? []).length, 1, `${name} must have one h1`);

    const ids = [...html.matchAll(/\bid="([^"]+)"/gi)].map((match) => match[1]);
    assert.equal(new Set(ids).size, ids.length, `${name} contains duplicate ids`);

    for (const image of html.matchAll(/<img\b([^>]*)>/gi)) {
      assert.match(image[1], /\balt="[^"]*"/i, `${name} contains an image without alt text`);
      assert.match(image[1], /\bwidth="\d+"/i, `${name} contains an image without width`);
      assert.match(image[1], /\bheight="\d+"/i, `${name} contains an image without height`);
    }

    const assetPaths = [...html.matchAll(/\b(?:src|href)="(\/[^"#?]+\.[a-z0-9]+)"/gi)]
      .map((match) => match[1].slice(1));
    for (const assetPath of assetPaths) {
      await access(new URL(assetPath, publicRoot));
    }
  }

  const firebaseConfig = JSON.parse(
    await readFile(new URL("../../../firebase.json", import.meta.url), "utf8"),
  );
  assert.equal(firebaseConfig.hosting.public, "apps/web/public");
  const csp = firebaseConfig.hosting.headers
    .flatMap((entry) => entry.headers)
    .find((header) => header.key === "Content-Security-Policy")?.value ?? "";
  assert.match(csp, /script-src 'self'/);
  assert.doesNotMatch(csp, /script-src 'none'/);

  const globalHeaders = firebaseConfig.hosting.headers
    .find((entry) => entry.source === "**")?.headers ?? [];
  assert.equal(
    globalHeaders.find((header) => header.key === "Cache-Control")?.value,
    "public,max-age=0,must-revalidate",
  );
  const assetHeaders = firebaseConfig.hosting.headers
    .find((entry) => entry.source === "**/*.@(css|png|jpg|jpeg|webp|svg|woff|woff2)")?.headers ?? [];
  assert.equal(
    assetHeaders.find((header) => header.key === "Cache-Control")?.value,
    "public,max-age=3600",
  );
});

test("publishes a coherent Google discovery and canonicalization surface", async () => {
  const content = Object.fromEntries(
    await Promise.all(
      Object.entries(pages).map(async ([name, path]) => [name, await readPage(path)]),
    ),
  );

  for (const [name, html] of Object.entries(content)) {
    assert.match(html, /<html lang="en-IN">/, `${name} must declare its Indian English locale`);
    assert.equal(
      (html.match(/<link rel="canonical"/g) ?? []).length,
      1,
      `${name} must expose exactly one canonical URL`,
    );
    assert.match(
      html,
      new RegExp(
        `<link rel="canonical" href="${canonicalUrls[name].replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}">`,
      ),
      `${name} canonical URL is incorrect`,
    );
    assert.match(html, /<meta name="robots" content="[^"]+">/);
    assert.match(html, /<link rel="icon" href="\/favicon\.svg" type="image\/svg\+xml">/);
    assert.match(html, /<link rel="manifest" href="\/site\.webmanifest">/);
  }

  for (const name of ["company", "privacy", "terms", "support"]) {
    assert.match(content[name], /<meta name="robots" content="index,follow/);
  }
  for (const name of ["disconnect", "deletion"]) {
    assert.match(content[name], /<meta name="robots" content="noindex,follow">/);
  }

  assert.match(content.company, /<meta property="og:site_name" content="MoolSocial">/);
  assert.match(content.company, /<meta property="og:locale" content="en_IN">/);
  assert.match(content.company, /<meta property="og:image:width" content="1536">/);
  assert.match(content.company, /<meta property="og:image:height" content="1024">/);
  assert.match(content.company, /<meta name="twitter:image:alt" content="MoolSocial — AI-Enabled Social Commerce">/);

  const jsonLdSource = content.company.match(
    /<script type="application\/ld\+json">([\s\S]*?)<\/script>/,
  )?.[1];
  assert.ok(jsonLdSource, "company page must include JSON-LD");
  const jsonLd = JSON.parse(jsonLdSource);
  const organization = jsonLd["@graph"].find((entry) => entry["@type"] === "Organization");
  const website = jsonLd["@graph"].find((entry) => entry["@type"] === "WebSite");
  assert.equal(organization.name, "MoolSocial");
  assert.equal(organization.legalName, "SuperMandi Tech Pvt Ltd");
  assert.equal(organization.url, canonicalUrls.company);
  assert.equal(organization.email, "hello@moolsocial.com");
  assert.equal(website.url, canonicalUrls.company);
  assert.equal(website.publisher["@id"], "https://moolsocial.com/#organization");

  const robots = await readPage("robots.txt");
  assert.match(robots, /^User-agent: \*\r?\nAllow: \//);
  assert.match(robots, /Sitemap: https:\/\/moolsocial\.com\/sitemap\.xml/);
  assert.doesNotMatch(robots, /Disallow:\s*\//);

  const sitemap = await readPage("sitemap.xml");
  assert.match(sitemap, /<urlset xmlns="http:\/\/www\.sitemaps\.org\/schemas\/sitemap\/0\.9">/);
  const sitemapUrls = [...sitemap.matchAll(/<loc>([^<]+)<\/loc>/g)].map((match) => match[1]);
  assert.deepEqual(sitemapUrls, [
    canonicalUrls.company,
    canonicalUrls.privacy,
    canonicalUrls.terms,
    canonicalUrls.support,
  ]);
  assert.doesNotMatch(sitemap, /disconnect|delete-account/);
  assert.equal((sitemap.match(/<lastmod>2026-07-26<\/lastmod>/g) ?? []).length, 4);

  const manifest = JSON.parse(await readPage("site.webmanifest"));
  assert.equal(manifest.name, "MoolSocial");
  assert.equal(manifest.start_url, "/");
  assert.equal(manifest.theme_color, "#000080");
  await access(new URL("favicon.svg", publicRoot));
});
