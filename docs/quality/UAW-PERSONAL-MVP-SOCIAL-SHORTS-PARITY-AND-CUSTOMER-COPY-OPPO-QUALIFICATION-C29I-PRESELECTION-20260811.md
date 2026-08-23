# C29I OPPO successor preselection

Date: 2026-08-11
Ticket: `UAW-PERSONAL-MVP-SOCIAL-SHORTS-PARITY-AND-CUSTOMER-COPY-OPPO-QUALIFICATION-C29I`
Classification: `mvp_supporting`

C29I is the non-retry successor to C29H. C29H consumed its wrapper invocation
without reading Firebase configuration or producing an APK because the newly
installed Google Cloud CLI was absent from the long-lived Codex PATH.

C29I adds no product UI or backend. It expands the stable build manifest to
include the wrapper, APK gate, same-shell CLI context gate and its self-test.
The exact installed x86 CLI path now passes the isolated no-token context for
`moolsocial-dev-fsc02d`, `hello@moolsocial.com` and
`moolsocial-dev-503018`.

The smallest complete scope is two fresh expanded-source cycles, a final clean
process/device/context audit, one r60.33 profile wrapper invocation, artifact
qualification, one in-place OPPO upgrade and real Social replay. C29H cannot be
retried. All no-cloud-write, no-secret-persistence, no-uninstall, no-data-clear,
no-downgrade, no-second-build/install and no-production-promotion locks remain.

Founder authority is the 2026-08-11 instruction to close the internal daemon,
continue production-grade implementation and test on OPPO before review.
