# Web MVP Google index retired-brand refresh FIX1 — completion

Completed: 7 August 2026 at 13:37 IST
Ticket: `WEB-MVP-GOOGLE-INDEX-RETIRED-BRAND-REFRESH-FIX1`
Branch: `remediation/prototype-conformance-2026-07-20`
HEAD preserved: `f6dfe7587aa02d782e94282d14af8bafff48ded0`

## Production outcome

The founder screenshot showed a Google Search result for the Privacy page whose
indexed copy was dated 26 July 2026 and still contained the retired company
identity. The current live Privacy page was already correct: it returned HTTP
200, contained no normalized retired-name match, declared the canonical
`https://moolsocial.com/privacy`, allowed indexing, and used `moolsocial.com`.

The escaped release defect was the sitemap freshness signal. All five canonical
public pages had changed significantly on 7 August, but the sitemap and its test
still asserted older dates. This ticket updated the five `lastmod` values to
`2026-08-07`, strengthened the existing test against stale 2026 dates, deployed
one changed Firebase Hosting file, resubmitted the sitemap, and requested Privacy
URL indexing.

No page was removed or blocked. No DNS, Flutter, Android, iOS, backend, Firestore,
Functions, APK, OPPO, email, YouTube capability, commit, push, merge, branch or
workspace-cleanup action occurred.

## Evidence and qualification

- Founder screenshot: `artifacts/quality/web-mvp-google-index-retired-brand-refresh-20260807-01/founder-google-search-stale-snippet.png`
  - SHA-256: `DB5A2702465A1443B74C4BA55C2790D42810D1AC799518104B0B3AF59116C383`
- Updated source: `apps/web/public/sitemap.xml`
- Strengthened regression owner: `apps/web/tests/firebase-public-site.test.mjs`
- Sitemap XML: valid, five canonical URLs, five `2026-08-07` values.
- Local sitemap SHA-256: `9D9D0316529F8E851F51AFEDF1DF3C92456FAC90ACCB669471A550BEF3B7D796`.
- Production web build and public-site tests: 7 passed, 0 failed.
- Lint: 0 errors and the same 2 pre-existing image-optimization warnings.
- Permanent regression gate: 126 entries, 99 applicable, passed.
- MVP scope and delivery-discipline gates passed before deployment.

Firebase CLI preflight resolved the active `moolsocial-dev-503018` project and
its default Hosting site. Hosting deployment reported 24 files, exactly one
new/changed upload, successful version finalization and successful release.
The live sitemap returned HTTP 200 and its SHA-256 exactly equalled the qualified
local sitemap.

## Google Search Console receipts

The `sc-domain:moolsocial.com` property was accessible.

- Sitemap receipt: `Sitemap submitted successfully`.
- Sitemaps report after submission: submitted 7 August 2026; last read 6 August
  2026; status `Success`; five discovered pages.
- Privacy inspection: `URL is on Google`; page indexed; last crawled 6 August
  2026 at 14:32:48 by Googlebot smartphone; crawl allowed; fetch successful;
  indexing allowed; user and Google canonical both resolve to the inspected
  Privacy URL.
- Indexing request receipt: `Indexing requested`.
- Google confirmation: the URL was added to a priority crawl queue, and repeated
  submission does not change its queue position or priority.
- Receipt screenshot:
  `artifacts/quality/web-mvp-google-index-retired-brand-refresh-20260807-01/search-console-privacy-indexing-requested.jpg`
  - SHA-256: `A24DCEA202EA5FD5B57424E039DB0068AE7C91A3E8E1E72B3FC65162752B0B98`

## Final state

The MoolSocial-controlled source, regression test, Hosting release and Search
Console submissions are complete and verified. The visible Google result refresh
remains an external-provider pending state; no immediate snippet replacement is
claimed. Machine-readable hashes and receipts are stored in
`config/web-mvp-google-index-retired-brand-refresh-fix1-state.json`.

The MVP scope gate is closed with no active ticket and no execution authority.
Both escaped defects are permanently registered as
`REG-20260807-125-PUBLIC-COPY-RELEASE-SITEMAP-LASTMOD-STALE` and
`REG-20260807-126-DELIVERY-DISPOSITION-ENUM-INVENTED`.
