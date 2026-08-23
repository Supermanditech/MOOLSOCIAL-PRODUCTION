# C30T deployment authorization patch stale context

Date: 2026-08-13

The first combined deployment-authorization patch expected an older aggregate-state line shape and was rejected in full. Verification confirmed that neither the proposed registry entry nor authorization state had been partially written.

Permanent prevention: read the exact target line immediately before mutation and apply registry/evidence additions separately from mutable aggregate-state updates.
