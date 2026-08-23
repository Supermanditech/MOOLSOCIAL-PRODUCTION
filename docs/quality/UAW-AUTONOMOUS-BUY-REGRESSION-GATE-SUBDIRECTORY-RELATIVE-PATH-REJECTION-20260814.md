# Autonomous Buy regression gate subdirectory-relative path rejection

Date: 2026-08-14
Registry ID: `REG-20260814-2113-AUTONOMOUS-BUY-REGRESSION-GATE-SUBDIRECTORY-RELATIVE-PATH-REJECTION`

The implementation regression-memory gate was invoked from `backend/functions` with a repository-root-relative `scripts/...` path. PowerShell could not resolve the script, so the gate did not run.

The failure was registered before retry. Repository gates must run from the repository root; package typechecks run separately from their package directory.
