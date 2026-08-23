# C33D self-gate evidence-path lifecycle ordering

Date: 2026-08-15

The first evidence-path assertion was placed before the gate calculated
whether C33D was selected or qualified. It therefore hardcoded the final
qualification path for both branches. The defect was found by source review
before executing the modified gate.

The correction derives one expected path after lifecycle validation: the
ticket manifest while selected, and the qualification document when qualified.
No failed gate run, product change or authority expansion occurred.
