# UAW C33F ambiguous evidence status patch target

While adding the first sanitized OPPO reproduction result, a context-light patch matched the first repeated `founder_reported_reproduction_pending` value in the evidence file. That first value belonged to the Feed defect, not the intended Google sign-in defect. Immediate JSON verification found the mismatch before device replay, ticket selection or qualification.

The repair is restricted by the stable defect IDs: `C33F-RUNTIME-01` remains founder-reported and pending reproduction, while `C33F-RUNTIME-02` is marked confirmed by the sanitized Google return-state evidence. Future repeated-field JSON patches must include the immutable record ID and journey in their context and must print an ID/status projection immediately afterward.
