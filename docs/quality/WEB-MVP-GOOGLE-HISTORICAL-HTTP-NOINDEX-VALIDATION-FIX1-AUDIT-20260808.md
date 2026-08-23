# Google historical HTTP noindex validation audit

## Founder report

On 8 August 2026 the founder supplied a Search Console transactional email
reporting a new `Excluded by ‘noindex’ tag` reason and authorized resolution.
The authenticated `sc-domain:moolsocial.com` Pages report was last updated on
5 August 2026.

## Exact Search Console examples

- `Excluded by ‘noindex’ tag`: `http://moolsocial.com/`, last crawled 18 July
  2026.
- `Crawled - currently not indexed`: `https://moolsocial.com/` and
  `https://moolsocial.com/youtube-api`, both last crawled 5 August 2026.
- `https://moolsocial.com/privacy` is independently reported as indexed.

## Current live disposition

The report is historical rather than a current source defect:

- HTTP Home returns `301 Moved Permanently` to `https://moolsocial.com/`.
- HTTPS Home and YouTube API return HTTP 200, expose `index,follow` and exactly
  one self-referencing canonical URL, with no `X-Robots-Tag: noindex` header.
- `robots.txt` allows `/` and declares the canonical sitemap.
- the live sitemap includes both Home and YouTube API with truthful
  `2026-08-07` last-modified dates.
- the local public-site regression suite passed 6/6.

The account-control utilities `/disconnect` and `/delete-account` intentionally
remain `noindex,follow`; neither is the Search Console example. Removing those
directives or deploying unchanged content would create a new regression and is
outside this ticket.

## Resolution boundary

Start Search Console validation for both reported reason groups and record the
receipts. Google controls re-crawl and index inclusion. No website source,
Firebase Hosting, DNS, mobile, backend, APK or OPPO mutation is required.
