# C30O Play app-ID bounded-folder search timeout rejection

- Date: 2026-08-12
- Scope: local correction-target discovery
- Result: rejected search scope; partial exact output retained

## Mistake

The follow-up fixed-string search was limited to `config`, `docs/quality`, and `scripts`, but `docs/quality` is itself large enough that the command still timed out.

## Root cause

The prevention narrowed top-level folders but did not narrow to the known C30O live-authority filenames. Folder-level scope was still excessive for this dirty repository.

## Permanent prevention

Do not repeat any folder-level app-ID search. Use only the exact files disclosed before timeout: the C30O machine state, app-container creation evidence, and founder tester-list evidence. Preserve regression documents and registry text that intentionally record the rejected old value.

## Partial exact result

The timed-out read-only command identified these live facts for correction:

- `config/play-internal-aab-regression-gate-state-c30o.json`
- `docs/quality/UAW-C30O-PLAY-INTERNAL-APP-CONTAINER-CREATION-EVIDENCE-20260812.md`
- `docs/quality/UAW-C30O-PLAY-INTERNAL-FOUNDER-TESTER-LIST-ATTACHMENT-EVIDENCE-20260812.md`

No mutation occurred during the search.
