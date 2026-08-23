# C30O keystore search rg no-match exit handling rejection

Date: 2026-08-12

## Observed mistake

A bounded repository search for `*.jks` and `*.keystore` files returned no matches. Ripgrep correctly used exit code 1 for no matches, but the compound diagnostic did not normalize that expected state, so the tool call was reported as failed after retaining the preceding configuration output.

## Root cause

The diagnostic treated ripgrep's documented no-match result as an exceptional command failure.

## Prevention

- Do not repeat the unhandled search.
- Run the same bounded file-name search once with explicit exit-code handling: exit 1 means `NO_MATCHES`; any other nonzero exit remains a failure.
- Do not broaden the search outside the authorized workspace.

## Retained evidence

The tool result retained the absent secret-define environment status and no matching keystore path. No build or external write occurred; C30O build authorization remains unconsumed.
