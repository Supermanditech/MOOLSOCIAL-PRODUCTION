# UAW C33F corrective patch missing file header

The first correction attempt placed the regression-registry hunk under the evidence-file update because it omitted a second `Update File` header. `apply_patch` failed its context verification and changed no file.

The retry is registered first and splits each target into an explicit file section. A rejected patch must never be treated as an applied correction; JSON and ID/status projections remain mandatory after the successful retry.
