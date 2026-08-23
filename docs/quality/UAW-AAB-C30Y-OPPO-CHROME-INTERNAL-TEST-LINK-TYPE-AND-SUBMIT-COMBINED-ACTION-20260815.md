# C30Y OPPO Chrome Internal Testing link combined type-and-submit action

Date: 2026-08-15
Regression: `REG-20260815-2213-AAB-C30Y-OPPO-CHROME-INTERNAL-TEST-LINK-TYPE-AND-SUBMIT-COMBINED-ACTION`
Status: resolved by founder-completed Play update and exact installed-identity reconciliation

## Finding

The first OPPO Chrome navigation attempt typed the exact private Internal
Testing URL and pressed Return in the same Windows-control action without a
fresh state observation between text entry and submission. Chrome exposed a
paste notification, but the resulting screen did not prove navigation to the
tester page. No opt-in, update, installation or MoolSocial device mutation
occurred.

## Prevention

Device-browser navigation uses one observed action per state transition:

1. focus and observe the address field;
2. type the exact URL and refresh;
3. verify the URL text is present and the address field remains focused;
4. submit once and refresh;
5. verify the tester-page identity before any Play action.

An ambiguous combined type-and-submit outcome is never repeated as a combined
action and is zero navigation evidence.

## Resolution

The founder independently completed the Play Store update. A later read-only
package-manager check proved `1.0.0-r60.48` / `2026081348` with installer
`com.android.vending` and a preserved earlier first-install timestamp. This
resolves the navigation incident without treating the failed combined action
as evidence and without any agent reinstall, data clear, downgrade or ADB
install.
