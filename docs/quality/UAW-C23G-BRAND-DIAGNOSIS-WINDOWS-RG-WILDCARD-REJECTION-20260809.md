# C23G brand diagnosis Windows ripgrep wildcard rejection — 2026-08-09

## Observed rejection

The brand-owner audit printed the exact gate and launcher evidence, then
ripgrep rejected `apps/mobile/lib/core/design/*.dart` as a literal Windows
path. The command therefore ended nonzero.

## Permanent prevention

Use an exact file, a verified directory operand, or ripgrep `--glob` on
Windows. Shell-style wildcards are not passed as literal path operands, and a
nonzero command is never described as a clean audit.
