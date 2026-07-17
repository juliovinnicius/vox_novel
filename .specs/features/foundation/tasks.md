# Foundation Tasks

## Execution Protocol (MANDATORY -- do not skip)

Implement these tasks with the `spec-driven-development` skill: **activate it by
name and follow its Execute flow and Critical Rules.** Do not proceed without the
per-task gate, atomic commit, adequacy review, and final independent Verifier.

**Design**: `.specs/features/foundation/design.md`
**Status**: In Progress

## Test Coverage Matrix

> Generated from codebase, project guidelines, and spec — confirm before Execute.
> Guidelines found: `analysis_options.yaml` (`flutter_lints`) and `docs/spec.md`
> section 24. The repository has one generated Flutter widget-test sample; strong
> defaults define the required depth.

| Code Layer | Required Test Type | Coverage Expectation | Location Pattern | Run Command |
| ---------- | ------------------ | -------------------- | ---------------- | ----------- |
| App state / Cubit | unit | Every transition and exact emitted state maps 1:1 to FND-02 | `test/app/**/*_test.dart` | `flutter test test/app` |
| Database infrastructure | unit | Constructor, executable in-memory query, and close lifecycle from FND-04 | `test/core/database/**/*_test.dart` | `flutter test test/core/database` |
| Dependency composition | unit | Registration, identity, repeat initialization, reset, and injected executor from FND-03 | `test/app/dependency_injection/**/*_test.dart` | `flutter test test/app/dependency_injection` |
| Router / widget presentation | widget | Root happy path, unknown-route error, visible exact labels, and app composition from FND-01 | `test/app/**/*_test.dart`, `test/features/**/*_test.dart` | `flutter test test/app test/features` |
| Entry point / package / CI configuration | none | Build gate proves compilation, analysis, tests, and Android build | — | build gate only |

## Gate Check Commands

> Generated from the Flutter manifest and analyzer configuration.

| Gate Level | When to Use | Command |
| ---------- | ----------- | ------- |
| Quick | After unit or widget-test tasks | `flutter test` |
| Full | After integration-level composition tasks | `flutter test` |
| Build | After phase completion or config-only tasks | `dart run build_runner build && flutter analyze && flutter test && flutter build apk --debug` |

## Execution Plan

### Phase 1: Tooling and Persistence

```text
T1 → T2
```

### Phase 2: State and Navigation

```text
T2 → T3 → T4 → T5
```

### Phase 3: Composition and Startup

```text
T5 → T6 → T7 → T8
```

### Phase 4: Continuous Integration

```text
T8 → T9
```

## Task Breakdown

### T1: Configure foundation packages ✅

**What**: Add the approved runtime, persistence, generation, and test dependencies.
**Where**: `pubspec.yaml`, `pubspec.lock`,
`linux/flutter/generated_plugins.cmake`,
`windows/flutter/generated_plugins.cmake`
**Depends on**: None
**Reuses**: Existing Flutter SDK and `flutter_lints` configuration.
**Requirement**: FND-01, FND-02, FND-03, FND-04

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`
- CLI: `flutter pub add`

**Done when**:

- [ ] `flutter_bloc`, `go_router`, `get_it`, `drift`, and `drift_flutter` are runtime dependencies.
- [ ] `drift_dev`, `build_runner`, and `bloc_test` are development dependencies.
- [ ] Dependency resolution completes without overrides.
- [ ] Build gate passes with the existing scaffold before product code changes.

**Tests**: none
**Gate**: build
**Commit**: `build(foundation): add application dependencies`

### T2: Create the Drift database boundary ✅

**What**: Add `AppDatabase` with production and injected-executor constructors.
**Where**: `lib/core/database/app_database.dart`, generated part,
`test/core/database/app_database_test.dart`, `analysis_options.yaml`
**Depends on**: T1
**Reuses**: Drift's documented custom-executor and `driftDatabase` patterns.
**Requirement**: FND-04

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`
- CLI: `dart run build_runner build`

**Done when**:

- [ ] Production construction uses `driftDatabase(name: 'vox_novel')`.
- [ ] An injected `NativeDatabase.memory()` executes `SELECT 1` and returns exactly `1`.
- [ ] `close()` completes and the executor rejects a subsequent query.
- [ ] Three spec-derived database tests pass.
- [ ] Build gate passes.

