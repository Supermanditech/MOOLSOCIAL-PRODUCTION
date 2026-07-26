# 45-day go-live plan

Start: 2026-07-18
Target launch: 2026-09-01
Rule: a journey is not complete until its original failed sequences and its
affected regression pass on staging.

## Founder sequencing and Buy operating model — 26 July 2026

- Comprehensive YouTube work is on provider-review hold after submission.
- Preserve the current Social module and its accepted/deployed Dev evidence as
  a regression baseline. The exact HTML, Flutter/source, OPPO-installed APK and
  Dev deployment identities are recorded in
  `artifacts/quality/social-protected-baseline-20260726-01/`.
- The mandatory Buy sequence is: complete shared UI/UX → prepare and verify
  Buy HTML → founder `FINAL` → freeze immutable reference → implement native
  Flutter → pass Social plus Buy regression → connected OPPO replay → separate
  deployment-trial decision.
- No Flutter Buy implementation starts from an unapproved HTML draft, and no
  Buy deployment trial starts from HTML approval or partial Flutter work.
- Use one canonical catalogue with separate retail and wholesale buying
  contexts, participant offers and PIN-code fulfilment.
- Shops, retailers, wholesalers, distributors, manufacturers and delivery
  partners may onboard, but each selling, buying and fulfilment capability is
  activated only after its own verification.
- The detailed proposed operating decision is
  `docs/decisions/ADR-0009-UNIFIED-BUY-CATALOGUE-OFFERS-AND-FULFILMENT.md`.

## Days 1-5: foundation and universal entry

- Repository, environments, CI, design tokens and architecture boundaries.
- Android/iOS application IDs and Firebase dev/staging projects.
- Install/open, Remote Config boot, language/area setup, Auth and universal Mool
  shell.
- Emulator tests, Android staging APK, iOS simulator build, connected-device
  replay, App Distribution and TestFlight preparation.

Exit: `PROD-JRN-001` works against real staging services.

## Days 6-13: consumer buy

- Canonical product discovery and decision-ready retail offers.
- Basket, home-delivery address, availability reservation and exact price.
- Razorpay sandbox payment, webhook inbox, idempotent order and status.
- Verified business workspaces may expose the separate wholesale context; no
  MOQ, case-price, credit or trade term appears in Personal Buy.

Exit: one consumer can pay once and see one authoritative order.

## Days 14-20: retailer fulfilment

- Retailer/shop workspace activation, catalogue matching, offer and stock.
- Order acceptance, pick/pack, delivery handoff and customer status.
- Capability-gated wholesaler, distributor, manufacturer and delivery-partner
  onboarding for eligible PIN codes.
- Minimal Superadmin user/workspace/offer provisioning.

Exit: the paid consumer order completes through the retailer side.

## Days 21-27: Work and payout

- Funded opportunity, eligibility, accept, proof, review and payout ledger.
- Duplicate proof, expiry, rejection, rework and appeal states.

Exit: one funded task completes with an auditable payout result.

## Days 28-34: social launch slice

- Native text/image post.
- YouTube Connect, attributed product/service action and campaign duration.
- Moderation, rights declaration and feature-flag controls.

Exit: content opens and its declared commerce/work action completes.

## Days 35-39: business web and Superadmin

- Public marketing pages.
- Authenticated creator/retailer/manufacturer upload surfaces for launch scope.
- Separate Superadmin deployment and role-gated provisioning.

## Days 40-43: hardening

- Full clean-state E2E regression.
- Test Lab device matrix, accessibility, offline/retry, performance and abuse
  checks.
- Backup/restore, budget alerts, runbooks, support and rollback drill.

## Days 44-45: controlled release

- Internal → closed → production Google Play tracks and staged App Store
  release from the same tagged source commit.
- Staged percentage rollout controlled by crash-free and journey-success gates.
- GO only when no release-blocking intent path is open.

## Scope protection

Ride, health, salon, advanced POS, broad B2B, long-form owned video, universal
AI agents and non-launch workspace depth remain behind disabled feature flags.
They are not allowed to delay the first controlled launch.
