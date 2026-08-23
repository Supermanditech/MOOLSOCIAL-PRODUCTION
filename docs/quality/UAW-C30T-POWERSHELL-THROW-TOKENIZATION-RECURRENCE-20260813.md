# C30T PowerShell `throw` tokenization recurrence

- Date: 2026-08-13
- Device: OPPO CPH2375, serial `2b3e0f71`
- Installed artifact: Google Play Internal Testing `1.0.0-r60.44 (2026081244)`
- Scope: non-writing Create-format journey inventory

After cancelling the Carousel photo picker, the composer semantically exposed only `Carousel / Carousel` and `Text / Text`. The first attempt to seek Image therefore found zero exact Image targets and entered its fail-closed branch. That branch contained an invalid compressed `throw"..."` token instead of `throw "..."`. Because `ErrorActionPreference` was `Stop`, execution terminated before coordinate derivation or any tap.

No UI state, content, backend, build, upload or installation changed. The next action must use readable multiline PowerShell, re-prove the current Carousel state and its unique Text selector, select Text once, recapture the six-format grid, and only then seek Image from a new hierarchy.
