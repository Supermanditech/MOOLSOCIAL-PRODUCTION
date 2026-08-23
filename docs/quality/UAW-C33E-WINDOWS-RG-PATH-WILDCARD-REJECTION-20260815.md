# C33E Windows ripgrep path wildcard rejection

Date: 15 August 2026
Regression: `REG-20260815-2337-C33E-WINDOWS-RG-PATH-WILDCARD-REJECTED`

A read-only search supplied `scripts/check-uaw-c33*.ps1` as a Windows path
argument. Ripgrep rejected that syntax before returning useful results. The
retry must use the literal `scripts` directory with an explicit `--glob`
filter, keep the C30Z path literal and cap output. No product, device, build,
provider or external-service state changed.
