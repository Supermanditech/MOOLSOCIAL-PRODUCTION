# UAW C30T Shorts sealing patch target-section mismatch — 13 August 2026

The first Shorts sealing patch began with the ticket JSON update but placed the
findings-document appendix before declaring a Markdown file update section.
`apply_patch` rejected the entire patch before writing.

The mistake was registered before retry. Sealing state and narrative evidence
are patched one file at a time, or each hunk must have an exact explicit file
header. The rejected patch produced zero mutation.
