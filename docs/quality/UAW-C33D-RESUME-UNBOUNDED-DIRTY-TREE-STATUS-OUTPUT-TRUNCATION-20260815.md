# C33D resumed unbounded dirty-tree output truncation

Date: 2026-08-15

The resumed Git identity command printed the full founder-owned dirty tree and
then appended a registry projection. The command succeeded, but its rendered
output was truncated; it is not a complete dirty-tree inventory.

Recovery will emit only the exact branch, HEAD and status-row count. Work will
inspect literal C33D-owned paths only and preserve every other tracked and
untracked path without attempting another unbounded listing.

No Git mutation occurred. No file was removed, reset, cleaned, switched,
committed or overwritten.
