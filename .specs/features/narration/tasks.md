# Narration Tasks

## Execution Protocol (MANDATORY -- do not skip)

Implement these tasks with the `spec-driven-development` skill: **activate it
by name and follow its Execute flow and Critical Rules.** Do not search for
skill files by filesystem path. The skill is the source of truth for the full
flow (per-task cycle, sub-agent delegation, adequacy review, Verifier,
discrimination sensor).

**If the skill cannot be activated, STOP and tell the user — do not proceed
without it.**

---

**Design**: `.specs/features/narration/design.md`
**Status**: In Progress

---

## Test Coverage Matrix

> Generated from codebase, project guidelines, and spec — confirm before
> Execute. Guidelines found: `.github/workflows/ci.yml`,
> `analysis_options.yaml`, and AD-006 in `.specs/STATE.md`; existing test
> conventions sampled from `test/features/visual_reader/**`,
> `test/core/database/app_database_test.dart`, and
> `test/app/dependency_injection/configure_dependencies_test.dart`.

| Code Layer | Required Test Type | Coverage Expectation | Location Pattern | Run Command |
| ---------- | ------------------ | -------------------- | ---------------- | ----------- |
| Narration domain models/services/contracts | unit | All branches; 1:1 to applicable ACs; every queue, voice, rate, validation, and stale-progress edge case | `test/features/narration/domain/**/*_test.dart` | `flutter test test/features/narration/domain` |
| TTS adapter | unit | Initialization once, strict mapping/dedup, exact configuration/text, completion, stop/error/close paths | `test/features/narration/data/services/**/*_test.dart` | `flutter test test/features/narration/data/services` |
| Drift schema/repository | integration | Fresh v5 and v4 migration, all query/write/error paths, ordered writes, repair data, and cascades | `test/features/narration/data/**/*_test.dart`, `test/core/database/app_database_test.dart` | `flutter test test/features/narration/data test/core/database/app_database_test.dart` |
| Narration Cubit/state | unit | Every legal/invalid transition and NAR-01–05 AC; delayed/out-of-order operations and exact messages | `test/features/narration/presentation/cubit/**/*_test.dart` | `flutter test test/features/narration/presentation/cubit` |
| Player/settings widgets | widget | Every NAR-02/NAR-06 state, callback, label, enabled/selected semantics, and 48×48 target | `test/features/narration/presentation/widgets/**/*_test.dart` | `flutter test test/features/narration/presentation/widgets` |
| Reader integration/DI/lifecycle | integration/widget | Happy, edge, and failure paths for visual synchronization, ownership, restart, reprocessing, lifecycle, deletion | `test/features/narration/*_test.dart`, `test/features/visual_reader/**`, `test/app/dependency_injection/**` | `flutter test test/features/narration test/features/visual_reader test/app/dependency_injection` |
| Package, Android manifest, generated schema | none | Build gate plus focused architecture/schema assertions | `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`, `lib/core/database/app_database.g.dart` | build gate only |

## Gate Check Commands

> Generated from codebase — confirm before Execute.

| Gate Level | When to Use | Command |
| ---------- | ----------- | ------- |
| Quick | After a task with focused unit/widget tests | `flutter test <task test path>` |
| Full | After data, composition, or integration changes | `flutter test` |
| Build | After phase completion or config/schema work | `flutter analyze && flutter test && flutter build apk --debug` |

---

## Execution Plan

Phases are ordered and run sequentially. Each task is implemented, tested, and
committed before the next task starts.

### Phase 1: Domain and durable foundation

```text
T1 → T2 → T3 → T4 → T5
```

### Phase 2: Engine and playback controller

```text
T5 → T6 → T7 → T8 → T9
```

### Phase 3: Reader experience and composition

```text
T9 → T10 → T11 → T12 → T13 → T14
```

---

## Task Breakdown

### T1: Define narration domain models and engine contract ✅

