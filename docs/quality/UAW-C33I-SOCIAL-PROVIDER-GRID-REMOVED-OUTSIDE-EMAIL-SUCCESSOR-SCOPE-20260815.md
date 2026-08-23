# C33I social-provider grid removed outside email-successor scope

- Regression: `REG-20260815-2478-C33I-SOCIAL-PROVIDER-GRID-REMOVED-OUTSIDE-EMAIL-SUCCESSOR-SCOPE`
- Founder finding: the first v5 proposal removed the earlier Screen 03 social-media sign-in icon grid.
- Root cause: the proposal broadened a passwordless-email amendment into an unrelated method-selection redesign.
- Required correction: restore Google, YouTube, Apple, X, Instagram and Facebook in the earlier three-column Social account grid, preserve Mobile OTP, and change only Email OTP into `Email me a sign-in link` plus its necessary return/recovery states.
- Acceptance: the corrected local proposal must prove all six icons, their labels/order, Email link and Mobile OTP at every required viewport/text scale before it is presented again. Accepted references, Flutter, Firebase, Hosting and email sending remain untouched.
