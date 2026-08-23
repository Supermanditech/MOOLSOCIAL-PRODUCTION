# UAW C30V browser upload-call object syntax rejection — 2026-08-14

The first in-app-browser file-selection call was rejected by the outer JavaScript parser because the nested `timeout_ms` property was written with template-literal delimiters. The browser action never ran, no file was selected, and Google Play remained unchanged.

The sealed r60.47 artifact and consumed one-build authority are unchanged. Before retry, use a minimal syntactically valid nested tool argument object, keep the exact `.aab` input and sealed artifact path, and confirm that Play still has no r60.47 candidate attached.