**What**: Add immutable voices, settings, override, progress, queue-entry and
status types plus the package-agnostic engine interface.
**Where**: `lib/features/narration/domain/entities/narration_models.dart`,
`lib/features/narration/domain/services/narration_engine.dart`
**Depends on**: None
**Reuses**: Existing immutable entity, UTC timestamp, and validation patterns
**Requirement**: NAR-01, NAR-02, NAR-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Constructors enforce paired non-empty voice identity, UTC progress, and rate `0.5...2.0` in `0.1` increments.
- [ ] Engine contract exposes initialize/configure/speak/stop/close without plugin types.
- [ ] Domain tests cover every valid boundary and invalid branch.
- [ ] Quick gate passes with no silent test deletion.

**Tests**: unit
**Gate**: quick
**Commit**: `feat(narration): define narration domain contracts`

### T2: Implement deterministic narration queue ✅

**What**: Add the pure source-order queue with lookup, traversal, boundaries,
empty-chapter handling, and exact normalized text entries.
**Where**: `lib/features/narration/domain/services/narration_queue.dart`
**Depends on**: T1
**Reuses**: `ReaderBookContent`, `ReaderChapter`, `NarrationBlockDraft`
**Requirement**: NAR-03, NAR-04, NAR-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Queue flattens active blocks in numeric source order and skips empty chapters.
- [ ] First/last/previous/next/lookup and foreign identity behavior match the spec.
- [ ] Tests cover all queue ACs and listed empty/stale/Unicode edge cases.
- [ ] Quick gate passes with no silent test deletion.

**Tests**: unit
**Gate**: quick
**Commit**: `feat(narration): add deterministic block queue`

### T3: Implement narration settings resolution ✅

**What**: Add deterministic voice sorting, global/book precedence, missing
voice repair, and bounded rate normalization.
**Where**:
`lib/features/narration/domain/services/narration_settings_resolver.dart`
**Depends on**: T2
**Reuses**: Narration domain models
**Requirement**: NAR-02

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Voices sort by locale then name and duplicate identities resolve deterministically.
- [ ] Override, global, same-locale, and first-overall fallbacks match every NAR-02 AC.
- [ ] Tests cover missing/empty voices and every rate boundary/step.
- [ ] Quick gate passes with no silent test deletion.

**Tests**: unit
**Gate**: quick
**Commit**: `feat(narration): resolve voices and speech rate`

### T4: Add Drift v5 narration schema and migration ✅

**What**: Add the three narration tables, v4-to-v5 migration, generated Drift
code, constraints, and book-deletion cascades.
**Where**: `lib/core/database/app_database.dart`,
`lib/core/database/app_database.g.dart`
**Depends on**: T3
**Reuses**: Existing schema migration and file-backed fixture patterns
**Requirement**: NAR-02, NAR-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Fresh databases create schema v5 with singleton global settings and two book-scoped tables.
- [ ] A v4 fixture preserves books, active content, visual settings, and positions.
- [ ] Constraints and delete cascades preserve global narration settings.
- [ ] Drift output is regenerated and the Build gate passes.

**Tests**: integration
**Gate**: build
**Commit**: `feat(database): add narration persistence schema`

### T5: Implement Drift narration repository ✅

**What**: Implement complete global/override/progress reads and writes with a
per-book newest-request write tail that survives failures.
**Where**:
`lib/features/narration/data/repositories/drift_narration_repository.dart`
**Depends on**: T4
**Reuses**: `DriftVisualReaderRepository` serialization pattern
**Requirement**: NAR-02, NAR-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Repository contract and Drift implementation round-trip every complete record atomically.
- [ ] Adversarial delayed writes prove physical serialization and newest-request wins.
- [ ] Failed writes propagate without poisoning later saves.
- [ ] Override/progress deletion cascades and global preservation pass file-backed tests.
- [ ] Full gate passes with no silent test deletion.

**Tests**: integration
**Gate**: full
**Commit**: `feat(narration): persist settings and progress`

### T6: Integrate the Flutter TTS adapter

