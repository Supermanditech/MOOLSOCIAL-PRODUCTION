# Temporary navigation prototype dynamic Home literal validator false failure

Date: 2026-08-09

The first validation retry for the temporary founder navigation HTML required literal source strings such as `Shop Home`. The prototype correctly renders those headings from the domain data and the `${domain.label} Home` template, so the static literal assertion rejected valid dynamic output.

Root cause: a source-text validator was used as though it were a rendered-DOM validator.

Correction: keep source validation to JavaScript syntax, required domain data and exact renderer/template ownership. Verify dynamically composed visible copy by executing the interaction in a browser or by testing the template and its complete domain input set together.

No production runtime, Flutter source, accepted screenbook or device state was changed by this false failure.
