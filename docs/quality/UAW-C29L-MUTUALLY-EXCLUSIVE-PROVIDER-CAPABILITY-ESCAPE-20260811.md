# C29L mutually exclusive provider capability escape

The first two C29L host cycles passed source and injected tests with both
`ownerConnect` and `privateUpload` set true. A subsequent read-only audit of
the real Dev controller and `readCapabilities` proved that this state is
impossible: exactly one expiring proof profile may be active. Consequently the
real Social creator choice could never appear, even during a valid private
upload proof.

The retained `20260811-01` host evidence is not deleted or overwritten. It is
superseded because its fixtures failed to model the provider's mutually
exclusive profile contract.

The least-privilege correction makes the single `privateUpload` profile own
upload-purpose Google consent and the minimum exact-channel connection-status
read required to connect, reconnect, disconnect and upload. Read-only owner
videos, playlists and subscriptions remain behind `ownerConnect`. The UI and
host gate must reject a renewed `ownerConnect && privateUpload` conjunction,
and two fresh identical host cycles are required in a new evidence directory.

No provider, cloud, credential, token, secret, APK or OPPO state was mutated
while detecting this defect.
