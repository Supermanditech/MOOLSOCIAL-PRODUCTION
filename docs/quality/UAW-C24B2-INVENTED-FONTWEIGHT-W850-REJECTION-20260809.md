# C24B2 invented FontWeight.w850 rejection — 2026-08-09

The first fixed-viewport direct-action style used nonexistent `FontWeight.w850`. The defect was observed before compilation and no qualifying test was run.

The correction uses the literal supported `FontWeight.w800`; selected family emphasis remains `FontWeight.w900`. This mistake is permanently registered as `REG-20260809-619-C24B2-INVENTED-FONTWEIGHT-W850`.
