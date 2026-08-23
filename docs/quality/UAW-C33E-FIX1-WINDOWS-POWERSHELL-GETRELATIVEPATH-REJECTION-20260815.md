# C33E FIX1 Windows PowerShell GetRelativePath rejection

Date: 15 August 2026
Regression: `REG-20260815-2339-C33E-FIX1-WINDOWS-POWERSHELL-PATH-GETRELATIVEPATH-UNAVAILABLE`

PowerShell 7 passed the complete C33E FIX1 lifecycle checker. Windows
PowerShell 5.1 then rejected `System.IO.Path.GetRelativePath` because that API
is unavailable in its .NET Framework runtime. The C30Z gate itself passed on
Windows PowerShell before the checker reached this incompatibility.

Recovery replaces the modern API with a repository-prefix-validated substring
conversion, confirms the unique temporary fixture directory was removed and
restarts the complete checker on both required hosts. No Flutter runtime,
device, build, provider, secret or external-service state changed.
