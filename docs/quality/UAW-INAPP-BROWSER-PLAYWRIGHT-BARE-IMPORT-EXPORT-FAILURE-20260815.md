# In-app browser Playwright bare-import export failure regression

- Regression: `REG-20260815-2473-INAPP-BROWSER-PLAYWRIGHT-BARE-IMPORT-EXPORT-FAILURE`
- Failure: the bare Playwright import failed before a browser connection was created because its entrypoint requested an unavailable default export.
- Impact: no browser navigation or page interaction occurred and no repository, provider or device state changed.
- Prevention: do not repeat the blind import; use an exact exposed browser surface, or fall back to repository-contained static/render checks and open the verified page without claiming automated browser evidence.
