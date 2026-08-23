# C25G fingerprinted gate changed after two cycles

Date: 2026-08-09

## Rejection

The first two C25G cycles passed on fingerprint
`76151E9E2AB35B0ED24FA4DC68430915F6F19DFD758C233399F063797B09AF29`,
but the fingerprinted C25G aggregate was then corrected to support exact C25H
replay. The earlier cycles therefore do not qualify the final source.

Their evidence remains preserved under
`artifacts/quality/uaw-c25g-host-qualification-20260809-01` as superseded,
non-qualifying history.

## Recovery

After this permanent-memory registration, no further fingerprinted source is
changed. Two fresh complete cycles must pass in a new `-02` evidence directory
on one identical final fingerprint before C25G may close.

## Permanent rule

Any post-cycle mutation inside the fingerprint scope invalidates the entire
cycle set, even when the mutation strengthens a gate.
