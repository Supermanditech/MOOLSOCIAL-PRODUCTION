# REG2875 — C34L retained FIX2 supplied REG2874 path discarded

- Status: registered read-only reconstruction mistake.
- Mistake: the retained agent was sent the exact REG2874 path ending `COMBINED-PROOF-PLACEHOLDER-OMISSION.md`, but replaced it with a shortened topic-derived filename and `Get-Content` failed.
- Root cause: a supplied durable path was not copied verbatim.
- Prevention: use the supplied exact path; if none is available, discover the numeric ID with bounded `rg --files` before reading. Never abbreviate or infer regression filenames.
- Impact: no memory gate, test, mutation, recovery, release, private, or external action followed.
