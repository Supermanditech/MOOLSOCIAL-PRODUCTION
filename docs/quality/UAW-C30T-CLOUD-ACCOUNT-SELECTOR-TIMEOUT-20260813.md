# C30T Cloud account selector timeout

Date: 2026-08-13

The claimed in-app Cloud Credentials tab showed the expected `MoolSocial Dev Trial` project label, but an exact account-button selector timed out. No broad authenticated DOM capture was attempted because it could expose transient query data.

Permanent prevention: do not use broad DOM fallbacks after an authenticated-header selector fails. Defer the provider revision read to founder-visible Cloud CLI reauthentication and never emit authenticated console query strings.
