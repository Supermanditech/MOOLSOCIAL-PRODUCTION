# MoolSocial public web navigation audit — 2026-07-26

## Release under test

- Public URL: `https://moolsocial.com/`
- Firebase project: `moolsocial-dev-503018`
- Release marker: `20260726-5`
- Canonical deploy source: `apps/web/public`
- Files deployed: 19

## Corrections verified

- The primary `Launch` link lands on the launch section beneath the sticky
  header.
- The Launch section owns the live countdown, exact launch date, registration
  action, contact action and public launch journey.
- The hero does not contain or duplicate the launch counter.
- Public wording uses `Built in India`; `Coming to India` is absent.
- Delivery language such as roadmap, readiness, validation, workflow, backend,
  operating support and launch participation is absent from customer-facing
  company-page copy.
- The phone showcase, information cards and ecosystem motion graphic are
  informational surfaces rather than oversized email links.
- Only visible navigation, buttons, social/contact cards and footer links are
  interactive.

## Automated and laptop-browser results

- `npm test`: 5 passed, 0 failed.
- Primary navigation:
  - `Our story` -> `#about`, destination visible.
  - `Our vision` -> `#vision`, destination visible.
  - `Launch` -> `#launch`, destination visible.
  - `Join us` -> `#opportunities`, destination visible.
- Legal routes:
  - `/privacy` -> `Privacy Policy`.
  - `/terms` -> `Terms of Use`.
  - `/support` -> `Support and contact`.
- Non-control taps on the phone showcase, information card and motion graphic
  left the URL unchanged.
- Oversized interactive regions: 0.
- Positive horizontal overflow: 0 pixels.
- The live Launch destination exposed stylesheet marker `20260726-5`, a running
  five-part counter, `24 October 2026`, `Built in India` and no internal wording.

## OPPO CPH2375 touch results

Connected device serial: `2b3e0f71`.

- `Our story`: correct heading visible.
- `Our vision`: correct heading visible.
- `Launch`: counter, launch date, launch actions and public launch journey
  visible; correct heading visible.
- `Join us`: correct heading visible.
- Neutral tap inside the countdown left Chrome focused and did not open another
  page or email application.

## Source-to-production integrity

All 19 files served by `https://moolsocial.com/` matched the canonical local
files byte-for-byte by SHA-256: 19 matched, 0 mismatched.

The complete digest list is in `SHA256SUMS.txt`.

## Evidence

- `01-oppo-home.png` / `.xml`: deployed mobile home.
- `02-oppo-launch.png` / `.xml`: Launch tab after a real touch.
- `03-oppo-neutral-tap.xml`: non-control tap remained in Chrome.
- `04-oppo-story.xml`: Our story destination.
- `05-oppo-vision.xml`: Our vision destination.
- `06-oppo-join.png` / `.xml`: Join us destination.
