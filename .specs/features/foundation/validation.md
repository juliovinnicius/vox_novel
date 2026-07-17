# Foundation Validation

**Date**: 2026-07-17
**Spec**: `.specs/features/foundation/spec.md`
**Diff range**: `4837fc2..bb1e678` (product focus `0f59636..bb1e678`)
**Verifier**: independent sub-agent (author ≠ verifier)

---

## Task Completion

| Task | Status | Notes |
| ---- | ------ | ----- |
| T1 | ✅ Done | Required runtime and development dependencies are present; the final build gate resolves them without overrides. |
| T2 | ✅ Done | Drift boundary, generated code, and three database tests are present. |
| T3 | ✅ Done | Typed Cubit state and three transition tests are present. |
| T4 | ✅ Done | Placeholder page and two widget tests are present. |
| T5 | ✅ Done | Root/error routing and three router tests are present. |
| T6 | ✅ Done | Root app composition and three widget tests are present. |
| T7 | ✅ Done | Composition root and four dependency tests are present. |
| T8 | ✅ Done | Thin asynchronous startup and replacement smoke test are present. |
| T9 | ✅ Done | Ordered Android GitHub Actions workflow is present. |

All nine tasks are marked complete in `tasks.md`; no blocked or partial task is recorded. The implementation commits are atomic by task, with documentation-only progress commits between the two execution batches.

---

## Spec-Anchored Acceptance Criteria

### FND-01 — Run the application shell

| Criterion | Spec-defined outcome | `file:line` + assertion expression | Result |
| --------- | -------------------- | ---------------------------------- | ------ |
| WHEN the application starts THEN dependencies initialize before the root widget renders. | `configureDependencies()` completes before `runApp(...)`. | No test assertion. Implementation ordering is visible at `lib/main.dart:10` (`await configureDependencies();`) and `lib/main.dart:13` (`runApp(...)`), but `test/widget_test.dart:13` directly pumps `VoxNovelApp` and bypasses `main()`. | ❌ GAP |
| WHEN `/` resolves THEN the library placeholder shows the exact visible title `Biblioteca`. | Exactly one visible `Biblioteca`. | `test/app/router/app_router_test.dart:12` — `expect(find.text('Biblioteca'), findsOneWidget)` | ✅ PASS |
| WHEN an unknown route is requested THEN a visible navigation error state renders. | Exact visible title `Erro de navegação` and attempted location. | `test/app/router/app_router_test.dart:23` — `expect(find.text('Erro de navegação'), findsOneWidget)`; `test/app/router/app_router_test.dart:36` — `expect(find.text('/rota-inexistente'), findsOneWidget)` | ✅ PASS |

### FND-02 — Manage presentation state with Cubit

| Criterion | Spec-defined outcome | `file:line` + assertion expression | Result |
| --------- | -------------------- | ---------------------------------- | ------ |
| WHEN mutable presentation state is needed THEN it is exposed through a Cubit. | `AppCubit` starts at `AppStatus.initial` and `markReady()` emits exactly `AppStatus.ready`. | `test/app/app_cubit_test.dart:11` — `expect(cubit.state.status, AppStatus.initial)`; `test/app/app_cubit_test.dart:18` — `expect: () => [isA<AppState>().having(..., AppStatus.ready)]` | ✅ PASS |
| WHEN the initial shell renders THEN it does not depend on event-based BLoC classes. | Shell composition uses the provided `AppCubit`; no event-based `Bloc` class participates. | `test/app/app_test.dart:35` asserts `tester.element(find.text('Biblioteca')).read<AppCubit>()` is `same(cubit)`, but no assertion detects introduction of an event-based BLoC dependency. Repository search found no `extends Bloc`/`Bloc<` implementation, which is implementation inspection rather than discriminating test evidence. | ❌ GAP |

### FND-03 — Compose dependencies centrally

