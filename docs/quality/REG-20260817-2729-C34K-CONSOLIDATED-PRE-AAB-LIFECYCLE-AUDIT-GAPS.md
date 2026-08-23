# REG2729 — C34K consolidated pre-AAB lifecycle audit gaps

Date: 2026-08-17 IST

Three independent read-only audits completed before any C34K hidden input,
build, Play action or OPPO mutation. They found the following complete blocker
batch:

1. `FixtureMode` is not confined to fixture state and can bypass artifact or
   evidence verification against real candidate state.
2. Detailed then aggregate file replacement is exception-rollback-safe but not
   crash/power-loss atomic between the two final renames.
3. Upload, install and device transitions do not bind durable proof that their
   prerequisite candidate gates ran, and do not validate the complete count
   and future-authority vector.
4. The generic wrapper catches Flutter-build failure but not later copy,
   signing, bundletool, resource, provenance, transition or postbuild-gate
   failure; those can strand a consumed `1/0/0/0` candidate.
5. Later candidate gates accept nonempty evidence paths/fields without proving
   exact retained candidate, version, artifact hash or evidence content.
6. Postbuild recovery hardcodes attempt one and trusts provenance booleans and
   signer shape without current manifest, keytool, bundletool, merged-manifest
   and resource revalidation.
7. Launcher cleanup is not failure-isolated, so a cleanup or prebuild-failure
   transition exception can suppress the retained terminal result.
8. The mandatory dual-host eight-phase candidate-gate fixture is neither run
   nor hash/output-bound by the main gate or cycle summaries.
9. The mutable six-row C33G postinstall acceptance ledger is included in the
   immutable source manifest even though final OPPO evidence must update it;
   the journey gate does not revalidate the source manifest afterward.
10. The preupload gate does not require the live-browser, signed-in MoolSocial
    route and Internal Testing route proof flags, all of which remain false.

The earlier web-production-build concern was withdrawn: `apps/web` runs its
production build inside `npm test`, and retained logs support build plus eight
tests.

C34K's two retained cycles are truthful but bound to the now-stale 2698-entry
registry. C34K is permanently rejected at `0/0/0/0`; neither its cycles nor its
state may be repaired, resealed, built, uploaded, installed or promoted. The
next ticket must correct and behaviorally bind this entire batch before its
source seal and must not expose founder input until the full dual-host release
lifecycle has durable retained proof.
