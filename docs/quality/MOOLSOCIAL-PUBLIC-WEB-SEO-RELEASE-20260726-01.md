# MoolSocial public web SEO release — 26 July 2026

## Release status

Technical SEO is deployed and verified at <https://moolsocial.com/>.

The prior site was publicly reachable but provided no `robots.txt`, sitemap or
canonical links, and Google returned no indexed MoolSocial result. This release
adds the discovery, canonicalization and identity signals required for Google
to crawl and evaluate the website.

## Search architecture

### Indexable public pages

- <https://moolsocial.com/>
- <https://moolsocial.com/privacy>
- <https://moolsocial.com/terms>
- <https://moolsocial.com/support>

### Non-indexed account utilities

- <https://moolsocial.com/disconnect>
- <https://moolsocial.com/delete-account>

The two utilities remain crawlable with `noindex,follow`. They are intentionally
excluded from the sitemap because they are account-control destinations rather
than search landing pages.

## Implemented signals

- Unique titles and descriptions
- Self-referencing canonical URLs
- `index,follow` directives for public pages
- `noindex,follow` directives for account utilities
- Open Graph site, locale, URL and image metadata
- Twitter large-image metadata
- `en-IN` language declarations
- `Organization` structured data for MoolSocial and SuperMandi Tech Pvt Ltd
- `WebSite` structured data
- Root `robots.txt`
- Root `sitemap.xml` with canonical absolute URLs and accurate `lastmod`
- MoolSocial favicon
- Web manifest
- Matching future dynamic-web metadata in `apps/web/app/layout.tsx`
- Automated regression checks for all SEO contracts

## Firebase release

| Field | Value |
| --- | --- |
| Project | `moolsocial-dev-503018` |
| Channel | `live` |
| Release | `1785077458371000` |
| Version | `9a11fef857fe4bd9` |
| Status | `FINALIZED` |
| Released | `2026-07-26T14:50:58.371Z` |
| Account | `hello@moolsocial.com` |

All 23 canonical source files matched the public domain byte-for-byte after
deployment.

## Validation

| Check | Result |
| --- | --- |
| Production build | PASS |
| Automated web tests | PASS, 7/7 |
| Lint | PASS, zero errors |
| Googlebot-style homepage fetch | PASS, HTTP 200 |
| Canonical URL | PASS |
| Index robots directive | PASS |
| `robots.txt` | PASS, HTTP 200 |
| `sitemap.xml` | PASS, HTTP 200 |
| Structured-data JSON | PASS |
| Live browser console | PASS, zero errors |
| Horizontal overflow | PASS |
| Source-to-live comparison | PASS, 23/23 |

## Remaining Google-account gate

The signed-in `hello@moolsocial.com` account does not currently have verified
access to the existing Search Console domain property `moolsocial.com`.
Search Console presented `Verify your ownership`.

Ownership verification is required before this account can submit the sitemap,
run URL Inspection and request indexing. Those actions can accelerate discovery
and provide monitoring, but Google does not guarantee immediate inclusion or a
particular ranking.

## Official Google references

- [Build and submit a sitemap](https://developers.google.com/search/docs/crawling-indexing/sitemaps/build-sitemap)
- [Specify canonical URLs](https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls)
- [Ask Google to recrawl URLs](https://developers.google.com/search/docs/crawling-indexing/ask-google-to-recrawl)
- [Inspect and troubleshoot a page](https://support.google.com/webmasters/answer/12482179)

Detailed hashes and machine-readable evidence:

`artifacts/quality/moolsocial-web-seo-20260726-01/`
