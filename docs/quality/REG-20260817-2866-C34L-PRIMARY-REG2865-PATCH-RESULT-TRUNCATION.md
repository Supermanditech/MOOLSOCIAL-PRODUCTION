# REG2866 — C34L primary REG2865 patch-result truncation

- Status: registered; readback required before any retry.
- Scope: registry/tooling/failure handling only.
- Mistake: the patch call that registered REG2865 returned a truncated tool result, leaving its mutation outcome unknown at the command boundary.
- Root cause: the primary accepted an output path whose wrapper could project an oversized result instead of requiring a compact patch acknowledgement.
- Prevention: after any truncated mutation result, perform bounded exact target readback before further mutation; never retry blindly. REG2865 was subsequently confirmed exactly once in both its durable document and registry tail.
- Repository/external impact: no release, state, build, browser, Play, OPPO, device, private, secret, or external action.
