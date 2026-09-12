# UAW-CODEX-REL-CONFIG-01-YOUTUBE-FLAG-PRESERVATION-20260825

Founder date: 25 August 2026 IST  
Parent: `UAW-CODEX-SOCIAL-RUNTIME-CONTINUATION-20260825`  
Runtime ticket: `REL-CONFIG-01`  
Lane: `codex_auth`  
Work ID: `social-runtime-core-20260824`

## Customer outcome

An isolated YouTube provider deployment cannot silently disable the accepted
Social runtime. The deploy wrapper preserves and verifies the complete
permanent non-secret runtime tuple on the new provider revision.

Classification: `mvp_required`. The omission already disabled production
Videos, Shorts, Search and related Social journeys once.

## Smallest complete implementation

- Keep the deploy target limited to `youtubeProvider`.
- After the Firebase provider deployment, explicitly restore the accepted
  provider environment, exact OAuth callback, enabled flag and accepted mode
  on the new Cloud Run revision.
- Read back the new revision's environment internally and fail unless all four
  exact values are present with 100 percent traffic.
- Strengthen the local deployment-control test so omission or reordering of
  the permanent update is rejected before any cloud action.

## Explicit exclusions

- No cloud, Firebase, provider-console or deployment action in this ticket.
- No callback, content, UI, mobile, session, cache, Cursor or APK change.
- No proof-window timer, proof expiry, secret, credential or private value.
- No build, install, Play, AAB, tag, integration or promotion.

## Owners

- `scripts/deploy-youtube-provider-c30m.ps1`
- `scripts/test-youtube-provider-c30m-deployment-controls.ps1`
- `config/runtime/moolsocial-production-runtime-tickets-20260825.json`
- this ticket

## Test plan

- PowerShell AST parse.
- Provider deployment-control source gate.
- Wrong-project negative fixture.
- Required permanent tuple and exact provider-only ordering assertions.
- Diff check and current package/content containment replay.
