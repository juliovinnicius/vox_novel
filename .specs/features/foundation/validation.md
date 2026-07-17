# Foundation Validation — Iteration 2

**Date**: 2026-07-17
**Spec**: `.specs/features/foundation/spec.md`
**Original implementation range**: `4837fc2..bb1e678`
**Validation-fix range**: `275d98e..4161e77`
**Product/test fix commits**: `1c8e683`, `c2c0c7f`, `4161e77`
**Verifier**: fresh independent Verifier (author != verifier)

---

## Verdict

**Overall**: PASS ✅ — all 14 acceptance criteria have exact, spec-anchored
assertion evidence; all four listed edge cases are covered; the build gate passes;
and all three targeted scratch mutants are killed.

## Task Completion

| Tasks | Status | Notes |
| ----- | ------ | ----- |
| T1–T9 | ✅ Done | Original foundation tasks are implemented in the stated range. |
| F1 | ✅ Done | Awaitable bootstrap ordering is executable and tested. |
| F2 | ✅ Done | The foundation shell has an executable Cubit-only architecture contract. |
| F3 | ✅ Done | CI triggers, exact command order, and fail-fast wiring are parsed and asserted. |

No task is blocked or partial.

## Spec-Anchored Acceptance Criteria

### FND-01 — Run the application shell

| # | Criterion | Spec-defined outcome | `file:line` + assertion expression | Result |
| - | --------- | -------------------- | ---------------------------------- | ------ |
| 1 | Dependencies initialize before the root widget renders. | Application creation remains incomplete until configuration completes; before the returned widget is pumped, the database, Cubit, and router exist and the Cubit is exactly ready. | `test/widget_test.dart:52-53` — `expect(applicationCreated, isFalse)` while the injected configurator is blocked; `:58-61` — three `isRegistered<...>()` assertions and `expect(locator<AppCubit>().state.status, AppStatus.ready)`; production conjunction at `lib/main.dart:17` — `runApp(await createApplication())`. | ✅ PASS |
| 2 | `/` renders exactly one visible `Biblioteca`. | One visible title with the exact text `Biblioteca`. | `test/app/router/app_router_test.dart:12` — `expect(find.text('Biblioteca'), findsOneWidget)`. | ✅ PASS |
| 3 | An unknown route renders a visible navigation error. | Exact visible title `Erro de navegação` and the attempted location. | `test/app/router/app_router_test.dart:23` — `expect(find.text('Erro de navegação'), findsOneWidget)`; `:36` — `expect(find.text('/rota-inexistente'), findsOneWidget)`. | ✅ PASS |

### FND-02 — Manage presentation state with Cubit

| # | Criterion | Spec-defined outcome | `file:line` + assertion expression | Result |
| - | --------- | -------------------- | ---------------------------------- | ------ |
| 4 | Mutable presentation state is exposed through a Cubit. | `AppCubit` begins at `AppStatus.initial`; `markReady()` emits exactly `AppStatus.ready`. | `test/app/app_cubit_test.dart:11` — `expect(cubit.state.status, AppStatus.initial)`; `:18-23` — `having((state) => state.status, 'status', AppStatus.ready)`. | ✅ PASS |
| 5 | The initial foundation shell does not depend on event-based BLoC classes. | Foundation application sources contain no declaration extending event-based `Bloc<...>`; Cubit remains allowed. | `test/architecture/foundation_architecture_test.dart:15-23` — scans `lib/main.dart` plus recursive `lib/app/**/*.dart` for `extends Bloc<` and asserts `expect(eventBlocDeclarations, isEmpty)`. | ✅ PASS |

### FND-03 — Compose dependencies centrally

