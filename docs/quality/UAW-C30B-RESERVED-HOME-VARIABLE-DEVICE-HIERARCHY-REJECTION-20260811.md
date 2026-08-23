# C30B reserved HOME variable device-hierarchy rejection

After the OPPO composer was correctly closed, a read-only UI hierarchy parser attempted to assign a node to PowerShell's reserved `$HOME` variable. PowerShell rejected the assignment. The inspection result is discarded; no install, app-data, backend, provider, Firebase or deployment mutation occurred.

Regression `REG-20260811-1355-C30B-RESERVED-HOME-VARIABLE-DEVICE-HIERARCHY-REJECTION` permanently requires task-specific shell variable names such as `$socialHomeNode` and forbids `$HOME`, `$home` and `$CODEX_HOME` reuse.
