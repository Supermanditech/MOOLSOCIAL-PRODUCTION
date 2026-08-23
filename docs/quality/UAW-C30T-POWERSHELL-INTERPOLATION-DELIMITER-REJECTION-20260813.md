# UAW C30T PowerShell interpolation delimiter rejection — 2026-08-13

The preflight that audits new registry paths used `$field:` inside an
interpolated string. PowerShell parsed the colon as part of the variable
reference and rejected the command before any path check ran. The retry uses
the format operator, which has no variable-delimiter ambiguity.
