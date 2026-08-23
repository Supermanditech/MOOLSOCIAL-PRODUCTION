# REG-20260820-3012 cumulative PowerShell transcript made latest hash attempt ambiguous

## Incident

After the founder entered the local Android debug-keystore password, the
certificate-hash workflow reported an error. The shared terminal transcript
also contained all earlier failed and successful-looking attempts, so bounded
marker inspection found both success and failure markers and could not prove
the outcome of the latest invocation.

## Impact

- No development key hash was accepted as current clipboard or Meta evidence.
- Codex did not read or emit any password, certificate, key hash, local path or
  clipboard value.
- No Meta save, repository build, deployment, Play or OPPO action was reported.
- The cumulative transcript is rejected as latest-attempt evidence.

## Root cause

Multiple attempts reused one PowerShell window without a unique attempt
boundary, and the workflow was evaluated from a cumulative transcript rather
than one isolated exit classification.

## Prevention

Do not paste full terminal history. Use a fresh PowerShell process or one unique
attempt marker, resolve all executables before the attempt, and report only one
literal sanitized terminal outcome: `MOOLSOCIAL_HASH_COPY_OK` or a bounded
failure class. Never emit or return the password or fingerprint.

## Post-registration bounded resolution

An output-only ordered classification resolved the cumulative sequence as
password rejection, password rejection, certificate stored, password
rejection, export failed. Therefore one earlier founder-entered local-keystore
password succeeded, while the later conventional Android default did not apply
to this keystore. No fingerprint output was accepted, and the next attempt must
run in a fresh terminal with only an isolated literal outcome marker.
