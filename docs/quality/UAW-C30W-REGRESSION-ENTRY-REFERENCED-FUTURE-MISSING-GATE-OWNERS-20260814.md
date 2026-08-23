# UAW C30W regression entry referenced future missing gate owners — 2026-08-14

The initial cold-start regression record placed two planned C30W files in its executable `gates` list before those files existed. The regression-memory gate correctly rejected the entry on missing repository evidence.

The planned controls remain mandatory in the C30W findings, but the registry now lists only existing gate owners. New files may be added to the executable list only after they are created, parser/test verified, and present in the repository.
