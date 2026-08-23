# REG-20260822-3208 — Registry readback relative index selected wrong incident

## Incident

A REG3205 correction readback used a relative array index and selected REG3204,
so the displayed root cause did not verify the intended incident.

## Impact

- Repository mutation caused by readback: `false`
- Additional APK or AAB builds: `0`
- Sealed artifacts: `0`
- OPPO actions: `0`

## Root cause

The verification assumed the target incident's position relative to the
registry tail after new entries had been appended.

## Permanent prevention

Select registry evidence by exact incident ID for every readback and reject
positional indexing whenever entries can be appended in the same task.
