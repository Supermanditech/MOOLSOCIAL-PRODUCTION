# C17H inline PowerShell/JavaScript quoting parse failure

The first semantic capture command embedded a multi-function PowerShell program containing backticks and regular-expression quoting inside the JavaScript tool wrapper. JavaScript parsing failed before the shell command or any device action began.

The correction uses an artifact-local PowerShell helper created with `apply_patch` and simple literal invocation arguments. Production `scripts`, runtime source and the installed app remain unchanged.
