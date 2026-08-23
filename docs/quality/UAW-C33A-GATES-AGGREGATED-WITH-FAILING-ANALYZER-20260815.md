# C33A gates aggregated with failing analyzer

The first C33A validation call launched both PowerShell-host gates and the
Flutter analyzer in one aggregate operation. The analyzer failed, so the
wrapper returned only its diagnostics and suppressed any successful gate
outputs. Those host invocations are not qualification evidence.

REG-2302 must be registered before replay. Repository gates and Flutter
analysis/tests will run in separate fail-closed calls from their correct
working directories.
