# REG-20260821-3063 upload-store password prompt and success marker interleaved

## Observed failure

The PowerShell transcript placed the expected success-marker text immediately
after the `New keystore password:` prompt, making it ambiguous whether that text
was entered as the password or emitted later. Keytool completed successfully,
but password strength cannot be accepted from the transcript.

## Root cause

The interactive keytool command and the follow-up marker block were pasted/run
separately while prompts were active, allowing marker text and prompt input to
interleave.

## Impact

- the keystore and private key remain structurally valid;
- no private key or certificate value was emitted;
- the current store password is known to the founder but is not qualified as
  strong or unexposed;
- no Play, build, repository or device state changed.

## Prevention and authorized retry

Change the store password once more to a fresh generated value. Wait for all
keytool prompts to finish before executing any marker command; the marker must
be emitted automatically only after exit zero. Never type an expected marker as
prompt input.
