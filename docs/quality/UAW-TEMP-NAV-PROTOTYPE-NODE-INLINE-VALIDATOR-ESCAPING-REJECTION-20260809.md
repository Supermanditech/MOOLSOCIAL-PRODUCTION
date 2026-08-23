# Temporary navigation prototype inline Node validator escaping rejection

Date: 2026-08-09

The first native syntax-validation retry embedded escaped double-quoted source-owner terms inside a PowerShell double-quoted `node -e` argument. PowerShell passed a stray backslash into the JavaScript array opener, so Node rejected the validator itself before reading the prototype script.

Root cause: unnecessary multi-layer quoting joined PowerShell interpolation and JavaScript literal escaping in one inline command.

Correction: keep the Node inline validator minimal and single-quoted internally, validating only extraction and JavaScript compilation. Perform source-owner assertions separately with PowerShell against the literal HTML.

No production runtime, Flutter source, accepted screenbook or device state changed.
