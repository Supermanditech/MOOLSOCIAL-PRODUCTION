# C30S YouTube main-source expected-no-match diagnostic nonzero

Date: 2026-08-13

A follow-up ripgrep looked only in the main Kotlin directory for debug-only
view-registration symbols. Its expected no-match exit was returned as a tool
failure. Direct reads of all variant registrar files replace that diagnostic.
