# Foundation Context

**Gathered:** 2026-07-17
**Spec:** `.specs/features/foundation/spec.md`
**Status:** Ready for design

---

## Feature Boundary

Establish only the reusable Flutter foundation from Milestone 0: application
composition, Cubit convention, routing, Drift boundary, dependency injection,
testing gates, linting, and Android CI. Product behavior begins in Milestone 1.

## Implementation Decisions

### State Management

- Use Cubit through `flutter_bloc`.
- Do not introduce event-based BLoC classes in the foundation.

### Dependency Injection

- The user delegated the choice.
- Use `get_it` through one explicit composition root.
- Provide deterministic reset behavior for tests.

### Navigation

- Use `go_router` from the foundation onward.
- The root route displays a minimal `Biblioteca` placeholder.
- Unknown routes display a visible error state.

### Continuous Integration

- Use GitHub Actions.
- Run Flutter analysis, the complete test suite, and an Android debug APK build.
- CI targets Android only during the MVP foundation.

### Agent's Discretion

- Exact file names inside the architecture described by `docs/spec.md`.
- Minimal visual treatment of the placeholder and navigation error screens.
- Dependency versions selected from compatible, current stable releases.

### Declined / Undiscussed Gray Areas → Assumptions

- Product database tables are deferred to their owning features.
- The foundation uses a single initial route because no product navigation flow exists yet.
- Product telemetry and structured logging are deferred until there are operational events to record.

## Specific References

No external product reference was requested. Follow the architecture and Android-first
constraints in `docs/spec.md`.

## Deferred Ideas

- Library UI and data model belong to Milestone 1.
- PDF processing, reader, narration, and background playback remain in their roadmap milestones.
