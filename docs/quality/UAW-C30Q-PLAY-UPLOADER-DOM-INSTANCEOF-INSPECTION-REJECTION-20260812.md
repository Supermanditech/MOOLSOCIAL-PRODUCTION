# C30Q Play uploader DOM instanceof inspection rejection

Date: 2026-08-12

## Mistake

A read-only Play Console uploader inspection used `instanceof HTMLElement` inside the browser evaluation sandbox. That sandbox did not expose `HTMLElement` as a constructor, so the inspection rejected before returning file-input metadata.

## Impact

- No file was selected or uploaded.
- No Play release, repository, artifact, device, credential, or secret state changed.
- The pre-upload gate and sealed AAB remained unchanged.

## Permanent prevention

Use supported locator methods and direct attribute reads for browser form inspection. Do not depend on page-realm DOM constructors inside the isolated evaluation sandbox.
