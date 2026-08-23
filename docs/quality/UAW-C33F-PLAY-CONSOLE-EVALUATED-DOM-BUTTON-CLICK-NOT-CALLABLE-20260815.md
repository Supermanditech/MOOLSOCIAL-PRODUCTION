# UAW C33F Play Console evaluated-button click correction

Date: 2026-08-15

The structural DOM evaluation found the exact `Show details` control, but its
evaluated proxy did not expose a callable `click` method. The failed attempt
made no external change and accessed no certificate value. The correction is
to interact through the browser-client role locator using the exact accessible
name and row position.
