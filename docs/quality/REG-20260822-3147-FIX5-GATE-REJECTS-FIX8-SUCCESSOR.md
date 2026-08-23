# REG-20260822-3147 — FIX5 gate rejects the selected FIX8 successor

Date: 22 August 2026

State: registered; zero test/build/device continuation

The first inherited FIX5 gate replay after selecting the founder-directed FIX8
source-repair ticket rejected the MVP selection boundary before evaluating the
new comprehensive-audit state. No later gate, test, build or device action ran.

Root cause: the FIX5 gate's selected-ticket allowlist predates FIX8 and accepts
only the FIX5 lifecycle identities it knew when written.

Prevention: add the exact FIX8 descendant ID and manifest binding to the
successor branch while preserving the FIX5 ticket hash, provider/runtime facts,
privacy prohibitions, zero build/Play/OPPO/private-action counts and all source
assertions. Retain unrelated-ticket negative rejection.
