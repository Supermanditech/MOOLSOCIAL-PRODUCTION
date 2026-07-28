# MoolSocial brand integrity contract

Status: founder-directed, mandatory, 27 July 2026

This contract is the durable cross-surface authority for MoolSocial identity.
It applies to editable HTML, native Flutter, Android/iOS trial artifacts,
cloud-hosted trial builds and every later app release. The website is recorded
as pending alignment and must satisfy this contract before its next release;
this decision does not authorize a website source change now.

## One identity

- The product wordmark is exactly `MoolSocial`.
- The core brand colours are navy `#000080`, saffron `#FF9933`, white
  `#FFFFFF` and green `#138808`.
- The identity line order is saffron, white, green.
- The logo treatment is the MoolSocial wordmark with the identity line. Do not
  invent a standalone letter `M`, initial tile, alternate animal/object mark,
  one-off colour system or module-specific product logo.
- Provider marks may appear only where truthful attribution requires them.
  They never replace or modify MoolSocial identity.

## Mool is navigation, not another logo

`Mool` is the shared service launcher. Its one app-wide navigation glyph is a
two-by-two grid:

- HTML uses four rounded square cells.
- Flutter uses `Icons.grid_view_rounded`.
- The visible label is `Mool`.

The grid is a functional navigation symbol. It must not be presented as the
MoolSocial company logo, and a module must not draw its own Mool glyph.

## Surface ownership

- HTML colour authority:
  `supermandi-uiux-screenbook/shared/moolsocial-ui-foundation.css`.
  Isolated module styles may consume matching tokens but cannot redefine the
  identity.
- Flutter colour authority:
  `apps/mobile/lib/core/design/mool_colors.dart`.
- Flutter wordmark and launcher authority:
  `MoolBrand` in
  `apps/mobile/lib/core/design/mool_design_system.dart`.
- Machine-readable authority:
  `config/brand-integrity.json`.
- Release enforcement:
  `scripts/check-brand-integrity.ps1`.

Approved immutable references are never edited to retrofit this contract.
Editable candidates are corrected before founder `FINAL`; new immutable
packages are created only after approval.

## Release rule

An artifact fails the brand gate if any customer-visible app surface:

1. changes the exact wordmark;
2. changes a core identity colour or the identity-line order;
3. substitutes a custom M, circle or module-specific mark for the Mool grid;
4. uses an unreviewed module-specific logo;
5. builds or deploys from source that did not pass the brand gate; or
6. cannot be traced to the same reviewed source and checksum recorded for the
   trial or promotion.

HTML founder review, native Flutter implementation, connected-device
acceptance and Dev trial deployment are separate gates. Passing the brand
check does not bypass the Buy founder `FINAL` or any protected Social lock.

## Website boundary

Website alignment remains pending by founder instruction. No website source is
changed under this decision. The next website release is blocked until the
website is audited against the same wordmark, colour and logo rules and the
pending status in `config/brand-integrity.json` is explicitly resolved.
