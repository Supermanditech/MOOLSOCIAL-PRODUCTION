# REG2716 — C34J MVP-state combined patch context mismatch

Date: 2026-08-17 IST

A combined patch attempted to update several distant C34J MVP scope sections
using one remembered long selected-assessment context. The live bytes differed,
so `apply_patch` rejected the operation before writing any hunk.

The retry is not a repeated combined patch. Each exact section is read and
patched independently through a unique local anchor, followed by complete JSON
parsing and the MVP scope gate. The rejected operation changed no repository
file, candidate authority, build count or external state.
