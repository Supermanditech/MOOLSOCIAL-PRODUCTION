# UAW C33F focused-manifest generator-name inference correction

Date: 2026-08-15

## Registered mistake

A filename search assumed a dedicated focused-manifest generator existed. No
matching script is present.

## Safe correction

- Register before retry.
- Inspect the existing focused manifest's bounded format.
- Reuse its exact authoritative file list and generate a fresh hash inventory.
- Do not invent or invoke a nonexistent generator path.
