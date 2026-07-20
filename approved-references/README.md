# Approved prototype references

This directory is the immutable, versioned source of truth for founder-approved
HTML states used by the native Flutter UI V2 conformance rebuild.

Each accepted screen version contains:

- a self-contained copy of the accepted HTML and every local dependency;
- reference images captured at the dimensions recorded in its contract;
- the complete visible-state and interaction contract;
- SHA-256 checksums recorded in `manifest.json`.

Accepted files are never overwritten. A later approval creates a new version
directory and a new manifest entry.

Flutter-generated goldens are comparison evidence only. They cannot approve or
replace a prototype reference.
