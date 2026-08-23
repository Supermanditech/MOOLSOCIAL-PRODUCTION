# UAW C30V browser locator unsupported setInputFiles method — 2026-08-14

The syntactically corrected browser call reached the selected `.aab` input locator, but the browser-client locator does not expose raw Playwright `setInputFiles`. The method error occurred before file selection, and r60.47 remained absent from the Play draft.

Recovery requires reading the exact browser-client upload contract and using only its supported file chooser/upload method with the sealed AAB path. Before retry, re-prove that the candidate version is still absent and keep the Internal Testing page as the only target.
