# C23G PowerShell HOME collision rejection

The first aggregate and placement pre-cycle checks assigned Mool Home source
text to `$home`. PowerShell treated it as the read-only `$HOME` automatic
variable and rejected both scripts. No host cycle passed and no build/install
authority opened. REG-20260809-572 requires `$moolHomeSource` or another
ticket-specific variable.
