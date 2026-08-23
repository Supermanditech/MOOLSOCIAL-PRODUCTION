# C30O Play Create app UIA set-value cache-property rejection — 2026-08-12

## Disposition

Rejected input attempt. The bridge reported a missing cached UIA read-only property while entering the app identity. The form was not submitted and no Play app was created. Any partial in-form text must be refreshed and verified before retry.

## Mistake

The first Play Create app form input used `set_value` for two Chrome-rendered edit controls. The Windows bridge could not read the cached UIA value/read-only state and rejected the attempt.

## Root cause

The accessible edit indexes did not expose the property set required by `set_value` in this Chrome form state.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Refresh the exact form and inspect whether either field changed.
- For unchanged fields, use one accessibility click followed by `Ctrl+A` and `type_text`, refreshing after each field.
- Do not submit until the app name, package, availability, category, pricing and declarations are all visibly exact.
