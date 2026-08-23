# C26H OPPO top-resumed activity foreground-gate rejection

- Observed: the first stable-capture invocation rejected MoolSocial as not foreground, while OPPO `dumpsys activity activities` proved `topResumedActivity`, `state=RESUMED` and `ResumedActivity` for `com.moolsocial.app/.MainActivity`; WindowManager also proved matching current focus and focused app.
- Root cause: the new capture owner recognized only the `mResumedActivity` key used by some Android builds. This OPPO firmware exposes the authoritative state as `topResumedActivity`/`ResumedActivity`.
- Classification: evidence gate compatibility defect; no screenshot or matrix XML was created or overwritten.
- Permanent prevention: foreground qualification accepts only an exact production MainActivity match under `mResumedActivity`, `topResumedActivity` or `ResumedActivity`, and repeats that same bounded check after capture. It does not weaken package/activity identity.
