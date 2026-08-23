# C24E root-script inventory from mobile cwd / masked exit rejection — 2026-08-09

The C24E post-test diagnostic searched `scripts` while its working directory was
`apps/mobile`. Ripgrep truthfully reported the missing operand, but the compound
command continued to a successful affected analyzer and returned that later
zero exit status.

The analyzer result remains valid on its own. The script-inventory portion is
rejected and is rerun separately from the repository root. Future checks split
the path domains and inspect each exit immediately. No runtime mutation was
caused by this diagnostic.
