# UAW C30T ADB package-list substring ambiguity — 2026-08-13

`cmd package list packages -i com.moolsocial.app` returned both the exact app
and the installed `.test` package because Android treats the argument as a
name filter. No device state changed and no installer conclusion was taken
from the ambiguous array. The retry filters the returned text to the literal
`package:com.moolsocial.app` record before accepting the installer identity.
