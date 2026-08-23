# C30U postbuild registry mutation invalidated the source seal

Date: 2026-08-14
Ticket: `UAW-C30U-POST-R60-45-SOCIAL-REPAIRS-PLAY-INTERNAL-ACCEPTANCE`

## Incident

The permanent regression entry for the read-only postbuild search timeout was added before invoking the C30U pre-upload gate. The gate then rejected the transition because `config/codex-development-regression-registry.json` is part of the qualified source manifest and had changed.

The rejection happened before any Google Play upload, release activation, or OPPO mutation. The sealed r60.46 AAB remains unchanged and the single build authority remains consumed.

## Required recovery boundary

- Do not bypass or weaken the C30U gate.
- Do not build a second AAB without new founder authorization.
- Read only exact existing C30U gate and manifest owners to determine whether a documented postbuild recovery path can prove all product inputs and the sealed AAB unchanged.
- If no such owner exists, keep upload and installation blocked and request founder direction.
