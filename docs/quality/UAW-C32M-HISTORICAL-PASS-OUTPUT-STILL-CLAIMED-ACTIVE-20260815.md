# C32M historical pass output still claimed active

Date: 15 August 2026
Regression: `REG-20260815-2263-C32M-HISTORICAL-PASS-OUTPUT-STILL-CLAIMED-ACTIVE`

C32M passed its exact preserved-prior assessment after C32N became active, but the static success string still said `active=C32M`. The logical assertions were green; the output identity was false.

The retry is blocked until the success string truthfully reports active-or-prior lifecycle binding and no longer claims that C32M is the current ticket.