**What**: Add `flutter_tts`, Android TTS-service visibility, and the adapter
that initializes once and strictly maps plugin behavior to the engine contract.
**Where**: `pubspec.yaml`, `pubspec.lock`,
`android/app/src/main/AndroidManifest.xml`,
`lib/features/narration/data/services/flutter_tts_narration_engine.dart`
**Depends on**: T5
**Reuses**: Existing injectable plugin-facade testing pattern
**Requirement**: NAR-01, NAR-02, NAR-03

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Adapter caches initialization, enables awaited completion, and returns only valid deduplicated sorted voices.
- [ ] Exact voice map, rate, normalized text, stop, failure, and close behavior are tested.
- [ ] Android manifest declares only the foreground TTS query required for this milestone.
- [ ] Build gate passes on the real dependency.

**Tests**: unit
**Gate**: build
**Commit**: `feat(narration): adapt on-device text to speech`

### T7: Implement narration state and load/settings behavior

**What**: Add state and the first cohesive Cubit slice for initialization,
progress restore/repair, voice/rate persistence, override scope, retry, and
preview.
**Where**: `lib/features/narration/presentation/cubit/narration_state.dart`,
`lib/features/narration/presentation/cubit/narration_cubit.dart`
**Depends on**: T6
**Reuses**: Existing Cubit clock injection and exact-message patterns
**Requirement**: NAR-01, NAR-02, NAR-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Load distinguishes ready, unavailable, empty queue, and exact initialization error/retry.
- [ ] Valid, completed, stale-run, and foreign progress restore/repair exactly.
- [ ] Voice/rate/global/override/preview paths preserve progress and exact messages.
- [ ] Delayed load and preview continuations cannot overwrite newer state.
- [ ] Quick gate passes with all applicable NAR-01/02/05 AC tests.

**Tests**: unit
**Gate**: quick
**Commit**: `feat(narration): load narration preferences and progress`

### T8: Implement generation-safe playback and traversal

**What**: Complete Cubit play, pause, previous, next, automatic advance,
failure, completion, lifecycle, reload, and close behavior.
**Where**: `lib/features/narration/presentation/cubit/narration_cubit.dart`
**Depends on**: T7
**Reuses**: Narration queue and repository write ordering
**Requirement**: NAR-03, NAR-04, NAR-05, NAR-06

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Exact selected/saved/first play origins and restart-whole-block pause work.
- [ ] Persistence precedes every automatic next speak and final completion never wraps.
- [ ] Generation invalidates completion/error after pause, skip, preview, reload, lifecycle, and close.
- [ ] Duplicate transitions, boundaries, missing voice retry, and operation failures match exact outcomes.
- [ ] Lifecycle state becomes paused synchronously and close awaits stop/latest save.
- [ ] Quick gate passes with all NAR-03/04/05 controller ACs.

**Tests**: unit
**Gate**: quick
**Commit**: `feat(narration): control foreground playback queue`

### T9: Add non-persisting visual narration follow

**What**: Add a validated `followNarration` transition that changes in-memory
reader focus without queueing a visual-position write.
**Where**:
`lib/features/visual_reader/presentation/cubit/visual_reader_cubit.dart`
**Depends on**: T8
**Reuses**: Existing chapter/block validation and reader state transitions
**Requirement**: NAR-03, NAR-04, NAR-06

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Valid narration focus updates chapter/block and exposes the highlight.
- [ ] Foreign/stale focus is a no-op.
- [ ] Repository records zero visual-position saves for narration follow.
- [ ] Existing explicit selection persistence remains unchanged.
- [ ] Quick gate passes with focused and regression tests.

**Tests**: unit
**Gate**: quick
**Commit**: `feat(reader): follow narration without saving position`

### T10: Build the foreground narration player bar

**What**: Add the persistent player bar for status, chapter, play/pause,
previous/next, settings, messages, and retry.
**Where**:
`lib/features/narration/presentation/widgets/narration_player_bar.dart`
**Depends on**: T9
**Reuses**: Existing reader palette, Material tooltip, and semantics patterns
**Requirement**: NAR-01, NAR-03, NAR-04, NAR-06

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Every state has the exact control labels, icons, enabled behavior, message, and retry action.
- [ ] All controls expose Portuguese semantics and minimum 48×48 targets.
- [ ] Queue boundary controls and completed/no-wrap state are represented exactly.
- [ ] Widget quick gate passes for every state.

