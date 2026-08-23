# UAW AAB C30Y postbuild owner-discovery compound search timeout

Date: 2026-08-15
Regression: `REG-20260815-2207-AAB-C30Y-POSTBUILD-OWNER-DISCOVERY-COMPOUND-SEARCH-TIMEOUT`
Status: resolved; bounded inventory and dual-host postbuild/preupload gates passed

## Finding

After the one authorized AAB succeeded, a read-only owner-discovery command
combined three separate questions and timed out before returning usable output.
The AAB was already sealed, and the timeout did not change source, artifact,
state, counts, upload, Play, device or transient inputs.

## Resolution

The retry was split into the exact C30X parameter read, filename-only inventory
and selected-owner content read. Regression memory passed at 2,178 entries,
and C30X postbuild plus preupload gates passed under PowerShell 7 and Windows
PowerShell with counts `1/0/0`.

## Prevention

- Read the exact C30X parameter block in one bounded command.
- Inventory candidate filenames separately under `scripts` and `tmp`.
- Search content only inside the selected exact owners.
- Register a timeout before any bounded retry and never repeat the compound
  search form.
