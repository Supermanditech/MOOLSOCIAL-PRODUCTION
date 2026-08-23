# C29O Social Chat test-key owner mismatch

Date: 2026-08-11

After the 140% overflow fix passed, the new C29O test searched for the generic
default key `mool-global-chat`. The Social dock deliberately injects the exact
key `social-global-chat`; the test failed before validating its semantics.

Permanent prevention: a navigation test reads the concrete call-site key
provided by the tested owner and does not assume a reusable widget's default
key is retained by every host.
