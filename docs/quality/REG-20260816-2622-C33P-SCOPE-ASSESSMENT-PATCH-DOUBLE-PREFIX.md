# REG-20260816-2622 — C33P scope assessment patch retained a diff prefix

Date: 2026-08-16 IST

The first C33P selected-assessment insertion generated an apply-patch hunk by
prefixing an already prefixed first added line. Apply-patch correctly consumed
one prefix and wrote the second `+` into `mvp-scope-gate-state.json`, so the
immediate JSON parse rejected the intermediate file. No scope gate, source
seal, test, build, Play write or device action ran.

The correction is to count no selection result, remove only the proved extra
character with a bounded patch, parse the complete JSON before any gate, and
generate future dynamic apply-patch blocks with exactly one patch marker per
added line. C33P remains pre-seal and must bind the updated registry.
