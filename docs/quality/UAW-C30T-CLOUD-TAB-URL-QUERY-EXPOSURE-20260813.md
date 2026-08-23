# C30T Cloud tab URL query exposure

Date: 2026-08-13

The read-only in-app browser tab inventory was emitted verbatim and therefore printed a transient Cloud Console reauthentication query value in tool output. The value was not copied into repository evidence, reused, or persisted.

Permanent prevention: never emit full authenticated console URLs or query strings. Match tabs internally, report only redacted host/path values, and never inspect cookies, local storage or session stores.
