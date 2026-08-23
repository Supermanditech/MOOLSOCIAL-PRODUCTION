# REG2931 — FIX3 producer output-root precreation ancestor

## Observed event

After REG2930 separated adapter source outputs from producer capture outputs, the next fresh PS7 authoritative-only fixture exited 1 with `capture output root ancestor is missing.` The failure occurs before producer-owned directory creation because the confinement helper requires the immediate parent to already exist.

## Impact

- Adapter/producer ownership separation advanced correctly.
- No output parent was created.
- WinPS was not run; no resolver edit, retry, later read/edit/test, cleanup probe, real build, browser, Play, OPPO, journey, device, private, provider, or external action occurred.

## Root cause

A resolver designed for existing input paths was reused for a canonical producer output path whose final contract-owned parent chain is intentionally absent before first persistence.

## Mandatory prevention

1. Resolve and validate the nearest existing ancestor under the exact repository/evidence/attempt root.
2. Reject any reparse component, sibling alias, `..`, unexpected existing leaf, or path outside the canonical contract mapping.
3. Create only the missing exact producer-owned directory components in order, then re-resolve and revalidate the final root before writing.
4. Add absent-parent positive plus wrong-root, reparse-nearest-ancestor, existing-file-as-parent, sibling, and partial-chain negatives.
5. Inventory/clean exact residue, parse, rerun fresh PS7, then WinPS.
