# UAW C30T post-player Back route assumption — 13 August 2026

## Observation

The official YouTube embedded player opened and played real provider content. After one Android Back action exited playback, MainActivity remained foreground. The next exact semantic-tap attempt assumed the Social Shorts rail was present, but the helper's newly captured pre-tap hierarchy found zero `Open Shorts, YouTube` nodes and stopped before injecting input.

## Root cause

Foreground activity identity was incorrectly treated as proof of a particular nested Flutter route after a provider WebView/fullscreen transition.

## Permanent prevention

- After any provider WebView, fullscreen player, system picker, dialog or system-Back transition, capture a fresh UI hierarchy before selecting the next semantic.
- Activity identity alone never proves the nested route.
- Never retry a zero-match semantic tap using stale hierarchy evidence.

## Safety result

The semantic helper performed no tap, no write and no external mutation. The exact zero-match pre-tap hierarchy is retained in the sealed C30T artifact-evidence directory.
