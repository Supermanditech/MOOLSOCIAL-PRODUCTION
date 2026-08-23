# REG2786 — C34L evidence producer provenance, atomicity and privacy gaps

Date: 17 August 2026
State: registered independent PRE-AAB-2 audit rejection; no external action

## Finding batch

Independent source review rejected the green PRE-AAB-2 producer fixtures:

1. Play, OPPO and journey success is derived only from caller switches and
   counts. No independently retained source evidence path/SHA/bytes, producer
   identity, session/nonce or digest manifest is bound, so success can be
   fabricated while satisfying the current validators;
2. the OPPO pair performs two sequential immutable moves. A failure after the
   cold proof move strands a cold-only record and the both-absent precheck
   permanently blocks deterministic retry or reconciliation;
3. retained/transition evidence validation requires some properties but permits
   unknown fields. Its credential regex misses ordinary emails, phones, private
   URLs/links, identifiers, exception payloads and non-Bearer tokens; and
4. producer and retained read paths reject a reparse leaf but do not walk and
   reject reparse-point ancestors under the exact evidence root.

The independent auditor did not rerun fixtures because source review found P0
blockers. No Play, OPPO, browser, device, authentication, private, build or
external action occurred.

## Required correction

Require immutable source-attestation manifests with exact path/SHA/bytes,
producer/session/nonce and evidence-type-specific digest bindings before a
sanitized success record can be written. Make the OPPO pair a journaled atomic
transaction with deterministic crash reconciliation. Enforce exact allowlisted
schemas plus explicit forbidden property-name and value-shape scanning in
producer, transition and retained gates. Walk every path ancestor and reject
reparse points under the exact real or fixture root. Add dual-host provenance,
partial-pair crash, unknown-field/privacy and ancestor-reparse negatives.
