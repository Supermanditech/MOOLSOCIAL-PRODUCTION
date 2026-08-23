# UAW C30W overnight report regression-total sentence-shape mismatch

Date: 2026-08-14
Ticket: `UAW-C30W-R60-47-PLAY-COLD-START-MISSING-SERVER-CLIENT-ID`
Registry ID: `REG-20260814-2108-C30W-OVERNIGHT-REPORT-REGRESSION-TOTAL-SENTENCE-SHAPE-MISMATCH`

## Rejected attempt

A final documentation-only patch tried to replace a remembered sentence for the regression-memory totals in the overnight handoff report. The report used the phrase `Regression-memory gate passes`, while the patch expected a different sentence shape. `apply_patch` rejected the unmatched context and made no change.

## Root cause

The totals were known, but the exact target line was not enumerated immediately before the precision patch.

## Required prevention

Enumerate the exact bounded line with `rg`, copy it literally into the patch context, and treat an `apply_patch` verification failure as zero mutation. Register the mismatch before retrying.

## Resolution

The exact line was enumerated. The retry updates only the two documented registry totals. This file and the report are outside the sealed C30W source manifest; no source-manifest member, release state, build, device, provider, credential, or external communication was touched.