**Tests**: widget
**Gate**: quick
**Commit**: `feat(narration): add accessible player bar`

### T11: Build voice and speed settings sheet

**What**: Add sorted voice selection/preview, global/book scope, and bounded
rate controls.
**Where**:
`lib/features/narration/presentation/widgets/narration_settings_sheet.dart`
**Depends on**: T10
**Reuses**: Existing `ReaderSettingsSheet` layout and accessibility patterns
**Requirement**: NAR-02, NAR-06

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Exact selected voice, locale/name order, preview, and scope callbacks work.
- [ ] Speed changes only by `0.1`; `0.5`/`2.0` boundary actions disable.
- [ ] Controls expose selected/disabled Portuguese semantics and 48×48 targets.
- [ ] Widget quick gate passes for all NAR-02 UI ACs.

**Tests**: widget
**Gate**: quick
**Commit**: `feat(narration): add voice and speed controls`

### T12: Compose narration with the reader

**What**: Add `ReaderNarrationHost` and minimally adapt `ReaderPage` so user
selection sets pending narration origin while playback focus follows visually.
**Where**:
`lib/features/narration/presentation/widgets/reader_narration_host.dart`,
`lib/features/visual_reader/presentation/pages/reader_page.dart`
**Depends on**: T11
**Reuses**: Reader route composition and text-reader selection callbacks
**Requirement**: NAR-03, NAR-04, NAR-06

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Ready reader displays the persistent player without breaking text/PDF/themes/settings.
- [ ] Explicit paragraph tap becomes next play origin; passive navigation does not change narration progress.
- [ ] Playback focus changes highlight/scroll without a visual-position write.
- [ ] Lifecycle pause synchronously leaves playing and awaits stop/save without auto-resume.
- [ ] Widget/integration full gate passes.

**Tests**: integration/widget
**Gate**: full
**Commit**: `feat(reader): compose foreground narration`

### T13: Register single engine and route narration ownership

**What**: Extend dependency injection with the engine/repository singletons and
a route registry that safely transfers foreground engine ownership and awaits
shutdown.
**Where**:
`lib/app/dependency_injection/configure_dependencies.dart`
**Depends on**: T12
**Reuses**: `ReaderCubitRegistry`, dependency reset and injected-factory seams
**Requirement**: NAR-01, NAR-03, NAR-05, NAR-06

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] One engine and repository are registered while every route receives its own Cubit.
- [ ] Ownership transfer awaits prior pause/close before a new controller can speak.
- [ ] Dependency reset awaits lifecycle/stop/latest progress before engine/database close.
- [ ] Tests inject a fake engine and never require a native plugin.
- [ ] Full gate passes with DI and ownership race coverage.

**Tests**: integration
**Gate**: full
**Commit**: `feat(app): register foreground narration lifecycle`

### T14: Verify the complete persisted foreground narration flow

**What**: Add the file-backed end-to-end feature integration suite and the
combined Milestone 3–4 UAT checklist, then run all release gates.
**Where**: `test/features/narration/narration_integration_test.dart`,
`.specs/features/narration/uat.md`
**Depends on**: T13
**Reuses**: Visual-reader file-backed integration fixtures and deferred M3 UAT
**Requirement**: NAR-01, NAR-02, NAR-03, NAR-04, NAR-05, NAR-06

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] File-backed restart restores exact settings/progress without autoplay.
- [ ] Automatic cross-chapter flow, pause, lifecycle, reprocessing repair, failures, and delete cascades pass end to end.
- [ ] Combined device UAT covers every item in NAR-06 AC 7 and is ready for user execution.
- [ ] Analysis, complete test suite, and Android debug APK Build gate pass.

**Tests**: integration
**Gate**: build
**Commit**: `test(narration): cover persisted foreground flow`

---

## Phase Execution Map

