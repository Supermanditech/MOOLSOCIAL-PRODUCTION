# Backend resolution document-context mismatch

Date: 2026-08-14
Incident: `REG-20260814-2170-AAB-BACKEND-RESOLUTION-DOC-CONTEXT-MISMATCH`
State: registered before retry

The combined resolution patch assumed an incorrect final sentence in one
incident document. `apply_patch` rejected the entire patch, so no registry
status or prior document changed. The retry will separate registry status
changes from document appends and use exact freshly read tails.

## Resolution

Registry statuses were updated in an ID-anchored patch. Each incident document
was then appended separately using its freshly read exact tail; no combined
multidocument resolution patch was retried.
