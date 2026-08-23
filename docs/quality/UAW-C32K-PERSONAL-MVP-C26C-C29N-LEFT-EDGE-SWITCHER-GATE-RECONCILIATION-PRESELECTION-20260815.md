# C32K C26C/C29N left-edge switcher gate preselection

Date: 15 August 2026
Ticket: `UAW-C32K-PERSONAL-MVP-C26C-C29N-LEFT-EDGE-SWITCHER-GATE-RECONCILIATION`
Classification: `mvp_supporting`

## Customer outcome

The accepted left-edge Mool launcher opens an on-screen connected switcher
while Chat remains at the right edge, and historical C26C qualification
validates the current conditional alignment owner instead of rejecting it for
lacking an obsolete direct literal.

## Diagnosis, reuse and duplicate search

C29N is the later authority and explicitly locks white Mool to the left edge,
white Chat to the right edge and Home/Shorts/Create/Feed in the middle. Current
Social source follows that order and does not opt into end alignment.

The shared navigator retains a conditional alignment API: compact callers may
opt into top-right/bottom-right, while the default is top-left/bottom-left.
C26C still searches for a direct `targetAnchor: Alignment.topLeft` expression,
which cannot exist once the alignment is conditional. C27C already accepts the
current shared switcher. No new route, screen, service, state or backend owner
is needed.

## Smallest implementation and authority

Change only the C26C alignment literals to bind the conditional target/follower
owner and both branches. Add one C32K checker that binds C26C, C27C, C29N,
current Social ordering and the focused edge test.

The founder's 15 August autonomous audit/finding/ticket/source implementation
direction opens test/gate source only. Runtime Flutter, references, backend,
cloud, provider, live data, build, Play, OPPO, funds, credentials and external
communications remain held.

## Qualification plan

Two identical cycles must pass C26C, C27C and C32K on both PowerShell hosts,
the C29N edge test and targeted analyzer, full C28E gate-only preflight through
all 22 gates, regression memory, MVP scope/delivery and approved UI locks.