| Criterion | Spec-defined outcome | `file:line` + assertion expression | Result |
| --------- | -------------------- | ---------------------------------- | ------ |
| WHEN startup runs THEN each foundation dependency is registered exactly once. | One registered `AppDatabase`, `AppCubit`, and `GoRouter`, with repeated setup preserving identity. | `test/app/dependency_injection/configure_dependencies_test.dart:26` — `expect(locator.isRegistered<AppDatabase>(), isTrue)`; lines 27–28 repeat the exact assertion for `AppCubit` and `GoRouter`; lines 42–44 assert each resolved object is `same(...)`. | ✅ PASS |
| WHEN tests initialize repeatedly THEN setup resets or reuses registrations without duplicate-registration failure. | Second setup completes and returns the same three instances; reset clears and disposes them. | `test/app/dependency_injection/configure_dependencies_test.dart:40` — `await configureDependencies(instance: locator)` followed by lines 42–44 `same(...)`; lines 57–60 assert all registrations are false and `cubit.isClosed` is true after reset. | ✅ PASS |

### FND-04 — Provide a local persistence boundary

| Criterion | Spec-defined outcome | `file:line` + assertion expression | Result |
| --------- | -------------------- | ---------------------------------- | ------ |
| WHEN local persistence is requested THEN DI returns a single Drift database abstraction. | `AppDatabase` is registered and repeated setup resolves the identical instance. | `test/app/dependency_injection/configure_dependencies_test.dart:26` — `expect(locator.isRegistered<AppDatabase>(), isTrue)`; line 42 — `expect(locator<AppDatabase>(), same(database))` | ✅ PASS |
| WHEN a test uses persistence THEN it can substitute an in-memory database. | Injected `NativeDatabase.memory()` executes `SELECT 1 AS value` and yields integer `1` without device filesystem use. | `test/app/dependency_injection/configure_dependencies_test.dart:77` — `expect(result.read<int>('value'), 1)`; `test/core/database/app_database_test.dart:32` repeats the exact result assertion. | ✅ PASS |
| WHEN the database closes THEN its executor is released without pending operations. | `close()` completes and a subsequent executor query throws `StateError`. | `test/core/database/app_database_test.dart:39` — `await database.close()`; lines 41–44 — `expect(executor.runSelect('SELECT 1', const []), throwsA(isA<StateError>()))` | ✅ PASS |

### FND-05 — Enforce automated quality gates

| Criterion | Spec-defined outcome | `file:line` + assertion expression | Result |
| --------- | -------------------- | ---------------------------------- | ------ |
| WHEN a commit or pull request reaches GitHub THEN CI runs Flutter static analysis. | Pushes to `main` and pull requests trigger a job containing `flutter analyze`. | No test assertion. Static configuration exists at `.github/workflows/ci.yml:3`–`:7` and `:31`–`:32`, but the suite does not parse/assert triggers or commands. | ❌ GAP |
| WHEN CI runs THEN it executes the complete Flutter test suite. | Workflow invokes unfiltered `flutter test`. | No test assertion. Static configuration exists at `.github/workflows/ci.yml:34`–`:35`. | ❌ GAP |
| WHEN analysis and tests pass THEN CI builds a debug Android APK. | `flutter build apk --debug` follows analysis and test steps. | No test assertion. Static configuration exists at `.github/workflows/ci.yml:31`–`:38`; the local build gate proves the command works but does not assert workflow wiring. | ❌ GAP |
| WHEN a required command fails THEN the workflow fails and cannot subsequently succeed. | Required commands are sequential fail-fast steps with no failure suppression. | No test assertion. The workflow has ordinary sequential steps and no `continue-on-error`, but no executable workflow/configuration test discriminates this behavior. | ❌ GAP |

**Status**: ❌ 8/14 acceptance criteria have spec-anchored assertion evidence; 6 gaps are evidence-zero.

### Payload and Conjunction Review

