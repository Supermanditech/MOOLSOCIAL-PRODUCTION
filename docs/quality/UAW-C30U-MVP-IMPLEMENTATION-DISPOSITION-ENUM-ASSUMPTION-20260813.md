# C30U implementation-disposition enum assumption

Date: 2026-08-13
Regression: `REG-20260813-2011-C30U-MVP-IMPLEMENTATION-DISPOSITION-ENUM-ASSUMPTION`

## Incident

The C30U selected-ticket assessment used `release_gate` as an implementation
disposition before reading the delivery lock's exact enum. The scope gate
failed closed. No build, deployment, upload, install, or device mutation began.

## Permanent prevention

Read the current machine gate's exact allowed values before writing any
scope-state enum. Use only that vocabulary.

This incident grants no additional authority.
