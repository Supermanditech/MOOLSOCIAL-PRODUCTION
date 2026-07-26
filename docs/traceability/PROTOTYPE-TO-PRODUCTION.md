# Prototype-to-production traceability

The production app does not recreate 167 independent HTML pages. It consolidates
the prototype evidence into stable routes and state machines.

| Prototype | Production owner | Current status |
| --- | --- | --- |
| Screen 00 Install App | Play Store listing and release pipeline | contract |
| Screen 01 Splash / First Open | `/boot` | **Production Accepted and locked:** immutable reference `v3`. One visible branded Flutter screen, minimum 3000 ms, same customer presentation during slow startup, plain navy Android system launch window. |
| Screen 02 Language / Location | `/setup` | **Production Accepted and locked:** immutable reference `v4`. Consent → Android permission/settings → resolved current area or explicit continue-for-now → Screen 03. Permanent serviceable area remains inside Universal after login. |
| Screen 03 Login / Handoff | `/sign-in`, `/verify` | **Production Accepted and locked:** immutable reference `v2`. Six provider handoffs plus email/mobile OTP. Exact APK passed both channels to Universal on OPPO; mobile passed after ADB reverse was deliberately removed. |
| Screen 04 Universal Focus Shell | `/app/social`, `/app/mool`, universal nav | **HTML v8 frozen; native v8 verified, awaiting founder:** immutable full-screen HTML `v8` at SHA-256 `0997F3AD…` freezes compact Videos search and progressive details, the approved rail, Shorts, thumb-zone Feed and direct Create contracts. The native v8 APK at SHA-256 `37F8E371…` passed 91 affected tests, two 448-test full regressions, Screen 01–03 locks and byte-identical installed-APK OPPO replay. It is not native Accepted until the founder reviews that installed candidate. Live YouTube integration remains Gate 3 Dev/Trial work. |

The exact source requirements remain in:

`C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook\screens\00-install-app.html`
through
`C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook\screens\04-universal-focus-shell.html`.

Any production change to this journey must update its journey contract and replay
tests in the same commit.

Screen 03 implementation ownership:

- Native presentation:
  `apps/mobile/lib/ui_v2/screens/screen03_login/`
- Existing non-UI state owner: `JourneySession`
- Mobile OTP owner: `OtpGateway` / `FirebaseOtpGateway`
- Social owner: `SocialAuthGateway` / `FirebaseSocialAuthGateway`
- Email OTP owner: `EmailOtpGateway` / `HttpEmailOtpGateway`
- Account merge owner: `AccountBootstrapGateway`
- Legacy `SignInScreen` and `VerifyOtpScreen`: read-only and no longer routed
- YouTube login: Google basic identity only; channel-management permission
  remains a separate creator-tool consent
- HTML/WebView: prohibited

First-open replay authority:
[`FIRST-OPEN-REAL-USER-STATE-MATRIX.md`](../quality/FIRST-OPEN-REAL-USER-STATE-MATRIX.md).

The accepted Screen 01–03 presentation files, contracts, reference images and
tests must not be changed while the next isolated UI set is developed. Live
authentication/provider configuration may advance only behind the locked
Screen 03 presentation and interaction contract. Combining the next accepted
set with this checkpoint requires a separate integration replay; it does not
authorize rewriting Screens 01–03.
