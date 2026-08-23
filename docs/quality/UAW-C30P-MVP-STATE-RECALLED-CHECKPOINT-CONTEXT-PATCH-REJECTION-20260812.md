# C30P MVP-state recalled checkpoint context patch rejection

Date: 2026-08-12

The first attempted C30P update to `config/mvp-scope-gate-state.json` used a
recalled C30O `approvalState` literal rather than the exact current dirty-file
value. `apply_patch` rejected the complete multi-hunk patch at verification;
no hunk was applied and no repository file changed.

Prevention: re-read only the exact live MVP ticket, authorization, checkpoint
and selected-assessment windows, then apply small context-verified patches.
Never infer a mutable machine-state literal from a summary or nearby ticket.
