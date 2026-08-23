# MoolSocial production-grade real-user exploratory release practice — 13 August 2026

## Permanent founder direction

Until MoolSocial is fully qualified and goes live—and for regressions after go-live—Codex must actively search for unexpected issues, not merely replay scripted happy paths. Every observed mistake, false result or escaped product defect is registered with retained evidence before continuing. Exact founder-authorized tickets are then implemented and verified; the practice itself never creates build, upload, install, Production, backend, communication or secret-access authority.

## Readiness vocabulary

- **Pre-AAB qualified** means source, backend, configuration, automated tests and build readiness passed. It does not mean real users or external providers passed on the installed candidate.
- **Internal candidate active** means the artifact is available only for controlled real-user acceptance.
- **Post-install identity qualified** means package, version, installer and Play signer are proved. Journeys remain separately gated.
- **Production-grade** requires every mandatory journey on the exact Play-installed candidate to pass truthfully with no unresolved MVP blocker.
- **Go-live ready** additionally requires every separately authorized store, policy, privacy, regulatory, operational and rollout gate.

## Mandatory depth

Testing must cover real backend/provider content and the exact Play identity; signed-out and signed-in states; every exposed provider or truthful disablement; Email OTP and Mobile OTP independently; cancel, error, retry, offline, relaunch, process death, Android Back, provider/system returns; accessibility bounds, system insets, customer copy and route continuity. Exploratory testing must deliberately look for contradictions, dead ends, wrong labels, stale state, false success and unexpected external-task exits.

## Claim rule

Automated tests are necessary and never sufficient. Never claim `complete`, `production-grade`, `reviewer-ready` or `go-live ready` while any required live journey is pending or failed, or any MVP-required blocker remains unresolved.

## C30T correction

C30T's two clean pre-AAB cycles were valid build-readiness evidence. Its state still marked post-install journeys pending. The OPPO run subsequently exposed Shorts top-inset collision, Play-signer authentication failure, provider-identity error, Email/Mobile OTP failures, YouTube account-handoff confusion, zero-bounds recovery semantics and auth cancellation exiting MoolSocial. Those escapes prove why the phase distinction and permanent exploratory rule are required.
