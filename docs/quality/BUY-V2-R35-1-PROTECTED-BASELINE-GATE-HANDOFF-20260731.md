# Buy V2 R35.1 protected baseline gate handoff

Date: 31 July 2026

State: `COMPLETE_NONVISUAL_PRODUCTION_HARDENING`

Ticket `BUY-FV2-107` machine-protects the founder-approved native Buy R35.1
runtime without changing the application, approved HTML or protected Social
source.

## Authority and protected identity

- Founder-approved baseline commit:
  `34045d33869e13ac17b03d59c2625f2d91a1fb92`
- Branch: `remediation/prototype-conformance-2026-07-20`
- Protected Buy runtime files: `28`
- Portable Buy runtime tree:
  `f712b5b8ce10dd92b64babc4703379a24918fef5cef9417afe9c6679db79bc5d`
- Gate: `scripts/check-buy-protected-baseline.ps1`
- Baseline:
  `artifacts/quality/buy-protected-baseline-r35-1-20260731-28/BASELINE.json`
- Protected Social tree:
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`

The runtime inventory covers all current files under the Buy feature and
native Buy V2 presentation roots, the Buy entry route owner and the five
approved runtime media atlases. Tests and documentation are deliberately
outside the immutable runtime tree so nonvisual hardening can advance without
pretending to reapprove presentation.

## Gate behavior

The gate uses the repository's established portable SHA-256 policy:

- UTF-8 text normalizes CRLF to LF;
- binary files retain their raw bytes;
- inventory is sorted and unique;
- file count and aggregate portable tree must both match;
- the retained review APK is checksum-verified when locally available.

Any missing, added or modified runtime file requires an additive
founder-approved baseline replacement. The existing baseline is never
overwritten.

## Adversarial verification

- The real repository passed with 28 files and the expected tree.
- An isolated exact copy passed.
- Replacing one source file inside the isolated copy was rejected with a
  runtime-tree mismatch.
- Adding one runtime file inside the isolated copy was rejected with an
  inventory-count mismatch.
- The intentionally mutated copy is retained as additive local audit evidence.

## Regression and protected gates

- Full Flutter analysis: passed.
- Complete Buy regression 1: `106` passed, `4` opt-in capture generators
  skipped.
- Complete Buy regression 2: `106` passed, `4` opt-in capture generators
  skipped.
- Protected Buy runtime: passed.
- Protected Social runtime: passed.
- Approved Screens 01–03 and reference locks: passed.
- Founder-FINAL Buy HTML reference: passed.
- Brand integrity: passed.
- User-facing Flutter copy: passed.
- HTML customer copy: `9/9` states passed.
- Interaction contracts: `154` routes passed.
- Temporary HTML server stopped and port 8765 verified free.

The main repository quality command now invokes both the Social and Buy
protected-baseline gates.

## Device boundary

No Flutter runtime file changed, so rebuilding or reinstalling an APK would
not test this release-infrastructure ticket. The OPPO remains on the exact
founder-approved R35.1 APK:

- version `1.0.0-r35.1`;
- version code `2026073045`;
- candidate and pulled installed APK SHA-256
  `10FC8C43626B7C2882A6340C6A3A4710C2092E4D45AB0A768CE7056F23BCB9C7`.

## Evidence

`artifacts/quality/buy-protected-baseline-r35-1-20260731-28`

The evidence includes the baseline JSON, clean-gate output, isolated
tree/inventory rejection logs, Flutter analysis, two Buy regressions and all
protected/reference/copy/interaction gate logs.

## Future-work rule

Nonvisual tests, documentation and read-only analysis may advance while this
gate remains exact. Motion, UI, routing, Buy runtime or protected-media changes
require founder review and a new additive baseline. Backend implementation
remains deferred until an approved transport, identity, authorization and
failure-semantics contract exists.
