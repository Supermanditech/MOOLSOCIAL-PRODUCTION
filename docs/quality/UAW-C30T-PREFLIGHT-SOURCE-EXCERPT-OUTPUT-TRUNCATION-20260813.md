# C30T preflight source excerpt output truncation

- Date: 2026-08-13
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-LIVE-READ-RECOVERY-C30T`
- Regression: `REG-20260813-1875-C30T-PREFLIGHT-SOURCE-EXCERPT-OUTPUT-TRUNCATION`

## Observation

A requested excerpt of the YouTube private-Dev preflight unexpectedly returned an oversized, truncated tool result. A truncated result is not complete evidence and was not used to authorize or perform any external write.

## Root cause and prevention

The source-range formatting command was not sufficiently bounded for this large dirty workspace. Future inspection is restricted to exact matches or source windows of at most 20 lines. Any truncated output is rejected, and deploy-sensitive conclusions require structural assertions and a passing preflight.

## External effect

None. No Firebase, Google Cloud, Hosting, AAB, Play, device, IAM, Gmail or quota mutation occurred.
