# UAW C30T UIAutomator raw XML entity auth-grid false classification — 13 August 2026

The guest Feed harness searched raw UIAutomator serialization for whitespace between multiline auth labels. UIAutomator encoded the line break as an XML entity, so Save, Message and the quiz-choice result were falsely summarized as not opening auth. Parsed clickable nodes prove Google, YouTube, Apple, X, Instagram, Facebook, Email OTP and Mobile OTP are present in each applicable result. Future assertions parse XML and compare semantic values; the product taps are not repeated.
