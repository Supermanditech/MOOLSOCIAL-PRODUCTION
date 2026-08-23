# C30T shared Chat key direct substitution failure

Date: 2026-08-13

Replacing retired `mool-root-chat` with current `mool-global-chat` did not repair the shared account journey because that global control is not mounted on the final shared account screen. The exact retry failed and the edit was rejected.

Permanent prevention: inspect the exact screen/router owner at the final route before migrating a navigation key. Use only a control proven to be mounted there, or remove the obsolete cross-owner assertion with explicit current-contract evidence.
