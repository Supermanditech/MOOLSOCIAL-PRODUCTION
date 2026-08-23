# UAW Personal MVP action wording, wiring and navigation FIX1 preselection assessment

Date: 6 August 2026
Ticket/candidate: `UAW-PERSONAL-MVP-ACTION-WORDING-WIRING-NAVIGATION-FIX1`
Classification: `mvp_required`

## Customer outcome and reason

A Personal user sees the founder-locked six main action words and seventeen
sub-action words, reaches the already-owned native product or service surface
in one tap, and can use visible or system Back without landing in a sibling
journey. Removed launch actions remain absent throughout the reachable path.

The post-r60.3 source audit confirmed production-path drift that earlier
root-only acceptance did not cover: Eat still exposes Tiffin in search, a
primary route card and its persistent dock; Book Table visible Back opens Order
Food; Earn Today has no visible Back; Workspace visible Back opens Earn Today;
and the Work dock uses stale labels, a legacy Mool owner and a hard-coded Chat
return. These are user-visible launch-journey defects against the locked
Personal MVP projection, so the correction is `mvp_required`.

## Reuse inventory and smallest complete scope

- Reuse `personalMoolRootActions`, `screen04Worlds`,
  `personalMvpActionChoiceRoots`, the production router, all existing native
  destination screens and all existing journey/session owners.
- Preserve protected Social and Buy runtime trees; add acceptance coverage for
  their exact words, direct owner selection and established Back behavior.
- Remove only reachable Tiffin presentation from Eat Home and Eat's persistent
  dock. Keep legacy route code available behind its existing containment and
  test-only boundaries.
- Correct only the top-level Eat/Work visible Back fallbacks and align the
  downstream Eat/Work destination and dock labels with the locked projection.
- Route Eat, Ride, Book and Work Mool controls to their canonical Personal Mool
  owner with origin, and make the Work Chat return preserve the current route.
- Add deterministic real-router tests for six main actions, seventeen
  sub-actions, visible/system Back, direct-open fallback, exact wording,
  selected product/service context and removed-action absence.

## Duplicate search and necessity proof

No new screen, route, state, service, store or backend owner is needed. Source
search located every defect inside existing destination/scaffold/dock owners.
The locked projection and existing route owners already express the intended
wording and destination. Configuration reuse and narrow fallback/copy changes
remove the drift points without duplicating any journey.

This ticket does not redesign protected Social or Buy, change an accepted
baseline, or activate a provider/payment capability. It only verifies those
owners while correcting confirmed downstream Personal launch continuity.

## Explicit exclusions

- No Social Shorts/Videos provider activation, YouTube compliance claim or
  protected Social content/presentation change.
- No Buy catalogue, Cart, checkout, transaction payment, order, tracking,
  recovery, runtime presentation, golden or accepted-baseline change.
- No new UI screen, route, state, session, service, store, backend, workspace,
  payment or provider owner.
- No deletion of legacy deep-link owners; existing truthful containment stays
  authoritative for removed direct links.
- No screenbook, locked Screens 01-03, manifest, golden or accepted-reference
  mutation.
- No OPPO uninstall, data clear, downgrade, signature workaround or deletion
  of predecessor evidence.
- No credentials, live provider message/call, funds, Production write, commit,
  push, deploy or promotion.

## Dependencies and verification

Dependencies: founder direction to audit and fix action wording/wiring under the
new MVP plan; locked Personal projection; existing canonical native owners;
qualified r60.3 and protected FIX1/FIX7 evidence; remediation branch/HEAD and
full dirty-state preservation; MVP scope, delivery, APK and device gates.

Verification: static projection matrix; focused production-router tests for
all six main and seventeen sub-actions; exact destination owner/selection;
visible and system Back; direct-open fallback; Mool and Chat continuity;
removed-action absence; format and analysis; affected Personal regressions
twice; complete Eat/Work and complete Buy regressions twice; protected
Social/Buy/brand/backend gates; two qualified broad mobile regressions. Only
after all host gates pass may one new unique profile APK be reserved and built,
verified for source/signature/badging/version/hash, installed compatibly in
place on the same OPPO, checksum-matched and replayed ticket by ticket.

Estimated impact: **1 day**, inside the founder-locked 60-75-day window.