```text
Phase 1 → Phase 2 → Phase 3

Phase 1: T1 → T2 → T3 → T4 → T5
Phase 2: T5 → T6 → T7 → T8 → T9
Phase 3: T9 → T10 → T11 → T12 → T13 → T14
```

Boundary tasks are repeated only to show the dependency entering the next
phase; each task executes exactly once.

## Task Granularity Check

| Task | Scope | Status |
| ---- | ----- | ------ |
| T1 | One cohesive domain contract | ✅ Granular |
| T2 | One pure queue service | ✅ Granular |
| T3 | One settings resolver | ✅ Granular |
| T4 | One database migration | ✅ Granular |
| T5 | One repository implementation | ✅ Granular |
| T6 | One external-engine adapter | ✅ Granular |
| T7 | One Cubit initialization/settings slice | ✅ Cohesive |
| T8 | One Cubit playback slice | ✅ Cohesive |
| T9 | One reader transition | ✅ Granular |
| T10 | One player widget | ✅ Granular |
| T11 | One settings widget | ✅ Granular |
| T12 | One reader composition boundary | ✅ Cohesive |
| T13 | One dependency ownership boundary | ✅ Cohesive |
| T14 | One full-flow verification deliverable | ✅ Cohesive |

## Diagram-Definition Cross-Check

| Task | Depends On (task body) | Diagram Shows | Status |
| ---- | ---------------------- | ------------- | ------ |
| T1 | None | Start | ✅ Match |
| T2 | T1 | T1 → T2 | ✅ Match |
| T3 | T2 | T2 → T3 | ✅ Match |
| T4 | T3 | T3 → T4 | ✅ Match |
| T5 | T4 | T4 → T5 | ✅ Match |
| T6 | T5 | T5 → T6 | ✅ Match |
| T7 | T6 | T6 → T7 | ✅ Match |
| T8 | T7 | T7 → T8 | ✅ Match |
| T9 | T8 | T8 → T9 | ✅ Match |
| T10 | T9 | T9 → T10 | ✅ Match |
| T11 | T10 | T10 → T11 | ✅ Match |
| T12 | T11 | T11 → T12 | ✅ Match |
| T13 | T12 | T12 → T13 | ✅ Match |
| T14 | T13 | T13 → T14 | ✅ Match |

The execution is deliberately stricter than the minimum dependency graph:
within each phase tasks run sequentially, and phases are gates.

## Test Co-location Validation

| Task | Code Layer Created/Modified | Matrix Requires | Task Says | Status |
| ---- | --------------------------- | --------------- | --------- | ------ |
| T1 | Domain/contract | unit | unit | ✅ OK |
| T2 | Domain service | unit | unit | ✅ OK |
| T3 | Domain service | unit | unit | ✅ OK |
| T4 | Schema/migration | integration/build | integration | ✅ OK |
| T5 | Repository | integration | integration | ✅ OK |
| T6 | TTS adapter/config | unit + build | unit | ✅ OK |
| T7 | Cubit/state | unit | unit | ✅ OK |
| T8 | Cubit/state | unit | unit | ✅ OK |
| T9 | Reader Cubit | unit | unit | ✅ OK |
| T10 | Player widget | widget | widget | ✅ OK |
| T11 | Settings widget | widget | widget | ✅ OK |
| T12 | Reader composition/lifecycle | integration/widget | integration/widget | ✅ OK |
| T13 | DI/ownership | integration | integration | ✅ OK |
| T14 | Root flow/UAT | integration | integration | ✅ OK |

---

## Requirement Traceability

| Requirement | Tasks |
| --- | --- |
| NAR-01 | T1, T6, T7, T10, T13, T14 |
| NAR-02 | T1, T3, T4, T5, T6, T7, T11, T14 |
| NAR-03 | T2, T6, T8, T9, T10, T12, T13, T14 |
| NAR-04 | T2, T8, T9, T10, T12, T14 |
| NAR-05 | T1, T2, T4, T5, T7, T8, T13, T14 |
| NAR-06 | T8, T9, T10, T11, T12, T13, T14 |

**Coverage**: 6/6 requirements mapped; no orphan task and no unmapped
requirement.
