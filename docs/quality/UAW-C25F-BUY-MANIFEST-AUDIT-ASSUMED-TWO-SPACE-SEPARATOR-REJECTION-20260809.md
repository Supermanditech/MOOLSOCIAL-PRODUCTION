# C25F Buy manifest audit separator assumption rejection

- Date: 2026-08-09
- Status: registered before audit retry

The first read-only Buy manifest comparison required exactly two spaces after each SHA-256. The existing accepted Buy manifest uses a different whitespace representation on at least its first line, so the audit stopped before comparing any file.

The retry must split on one-or-more whitespace characters after validating the 64-hex prefix, preserving the accepted manifest rather than rewriting it.
