# C09 first fitment regression failure

Date: 7 August 2026

The first compiled multi-file C09 cycle reached 34 passing tests, then the R15
copy/fitment matrix rejected every viewport because the Home summary rendered
an exact `Social` label while the bottom rail rendered its own exact `Social`
label. The same duplication applied to the other main actions. This was a real
single-owner copy and semantics defect, not a stale test.

REG-20260807-136 retains the failure. The non-interactive duplicate chips are
removed; the benefit-led summary names the available actions in one sentence,
while the bottom rail remains the only per-action label and tap owner.
