# C29O wide Social consumer patch-anchor rejection

Date: 2026-08-11

A single product patch attempted many distant edits in
`social_v2_consumer.dart`. One expected copy anchor did not match the exact
current file, so `apply_patch` rejected the entire patch. No product source was
changed.

Permanent prevention: one patch edits one re-read local region or one repeated
mechanical symbol family. Distant UI, state, method and class removals are
separate patches, and each region is re-read immediately before mutation.
