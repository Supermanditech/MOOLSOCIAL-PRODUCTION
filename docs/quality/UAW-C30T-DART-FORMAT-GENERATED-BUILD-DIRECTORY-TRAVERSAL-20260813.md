# UAW C30T Dart format generated-build traversal — 13 August 2026

The final no-change format audit invoked `dart format` on the entire
`apps/mobile` directory. Dart entered a stale generated
`build/firebase_remote_config` transform directory that disappeared while it
was being listed, so the invocation aborted before producing valid evidence.

The mistake was registered before retry. Format audits must target exact owned
Dart source and test roots, never an application root containing volatile
generated build output.
