# C22B post-fix format-dirty rejection

The fail-fast retry stopped at the formatter because the focused test changed after the alpha assertion patch. The check-only formatter returned nonzero; no test, analysis or later policy gate from that call is counted. A separate write-mode format is required before the clean verification.