| # | Criterion | Spec-defined outcome | `file:line` + assertion expression | Result |
| - | --------- | -------------------- | ---------------------------------- | ------ |
| 6 | Startup registers each foundation dependency exactly once. | One registered `AppDatabase`, `AppCubit`, and `GoRouter`; repeated setup preserves each instance identity. | `test/app/dependency_injection/configure_dependencies_test.dart:26-28` — exact registration assertions for all three types; `:42-44` — `same(database)`, `same(cubit)`, and `same(router)`. | ✅ PASS |
| 7 | Repeated test initialization does not fail on duplicate registration. | A second setup completes and reuses all three instances; reset clears and disposes them. | `test/app/dependency_injection/configure_dependencies_test.dart:40-44` — second `configureDependencies` followed by three `same(...)` assertions; `:55-64` — reset, three unregistered assertions, closed Cubit, and rejected executor query. | ✅ PASS |

### FND-04 — Provide a local persistence boundary

| # | Criterion | Spec-defined outcome | `file:line` + assertion expression | Result |
| - | --------- | -------------------- | ---------------------------------- | ------ |
| 8 | DI returns a single Drift database abstraction. | `AppDatabase` is registered and repeated setup resolves the identical object. | `test/app/dependency_injection/configure_dependencies_test.dart:26` — `expect(locator.isRegistered<AppDatabase>(), isTrue)`; `:42` — `expect(locator<AppDatabase>(), same(database))`. | ✅ PASS |
| 9 | Tests can substitute an in-memory database. | Injected `NativeDatabase.memory()` executes `SELECT 1 AS value` and returns integer `1`, without a device filesystem. | `test/app/dependency_injection/configure_dependencies_test.dart:67-77` — injects the memory executor and asserts `expect(result.read<int>('value'), 1)`; corroborated by `test/core/database/app_database_test.dart:24-32`. | ✅ PASS |
| 10 | Closing the database releases its executor without pending operations. | `close()` completes and a subsequent executor query throws `StateError`. | `test/core/database/app_database_test.dart:39-44` — `await database.close()` then `expect(executor.runSelect(...), throwsA(isA<StateError>()))`. | ✅ PASS |

### FND-05 — Enforce automated quality gates

| # | Criterion | Spec-defined outcome | `file:line` + assertion expression | Result |
| - | --------- | -------------------- | ---------------------------------- | ------ |
| 11 | A push to `main` or pull request runs CI static analysis. | Parsed workflow contains push branch `main`, a `pull_request` trigger, and exact `flutter analyze` in its command sequence. | `test/ci/ci_workflow_test.dart:19-25` — `expect(branches, contains('main'))` and `expect(triggers.containsKey('pull_request'), isTrue)`; `:34-41` includes exact `flutter analyze`. | ✅ PASS |
| 12 | CI executes the complete Flutter test suite. | Workflow command is the exact unfiltered `flutter test`. | `test/ci/ci_workflow_test.dart:34-41` — `expect(commands, equals([... 'flutter test', ...]))`. | ✅ PASS |
| 13 | After analysis and tests pass, CI builds a debug Android APK. | Exact sequence is dependency restore → analysis → complete tests → debug APK build. | `test/ci/ci_workflow_test.dart:28-42` — ordered list equality ending in `flutter build apk --debug`. | ✅ PASS |
| 14 | Any required command failure fails the workflow and prevents later success. | Neither the Android job nor any required command step suppresses failure; commands remain sequential. | `test/ci/ci_workflow_test.dart:45-52` — job lacks `continue-on-error` and `commandSteps.every((step) => !step.containsKey('continue-on-error'))` is `isTrue`; ordered equality at `:34-41` proves the required commands are sequential steps. | ✅ PASS |

**Spec-anchored status**: 14/14 matched exact outcomes; 0 evidence-zero gaps;
0 spec-precision gaps.

## Edge Cases

- [x] Repeated dependency initialization: second setup and identity assertions at
  `test/app/dependency_injection/configure_dependencies_test.dart:40-44`.
- [x] Unknown route is not blank: exact error title and attempted path at
  `test/app/router/app_router_test.dart:23,36`.
- [x] In-memory persistence needs no device filesystem: injected memory executor
  and exact query payload at
  `test/app/dependency_injection/configure_dependencies_test.dart:67-77`.
- [x] Clean-checkout CI restores dependencies before all gates:
  `test/ci/ci_workflow_test.dart:34-41` asserts exact ordered commands beginning
  with `flutter pub get`.

## Gate Check

