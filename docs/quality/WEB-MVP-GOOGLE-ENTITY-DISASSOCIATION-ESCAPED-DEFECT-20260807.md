# Web MVP Google entity disassociation — escaped defect

Registered: 7 August 2026
Regression: `REG-20260807-127-PUBLIC-ENTITY-DISASSOCIATION-QUERY-AUDIT-INCOMPLETE`

## Escaped condition

The first Google index refresh ticket correctly reconciled the founder-supplied
Privacy result, repaired sitemap freshness, deployed the qualified sitemap,
resubmitted it, and requested Privacy indexing. It did not yet prove the
founder's semantic outcome that MoolSocial and SuperMandi are separate entities
across Google result surfaces.

A read-only live Google audit then found:

- the `moolsocial` query AI Overview still described MoolSocial as developed by
  SuperMandi and cited the stale Privacy copy;
- the exact `"supermandi tech pvt ltd"` query returned stale MoolSocial Home,
  Privacy and YouTube API results;
- `site:moolsocial.com "SuperMandi Tech"` returned those same three
  owner-controlled URLs with retired identity fragments.

All affected live MoolSocial pages already contain zero normalized retired-name
matches. The remaining defect is therefore Google's indexed copy and derived
entity association, not current production HTML.

## Permanent prevention

Identity disassociation qualification is semantic and bidirectional. Future
releases must audit the current brand query, retired-entity query, AI-generated
surfaces and a domain-restricted query, enumerate every affected canonical URL,
and record the exact Search Console response for each safe snippet-clear and
reindex action. Valid MoolSocial pages must stay indexed; temporary whole-URL
removal is prohibited unless separately classified and explicitly authorized.

## Evidence

- `artifacts/quality/web-mvp-google-entity-disassociation-20260807-01/moolsocial-query-ai-overview.jpg`
  - SHA-256: `CA54C69C498B8F70A80C1DE083982820F44D878A31787AFDC6EDD6C0AEF23FD9`
- `artifacts/quality/web-mvp-google-entity-disassociation-20260807-01/supermandi-query-cross-results.jpg`
  - SHA-256: `35F4EA6906B111DEDF1233B9D9E3E9A1C860E0947AB175F01E9D655B772A965C`
- `artifacts/quality/web-mvp-google-entity-disassociation-20260807-01/site-moolsocial-retired-identity-results.jpg`
  - SHA-256: `38DA05DB7B3E6BEB76DBCABFCE6CEF823A5203D12DA738D42C4734F88C7CEA43`
