# LESSONS — auto-maintained by scripts/lessons.py

> Machine-owned. Do NOT hand-edit. Changes are overwritten on the next `lessons.py` write.
> Canonical state lives in `.specs/lessons.json`. Edit lessons only via the script.
> promote_threshold=2 distinct features · window_days=45 · quarantine_threshold=2

## Confirmed (load these at Specify/Design)

Corroborated across multiple features. Safe to apply as guidance.

_none_

## Candidates (under observation — do NOT load as guidance yet)

Seen once or not yet corroborated. Tracked, not trusted.

### L-001 — Treat permanent cleanup of application-owned files as part of deletion success and restore durable state when it fails
- signal: `ac_gap` · recurrence: 1 feature(s) · scope: `library deletion` · harmful: 0
- features: library_import
- evidence: LIB-05 AC3/AC4/AC5; validation.md Fix 1 (library deletion)
- last seen: 2026-07-17T20:01:11Z

### L-002 — Assert the execution boundary for work required off the UI isolate, not only asynchronous responsiveness
- signal: `ac_gap` · recurrence: 1 feature(s) · scope: `filesystem concurrency` · harmful: 0
- features: library_import
- evidence: LIB-01 AC4; validation.md Fix 2 (filesystem concurrency)
- last seen: 2026-07-17T20:01:11Z

### L-003 — Test restart and latency requirements as joined observable outcomes over persistent storage
- signal: `ac_gap` · recurrence: 1 feature(s) · scope: `library lifecycle` · harmful: 0
- features: library_import
- evidence: LIB-03 AC5/AC6; validation.md Fix 3 (library lifecycle)
- last seen: 2026-07-17T20:01:11Z

### L-004 — Assert dialog input payloads and cancellation side effects, not only labels and confirmation paths
- signal: `ac_gap` · recurrence: 1 feature(s) · scope: `presentation dialogs` · harmful: 0
- features: library_import
- evidence: LIB-04 AC1/AC5 and LIB-05 AC2; validation.md Fix 3 (presentation dialogs)
- last seen: 2026-07-17T20:01:11Z

### L-005 — Inject each specified filesystem failure shape and assert its exact storage, repository, and stream payloads
- signal: `ac_gap` · recurrence: 1 feature(s) · scope: `filesystem testing` · harmful: 0
- features: library_import
- evidence: Edge Cases; validation.md Fix 4 (filesystem testing)
- last seen: 2026-07-17T20:01:11Z

### L-006 — Exercise UI responsiveness with CPU-bound work, not only suspended asynchronous futures
- signal: `ac_gap` · recurrence: 1 feature(s) · scope: `processing-ui` · harmful: 0
- features: text_processing
- evidence: validation.md E4 (processing-ui)
- last seen: 2026-07-18T17:38:59Z

### L-007 — Exercise every composed terminal path with exact status, message, and orphan-state assertions
- signal: `ac_gap` · recurrence: 1 feature(s) · scope: `composition` · harmful: 0
- features: text_processing
- evidence: validation.md Pass B terminal-path integration coverage (composition)
- last seen: 2026-07-18T17:42:23Z

### L-008 — Verify dependency reset with an active worker and assert cancellation, disposal, and staged-state cleanup
- signal: `ac_gap` · recurrence: 1 feature(s) · scope: `composition` · harmful: 0
- features: text_processing
- evidence: validation.md Pass B reset lifecycle coverage (composition)
- last seen: 2026-07-18T17:42:23Z

### L-009 — Assert production dependency defaults through observable behavior, not only explicitly injected test seams
- signal: `surviving_mutant` · recurrence: 1 feature(s) · scope: `composition` · harmful: 0
- features: text_processing_reverification
- evidence: validation.md mutation: DI default isolate to inline (composition)
- last seen: 2026-07-18T20:01:00Z

### L-010 — Assert caller-remapped IDs and foreign-key conjunctions at worker boundaries
- signal: `surviving_mutant` · recurrence: 1 feature(s) · scope: `processing-payload` · harmful: 0
- features: text_processing_id_followup
- evidence: validation.md mutation: temporary worker block ID persisted (processing-payload)
- last seen: 2026-07-18T20:16:15Z

## Quarantined (failed when applied — ignore)

A confirmed lesson that recurred alongside failure. Kept for the maintainer to review.

_none_
