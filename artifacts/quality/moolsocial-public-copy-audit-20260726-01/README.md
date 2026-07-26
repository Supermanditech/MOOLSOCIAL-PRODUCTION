# MoolSocial public website copy audit — 26 July 2026

## Result

PASS. The MoolSocial public website was rewritten, deployed and verified as professional customer-facing content. Internal planning language, implementation commentary and explanatory motion language were removed.

Live website: <https://moolsocial.com/>

## Audited public surfaces

- Company home page, including navigation, hero, experience, company, vision, launch, opportunities, social profiles, contact and footer
- Page titles, descriptions, Open Graph and Twitter metadata
- Visible text, accessible labels, image descriptions, placeholders and link destinations
- Privacy Policy
- Terms of Service
- Support
- Connected-services management
- Account deletion

## Automated copy lock

`apps/web/tests/firebase-public-site.test.mjs` derives a normalized public-copy surface for every deployed HTML page and locks it with SHA-256. The surface includes visible text, metadata, accessibility attributes, placeholders and links.

| Page | Approved public-copy SHA-256 |
| --- | --- |
| Company | `682c245968880b4e34e84720a737791348a4da32e1e1e14d526e70d1dd92576b` |
| Privacy | `77c93fb8d887b233bc65fe8f7c3454322dbcb49b06c63ed17302f49fb9429af6` |
| Terms | `9840209eeadae43463724b0d4d027b0e28f1a3228357555ca8ac07e131d03685` |
| Support | `5d339025d99123cd8a42684b8484df804f49f72f9806b0b9cd32def8b62f7a8a` |
| Connected services | `006abf94d94c80d7baa5d43743ddfb740f8e3bf9e751332642e920f03d90e17e` |
| Account deletion | `dfded552130632b83675202c0d68a21aa5886b09a4b36bfe2306a78b664bc2b6` |

The gate also rejects replacement characters, public HTML comments and known internal or non-public wording.

## Verification

- Production build: PASS
- Automated tests: PASS, 6/6
- Lint: PASS, zero errors
- Rejected-copy scan: PASS
- Public routes and assets: PASS
- Source-to-live byte comparison: PASS, 19/19 files
- Desktop live rendering: PASS
- OPPO live rendering: PASS
- OPPO Launch navigation: PASS
- Horizontal overflow check: PASS
- Security headers: PASS
- HTML cache revalidation: PASS

## Firebase release

- Project: `moolsocial-dev-503018`
- Channel: `live`
- Release: `projects/moolsocial-dev-503018/sites/moolsocial-dev-503018/channels/live/releases/1785076354189000`
- Version: `projects/moolsocial-dev-503018/sites/moolsocial-dev-503018/versions/6d4d89b7febf43bf`
- Status: `FINALIZED`
- Release time: `2026-07-26T14:32:34.189Z`
- Release account: `hello@moolsocial.com`

## Deployed source hashes

| File | SHA-256 |
| --- | --- |
| `apps/web/public/index.html` | `4588b52869786bde0a4ccddf783057c32249237596677065dc535d27c5bd727d` |
| `apps/web/public/privacy/index.html` | `44cdbaa61dc5dee620ba997000aa73933f7b9717914fb6468110d8fed6865611` |
| `apps/web/public/terms/index.html` | `c54669807fae0df501e4827534890ffce20d664663f115f7ee9da7e8ab9b6d4f` |
| `apps/web/public/support/index.html` | `4115947627acb550ab2de19593a12e677cd9e29315d8629e159f09f0cac90329` |
| `apps/web/public/disconnect/index.html` | `6b2312ad5680b28f067755d809804de65b013397aa409da8cc39657a49db29a9` |
| `apps/web/public/delete-account/index.html` | `6ef6aa309b9cef7addd5919dcf361e528939c8d53a848b042c1bb46534c343e3` |
| `apps/web/public/site.css` | `db343e3945c034f8c11c5ee55466f799eb2f36c0b881e6d51117a5eacdc7ff33` |
| `apps/web/public/site.js` | `8b092a3b65a111abb87762a434cc9b0bcb61e4096c445d880595f0919cc1e7d4` |
| `firebase.json` | `6f87a11ea15e47f3a3e09e6a756b550787d3de3e445690caf550027a9f724e94` |

## Evidence

- `laptop-live-top.png` — public site at desktop width
- `oppo-live-top.png` and `oppo-live-top.xml` — public site first view on OPPO
- `oppo-live-launch.png` and `oppo-live-launch.xml` — Launch menu destination on OPPO

Policy wording was checked against the current official YouTube API Services policies, Google API Services User Data Policy and RBI card-data requirements. Legal-counsel review remains a separate production governance gate.
