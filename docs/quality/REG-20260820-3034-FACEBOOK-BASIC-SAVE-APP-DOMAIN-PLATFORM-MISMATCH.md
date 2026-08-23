# REG-20260820-3034 Facebook Basic save app-domain platform mismatch

## Incident

The founder attempted to save the dedicated Facebook app's privacy, terms and
signed data-deletion callback settings together with `moolsocial.com` under App
domains. Meta rejected the save because that domain did not match a configured
Website, Mobile Site, Web Games, Unity or Page Tab platform URL.

## Impact

- The Basic settings change was not saved.
- Facebook remains native-only with Web OAuth disabled.
- No provider callback, secret, website platform, build, Play or OPPO state
  changed.

## Root cause

An optional web-domain field was populated for a native Android-only app even
though no matching web platform was intentionally configured.

## Prevention

Do not add a Website platform merely to satisfy an optional field. Remove the
App domains entry, retain native-only OAuth settings, revalidate the complete
HTTPS data-deletion callback prefix and suffix, then save privacy, terms and
deletion settings without expanding platform scope.
