# C30T registrant consolidation patch-context mismatch

Date: 2026-08-13

The first multi-file registrant-resolution consolidation patch used paraphrased rather than exact registry text and was rejected atomically by `apply_patch`. None of the intended registry, ticket, checkpoint or findings status edits from that patch applied.

The corrected update must first read the exact REG-1831 slice and then patch that literal context. Runtime, release and device state were unaffected.
