# UAW-CURSOR-BUY-SCREEN-SUBACTIONS-UI-20260823

Founder date: 23 August 2026 IST
Lane: `cursor_ui`
Work ID: `buy-screen-subactions-ui-20260823`
Branch: `work/cursor-ui/buy-screen-subactions-ui-20260823`

## Objective

Prepare and implement the founder-directed production UI/UX work for the Buy
screen and its Buy subactions without changing authentication, business logic,
backend contracts, platform configuration, dependencies or release controls.

## Safe start boundary

Cursor may inspect the claimed Buy UI/test owners and produce a concise
current-state/requirement mapping. Cursor must not make a speculative visual or
interaction change until the founder supplies and approves the exact Buy
screen/subaction requirement or reference for the next atomic change.

## Implementation boundary

- Modify only the exact `cursor_ui` owners recorded for this task in
  `config/codex-subagent-coordination-policy.json`.
- Preserve all existing Buy domain/session/service behavior and navigation
  contracts. UI code may consume those contracts but may not redefine them.
- Do not edit authentication, Android/iOS, backend, configuration, scripts,
  dependencies, platform or infrastructure owners.
- Add or update only focused Buy UI/widget tests owned by this ticket.
- One founder-approved UI outcome forms one atomic implementation commit.

## Acceptance

The focused tests pass, the founder approves the exact rendered behavior, the
accepted commit passes the required OPPO journey without regression, sanitized
evidence binds that commit, the evidence-only closure commit is pushed, remote
HEAD equals closure HEAD, and the worktree is clean.
