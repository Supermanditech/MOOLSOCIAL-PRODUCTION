# UAW C33F rg Windows wildcard-path diagnostic failure

A read-only related-evidence search passed `docs/quality/UAW-C33F*` and an artifact `*.json` path directly to `rg` on Windows. `rg` treated both wildcard strings as literal invalid paths and returned exit code 1 after earlier command sections had already printed valid state.

The retry must target existing directory roots and use `-g` include filters. Read-only output printed before the failure remains informational only; a nonzero composite command is never recorded as a passing diagnostic.
