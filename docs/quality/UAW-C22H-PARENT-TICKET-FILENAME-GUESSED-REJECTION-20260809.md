# C22H parent-ticket filename rejection

- Date: 2026-08-09
- Scope: C22H authority inventory
- Build/install/device mutation: none

## Rejection

The inventory guessed a C22 filename ending in `-parent-ticket.json`. The
actual owner discovered under the bounded config inventory is
`config/uaw-personal-mvp-global-capsule-subaction-recovery-fix5-c22-ticket.json`.
The stopped aggregate was rejected in full and granted no authority.

## Prevention

Discover the exact ticket hierarchy filenames before literal reads or patches;
never translate a manifest's logical parent role into an assumed path suffix.
