# UAW C33F Play Console locator direct-scroll correction

Date: 2026-08-15

The browser-client locator did not expose Playwright's direct
`scrollIntoViewIfNeeded` convenience method. The failed navigation attempt made
no external change and accessed no signing value. The correction is to use the
supported locator evaluation surface to call the DOM element's native
`scrollIntoView` method and continue without reading certificate content.
