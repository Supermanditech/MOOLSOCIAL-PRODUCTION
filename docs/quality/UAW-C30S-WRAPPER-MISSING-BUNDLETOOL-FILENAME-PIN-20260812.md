# C30S wrapper missing bundletool filename pin

Date: 2026-08-12

The wrapper self-audit found that the standalone inspector path and hash were
machine-state pinned but the code lacked a second exact filename invariant. No
build or artifact mutation ran.

The wrapper now requires the resolved leaf
`bundletool-all-1.18.3.jar` and the pinned SHA-256 before any preflight or
artifact inspection.
