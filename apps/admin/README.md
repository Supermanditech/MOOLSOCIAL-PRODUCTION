# MoolSocial Superadmin

Separately deployed, role-gated Next.js Superadmin for screens 147–156 and
163–164. It covers 42 governed operating cases, shares contracts and generated
SQL Connect types with the product platform, and never shares a public
deployment or client-side admin privilege.

Offering provisioning covers the permanent personal profile and all 28
approved workspace profiles. Business-funded creator Reels use controlled
1–7-day durations, including explicit 24-hour and 48-hour choices.

## Local review

```powershell
npm install
$env:MOOLSOCIAL_ADMIN_REVIEW_MODE="true"
npm run dev
```

Open `http://127.0.0.1:3100/admin`.

Review mode uses deterministic, isolated evidence and one-shot failure
adapters. It cannot reach production data or execute a real platform command.
Production access remains denied until Firebase session verification and
server-side role claims are connected.

## Quality gates

```powershell
npm run typecheck
npm run lint
npm run build
npm run test:contracts
npm run test:e2e
```

With the review server running, the connected OPPO Chrome replay can be run
twice from clean page state:

```powershell
node scripts/oppo-admin-replay.mjs 1
node scripts/oppo-admin-replay.mjs 2
```

The Superadmin is a desktop-first responsive web application. It is not
embedded inside the public web site or the Android/iOS client.
