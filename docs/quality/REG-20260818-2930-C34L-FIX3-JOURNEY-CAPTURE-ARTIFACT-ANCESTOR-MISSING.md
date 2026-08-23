# REG2930 — FIX3 journey capture artifact ancestor missing

## Observed event

After the deterministic session correction, the fresh PS7 authoritative-only fixture advanced through Play and OPPO, then exited 1 before first journey artifact persistence with `journey capture publicGuest ancestor is missing.`

## Impact

- Play and OPPO authoritative receipt paths advanced beyond prior failures.
- No journey artifact was persisted.
- WinPS was not run; no later diagnosis, directory creation, retry, read/edit/test, cleanup probe, real build, browser, Play, OPPO, journey, device, private, provider, or external action occurred.

## Root cause boundary

The journey adapter output/fixture scaffolding and capture producer disagree about which owner creates the exact immutable parent directories for per-row artifacts.

## Mandatory prevention

1. Inspect the exact contract path mapping and determine one owner for directory creation.
2. Production capture creates only its own canonical output directories after all input validation; source adapters create only their confined source outputs.
3. Canonicalize and prove every ancestor under the exact attempt/type root, reject reparse/sibling aliases, and never infer missing parents from caller input.
4. Add missing-parent, wrong-parent, reparse-ancestor, cross-row, and duplicate-role negatives.
5. Inventory/clean exact residue, parse, rerun fresh PS7, then WinPS.
