# C30T approved Feed contract root path guess

## Incident

The Feed action audit treated the manifest-relative
`screens/04-universal-social-feed-create/v2` root as a literal directory below
the screenbook repository root. A read-only existence check proved that inferred
path does not exist.

## Impact

No file was read from an unintended workspace and no repository or screenbook
state was changed. The failed path is not approved-reference evidence.

## Prevention

Use a narrow `rg --files` inventory within the explicitly authorized
`C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook` root, select the exact
Feed v2 interaction-contract result, and read only that returned path. Never
join manifest-relative roots to a filesystem layout by convention.
