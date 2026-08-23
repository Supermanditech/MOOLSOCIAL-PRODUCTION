# C21 PowerShell-interpolated Dart key token rejection — 2026-08-08

Static review found that the new C21B PowerShell gate placed the Dart `${action.id}` key fragment in a double-quoted PowerShell string. PowerShell would interpolate it before the source search and produce a false missing-token failure. The gate had not yet been executed or cited as evidence.

Cross-language source tokens containing `$` use literal single-quoted PowerShell strings or a smaller interpolation-free invariant. The corrected gate checks the literal `specular-edge` fragment.
