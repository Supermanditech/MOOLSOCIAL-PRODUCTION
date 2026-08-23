# Browser locator evaluate is not a native DOM element callback

- Regression: `REG-20260815-2463-BROWSER-LOCATOR-EVALUATE-NOT-NATIVE-DOM-ELEMENT`
- Failure: `el.click()` inside locator evaluate was rejected because this constrained browser wrapper did not provide a native DOM element.
- Impact: no Firebase state changed; Phone remains Disabled with the approved fictional row staged in the open dialog.
- Prevention: prohibit locator-evaluate DOM-click fallbacks on this surface, inspect its supported methods before recovery, and require provider-table verification for success.
