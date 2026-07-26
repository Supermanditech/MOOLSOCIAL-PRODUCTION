# MoolSocial public web copy release — 26 July 2026

## Release decision

Approved public copy is deployed at <https://moolsocial.com/> and preserved in the production repository.

This release replaces internal, procedural and implementation-oriented wording with direct public-facing language across the complete hosted website. It also introduces a character-level regression gate for the public copy surface.

## Public message

The website now presents MoolSocial as an Indian technology company building an AI-enabled social commerce platform that connects content, commerce, services, mobility, payments and work.

The primary public themes are:

- Built in India
- One connected experience around everyday life
- Clear value for people, creators, businesses and partners
- AI with human control and clear accountability
- Public launch across India on 24 October 2026
- Open applications, partnerships and official profile enquiries

## Copy changes

- Removed phrases that read like internal product commentary, including “meaningful action”, “shared digital environment”, “responsible execution”, “accountable execution”, “operating locations” and “field execution”.
- Replaced abstract or explanatory statements with specific public actions and benefits.
- Rewrote company, vision, launch, opportunities, social-profile and contact sections.
- Rewrote metadata, image descriptions, accessibility labels, placeholders and link descriptions.
- Polished Privacy Policy, Terms of Service, Support, connected-services and account-deletion pages.
- Kept third-party references proportionate to their actual role in the wider MoolSocial platform.

## Permanent regression protection

The hosted-site test now builds a canonical copy surface from every public page. It includes:

- visible text;
- title and description metadata;
- Open Graph and Twitter metadata;
- accessibility labels and image descriptions;
- form placeholders;
- link destinations.

Each page is locked by an approved SHA-256 digest. Any character-level change requires an intentional test update and review. The gate also rejects public HTML comments, invalid replacement characters and known internal wording.

## Deployment

| Field | Value |
| --- | --- |
| Firebase project | `moolsocial-dev-503018` |
| Hosting channel | `live` |
| Release | `1785076354189000` |
| Version | `6d4d89b7febf43bf` |
| Status | `FINALIZED` |
| Released | `2026-07-26T14:32:34.189Z` |
| Public domain | <https://moolsocial.com/> |

The source and live release matched byte-for-byte for all 19 hosted files.

## Validation

| Check | Result |
| --- | --- |
| Production build | PASS |
| Automated web tests | PASS, 6/6 |
| Lint | PASS, zero errors |
| Character-level copy gate | PASS, 6/6 pages |
| Rejected-copy scan | PASS |
| Public links and routes | PASS |
| Security headers | PASS |
| HTML cache revalidation | PASS |
| Desktop live rendering | PASS |
| OPPO live rendering | PASS |
| OPPO Launch navigation | PASS |

HTML now uses immediate cache revalidation so visitors receive the current public release instead of an older cached page. Static CSS and image assets retain a one-hour public cache to control hosting cost.

## Policy verification

Integration-related wording was checked against:

- [YouTube API Services Developer Policies](https://developers.google.com/youtube/terms/developer-policies)
- [Google API Services User Data Policy](https://developers.google.com/terms/api-services-user-data-policy)
- [RBI restriction on storage of actual card data](https://www.rbi.org.in/scripts/NotificationUser.aspx?Id=12345)

This content check supports product readiness. Formal legal-counsel review remains a separate production governance gate.

## Evidence

Detailed hashes, copy digests and device captures are stored in:

`artifacts/quality/moolsocial-public-copy-audit-20260726-01/`