- Unknown-route behavior is conjunctive: both the exact error title and attempted location are asserted.
- Dependency registration is conjunctive: all three required types are asserted, repeated identity is asserted for all three, and reset asserts both removal and disposal effects.
- Persistence substitution asserts the returned payload value (`1`), not merely that a query occurred.
- CI criteria combine trigger, command, ordering, and failure propagation. Source inspection shows all fields, but no test assertion covers any part, so the conjunction is not counted as covered.

### Necessary/Sufficient Test Review

- The Cubit, route output, DI identity/reset, injected executor, and database-close assertions are necessary and sufficiently exact for their claimed outcomes.
- The app smoke test is insufficient for startup ordering because it constructs `VoxNovelApp` directly rather than invoking the entry point.
- The supplied-Cubit widget assertion is insufficient to prove the shell has no event-based BLoC dependency.
- A successful local build gate is necessary but insufficient to prove GitHub workflow triggers, step ordering, and fail-fast semantics.

---

## Discrimination Sensor

Mutations ran in two isolated copies under `/tmp`; no mutation touched the real working tree.

| Mutation | File:line | Description | Focused command | Killed? |
| -------- | --------- | ----------- | --------------- | ------- |
| M1 | `lib/app/app_cubit.dart:12` | Changed emitted readiness status from `AppStatus.ready` to `AppStatus.initial`. | `flutter test test/app/app_cubit_test.dart test/app/app_test.dart` | ✅ Killed — exact ready-state assertions failed. |
| M2 | `lib/app/router/app_router.dart:16` | Changed navigation error title from `Erro de navegação` to `Falha inesperada`. | `flutter test test/app/router/app_router_test.dart test/app/app_test.dart` | ✅ Killed — exact error-title assertions failed. |

**Sensor depth**: lightweight
**Result**: 2/2 killed — PASS ✅

The isolated copies were throwaway scratch state. `git status --short` in the real worktree remained clean before the validation report was added.

---

## Interactive UAT Results

Not performed. Foundation behavior is infrastructure and deterministic shell behavior covered by automated gates; no complex visual interaction requires human judgment.

---

## Code Quality

| Principle | Status |
| --------- | ------ |
| Minimum code | ✅ Foundation components are small and direct. |
| Surgical changes | ✅ Product commits are confined to foundation source, tests, dependency/generated files, analyzer configuration, and CI. |
| No scope creep | ✅ No library data model or later-milestone product behavior was introduced. |
| Matches patterns | ✅ Feature-first placement, constructor injection outside the composition root, Cubit, `go_router`, and Drift match the approved design. |
| Spec-anchored outcome check | ❌ Six ACs lack assertion evidence. |
| Per-layer coverage expectation | ❌ Tested runtime layers meet the matrix, but entry-point ordering and CI behavior have no executable coverage. |
| Every in-scope test is claimed | ✅ The 19 tests map to an AC, listed edge case, or task Done-when criterion (including schema version and semantics checks). |
| Documented guidelines followed | ✅ `analysis_options.yaml` includes `flutter_lints`; `flutter analyze` is clean. `docs/spec.md` §24 requires library widget coverage, which is present. |
| No weakened/deleted tests | ✅ Baseline had 1 generated counter test; the obsolete scaffold test was replaced and the suite increased to 19 relevant tests. |
| No skipped tests or deviations | ✅ No `skip`, `@Skip`, or `SPEC_DEVIATION` marker was found in scope. |

Implementation quality is concise and consistent. The FAIL verdict is caused by verification gaps, not an observed runtime defect.

---

## Edge Cases

- [x] Repeated dependency initialization does not duplicate registrations: `test/app/dependency_injection/configure_dependencies_test.dart:40` and identity assertions at lines 42–44.
- [x] Unknown locations show an error instead of blank content: exact title and attempted path at `test/app/router/app_router_test.dart:23` and `:36`.
- [x] In-memory persistence needs no device filesystem: injected `NativeDatabase.memory()` and exact query result at `test/core/database/app_database_test.dart:25`–`:32`.
- [ ] Clean-checkout CI restores dependencies before analysis, test, and build: configuration ordering exists at `.github/workflows/ci.yml:28`–`:38`, but no assertion parses and proves it.