**Tests**: unit
**Gate**: build
**Expected tests**: 3
**Commit**: `feat(database): add Drift application database`

### T3: Establish the application Cubit ✅

**What**: Add typed application startup state and its single readiness transition.
**Where**: `lib/app/app_cubit.dart`, `lib/app/app_state.dart`, `test/app/app_cubit_test.dart`
**Depends on**: T2
**Reuses**: Cubit APIs from `flutter_bloc`.
**Requirement**: FND-02

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Initial state has exact status `AppStatus.initial`.
- [ ] `markReady()` emits exactly `AppStatus.ready`.
- [ ] Repeated `markReady()` calls do not emit duplicate ready states.
- [ ] Three spec-derived Cubit tests pass.
- [ ] Quick gate passes.

**Tests**: unit
**Gate**: quick
**Expected tests**: 3
**Commit**: `feat(app): add startup Cubit`

### T4: Create the library placeholder page ✅

**What**: Add the deterministic initial page without library product behavior.
**Where**: `lib/features/library/presentation/pages/library_placeholder_page.dart`, `test/features/library/presentation/pages/library_placeholder_page_test.dart`
**Depends on**: T3
**Reuses**: Flutter Material `Scaffold` and accessible `AppBar`.
**Requirement**: FND-01

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] The page renders the exact visible title `Biblioteca`.
- [ ] The title is exposed to Flutter semantics.
- [ ] Two spec-derived widget tests pass.
- [ ] Quick gate passes.

**Tests**: widget
**Gate**: quick
**Expected tests**: 2
**Commit**: `feat(library): add placeholder page`

### T5: Configure application routing ✅

**What**: Add the root route and visible unknown-route error handling.
**Where**: `lib/app/router/app_router.dart`, `test/app/router/app_router_test.dart`
**Depends on**: T4
**Reuses**: `LibraryPlaceholderPage` and `go_router`.
**Requirement**: FND-01

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Resolving `/` renders exactly one `Biblioteca` title.
- [ ] Resolving an unknown path renders `Erro de navegação`.
- [ ] The error state includes the attempted location.
- [ ] Three spec-derived router widget tests pass.
- [ ] Build gate passes.

**Tests**: widget
**Gate**: build
**Expected tests**: 3
**Commit**: `feat(router): add application routes`

### T6: Create the root application widget ✅

**What**: Add `VoxNovelApp` using the injected router and Cubit.
**Where**: `lib/app/app.dart`, `test/app/app_test.dart`
**Depends on**: T5
**Reuses**: `AppCubit`, `GoRouter`, `BlocProvider`, and Material 3.
**Requirement**: FND-01, FND-02

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] `MaterialApp.router` uses the provided router.
- [ ] The provided Cubit is available below the root widget.
- [ ] Rendering the app shows `Biblioteca`.
- [ ] `markReady()` changes the provided Cubit state to exactly `AppStatus.ready`.
- [ ] Three spec-derived widget tests pass.
- [ ] Quick gate passes.

**Tests**: widget
**Gate**: quick
**Expected tests**: 3
**Commit**: `feat(app): add root application widget`

### T7: Create the dependency composition root

**What**: Register and reset the database, router, and Cubit deterministically.
**Where**: `lib/app/dependency_injection/configure_dependencies.dart`, `test/app/dependency_injection/configure_dependencies_test.dart`
**Depends on**: T6
**Reuses**: `AppDatabase`, `AppCubit`, `createAppRouter`, and `GetIt`.
**Requirement**: FND-03, FND-04

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Setup registers one `AppDatabase`, one `AppCubit`, and one `GoRouter`.
- [ ] Repeated setup returns the same registered instances and does not throw.
- [ ] Reset disposes registered resources and clears the supplied locator.
- [ ] An injected in-memory executor is used by the resolved database.
- [ ] Four spec-derived composition tests pass.
- [ ] Full gate passes.

**Tests**: unit
**Gate**: full
**Expected tests**: 4
**Commit**: `feat(app): add dependency composition root`

### T8: Replace the generated startup entry point

