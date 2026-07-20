# Customer-copy machine gate

Status: **mandatory for every customer-facing screen**

Owner confirmation: 20 July 2026

## Purpose

No MoolSocial customer may see a design note, implementation explanation,
example fixture or relationship between internal screens. This gate converts
the product-language rule into an executable, state-complete release boundary.

## Machine rule

For every touched customer checkpoint:

1. enumerate every reachable visible state before writing the test;
2. mount or navigate to each state;
3. collect rendered `Text`, `RichText`, editable-field labels/hints and
   semantic labels inside the customer screen;
4. reject centralized prohibited-language patterns;
5. assert no Flutter exception or overflow;
6. assert every primary and recovery action is visible or scroll-reachable;
7. retain the missed state and phrase as a permanent regression case whenever
   the founder finds a violation.

A default-state-only test, source-only search, screenshot-only check or golden
comparison does not satisfy this gate.

## Central prohibited-language patterns

The executable test must reject customer wording that includes:

- production, prototype, founder review, review build;
- sample, example, demo, mock, placeholder, test or testing;
- working note, internal plan, implementation, workflow, state machine;
- route, endpoint, payload, API, backend, provider callback;
- next screen, next owner, screen 01, screen 02, screen 03, screen 04;
- same screen, same verify screen, instead of email, instead of mobile;
- this screen is used for, for review, for testing.

The checker applies case-insensitively to normalized rendered copy. Technical
language outside a simulated phone viewport in a screenbook engineering
contract is allowed; it is never copied into native customer UI.

## Screen 01–03 required state inventory

| Checkpoint | Required rendered states |
| --- | --- |
| Screen 01 | normal open, slow open, connection failure/retry, reduced motion |
| Screen 02 | consent, resolving, resolved current area, Location Services off, app permission off, unavailable/retry, continue for now |
| Screen 03 login | method selection, each enabled social pending/cancel/failure return, email destination invalid/valid, mobile destination invalid/valid |
| Screen 03 OTP | email OTP, mobile OTP, wrong code, resend countdown, resend ready/new code, verifying, change method |

## Supported-phone fitment matrix

Screens 01–03 must render in portrait at:

| Logical viewport | Representative boundary |
| --- | --- |
| 320 x 568 | smallest supported compact iOS boundary |
| 360 x 640 | compact Android boundary |
| 360 x 720 | approved HTML comparison viewport |
| 375 x 667 | compact current iPhone boundary |
| 390 x 844 | common current iPhone boundary |
| 412 x 915 | common large Android boundary |
| 430 x 932 | large iPhone boundary |

Each checkpoint also runs at 140% text scaling on the compact Android/iOS
boundaries. Scroll is allowed when required for accessibility, but clipped,
overlapping or unreachable primary actions are not.

This matrix verifies Flutter logical layout on both platform size classes.
Final staging still requires native Android and iOS artifacts and physical or
hosted-device replay; Windows cannot substitute for iOS signing/runtime tests.

