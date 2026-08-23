# UAW C30T PowerShell multikey sort syntax rejection — 2026-08-13

The first failure-grouping command used `Sort-Object Value -Descending,Name`,
which is not valid PowerShell parameter syntax. It rejected before reading or
grouping any failure marker. The retry uses explicit calculated properties for
descending failure count and ascending filename.
