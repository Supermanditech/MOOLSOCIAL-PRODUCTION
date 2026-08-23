# C30L deployment audit foreach-pipeline parser rejection

- Scope: local read-only deployment-preparation audit.
- Rejection: PowerShell rejected a direct `foreach (...) { ... } | ConvertTo-Json` construction before the audit ran.
- Root cause: the loop output was not grouped or assigned before piping.
- Prevention: collect bounded loop output in an array before serialization and separate unrelated audit questions.
- Runtime impact: none. No cloud write, deployment, build, install, or device mutation occurred.
