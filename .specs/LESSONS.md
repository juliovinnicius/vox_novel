# Project Lessons

> Fallback ledger: `scripts/lessons.py` and `.specs/lessons.json` are not present
> in this repository. Entries remain candidates until corroborated by a second
> distinct feature.

## Candidates

### L-001 — Bootstrap ordering must be behavior-tested

- **Status**: candidate
- **Signal**: ac_gap
- **Feature**: foundation
- **Source**: `.specs/features/foundation/validation.md` — FND-01 startup-order gap
- **Scope**: application bootstrap
- **Lesson**: Assert asynchronous bootstrap ordering through the entry-point boundary, not by directly pumping the already-composed root widget.

### L-002 — Architectural exclusions need executable checks

- **Status**: candidate
- **Signal**: ac_gap
- **Feature**: foundation
- **Source**: `.specs/features/foundation/validation.md` — FND-02 no-event-BLoC gap
- **Scope**: architecture constraints
- **Lesson**: Enforce forbidden dependency patterns with an executable architecture check rather than repository inspection alone.

### L-003 — CI workflow behavior needs contract assertions

- **Status**: candidate
- **Signal**: ac_gap
- **Feature**: foundation
- **Source**: `.specs/features/foundation/validation.md` — FND-05 workflow gaps
- **Scope**: continuous integration
- **Lesson**: Parse CI workflows in tests and assert triggers, exact commands, ordering, and failure propagation.
