# C30U combined Flutter command exit masked by finally

A combined format/analyze/test command contained a cleanup `Pop-Location` in
`finally`. The Flutter test failed, but cleanup became the reported shell exit.

All retries use separate processes or explicitly preserve the native exit after
cleanup. The failed run is not qualification evidence.
