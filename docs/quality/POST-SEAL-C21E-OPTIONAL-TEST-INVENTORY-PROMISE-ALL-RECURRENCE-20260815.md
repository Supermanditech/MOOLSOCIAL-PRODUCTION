# Post-seal C21E optional test inventory Promise.all recurrence

The first C21E authority lookup again combined three required file reads with
an optional test-filename ripgrep search in `Promise.all`. The optional search
returned exit 1 and suppressed all successful sibling output.

No state changed and none of the suppressed output is evidence. REG-2298 must
be registered before retry. Required C21E/C22G documents will be read
independently, and the optional test inventory will normalize no-match before
aggregation.
