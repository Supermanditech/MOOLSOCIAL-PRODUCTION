# C32M delivery-lock unsupported CandidateId parameter

Date: 15 August 2026
Regression: `REG-20260815-2257-C32M-DELIVERY-LOCK-UNSUPPORTED-CANDIDATEID-PARAMETER`

## Failure

The first post-transition validation group invoked `scripts/check-mvp-delivery-discipline-lock.ps1` with `-CandidateId`. The script does not declare that parameter, so PowerShell rejected the invocation and the grouped results were not accepted.

## Root cause and prevention

The parameter was inferred from the adjacent MVP scope gate. Before retry, the delivery-lock parameter block was read directly. The retry must use its supported `-RequireTicketSelectionAssessment` switch and default state paths. This failure changed no product source, device state, release state or external service.
