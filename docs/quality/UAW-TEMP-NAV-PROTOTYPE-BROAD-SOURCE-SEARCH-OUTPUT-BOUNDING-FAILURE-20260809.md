# Temporary prototype broad source-search output-bounding failure

Date: 2026-08-09

During final review discovery, an in-memory PowerShell `Split` result was piped
to `Select-String` and emitted an oversized portion of the prototype instead of
the intended bounded matching lines. A later retry combined the complete docs
tree with the prototype and timed out after returning only part of the relevant
matches.

Root cause: the diagnostic was not restricted to the exact known source owners
and did not bound both result count and search cost before execution.

Correction contract: source review searches operate on exact known paths, cap
the displayed matches, and use direct path-based `Select-String` or ripgrep.
They do not pipe a full in-memory document through an ambiguous `Split`
overload and do not scan the full documentation tree when one evidence file is
the owner.

No Flutter source, accepted screenbook, APK, installed OPPO state or protected
runtime was changed by this diagnostic failure.
