# C22G combined process-name probe partial not-found rejection

- Observed: 2026-08-08 during the bounded live diagnostic.
- Rejection: `Get-Process -Name dart,flutter -ErrorAction SilentlyContinue`
  printed the existing Dart process but returned failure because no process
  named Flutter existed.
- Root cause: multiple expected process names were queried in one cmdlet call,
  allowing one absent name to contaminate a valid result.
- Prevention: enumerate processes once and filter names, or probe each optional
  name independently while explicitly normalizing absence. A partial result
  cannot be used as a passing process gate.