**What**: Bootstrap bindings, dependencies, readiness state, and the root app.
**Where**: `lib/main.dart`, `test/widget_test.dart`
**Depends on**: T7
**Reuses**: Composition root and `VoxNovelApp`.
**Requirement**: FND-01, FND-03

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] `main` initializes Flutter bindings before asynchronous setup.
- [ ] Dependency setup completes before `runApp`.
- [ ] The generated counter UI and counter assertions are removed.
- [ ] The application smoke test renders exactly one `Biblioteca`.
- [ ] Build gate passes.

**Tests**: widget
**Gate**: build
**Expected tests**: 1 replacement smoke test; total suite must not decrease
**Commit**: `feat(app): bootstrap application foundation`

### T9: Add the Android continuous integration gate

**What**: Add the ordered GitHub Actions workflow required by FND-05.
**Where**: `.github/workflows/ci.yml`
**Depends on**: T8
**Reuses**: Local build gate commands and generated Android Gradle project.
**Requirement**: FND-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Pushes to `main` and pull requests trigger the workflow.
- [ ] Workflow restores dependencies before gates.
- [ ] Analysis runs before the complete test suite.
- [ ] Debug APK build runs only after analysis and tests succeed.
- [ ] Workflow YAML parses successfully.
- [ ] The identical local build gate passes.

**Tests**: none
**Gate**: build
**Commit**: `ci(android): add Flutter quality gate`

## Phase Execution Map

```text
Phase 1 → Phase 2 → Phase 3 → Phase 4

Phase 1: T1 ──→ T2
Phase 2: T2 ──→ T3 ──→ T4 ──→ T5
Phase 3: T5 ──→ T6 ──→ T7 ──→ T8
Phase 4: T8 ──→ T9
```

Execution is sequential. Phase boundaries are semantic; execution batches may
contain consecutive whole phases but never split a phase.

## Task Granularity Check

| Task | Scope | Status |
| ---- | ----- | ------ |
| T1 | One dependency-manifest change | ✅ Granular |
| T2 | One database boundary plus co-located tests/generated part | ✅ Granular |
| T3 | One Cubit/state component plus tests | ✅ Granular |
| T4 | One page component plus tests | ✅ Granular |
| T5 | One router component plus tests | ✅ Granular |
| T6 | One root widget plus tests | ✅ Granular |
| T7 | One composition-root function set plus tests | ✅ Granular |
| T8 | One startup entry point plus replacement smoke test | ✅ Granular |
| T9 | One CI workflow | ✅ Granular |

## Diagram-Definition Cross-Check

| Task | Depends On (task body) | Diagram Shows | Status |
| ---- | ---------------------- | ------------- | ------ |
| T1 | None | Initial node | ✅ Match |
| T2 | T1 | T1 → T2 | ✅ Match |
| T3 | T2 | T2 → T3 | ✅ Match |
| T4 | T3 | T3 → T4 | ✅ Match |
| T5 | T4 | T4 → T5 | ✅ Match |
| T6 | T5 | T5 → T6 | ✅ Match |
| T7 | T6 | T6 → T7 | ✅ Match |
| T8 | T7 | T7 → T8 | ✅ Match |
| T9 | T8 | T8 → T9 | ✅ Match |

## Test Co-location Validation

| Task | Code Layer Created/Modified | Matrix Requires | Task Says | Status |
| ---- | --------------------------- | --------------- | --------- | ------ |
| T1 | Package configuration | none | none | ✅ OK |
| T2 | Database infrastructure | unit | unit | ✅ OK |
| T3 | App state / Cubit | unit | unit | ✅ OK |
| T4 | Widget presentation | widget | widget | ✅ OK |
| T5 | Router / widget presentation | widget | widget | ✅ OK |
| T6 | Root widget presentation | widget | widget | ✅ OK |
| T7 | Dependency composition | unit | unit | ✅ OK |
| T8 | Entry point + smoke surface | widget | widget | ✅ OK |
| T9 | CI configuration | none | none | ✅ OK |

## Requirement-to-Task Traceability

| Requirement | Tasks | Coverage |
| ----------- | ----- | -------- |
| FND-01 | T1, T4, T5, T6, T8 | ✅ Mapped |
| FND-02 | T1, T3, T6 | ✅ Mapped |
| FND-03 | T1, T7, T8 | ✅ Mapped |
| FND-04 | T1, T2, T7 | ✅ Mapped |
| FND-05 | T9 | ✅ Mapped |
