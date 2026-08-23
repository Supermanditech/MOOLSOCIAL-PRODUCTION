# C30O source-manifest script-name search no-match rejection — 2026-08-12

## Disposition

Rejected as path evidence. No source, build, device, provider, console or account state changed.

## Mistake

The bounded `scripts` filename search for `source`, `aggregate` or `manifest` returned no match and exit 1.

## Root cause

The historical manifest generation owner was assumed to be named after its output instead of being discovered from the sealed C30N evidence or exact wrapper reference.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Search the exact C30N artifact/provenance owner for the manifest-generation command or read the referenced qualifying-cycle owner.
- Do not broaden to the complete repository.
