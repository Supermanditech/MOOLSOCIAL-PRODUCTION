# C29R measurement counter corruption-reset rejection

Date: 2026-08-11

Prequalification review found the initial quota and shared-catalogue
measurement helpers returned zero for any invalid stored counter. A corrupt or
negative value could therefore be overwritten and understate operational
evidence.

Missing fields now initialize to zero, while every present counter must be a
non-negative safe integer. Focused tests inject corrupted quota and catalogue
counters and require the write to fail. Catalogue delivery remains available
when only best-effort measurement storage fails; no false measurement is
written. No external runtime, device or deployment action occurred.
