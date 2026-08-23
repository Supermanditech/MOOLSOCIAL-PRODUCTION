# C29O broad quality search timeout rejection

## Rejection

A command combined the exact C29O gate-owner read with a recursive search across
quality and configuration content. The command exceeded its bounded timeout, so
none of its output was admitted as evidence.

## Permanent prevention

Read required qualification owners one exact file at a time. Resolve a bounded
candidate filename set before any evidence-content search, and keep that search
separate from the required owner read.
