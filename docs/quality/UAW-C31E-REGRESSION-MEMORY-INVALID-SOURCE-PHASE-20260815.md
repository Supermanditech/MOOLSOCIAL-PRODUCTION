# UAW C31E regression-memory invalid source phase

Date: 2026-08-15
Ticket: `UAW-C31E-PERSONAL-MVP-CHAT-PHOTO-ATTACHMENT-CONTINUITY`

## Rejected attempt

After the interrupted C31E continuation resumed, the regression-memory gate
was called with `-Phase source`. PowerShell parameter validation rejected that
argument because the script accepts only `general`, `implementation`, `build`
or `device`. The rejected invocation is zero qualification evidence.

## Root cause

The intended source-work meaning was converted into an assumed phase label
without first checking the script's actual parameter contract.

## Permanent prevention

C31E source and source-test work uses `-Phase implementation`. After a resume,
any parameterized repository gate is invoked only with an already proven exact
command or after its declared parameter set is verified. This incident was
registered before retry; it did not change product source, release state or the
connected OPPO.
