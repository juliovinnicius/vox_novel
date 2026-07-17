# Foundation Specification

## Problem Statement

The Flutter scaffold has no product architecture, state-management convention,
local persistence, dependency composition, navigation, or continuous integration.
The foundation must establish these cross-cutting capabilities before product
features are added, while preserving an Android-first path and future portability.

## Goals

- [ ] Establish a feature-first structure with separated presentation, domain, and data concerns.
- [ ] Provide a runnable application shell using Cubit and `go_router`.
- [ ] Configure Drift and dependency injection so later features can add persisted data safely.
- [ ] Make analysis, tests, and an Android build reproducible in GitHub Actions.

## Out of Scope

| Feature | Reason |
| ------- | ------ |
| PDF import and processing | Milestones 1 and 2 |
| Library data model and screens | Milestone 1 |
| Reader, narration, and playback | Milestones 3 through 5 |
| Production database tables | Defined by the feature that owns each model |
| iOS, desktop, and web CI builds | MVP is Android-first |

---

## Assumptions & Open Questions

| Assumption / decision | Chosen default | Rationale | Confirmed? |
| --------------------- | -------------- | --------- | ---------- |
| State management | Cubit from `flutter_bloc` | Explicit user choice and lower ceremony than event-based BLoC | yes |
| Dependency injection | `get_it` with one composition root | Small runtime footprint and no competing state-management model | agent discretion |
| Navigation | `go_router` configured in the foundation | Explicit user choice | yes |
| Continuous integration | GitHub Actions runs analysis, tests, and Android build | Explicit user choice | yes |
| Initial route | A minimal library placeholder shell | Provides a deterministic startup target without implementing Milestone 1 | agent discretion |
| Persistence schema | Create the Drift database boundary without product tables | Avoids assigning domain ownership prematurely | agent discretion |

**Open questions:** none — all resolved or logged above.

---

## User Stories

### P1: Run the application shell ⭐ MVP

**User Story**: As a developer, I want a deterministic application shell so that
product features can be added without restructuring the entry point.

**Why P1**: Every user-facing feature depends on application startup and routing.

**Acceptance Criteria**:

1. WHEN the application starts THEN it SHALL initialize dependencies before rendering the root widget.
2. WHEN the router resolves `/` THEN it SHALL render a library placeholder identified by the visible title `Biblioteca`.
3. WHEN an unknown route is requested THEN it SHALL render a visible navigation error state.

**Independent Test**: Pump the root application, verify `Biblioteca`, then navigate
to an unknown location and verify the error state.

### P1: Manage presentation state with Cubit ⭐ MVP

**User Story**: As a developer, I want Cubit established as the presentation-state
pattern so that later features follow one predictable convention.

**Why P1**: State consistency is a cross-cutting architectural dependency.

**Acceptance Criteria**:

1. WHEN a feature needs mutable presentation state THEN it SHALL expose that state through a Cubit.
2. WHEN the initial shell is rendered THEN it SHALL not depend on event-based BLoC classes.

**Independent Test**: Inspect the shell composition and exercise the foundation Cubit state transition.

### P1: Compose dependencies centrally ⭐ MVP

**User Story**: As a developer, I want dependencies registered in one composition
root so that implementations remain replaceable in tests.

**Why P1**: Later storage, processing, and playback adapters require stable boundaries.

**Acceptance Criteria**:

1. WHEN application startup runs THEN it SHALL register each foundation dependency exactly once.
2. WHEN tests initialize the composition root repeatedly THEN it SHALL reset or reuse registrations without duplicate-registration failure.

**Independent Test**: Initialize, resolve the database boundary, reset, and initialize again.

### P1: Provide a local persistence boundary ⭐ MVP

**User Story**: As a developer, I want a Drift database boundary so that later
features can own durable tables and transactional repositories.

**Why P1**: Local persistence is required throughout the offline MVP.

**Acceptance Criteria**:

1. WHEN the application requests local persistence THEN it SHALL receive a single Drift database abstraction from dependency injection.
2. WHEN a test uses persistence THEN it SHALL be able to substitute an in-memory database.
3. WHEN the database is closed THEN it SHALL release its executor without leaving pending operations.

**Independent Test**: Resolve an in-memory database, execute a trivial Drift statement, and close it successfully.

### P1: Enforce automated quality gates ⭐ MVP

**User Story**: As a maintainer, I want continuous integration so that regressions
are detected before changes merge.

**Why P1**: Every subsequent milestone depends on a trustworthy automated gate.

**Acceptance Criteria**:

1. WHEN a commit or pull request reaches GitHub THEN CI SHALL run Flutter static analysis.
2. WHEN CI runs THEN it SHALL execute the complete Flutter test suite.
3. WHEN analysis and tests pass THEN CI SHALL build a debug Android APK.
4. WHEN any required command fails THEN the workflow SHALL fail and prevent subsequent success.

**Independent Test**: Validate the workflow syntax and run the same commands locally.

## Edge Cases

- WHEN dependency initialization is invoked twice in a test process THEN it SHALL not throw a duplicate-registration error.
- WHEN the route location is unknown THEN the shell SHALL show an error state instead of a blank screen.
- WHEN persistence uses an in-memory executor THEN no device filesystem SHALL be required.
- WHEN CI runs from a clean checkout THEN dependency resolution SHALL occur before analysis, tests, or build.

## Implicit-Requirement Dimensions

| Dimension | Resolution |
| --------- | ---------- |
| Input validation & bounds | Route validation is limited to the unknown-route error state; no product inputs exist in this milestone. |
| Failure / partial-failure states | Startup dependency failures propagate to a deterministic failed startup/test; CI stops on the failing command. |
| Idempotency / retry / duplicate handling | Dependency initialization must tolerate repeated test initialization without duplicate registrations. |
| Auth boundaries & rate limits | N/A because the MVP foundation has no backend, accounts, or remote API. |
| Concurrency / ordering | Dependency initialization completes before `runApp`; CI gates run in analysis → test → build order. |
| Data lifecycle / expiry | The database exposes explicit close/reset behavior; product retention belongs to owning features. |
| Observability | CI command failures are visible in job logs; product logging is deferred until a feature emits operational events. |
| External-dependency failure | Package resolution and Android toolchain failures fail CI; no runtime network dependency exists. |
| State-transition integrity | Foundation Cubit transitions are typed and tested; product state machines are out of scope. |

## Requirement Traceability

| Requirement ID | Story | Phase | Status |
| -------------- | ----- | ----- | ------ |
| FND-01 | Run the application shell | Design | Pending |
| FND-02 | Manage presentation state with Cubit | Design | Pending |
| FND-03 | Compose dependencies centrally | Design | Pending |
| FND-04 | Provide a local persistence boundary | Design | Pending |
| FND-05 | Enforce automated quality gates | Design | Pending |

**Coverage:** 5 total, 0 mapped to tasks, 5 pending task mapping.

## Success Criteria

- [ ] A clean checkout passes analysis and all tests.
- [ ] A clean checkout builds a debug Android APK.
- [ ] The application starts at a tested `Biblioteca` route.
- [ ] Foundation dependencies can be initialized, resolved, reset, and initialized again in tests.
- [ ] An in-memory Drift database can execute and close without filesystem access.
