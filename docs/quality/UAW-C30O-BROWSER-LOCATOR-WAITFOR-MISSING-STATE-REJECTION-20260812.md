# C30O Browser locator waitFor missing-state rejection

Date: 2026-08-12

## Observed mistake

After requesting navigation to the exact Play Integrity settings URL, a heading readiness check called Browser locator `waitFor` with a timeout but without its required explicit `state`. The API rejected the readiness check.

## Root cause

The action assumed the Browser wrapper accepted Playwright's implicit default state, but this surface requires a state argument.

## Prevention

- Do not repeat the incomplete wait call.
- Reacquire the current URL and snapshot directly.
- If a wait is later necessary, specify `state: "visible"` explicitly.

## Retained evidence

The Browser error records the missing state. No Cloud-project link was submitted.
