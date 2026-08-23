# UAW C10E dynamic app-section builder page type

- Registry: `REG-20260807-220-C10E-DYNAMIC-APP-SECTION-RETAINED-WIDGET-BUILDER-AFTER-PAGE-RETURNS`
- State: resolved; the complete mobile analyzer passes with no issues
- Detection: Flutter analysis reported four `return_of_invalid_type_from_closure` errors at the `/app/:section` branches.
- Root cause: branch returns were wrapped in `CustomTransitionPage<void>` but the encompassing dynamic route declaration retained `builder` instead of `pageBuilder`.
- Durable prevention: every route migrated to `moolMainDestinationPage` is statically required to declare `pageBuilder`; analyze the complete mobile package immediately after route-owner edits.
