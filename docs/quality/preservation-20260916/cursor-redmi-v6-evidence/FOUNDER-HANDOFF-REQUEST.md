# Founder request: Cursor Git reconciliation and Store catalogue handoff

Reconcile all Cursor/Redmi tickets and changes since Cursor/Codex integration. Preserve every source change and non-secret ticket/evidence record in Git, with fresh remote verification. List exact ticket IDs, implementation/evidence commits, tests actually completed, founder approvals, agent verification, WIP and open defects separately. Do not discard changes, rewrite history or treat archived WIP as accepted implementation.

Before Codex starts the Store product catalogue ticket, commit and push a field-by-field map of every existing public Store/product field and its actual consumer, model, provider, source file, owner editor, save/publish action, validation, visibility and update/unpublish behavior. Cover existing store identity, images, description, public contact/location/service area/hours/status; product identity/media/descriptions/categories/variants/pack/units; owner-specific prices, offers, quantity rules, availability and fulfilment/policy information. Identify missing wiring rather than inventing features.

Founder requirement: store-specific consumer/public data must originate from the store owner's authoritative published data. Trace owner edit/save/publish → shared contract/provider → public storefront/catalogue/product detail and downstream price/availability consumers. Reuse existing models and providers. Separate canonical platform product facts and system-derived/moderated facts from the owner's offer; retain the correct authority for each. Drafts and private procurement costs, margins, customer/ledger data, KYC, credentials and internal notes must not become public.

Return a clean, remotely verified handoff branch/commit, field-map path/hash, owner boundaries, baseline, open dependencies and focused checks for owner updates, publish/unpublish, unavailable items and public refresh. Codex must read this handoff before implementation. This request does not authorize a new APK, backend deployment, Play action or external customer message.

## Already preserved — avoid duplicate work

- Latest installed integration: `21977bff27cf22bfadb50f592a635355bb80574e`.
- Source: `54eae4970959d39cb978cd01082be828625721f9`.
- All 269 audited branch histories, including 102 Codex branches, are remotely preserved.
- Evidence archive: `archive/preservation-20260916-codex-history`, commit `68b2316cea213c26ebc6bb9b095c8fd1f415c596`.
- Cursor catalogue WIP snapshot: `archive/preservation-20260916-cursor-catalogue`, commit `72f5d36a45525ee36740a1e7214d0cc88a8a0f2a`, parent `e5d39769e260c1a6691ea7808642308472261a97`. The original checkout/index was untouched. Recheck current state; this snapshot is not accepted or integrated.
- Local receipt: `C:/Users/jisal/Documents/Codex/2026-09-15/wh/outputs/git-preservation-complete.json`.
- Final YouTube API review cutoff remains Play r60.95 at `f2ef92180bc4c9d14683d98664da84a1628f6725`, remote tag `moolsocial-youtube-api-review-r60.95-cutoff-20260827`.
