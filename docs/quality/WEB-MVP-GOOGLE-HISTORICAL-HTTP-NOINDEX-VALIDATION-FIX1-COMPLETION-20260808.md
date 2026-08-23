# Google historical HTTP noindex validation completion

## Outcome

All owner-controlled actions are complete. Google Search Console now shows
`Validation Started` with start date 8 August 2026 for both reported groups:

- `Excluded by ‘noindex’ tag`: historical example
  `http://moolsocial.com/`, last crawled 18 July 2026.
- `Crawled - currently not indexed`: `https://moolsocial.com/` and
  `https://moolsocial.com/youtube-api`, last crawled 5 August 2026.

Home and YouTube API already had priority crawl requests from the 7 August
entity-disassociation ticket, so this ticket did not repeat them.

## Technical finding

No current source defect required a release. HTTP Home permanently redirects
to HTTPS. Both canonical HTTPS pages return HTTP 200, `index,follow`, one
self-canonical and no noindex response header. `robots.txt` allows crawling,
the live sitemap contains both URLs with 7 August freshness, and the public
site SEO suite passes 6/6.

The separate Website brand-integrity gate remains founder-recorded as pending
and blocks an unnecessary next release. No website source or Firebase Hosting
change was made.

## Safety disposition

The intentional `noindex,follow` directives on `/disconnect` and
`/delete-account` remain intact. No DNS change, temporary URL removal,
robots block, 404/410, cloaking, deployment, mobile/backend/APK/OPPO change,
email or YouTube reply occurred.

Google controls validation, recrawl, index inclusion and ranking. The truthful
remaining state is `validation_started_recrawl_and_index_decision_pending`.
