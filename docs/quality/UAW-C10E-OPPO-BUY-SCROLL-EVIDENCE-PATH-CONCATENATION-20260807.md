# C10E OPPO Buy scroll evidence path concatenation

- Registry: `REG-20260807-238-C10E-OPPO-BUY-SCROLL-EVIDENCE-PATH-CONCATENATION`
- State: resolved; permanent gate active.

The Buy scroll → Mool → Back journey completed and both screenshot/hierarchy
pairs were pulled successfully. The final verifier placed a filename suffix
outside `Join-Path`, producing a malformed `32\+...` lookup. No device journey
is repeated and no evidence is overwritten.

Post-capture comparison now reads the two exact literal filenames already
reported by the successful pull operations. Device evidence path construction
uses one complete leaf string before `Join-Path` and verifies existence before
parsing.
