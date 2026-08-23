# UAW C33J FIX2 explicit default HTTPS port misclassified

- Regression: `REG-20260815-2514-C33J-FIX2-EXPLICIT-DEFAULT-HTTPS-PORT-MISCLASSIFIED`
- Failure: the first focused run passed both manifest tests but expected
  `https://moolsocial.com:443/...` to fail even though Dart normalizes the
  default HTTPS port as the same origin.
- Prevention: use a non-default port to test the origin-changing rejection.
- Impact: no product, external, build or device state changed.
