# UAW C09 Windows wildcard rg operand recurrence

## Incident

An affected-test discovery command passed `docs\quality\UAW-C09*.md` directly
to `rg` alongside valid literal roots. Windows rejected that operand and the
command exited with code 1 after printing partial matches from other roots.

This repeated the failure class already covered by the project-memory rule that
native search operands must be existing literal paths and filename patterns
must use `-g`.

## Disposition and prevention

The entire partial result was discarded. Follow-up discovery uses literal file
paths or an existing literal directory with a separate `-g "UAW-C09*.md"`
filter. Before execution, every `rg` path operand is checked for wildcard
characters; one invalid operand invalidates the complete multi-root command.

No product source, APK, OPPO package or application data was changed by this
failed read-only discovery command.
