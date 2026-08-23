# C30T final reconciliation output truncation

Date: 2026-08-13

The attempted final reconciliation combined nested JSON gates, preserved artifact identity, connected-device package state and current provider revision reads in one tool response. The response exceeded the available output budget and was truncated, so the entire combined result is rejected and cannot support a pass claim.

Permanent prevention: run every reconciliation phase separately. Persist verbose gate output in immutable evidence logs and return only the pass state, checksum and count. Return only bounded, derived device fields and one compact line per provider revision. Never infer a result from a truncated response.
