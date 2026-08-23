# C25F Buy manifest audit 64-hex line assumption rejection

- Date: 2026-08-09
- Status: registered before audit retry

After relaxing the separator, the audit still rejected the accepted Buy manifest because at least one historical manifest line contains a shortened hash token. The active protection gate does not consume this per-file manifest; it computes the whole runtime tree independently from the live file inventory and the sealed tree hash.

The mismatch audit will therefore parse each path from the accepted line, compare only lines with a valid 64-hex token, and report historical malformed tokens separately. It will not alter predecessor evidence.
