# C28D machine-blueprint broad artifact search timeout

- Date: 2026-08-10
- Phase: read-only APK machine-state blueprint audit
- Rejection: a broad `rg` for historical one-build authorization states across
  the full artifacts tree exceeded its 34-second read deadline.
- Product/device effect: none; no repository or OPPO mutation occurred.
- Root cause: the query ignored the already known C27F/C26H authority owners
  and searched the entire cumulative evidence archive.
- Prevention: constrain machine-state precedent searches to the current config,
  named predecessor ticket and known recent evidence directories; do not retry
  or broaden an all-artifacts scan.
