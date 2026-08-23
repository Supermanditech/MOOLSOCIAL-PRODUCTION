# REG2657 — C34B combined document patch context mismatch

Date: 2026-08-16 IST

The first combined patch for the C34B founder authorization, browser
qualification and upload runbook expected a browser-document context copied
from another document. `apply_patch` rejected the complete operation and
changed no document bytes.

No C34B parser, gate or source seal result is counted. Each document must be
read exactly, patched separately and verified before registry/ticket binding,
dual-host parsing or source gates.