---

## Gate Check

- **Gate command**: `dart run build_runner build && flutter analyze && flutter test && flutter build apk --debug`
- **Result**: exit 0; 19 passed, 0 failed, 0 skipped
- **Code generation**: succeeded; 0 outputs written because generated output was current
- **Analysis**: no issues found
- **Android build**: succeeded; `build/app/outputs/flutter-apk/app-debug.apk`
- **Test count before feature**: 1
- **Test count after feature**: 19
- **Delta**: +18 tests
- **Skipped tests**: none
- **Failures**: none

---

## Fix Plans

### Fix 1: Add an executable startup-order test

- **Root cause**: The smoke test directly pumps `VoxNovelApp`, so it cannot fail if `runApp` moves before dependency initialization.
- **Fix task**: Extract or inject the bootstrap boundary minimally, then test that dependency configuration completes before the root app is passed to the runner. Preserve production behavior and avoid filesystem-backed database startup in the test.
- **Verify**: A behavior mutation that removes the await or runs the app first must fail the new test.
- **Priority**: Major

### Fix 2: Make the no-event-BLoC architectural constraint executable

- **Root cause**: The test proves the supplied Cubit is available but cannot detect an added event-based BLoC dependency.
- **Fix task**: Add a focused architecture/source-boundary test or an equivalent enforceable analyzer rule that rejects event-based BLoC classes in the foundation shell while allowing Cubit.
- **Verify**: Introducing a minimal `Bloc<Event, State>` dependency in scratch state must fail the check.
- **Priority**: Minor

### Fix 3: Add workflow configuration contract tests

- **Root cause**: Local commands prove the toolchain works, but nothing asserts GitHub triggers, exact unfiltered commands, dependency-restoration ordering, APK ordering, or failure propagation.
- **Fix task**: Add a YAML workflow contract test that parses `.github/workflows/ci.yml` and asserts push-to-main plus pull-request triggers, then exact ordered commands `flutter pub get` → `flutter analyze` → `flutter test` → `flutter build apk --debug`, with no failure-suppression settings.
- **Verify**: Mutating each trigger/command/order or adding `continue-on-error: true` must fail the contract test.
- **Priority**: Major

---

## Requirement Traceability Update

The verifier did not modify `spec.md`; these are the recommended status updates.

| Requirement | Previous Status | Recommended Status |
| ----------- | --------------- | ------------------ |
| FND-01 | In Tasks | ❌ Needs Fix — startup ordering lacks assertion evidence |
| FND-02 | In Tasks | ❌ Needs Fix — no-event-BLoC constraint lacks discriminating evidence |
| FND-03 | In Tasks | ✅ Verified |
| FND-04 | In Tasks | ✅ Verified |
| FND-05 | In Tasks | ❌ Needs Fix — workflow behavior lacks contract assertions |

---

## Summary

**Overall**: ❌ Not Ready

**Spec-anchored check**: 8/14 ACs matched exact spec outcomes; 6 evidence-zero gaps; 0 spec-precision gaps
**Sensor**: 2/2 mutations killed
**Gate**: 19 passed, 0 failed, 0 skipped; analysis and Android debug build passed

**What works**: Runtime shell routing, exact visible states, Cubit transitions, centralized dependency identity/reset, injected in-memory Drift execution, executor disposal, static analysis, the full test suite, and Android APK compilation.

**Issues found**: Startup ordering, the no-event-BLoC constraint, and four CI behaviors have implementation/configuration evidence but no assertion expression, so they cannot pass the verifier's evidence-or-zero and discrimination requirements.

**Next steps**: Implement Fixes 1–3 as atomic tasks, then repeat the build gate and independent verification with scratch mutations targeting startup ordering and workflow wiring.
