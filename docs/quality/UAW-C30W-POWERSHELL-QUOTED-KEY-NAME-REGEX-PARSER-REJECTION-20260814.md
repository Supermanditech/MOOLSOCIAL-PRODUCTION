# UAW C30W PowerShell quoted key-name regex parser rejection — 2026-08-14

A key-name-only inventory command failed before execution because its inline PowerShell regex attempted to match both surrounding quote forms with incorrect escaping. No file or credential value was read by the rejected command.

Recovery is to match only the safe token form `MOOLSOCIAL_[A-Z0-9_]+`, emit unique token names, and avoid printing any associated values.
