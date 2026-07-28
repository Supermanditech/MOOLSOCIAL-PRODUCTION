# Brand integrity baseline — 27 July 2026

## Decision

Founder-directed app identity is now:

- wordmark: `MoolSocial`;
- colours: navy `#000080`, saffron `#FF9933`, white `#FFFFFF`, green
  `#138808`;
- identity line: saffron → white → green; and
- Mool service launcher: two-by-two grid, not a company logo.

Website alignment remains pending and no website source was changed.

## Corrections

- Removed the Buy-only custom M artwork from the editable Screen 09 header.
- Replaced the Buy dock custom M artwork with the shared grid launcher.
- Added `MoolBrand` to the Flutter design system.
- Updated the shared Flutter outcome dock, Chat Mool entry and existing product
  vertical Mool references to the same launcher constant.
- Left protected Social source unchanged; its two existing Mool entries already
  use `Icons.grid_view_rounded`.

## Automated enforcement

- Contract: `docs/design/MOOLSOCIAL-BRAND-INTEGRITY-CONTRACT.md`
- Registry: `config/brand-integrity.json`
- Gate: `scripts/check-brand-integrity.ps1`
- Local suite integration: `scripts/check.ps1`
- CI integration: `.github/workflows/quality.yml`
- Promotion policy integration: `docs/quality/RELEASE-GATES.md`

The App gate validates production Flutter tokens and launcher usage, active
Social/Buy HTML tokens and identity-line order, and scans all editable
screenbook HTML/CSS/JavaScript for the forbidden one-off M geometry. The
Website gate intentionally blocks while the founder-recorded website status is
pending.

## Evidence

- Brand gate: passed for App with the screenbook required.
- Website pending gate: blocked as expected.
- Approved UI locks: passed.
- Protected Social baseline: passed, 119 files,
  `927ba8662457d64640ef3a3a97b2b53120ca53e26e80f761a937ee35bad92851`.
- Flutter analysis: passed with no issues.
- Focused Flutter design-system tests: 6 passed.
- Interaction contract: passed, 153 unique routes.
- User-facing copy gate: passed.
- Buy JavaScript syntax: passed.
- Diff whitespace checks: passed in both repositories.
- Static audit: 177 Flutter source files and 199 screenbook HTML/CSS/JavaScript
  files scanned; 14 Mool-labelled Flutter entries found; no forbidden Mool
  placeholder remained.
- Rendered local Buy check at 100%: exact `MoolSocial` wordmark, zero custom
  header marks, four Mool grid cells, no legacy M path and zero horizontal
  overflow.

## Updated boundary — Buy founder FINAL

The complete Buy HTML became founder FINAL on 29 July 2026 and is frozen at
`approved-references/screens/09-buy-complete/v1`. Its wordmark, identity line,
Mool launcher and module colours are now part of the immutable Buy
presentation contract.

This authorizes an isolated native Flutter Buy V2 implementation only. The
protected Social source, website source, Firebase/GCP resources and deployed
artifacts remain unchanged. Flutter acceptance and a Dev trial remain blocked
until the brand gate, exact-reference parity, complete regression, exact-APK
OPPO and founder acceptance gates pass.
