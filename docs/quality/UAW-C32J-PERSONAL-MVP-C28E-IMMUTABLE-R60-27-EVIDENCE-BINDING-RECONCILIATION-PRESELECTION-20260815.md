# C32J C28E immutable r60.27 evidence binding preselection

Date: 15 August 2026
Ticket: `UAW-C32J-PERSONAL-MVP-C28E-IMMUTABLE-R60-27-EVIDENCE-BINDING-RECONCILIATION`
Classification: `mvp_supporting`

## Customer outcome

Personal navigation host qualification remains auditable after later
candidates advance, while the original r60.27 version, checksum, two-cycle
source fingerprint and closed build/install evidence stay immutable and exact.

## Reuse and duplicate search

The C28E contract already pins two immutable qualification files and their
SHA-256 values. Both files still match those hashes and contain the exact C28E
ticket, cycles 1 and 2, identical source fingerprint, 53 tests, 22 gates, clean
format/analyzer/suite state, r60.27 identity/checksum and closed runtime/build/
install state.

The host gate ignores those existing sealed files and instead compares its
historical r60.27 values to `config/apk-regression-gate-state.json`, a mutable
pointer that later authorized candidate workflows necessarily advance. No new
screen, route, service, state owner, evidence file or backend owner is needed.

## Smallest implementation and authority

Change only the C28E host gate to read, hash and validate the two existing
contract-pinned cycle files. Add one C32J source checker proving the generic APK
pointer is no longer used by the historical assertion and all current scope
release authorities remain closed.

The founder's 15 August autonomous audit/finding/ticket/source implementation
direction opens test/gate source only. The C28E contract and historical cycle
files, runtime Flutter, references, backend, provider, cloud, live data, build,
Play, OPPO, funds, credentials and communications remain held.

## Qualification plan

Two identical cycles must pass C28E and C32J on PowerShell 7 and Windows
PowerShell, the full C28E gate-only preflight through all 22 gates without
writing cycle evidence, regression memory, MVP delivery/scope and approved UI
locks. A source-gate pass cannot claim current device acceptance.
