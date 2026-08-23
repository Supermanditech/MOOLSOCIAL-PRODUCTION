# REG-20260821-3062 Play upload-cert clipboard exact-hex-length assumption

## Observed failure

The local upload-certificate comparison normalized every hexadecimal character
from the complete clipboard text and required a total length of exactly 64. The
copied Play field included additional text, so validation stopped before
keystore access or password entry.

## Root cause

The parser assumed a fingerprint-only clipboard payload instead of extracting
one explicit colon-separated or contiguous SHA-256 fingerprint token.

## Impact

- no keystore was opened and no password was requested;
- no certificate, fingerprint or private value was emitted;
- no Play, repository, build or device state changed.

## Prevention and authorized retry

Require the founder to recopy the Upload key certificate SHA-256 field. Extract
exactly one strict 32-byte fingerprint token locally, reject zero or multiple
matches, clear the clipboard, and emit only MATCH/MISMATCH.
