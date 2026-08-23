# C24I Home deep-link setup command rejection

Date: 2026-08-09

After the installed r60.23 accessibility tree proved `clickable=true` for the MoolSocial launcher and connected navigator, a compound ADB command attempted to seed the supported HTTPS `/app/mool` route for Home evidence. The host command policy rejected the command before execution.

No device, app, repository runtime, build or install state changed. C24I does not retry the deep-link form; Home must be reached through visible installed-app controls with verified Android tap actions.
