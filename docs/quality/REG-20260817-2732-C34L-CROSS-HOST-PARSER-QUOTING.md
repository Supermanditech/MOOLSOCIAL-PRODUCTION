# REG-20260817-2732: C34L cross-host parser quoting

PowerShell 7 parsed the C34L transition owner successfully. In the same
read-only checkpoint command, outer-shell interpolation removed the nested
Windows PowerShell `$tokens` assignment, so Windows PowerShell rejected the
command text before parsing the target file.

No candidate, AAB, device, Play, secret, deployment or external state changed.
Future cross-host checks use a retained parser script or safely encoded command
instead of inline nested PowerShell variables. The separate agent checkpoint
already retained a Windows PowerShell parser pass; no shutdown-time retry is
performed.
