# Browser locator unsupported ARIA snapshot helper regression

- Regression: `REG-20260815-2459-BROWSER-LOCATOR-UNSUPPORTED-ARIA-SNAPSHOT-HELPER`
- Failure: a read-only inspection called `ariaSnapshot` on the browser skill locator wrapper, which does not expose that helper.
- Impact: no Firebase state changed, no value was entered, and no configuration was saved.
- Prevention: inspect dynamic console state only through the supported tab `playwright.domSnapshot` method, then use fresh semantic locators for each individual action.