- **Command**: `dart run build_runner build && flutter analyze && flutter test && flutter build apk --debug`
- **Result**: exit 0
- **Generation**: succeeded; 0 outputs written because generated output was current
- **Analysis**: no issues found
- **Tests**: 24 passed, 0 failed, 0 skipped
- **Android build**: succeeded at `build/app/outputs/flutter-apk/app-debug.apk`
- **Test count before feature**: 1 generated scaffold test
- **Test count after fixes**: 24
- **Delta**: +23; the obsolete scaffold assertion was replaced, not weakened
- **Skipped tests**: none

## Discrimination Sensor

All mutations ran in throwaway copies under `/tmp`; the real implementation and
tests were never mutated.

| Mutation | Scratch fault | Focused command | Result |
| -------- | ------------- | --------------- | ------ |
| M1 — bootstrap await/order | Removed the `await` from the injected dependency configurator in `lib/main.dart:26`. | `flutter test test/widget_test.dart` | ✅ Killed — bootstrap-order test failed before dependency registration with an unregistered `AppCubit`. |
| M2 — event-based Bloc architecture | Added a compiling `FaultBloc extends Bloc<FaultEvent, FaultState>` declaration under `lib/app/`. | `flutter test test/architecture/foundation_architecture_test.dart` | ✅ Killed — `eventBlocDeclarations` contained the injected file. |
| M3 — CI complete-suite wiring | Changed workflow command `flutter test` to filtered `flutter test test/app`. | `flutter test test/ci/ci_workflow_test.dart` | ✅ Killed — exact ordered-command assertion rejected the filtered command. |

**Sensor depth**: lightweight, three highest-risk mutations
**Result**: 3/3 killed, 0 survived — PASS ✅

## Test Necessity, Sufficiency, and Quality

- Assertions derive from the acceptance criteria and target exact observable
  outcomes: labels, state enum values, dependency identity, query payload, thrown
  error type, parsed triggers, exact commands, ordering, and failure suppression.
- Payload/conjunction checks are sufficient: unknown routing asserts both title
  and location; DI asserts all three registrations and identities; CI asserts
  triggers, all four exact commands, order, and fail-fast settings.
- The three new contract tests are necessary: each focused behavior fault was
  empirically killed by its corresponding assertion.
- All 24 tests map to an AC, edge case, or task Done-when criterion. Schema version,
  semantics exposure, duplicate-ready suppression, supplied-Cubit composition, and
  production database construction are legitimate Done-when/design contracts.
- No test was skipped, deleted to reduce failures, or weakened. No
  `SPEC_DEVIATION` marker exists in scope.

## Code Quality

| Principle | Status |
| --------- | ------ |
| Minimum code / no speculative abstraction | ✅ |
| Surgical changes / no unrelated refactor | ✅ |
| No scope creep beyond Foundation | ✅ |
| Matches approved feature-first, Cubit, DI, router, and Drift design | ✅ |
| Spec-anchored exact outcome assertions | ✅ |
| Per-layer coverage expectation | ✅ |
| Every test claimed by AC, edge case, or Done-when | ✅ |
| Guidelines followed | ✅ `analysis_options.yaml` uses `flutter_lints`; `docs/spec.md` §24 widget coverage is present |
| Senior-engineer review bar | ✅ |

## Requirement Traceability

| Requirement | Validation status |
| ----------- | ----------------- |
| FND-01 | ✅ Verified |
| FND-02 | ✅ Verified |
| FND-03 | ✅ Verified |
| FND-04 | ✅ Verified |
| FND-05 | ✅ Verified |

## Lessons

This is a clean PASS: no failed/uncovered AC, surviving mutant,
spec-precision gap, gate failure, or `SPEC_DEVIATION` signal was found. Per the
lessons protocol, no new lesson is recorded and prior candidates are preserved.

## Summary

**Ready**: ✅
**ACs**: 14/14 exact spec outcomes
**Gate**: 24 passed, 0 failed, 0 skipped; analysis and Android build passed
**Sensor**: 3/3 killed, 0 survived
**Ranked gaps**: none
