# Buy MVP acceptance-policy audit and rollback preselection assessment

Date: 7 August 2026
Ticket: `BUY-MVP-ACCEPTANCE-POLICY-AUDIT-ROLLBACK`
Classification: `mvp_required`
Disposition: `REUSE + ONE NECESSARY PURE DOMAIN OWNER`

## Exact outcome

An authorized policy maker can propose approval of a published Ticket 1 global
SLA revision or Ticket 2 schedule-override revision. A different authorized
checker can approve or reject it with an explanation. An approved rollback is
a new future-effective governance decision pointing to an older exact revision;
no source revision, audit event, receipt, Ticket 3 order snapshot or Ticket 4
provider declaration is rewritten or deleted.

## Reuse decision

- Reuse Ticket 1 global policy IDs, versions, effective dates and command
  fingerprints.
- Reuse Ticket 2 override-set IDs, versions, selector fingerprints, state and
  command fingerprints.
- Reuse SAM-R07 privileged authorization, optimistic version, exact retry,
  conflict, immutable receipt and tenant behavior.
- Preserve Ticket 3 immutable active-order snapshots and Ticket 4 provider
  readiness as protected consumers, not rollback targets.

Production source search found no existing maker-checker or policy-governance
owner. The only rollback match was unrelated YouTube credential-error handling.
One pure acceptance-policy governance aggregate and effective-at projection is
therefore necessary; duplicating policy publication or source truth is not.

## Smallest complete implementation

- Govern exact `global_policy` and `schedule_override` revision references.
- Append immutable maker proposals with bounded reason code and explanation.
- Require a different checker for approve/reject; fail closed on wrong tenant,
  scope, source identity, version, fingerprint or expired approval time.
- Distinguish pending, rejected, approved-forward and approved-rollback facts.
- Resolve the last approved decision effective at an explicit canonical clock.
- Keep rollback append-only and future-order-only; never destructively delete,
  mutate active snapshots or silently alter source contracts.
- Provide payload-minimized immutable audit/receipts, exact restart schemas and
  tamper rejection.

## Explicit holds

- No Admin UI, screen, route, copy or Flutter/reference change.
- No Firestore/store/rule/index/callable/API adapter or Production write.
- No automatic publication, source-revision mutation or active-order change.
- No APK build/install or OPPO mutation.
- No credentials, provider messages/calls, payment, funds, live service action,
  commit, push, deploy, promotion or destructive deletion.

## Qualification plan

Strict focused TypeScript and two focused test cycles cover maker-checker,
forward approval, scheduled rollback, effective-at resolution, rejection,
authorization-before-data, source binding, retry/conflict, restart tamper,
append-only history, audit minimization and immutability. Then run complete
backend typecheck and full regressions twice, MVP and regression-memory gates,
hashes and targeted drift checks.
