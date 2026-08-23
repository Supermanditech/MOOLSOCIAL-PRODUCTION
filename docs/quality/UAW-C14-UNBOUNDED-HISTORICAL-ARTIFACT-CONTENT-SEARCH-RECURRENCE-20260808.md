# C14 unbounded historical artifact content search recurrence

Date: 2026-08-08

Regression:
`REG-20260808-282-C14-UNBOUNDED-HISTORICAL-ARTIFACT-CONTENT-SEARCH-RECURRENCE`

## Failure

A C14 lookup for the historical phrase `26-file` searched all retained
`artifacts/quality` Markdown, text and log content and timed out. It produced
no accepted inventory or evidence.

## Prevention

Historical evidence lookup begins with one exact known candidate directory or
a bounded filename inventory, never repository-wide artifact content. The C14
affected list is derived from the live exact test inventory and current source
owners; the timed-out output is discarded and not retried.
