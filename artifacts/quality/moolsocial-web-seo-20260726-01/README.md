# MoolSocial technical SEO release — 26 July 2026

## Result

PASS for public crawlability and technical search readiness.

The live website now provides:

- an indexable homepage with a self-referencing canonical URL;
- unique canonical and social metadata for public policy and support pages;
- `robots.txt` with an absolute sitemap declaration;
- a root XML sitemap containing only canonical, indexable pages;
- `Organization` and `WebSite` structured data;
- a crawlable MoolSocial favicon and web manifest;
- deliberate `noindex,follow` treatment for account-management utilities;
- consistent `en-IN` language metadata;
- canonical signals that point the Firebase-hosted duplicate to `https://moolsocial.com/`.

Live website: <https://moolsocial.com/>

## Verification

- Production build: PASS
- Automated tests: PASS, 7/7
- Lint: PASS, zero errors
- Source-to-live byte comparison: PASS, 23/23
- Googlebot-style fetch: PASS, HTTP 200
- `robots.txt`: PASS, HTTP 200 and `text/plain`
- `sitemap.xml`: PASS, HTTP 200 and `application/xml`
- Structured data: PASS, valid JSON containing `Organization` and `WebSite`
- Browser rendering: PASS, no console error and no horizontal overflow

## Google Search Console

The `moolsocial.com` domain property exists, but the signed-in account
`hello@moolsocial.com` is not currently verified for it. Google presented
`Verify your ownership`.

After ownership verification, the remaining submission steps are:

1. submit `https://moolsocial.com/sitemap.xml`;
2. inspect `https://moolsocial.com/`;
3. run the live URL test;
4. request indexing;
5. monitor Page Indexing and Search Performance.

Google states that a sitemap and indexing request are discovery signals, not a
guarantee of immediate inclusion or ranking.

## Source hashes

| File | SHA-256 |
| --- | --- |
| `apps/web/public/index.html` | `80adb97768789630691ee4777adf784304d101ca13784f2791051989903ff59e` |
| `apps/web/public/privacy/index.html` | `29830e44149c66342827497437eb6ff5377cdf27f369ebab57db2f9f0fdd13e4` |
| `apps/web/public/terms/index.html` | `cd76f595e661472fc1f8fee4dff322d8bd041828ab60599e9482d455474ce2af` |
| `apps/web/public/support/index.html` | `1956add78cadd230a8a4f7afb7d193a85d1ebdf1a395f6d2308cba05c2aea2b8` |
| `apps/web/public/disconnect/index.html` | `0c4c27404918d65d3048b113ba318bb1295193528dfd9820e2cbc2a22bb4de1a` |
| `apps/web/public/delete-account/index.html` | `01ca71530b40bd00f492ab89b647d89802b27f0a5de80c53c80b51adfcbcc1ae` |
| `apps/web/public/robots.txt` | `99d2452fa8c3dbe40199e14996f8e826537f49ec06aa2bd5c9fc7ac220e61f0e` |
| `apps/web/public/sitemap.xml` | `5aaa1c26ca7bd8d8acec99f7ed48ae9cd7c9f5cd5a6d99d1417e5a1a69c293eb` |
| `apps/web/public/site.webmanifest` | `695c56ccb1bcec9c6c0f8d910f674b924ba62754ed426204152585e8cca7c6c0` |
| `apps/web/public/favicon.svg` | `527294463781b7f4c554d391b824c62a27e2fcfba7ed0e40de72845c3d710955` |
| `apps/web/app/layout.tsx` | `fc61c4439745a5c5ed63c8c73fc34abdda26dee034fb07c5b6e741999f3c4c44` |
| `apps/web/tests/firebase-public-site.test.mjs` | `1bd8b90a79c8735ac55dcc4bd710fe6d3270959b37c56b3205488957da625557` |

Machine-readable results are retained in `live-seo-audit.json`.
