# C30T machine-state schema property assumption

Date: 2026-08-13

The first pre-AAB authority summary selected obsolete or assumed top-level property names from the current C30T machine-state JSON and returned only null values. That output is rejected and proves nothing about build, upload, install or prebuild authority.

The corrected check must inspect the exact current top-level and nested property names before selecting counters and flags. No release authority is consumed or inferred by this diagnostic correction.
