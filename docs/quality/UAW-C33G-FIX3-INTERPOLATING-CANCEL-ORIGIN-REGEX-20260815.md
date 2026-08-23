# UAW C33G FIX3 interpolating cancel-origin regex

Pre-execution review found the new cancel-origin static assertion used a double-quoted PowerShell regex containing Dart `${_tab.name}`. The gate had not been run, so it produced no false result.

The regex now uses a PowerShell single-quoted literal with doubled embedded apostrophes. The permanent memory gate carries this prevention forward.
