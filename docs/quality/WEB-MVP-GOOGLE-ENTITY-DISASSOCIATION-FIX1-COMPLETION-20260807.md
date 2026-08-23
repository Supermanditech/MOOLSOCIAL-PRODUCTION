# Web MVP Google entity disassociation FIX1 — completion

Owner-controlled actions completed: 7 August 2026 at 13:48 IST
Ticket: `WEB-MVP-GOOGLE-ENTITY-DISASSOCIATION-FIX1`
Branch: `remediation/prototype-conformance-2026-07-20`
HEAD preserved: `f6dfe7587aa02d782e94282d14af8bafff48ded0`

## Founder outcome

MoolSocial and SuperMandi are separate entities. MoolSocial-owned Google results
must not cross-associate them when users search in either direction.

## Confirmed source state

All seven live public MoolSocial routes returned HTTP 200 and zero normalized
retired-identity matches. No source or deployment defect remained, so this
ticket made no HTML, structured-data, sitemap, Firebase, DNS, mobile, backend,
APK or OPPO change.

The current Google surface nevertheless still cross-associated the entities:

- `moolsocial` produced an AI Overview with an obsolete SuperMandi relationship;
- exact `SuperMandi Tech Pvt Ltd` surfaced stale MoolSocial Home, Privacy and
  YouTube API copies;
- `site:moolsocial.com "SuperMandi Tech"` returned the same three stale copies.

## Safe Google actions completed

In the verified `sc-domain:moolsocial.com` Search Console property, **Clear
snippet** was submitted for these exact canonical URLs:

1. `https://moolsocial.com/`
2. `https://moolsocial.com/privacy`
3. `https://moolsocial.com/youtube-api`

All three rows show request date 7 August 2026, type `Clear snippet`, and status
`Processing request` at this checkpoint. Search Console explicitly states this
choice keeps the URLs in search results, deletes the current snippet, and lets
Google generate a new snippet when the page is reindexed.

**Temporarily remove URL was not used.** No valid MoolSocial page was hidden.

Google also accepted `Indexing requested` for Home and YouTube API. Privacy had
already received the same accepted priority-crawl receipt in the predecessor
ticket, so it was not submitted repeatedly. All three affected canonical URLs
are now in Google's priority crawl workflow.

## Permanent regression prevention

`REG-20260807-127-PUBLIC-ENTITY-DISASSOCIATION-QUERY-AUDIT-INCOMPLETE` is active.
Future public-identity releases must audit both query directions, AI-generated
surfaces and a domain-restricted retired-identity query, then enumerate and
remediate every affected owner-controlled canonical URL.

## Final state

Every safe action under MoolSocial's control is complete. Google still controls
snippet-clear processing, recrawl, reindexing and AI Overview regeneration.
Visible cross-association removal is therefore pending and is not claimed as
instantaneous. Exact query evidence, Search Console receipts and hashes are in
`config/web-mvp-google-entity-disassociation-fix1-state.json`.

The MVP scope gate is closed with no active ticket and no execution authority.
