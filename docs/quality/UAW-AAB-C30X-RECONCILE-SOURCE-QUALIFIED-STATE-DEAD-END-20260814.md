# C30X reconcile source-qualified state dead end

Date: 2026-08-14
Incident: `REG-20260814-2171-AAB-C30X-RECONCILE-SOURCE-QUALIFIED-STATE-DEAD-END`
State: registered before repair or retry

After two identical source cycles passed, the machine state truthfully moved
to `source_qualified_exact_successor_candidate_selection_pending`. The C30X
reconcile phase still accepts only the earlier
`prebuild_audit_blocked_no_candidate_no_authority` state and failed closed.

The repair must add an exact, fully bound source-qualified no-candidate context
without weakening the initial context. Both must require empty candidate
identity, zero build/upload/install counts and no candidate, build, upload,
Play-update, device, external-service or secret authority.

The 1,121-file canonical manifest and both completed cycles are preserved as
superseded evidence. A corrected source gate requires a new manifest and two
fresh identical cycles before candidate selection.

## Resolution

FIX6 defines two exact reconcile contexts: the original unqualified audit state
and the fully bound source-qualified candidate-selection-pending state. The
qualified context requires a current sealed manifest, two cycles, all
regressions and source controls; both contexts retain empty candidate identity,
zero counts and no release authority. Positive replay passes on both hosts and
a tampered source-control fact fails closed with counts 0/0/0.
