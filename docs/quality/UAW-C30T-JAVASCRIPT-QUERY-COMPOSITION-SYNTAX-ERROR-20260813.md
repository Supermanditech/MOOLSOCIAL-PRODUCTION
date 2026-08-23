# C30T JavaScript query composition syntax error

Date: 2026-08-13

A retry constructed fixed audit commands by concatenating JavaScript strings that embedded PowerShell and ripgrep quoting. The composed tool script was invalid JavaScript, so no nested command executed.

The corrected retry uses literal shell-tool commands and handles the ripgrep exit contract inside each command. No product, backend, provider, device, AAB, Play or communication state changed.
