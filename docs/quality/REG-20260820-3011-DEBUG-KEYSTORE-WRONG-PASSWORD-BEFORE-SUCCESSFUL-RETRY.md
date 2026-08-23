# REG-20260820-3011 debug keystore wrong password before successful retry

## Incident

Bounded marker inspection of the founder-provided terminal transcript confirmed
that an Android debug-certificate export first failed because an unrelated
account password was entered at the local keystore prompt. A later founder
retry successfully exported the certificate and copied the derived development
key hash to the local clipboard before this failure was registered.

## Impact

- The rejected password attempt stayed inside the local `keytool` process and
  was not sent to Firebase, Google Cloud, Meta or Codex.
- Codex did not read or emit the password, certificate, key hash, local path or
  clipboard value.
- The successful retry left only the founder-controlled fingerprint on the
  clipboard; Meta save was not reported.
- No repository, build, Play, OPPO or deployment state changed.

## Root cause

The credential domain of the `keytool` prompt was not made explicit before the
first invocation, so an unrelated online-account password was supplied to a
local Android debug-keystore operation.

## Prevention

Before invoking any password-bearing tool, name the exact local or provider
credential domain and explicitly prohibit unrelated account credentials. Stop
after a rejected prompt and register it before retry. Keep successful key-hash
material founder-only and clipboard-to-provider, with no chat or repository
value capture.
