# C26H semantic-tap IME hardening wrong-file-context patch rejection

- Observed: the first IME-hardening patch referenced `$pngPath`, `$readyOnePath` and `$readyTwoPath`, which belong to the stable screenshot helper, while targeting the semantic-tap helper. `apply_patch` rejected the complete patch before mutation.
- Root cause: an uninspected context line from a different newly added PowerShell owner was reused in a multi-file patch.
- Permanent prevention: inspect the literal current target slice first and apply only small owner-specific hunks. Gate/evidence/registry additions may accompany the change only after the target hunk is anchored to exact current semantic-tap lines.
