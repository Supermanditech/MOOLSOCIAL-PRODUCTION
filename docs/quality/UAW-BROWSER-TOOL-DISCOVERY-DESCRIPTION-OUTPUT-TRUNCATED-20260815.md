# Browser tool discovery description output truncation regression

- Regression: `REG-20260815-2472-BROWSER-TOOL-DISCOVERY-DESCRIPTION-OUTPUT-TRUNCATED`
- Failure: discovery emitted complete descriptions for every browser-related tool and exceeded the output budget.
- Impact: the result was not used as complete tool-schema evidence; no browser, repository, external service or device state changed.
- Prevention: project discovery results to exact tool names only, then inspect one selected tool schema if necessary.
