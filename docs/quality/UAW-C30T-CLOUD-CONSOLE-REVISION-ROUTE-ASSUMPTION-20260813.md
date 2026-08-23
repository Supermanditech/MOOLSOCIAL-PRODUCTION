# C30T Cloud Console revision route assumption

Date: 2026-08-13

The read-only browser fallback used an inferred `/run/revisions` route. Cloud Console rendered `URL not found`. The visible Chrome identity was `supermanditech@gmail.com`, and the project selector reported no project selected; the removed Dev IAM roles were not restored.

Permanent prevention: verify the visible account and project access first, then navigate using the visible Cloud Run Services surface rather than guessed console route variants. Never add IAM merely to bypass a read-only reconciliation blocker.
