# C21G PowerShell read-only Host variable collision — 2026-08-08

The first C21G optical-delta checker parsed and chained C21B through C21F successfully, then attempted to assign the qualification contract to `$host`. PowerShell treats variable names case-insensitively, so this collided with read-only automatic variable `$Host` and rejected the run.

REG-20260808-491 requires the task-specific name `$hostQualificationContract` and a fresh positive/negative gate proof. The rejected run is not qualification evidence. Runtime, build, install and OPPO state remain unchanged.
