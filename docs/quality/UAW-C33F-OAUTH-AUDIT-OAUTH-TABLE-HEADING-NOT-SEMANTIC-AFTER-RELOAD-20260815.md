# UAW-C33F OAuth audit OAuth table heading not semantic after reload

- Recorded at: `2026-08-15T11:04:07.4033763Z`
- Regression: `REG-20260815-2410-C33F-OAUTH-AUDIT-OAUTH-TABLE-HEADING-NOT-SEMANTIC-AFTER-RELOAD`

The final Web-client audit reload did not expose `OAuth 2.0 Client IDs` using the previously observed heading semantics. The bounded wait timed out before any detail link or field read. No OAuth client-ID or account value was accessed.

This browser path is stopped. The auto-created Web application display name/type observation is insufficient to bind the hidden mobile runtime value, so `web_server_client_mobile_relationship` remains pending for a separate hidden-value-safe qualification workflow.
