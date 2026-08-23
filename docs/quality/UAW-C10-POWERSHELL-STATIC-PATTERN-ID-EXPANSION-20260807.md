# UAW C10 PowerShell static pattern ID expansion

## Incident

The first C10B gate edit used a double-quoted source pattern containing `$id`.
PowerShell would expand that variable instead of interpreting the intended Dart
token literally. The defect was found during read-back before the gate ran.

## Prevention

Cross-language interpolation-shaped patterns are not used for static source
ownership. The action-root visible-Back rejection now checks the unique retired
`Icons.arrow_back_ios_new_rounded` owner token inside the bounded chooser file.

No test, build or OPPO qualification used the invalid pattern.
