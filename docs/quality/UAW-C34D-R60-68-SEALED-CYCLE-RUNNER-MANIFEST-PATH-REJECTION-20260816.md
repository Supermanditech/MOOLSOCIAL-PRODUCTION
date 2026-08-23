# C34D r60.68 sealed cycle-runner manifest-path rejection

Date: 2026-08-16 IST

C34D r60.68 / `2026081368` is rejected before cycle 1 and before any build because its sealed cycle runner names the nonexistent registry-2630 manifest rather than the sealed registry-2632 manifest.

- Regression: `REG-20260816-2662-C34D-SEALED-CYCLE-RUNNER-STALE-SOURCE-MANIFEST-REGISTRY-PATH`
- Sealed registry at candidate seal: 2,632 entries; `490F6FDEDCD805FD44DF4126F6779C20205B0AEB70BA9285E367C43EF3814200`
- Rejection registry: 2,633 entries; `9256B7B97E1806FF49A076976AF029E1CBBC62A5FD06A250F2BD13588EE7F130`
- Sealed source manifest: 1,291 files; `F494A95EF432FAB4A32FD46A0317756229FEF9C051AAEE638735BB214ECF6E6B`
- Source cycles: `0/2`
- Build/upload/install/device-acceptance counts: `0/0/0/0`
- Hidden founder inputs entered: false
- Build authority consumed: false
- Artifact reusable/uploadable/installable/promotable: false

C34D must not be repaired, retried, built, uploaded, installed or promoted. An exact successor with the manifest-path assertion and preseal prerequisite preflight is required.
