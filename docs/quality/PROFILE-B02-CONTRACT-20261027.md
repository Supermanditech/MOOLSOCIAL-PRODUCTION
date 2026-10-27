# PROFILE-B02: Plans and paid-feature readback

Status: founder activated the bounded frontend/backend scope; exact source/interaction admission acceptance pending. This document does not claim implementation or production acceptance.

## Source and preservation

Use the original approved Profile/Plans presentation from UI commit c9d03bb37b6115f7fe63f3f1dd819892dc037fc9, carried by the combined remote-exact source checkpoint 955f793dcfc593b603797d9e960925f774a6c2c2. Start the B02 checkout from that combined checkpoint so B01/B03 and the pending-access race correction cannot be lost. Retain all existing cloud, authenticated-device, canonical Workspace authority and release qualification limits. No main or original-worktree mutation.

## Expected user behaviour

1. Reuse Profile -> Plans & billing and the existing comparison cards. Personal and Workspace are the two plan audiences. Personal readback is bound to the current authenticated account. Workspace readback additionally binds the selected approved Store and current account-to-Store authority; payment never establishes that authority.
2. The approved catalogue supplies stable plan/version and feature identities, display name, price/tax/billing-period wording, benefits, eligibility, availability, recommended display metadata and applicable current subscription. No hardcoded plan count, guessed commercial content, invented free AI or new paywall on existing manual functions. An unavailable catalogue is not an empty catalogue or a free subscription.
3. Show a compact initial comparison and View all plans when the authoritative catalogue has more entries. Support the whole supplied catalogue through bounded/lazy rendering or pagination without silently omitting plans. Preserve readable text, full tap targets, narrow/enlarged layouts and navigation. Do not redesign the approved Profile or Mool AI composer.
4. Read active subscription/entitlement state only from a validated, current server response. Bind owner, audience, Store when relevant, source/version, timestamps and effective access window. A local plan preference, route parameter, purchase attempt or device clock alone never creates paid access. Personal entitlement cannot silently become a Store entitlement or cross another account/Store.
5. Buy remains free for individual/business buyers. Approved Store users retain applicable free operations independently of subscription. Purchased feature access requires no further human/admin approval. Mool AI requires its explicit valid feature entitlement and existing actor/Workspace permissions; an active subscription does not connect the still-deferred model service.
6. Price, feature or limit changes use a new authoritative version; display edits do not alter feature identities. Existing subscription readback retains its assigned version/effective dates. Cancellation follows the server's effective access dates, not an invented immediate-revocation/grace-period rule. Missing approved versions, unknown statuses or ambiguous dates fail closed for paid features while preserving free access.
7. Loading, unavailable, retry, account/Store change, expired/revoked access and stale/out-of-order responses retire prior paid authority. Share duplicate concurrent reads where safe; never repeat an upgrade/charge or infer purchase success. No silent fallback to another tenant/account/Store or catalogue version.
8. Upgrade/Manage controls use only a verified supported handoff. Actual purchase, subscription changes, payment collection and redirects remain unavailable until approved commercial content and receiving billing contracts exist. Do not add a fictitious checkout or claim paid activation on OPPO.

## Backend and integration boundary

Implement the existing authenticated HTTP/App Check -> service -> durable read repository path using current project conventions and dependencies. Reuse the accepted Firebase identity and DataConnect persistence patterns; do not introduce a parallel account database. Define read-only catalogue/subscription/feature projection and corresponding local schema/query adapters. Account authority comes from verified identity, never submitted user IDs. Store selection is validated against the existing authoritative Workspace contract; unavailable B03 authority remains unavailable, not an invented approval.

Add the thin mobile credentials/transport/parser/controller connection to the existing Plans screen and Mool AI access interface. Reject malformed, cross-scope, duplicate/conflicting or stale records. No billing writer, admin catalogue editor, webhook, subscription issuer, payment processor, paid quota enforcement system or entitlement issuance is included. Final commercial catalogue and authoritative billing lifecycle are named backend-phase dependencies.

Deployment/Google flags remain disabled/unqualified until later real SDK/schema/provisioning/App Check/deployment qualification. Production code and isolated host fixtures must remain distinguishable. Do not inject test subscriptions, plans, identities or authority into OPPO.

## Required verification

- Parse/contract tests for any supported catalogue size and invalid/missing/duplicate/versioned entries; confirmed empty versus unavailable.
- Backend authentication/App Check/tenant/account restrictions; unauthorized Store requests, absent authority, owner isolation, effective dates, cancellation/expiry/revocation, unavailable repository and sanitized errors.
- Mobile gateway and existing forms/cards: audience/Store switching, account sign-out/switch, delayed/reversed replies, duplicate reads, timeout/retry, lifecycle resume/expiry and no stale entitlement recovery from preferences.
- Integration: actual mobile production gateway payloads through production HTTP handler/service/durable repository with isolated host data; distinguish SDK/emulator seams from genuine deployed testing. Reuse existing dependencies and retain durable restart evidence where practical.
- Protect free Buy/approved free Store behaviour and B01/B03 regressions. Test Mool AI scoped entitlement adapter with the existing controller; no model execution claim.
- OPPO: exact current-source launch settings, reachable real loading/unavailable/signed-out states, navigation/keyboard/layout and saved-data preservation. Populated authenticated/paid cases remain unqualified without authentic sources. Existing native accessibility/release holds remain.

## Stop boundary

Finish actionable implementation and local verification, register demonstrated defects and fixes, record implemented/host-qualified/OPPO-qualified/deferred cases separately and stop. No Google setup/deployment, real billing/live charges, admin, APK, publication, main/history changes or unrelated feature. No source feature commits or pushes in this implementation scope. Exact one-time local metadata admission commit is separately requested to meet the existing clean recorded task-start requirement.
