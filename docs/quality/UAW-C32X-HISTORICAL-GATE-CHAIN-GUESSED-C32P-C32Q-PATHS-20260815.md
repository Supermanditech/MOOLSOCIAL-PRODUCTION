# C32X historical gate chain guessed C32P/C32Q paths

The first bounded C32P-C32X chain command stopped before executing any gate
because it used remembered C32P and C32Q script names that do not exist. The
command performed only literal existence checks, so it changed no source,
evidence, test, device or external state.

This recurs the historical-label/path mistake: ticket labels and document
titles are not executable filenames. The retry must use an `rg --files`
inventory, preserve only exact returned paths and fail closed if any required
ticket has zero or multiple candidate gates.

REG-2290 was registered before retry. The exact inventory then resolved one
gate each for C32P through C32X, and the complete nine-gate chain passed on
PowerShell 7 and Windows PowerShell.
