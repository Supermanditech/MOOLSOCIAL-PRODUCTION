# REG-20260820-3041 MVP execution gate obsolete script-name lookup

## Observed failure

The preflight gate-discovery command requested help for
`scripts/check-mvp-scope.ps1`, which does not exist. No MVP gate ran.

## Root cause

The diagnostic assumed a shortened historical filename instead of locating the
current repository-owned gate that exposes `-RequireExecutionAuthorized`.

## Impact

- no repository, source, provider, build, Play, OPPO or device state changed;
- no gate result was accepted;
- no retry occurred before registration.

## Prevention and authorized retry

Locate the exact gate using a bounded filename/content search, then invoke only
that repository-owned script with its required authorization switch.
