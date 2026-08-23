# UAW C33F Windows PowerShell nested syntax-check command mangled

Date: 2026-08-15
Regression: `REG-20260815-2363-C33F-WINDOWS-POWERSHELL-NESTED-SYNTAX-CHECK-COMMAND-MANGLED`

The new C33F gate parsed successfully under PowerShell 7. The first Windows PowerShell 5.1 syntax-check attempt embedded a second `-Command` string inside PowerShell 7; interpolation and quoting changed the text reaching the legacy parser, which then reported artificial token spacing errors. The C33F gate was not executed and no release, device, provider or external state changed.

Recovery: register before retry. Do not reuse the nested interpolated command. Pass a literal UTF-16LE Base64 `-EncodedCommand` to Windows PowerShell so its parser reads the resolved gate path directly without an outer-shell interpolation boundary, then compare the result with the already clean PowerShell 7 parse.
