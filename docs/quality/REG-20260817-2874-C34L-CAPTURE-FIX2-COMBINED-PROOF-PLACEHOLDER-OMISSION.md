# REG2874 — C34L capture FIX2 combined proof placeholder omission

- Status: registered pre-test incomplete repair of REG2837.
- Defect: the combined producer fixture still hardcoded `evidencePath` to `fixture-prerequisite-proof.json` and `sha256` to `F` × 64 instead of binding each newest lifecycle proof to the actual Play, OPPO-cold, or journey evidence path and SHA.
- Root cause: producer/attestation FIX2 updated capture provenance but did not remove the combined fixture's legacy placeholder proof owner after the independent audit had identified it.
- Prevention: construct each final proof only after its writer result exists; pass that exact confined path/SHA and add wrong evidence-path/hash negatives. The retained gate must continue comparing detailed and aggregate proof histories exactly.
- Impact: found by static readback before the combined retry; no fixture, release, device, private, or external action.
