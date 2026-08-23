# C30U qualifier retry log collision risk

The first qualifier used cycle-only log names. A retry after the failed
pre-seal attempt would have overwritten the retained failure logs.

Retries now require an explicit attempt number, use attempt-scoped log names,
and fail if any intended log already exists. Accepted cycle evidence is written
only after every check passes.

The original failure logs remain preserved. No release mutation occurred.
