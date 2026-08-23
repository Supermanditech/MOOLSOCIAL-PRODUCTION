# C30O computer-use skill full raw read truncation rejection

- Date: 2026-08-12
- Scope: C30O Google Play Internal Testing desktop-control prerequisite
- Result: rejected before any Play or repository mutation

## Mistake

The selected computer-use skill was requested as one full raw shell output. The tool output exceeded the retained context and was truncated, so the required complete skill read could not be proven.

## Root cause

The instruction file was streamed as a single unbounded response instead of being read in bounded, sequential line ranges through end of file.

## Permanent prevention

Do not repeat a full raw output for this skill or its required references. Determine each file's line count, read every line in bounded sequential chunks through EOF, and take no computer-use action until the complete read is confirmed.

## Secret and external-write safety

No credentials, tokens, nonces, private attestation payloads, Play input, device input, or external write occurred during the rejected attempt.
