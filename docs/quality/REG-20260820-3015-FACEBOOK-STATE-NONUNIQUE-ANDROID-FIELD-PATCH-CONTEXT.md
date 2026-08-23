# REG-20260820-3015 Facebook state non-unique Android field patch context

## Incident

After the founder saved the Facebook development key hash, the primary tried to
record the sanitized fact under the Facebook provider object. `apply_patch`
rejected the combined hunk atomically because the expected Android package and
activity context did not match the current Facebook subtree.

## Impact

- The rejected patch changed no file.
- The external Facebook save remains valid and founder-controlled.
- An earlier patch used repeated Android field names without a provider-object
  anchor and may have changed the Google/YouTube subtree instead of Facebook;
  current state must be projected by provider before correction.
- No build, deployment, Play or OPPO action occurred.

## Root cause

Repeated property names across provider objects were patched using short scalar
context rather than one unique provider-object anchor and parsed post-write
projection.

## Prevention

Never patch repeated readiness field names without the literal provider object
anchor. After refreshed gates, project only Google/YouTube and Facebook Android
booleans, patch each unique subtree separately, parse JSON, and rerun the FIX5
gate in both PowerShell hosts.
