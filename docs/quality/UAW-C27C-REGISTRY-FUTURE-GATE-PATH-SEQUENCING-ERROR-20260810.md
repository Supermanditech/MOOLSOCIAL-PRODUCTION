# C27C registry future-gate path sequencing error

## Observation

REG918 was initially appended with the planned C27C gate path before that gate
file existed. The permanent registry contract requires every referenced gate to
exist at the time of registration.

## Cause

The future prevention owner was recorded instead of the already-existing
permanent regression-memory gate during ticket implementation sequencing.

## Permanent prevention

New regression entries reference only gate files that already exist. After a
successor gate is created and passes, an entry may be updated to include it.

## Resolution evidence

Before running the registry validator, REG918 was corrected to the existing
permanent gate and this sequencing error was registered separately.
