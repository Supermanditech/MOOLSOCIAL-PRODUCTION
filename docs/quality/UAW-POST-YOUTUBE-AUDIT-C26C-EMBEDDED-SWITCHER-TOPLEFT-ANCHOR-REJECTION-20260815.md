# Post-YouTube audit C26C embedded-switcher top-left anchor rejection

Date: 15 August 2026
Registry: `REG-20260815-2249-POST-YOUTUBE-AUDIT-C26C-EMBEDDED-SWITCHER-TOPLEFT-ANCHOR-REJECTION`

The post-C32J C28E gate-only preflight passed these gates in order: C28E host,
C28E exported semantics, C27B, C27C, C27D and C26B. It then stopped at C26C:

`C26C gate rejected: embedded switcher contract missing: targetAnchor: Alignment.topLeft`

No later C28E gate ran and no qualification evidence, runtime, build, device,
provider or external state changed. The exact C26C predecessor assertion must
be compared to the later C27C owner, current runtime alignment, C29E Social
end-aligned amendment and focused tests before a product or stale-gate
conclusion is made. No retry or correction precedes that diagnosis.
