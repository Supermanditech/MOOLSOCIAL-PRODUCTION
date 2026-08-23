# C30T Chat-context owner path guess recurrence

## Incident

The first Repost/Share implementation search included two convention-derived
paths: `apps/mobile/lib/ui_v2/chat/chat_v2.dart` and
`apps/mobile/lib/ui_v2/universal/universal_v2.dart`. Neither exists. All output
from that grouped search was rejected even though other files returned matches.

## Impact

The search was read-only and changed no source, backend, service or device
state. It is not implementation-owner evidence.

## Prevention

Resolve Chat and Universal files with a narrow `rg --files apps/mobile/lib`
inventory first. Search symbols only in exact returned paths and the separately
verified Journey router. Any rg missing-path error rejects the complete grouped
diagnostic even if a PowerShell pipeline masks its native status.
