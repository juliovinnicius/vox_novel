# Text Processing Tasks

## Execution Protocol (MANDATORY -- do not skip)

Implement these tasks with the `spec-driven-development` skill: **activate it by
name and follow its Execute flow and Critical Rules.** The skill is the source of
truth for the per-task cycle, gate, test-adequacy review, atomic commit, worker
batching, and independent Verifier.

**If the skill cannot be activated, STOP and tell the user — do not proceed
without it.**

---

**Design**: `.specs/features/text_processing/design.md`
**Status**: In Progress

---

## Test Coverage Matrix

> Generated from codebase, project guidelines, and spec — confirm before
> Execute. Guidelines found: `analysis_options.yaml`, `.github/workflows/ci.yml`,
> and `docs/spec.md` sections 24–25. Existing Flutter tests were sampled for
> style/location only; the spec supplies the coverage ceiling.

| Code Layer | Required Test Type | Coverage Expectation | Location Pattern | Run Command |
| ---------- | ------------------ | -------------------- | ---------------- | ----------- |
| PDF extractor adapter / isolate boundary | integration | Android-compatible dependency proof; exact ordered page payloads; worker-isolate identity; corrupt/protected/empty/cancel/dispose branches | `test/features/pdf_processing/data/services/*_test.dart` | `flutter test test/features/pdf_processing/data/services` |
| Domain entities and pure processing services | unit | All branches; 1:1 mapping to TXT-01–TXT-04 outcomes; every applicable edge case; exact output strings/payload fields | `test/features/pdf_processing/domain/**/*.dart` | `flutter test test/features/pdf_processing/domain` |
| Drift schema, migration, and repository | integration | Fresh schema and v2→v3 preservation; every staged/active transaction path; rollback, idempotency, ordering, cascades, and exact payloads | `test/features/pdf_processing/data/**/*.dart`, `test/core/database/app_database_test.dart` | `flutter test test/features/pdf_processing/data test/core/database/app_database_test.dart` |
| Processing orchestration service | unit/integration | 1:1 to TXT-01–TXT-05; exact progress ranges/status/messages; cancellation/failure cleanup; duplicate calls; prior-run preservation | `test/features/pdf_processing/domain/services/text_processing_service_test.dart` | `flutter test test/features/pdf_processing/domain/services/text_processing_service_test.dart` |
| Cubit | unit | Exact state sequences for start/success/unsupported/failure/cancel/duplicate/close; no shallow call-count-only assertions | `test/features/pdf_processing/presentation/cubit/*_test.dart` | `flutter test test/features/pdf_processing/presentation/cubit` |
| Library widgets/page | widget | List/grid parity; exact stages/percentages/messages; accessible cancel target; busy, cancellation, failure, and completed paths | `test/features/library/presentation/**/*_test.dart` | `flutter test test/features/library/presentation` |
| Import/composition/deletion flow | integration/widget | Complete import→process→ready flow; exact durable data after restart; cancel/failure; complete deletion and compensated cleanup | `test/features/import_book/**`, `test/app/**`, `test/widget_test.dart` | `flutter test test/features/import_book test/app test/widget_test.dart` |
| Dependency/config/generated schema | none | Build gate only, except behavior covered by the adjacent adapter/schema/integration task | — | Build gate only |

## Gate Check Commands

> Generated from the repository manifest and CI workflow — confirm before Execute.

| Gate Level | When to Use | Command |
| ---------- | ----------- | ------- |
| Quick | After tasks with unit or widget tests only | `flutter test` |
| Full | After adapter, database, repository, or cross-feature integration tasks | `flutter analyze && flutter test` |
| Build | After each phase and the final application integration | `flutter analyze && flutter test && flutter build apk --debug` |

---

## Execution Plan

Phases are ordered and execute sequentially. Tasks within each phase execute in
order and receive one atomic commit each.

### Execution status

- [x] T1 — `e9bee71`
- [x] T2 — `985f87a`
- [x] T3 — `6e7da31`
- [x] T4 — `a19c8ee`
- [x] F0 — Resolve committed domain analyzer findings before the Phase 1 build
  gate without changing behavior or tests — `7c161c8`
- [x] T5
- [x] T6
- [x] T7
- [x] T8
- [x] T9

### Phase 1: PDF boundary and deterministic domain

```text
T1 → T2 → T3 → T4 → T5
```

### Phase 2: Durable pipeline

```text
T5 → T6 → T7 → T8 → T9
```

### Phase 3: Product integration

```text
T9 → T10 → T11 → T12 → T13 → T14
```

---

## Task Breakdown

### T1: Prove and implement the isolated pdfrx extraction adapter ✅

**What**: Add `pdfrx`, define the extractor contract/event protocol, and implement
the production adapter with a spawned isolate and cancellation.
**Where**: `pubspec.yaml`, `pubspec.lock`,
`lib/features/pdf_processing/domain/services/pdf_text_extractor.dart`,
`lib/features/pdf_processing/data/services/pdfrx_pdf_text_extractor.dart`,
`test/features/pdf_processing/data/services/pdfrx_pdf_text_extractor_test.dart`,
selectable-text PDF fixtures under `test/fixtures/`
**Depends on**: None
**Reuses**: Existing constructor-injected adapter pattern and application-owned paths.
**Requirement**: TXT-01, TXT-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Production extraction creates, uses, and disposes the PDF document entirely inside a non-caller isolate.
- [ ] A multi-page fixture emits exact one-based page numbers, page count, text, and completion in source order.
- [ ] Empty page text is emitted rather than omitted.
- [ ] Corrupt and password-protected fixtures emit typed sanitized failures and no text payload.
- [ ] Cancellation stops before the next page event, closes ports, and leaves no reusable active worker.
- [ ] Repeated extract/cancel cycles complete without duplicate events or leaked active-run bookkeeping.
- [ ] At least 7 adapter/integration tests pass and the Android debug APK builds.

**Tests**: integration
**Gate**: build
**Commit**: `feat(processing): add isolated PDF text extractor`

### T2: Define the text-processing domain model ✅

**What**: Add exact processing stages/events/results/page/chapter/block value
objects and extend `Book` with processing counts, stage, and active run identity.
**Where**: `lib/features/pdf_processing/domain/entities/text_processing_models.dart`,
`lib/features/library/domain/entities/book.dart`,
`test/features/pdf_processing/domain/entities/text_processing_models_test.dart`,
`test/features/library/domain/entities/book_test.dart`
**Depends on**: T1
**Reuses**: Existing immutable `Book`, `copyWith`, equality, and storage enum patterns.
**Requirement**: TXT-01, TXT-03, TXT-04, TXT-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Every named page/chapter/block/run field from the design has immutable equality and exact validation.
- [ ] Processing stages expose the exact Portuguese labels and exact percentage bounds.
- [ ] Book defaults preserve all existing records while new processing values round-trip through `copyWith`.
- [ ] Invalid page/order/count/progress combinations are rejected with typed domain failures.
- [ ] At least 7 domain tests assert each named payload field and all prior `Book` tests remain unchanged/passing.

**Tests**: unit
**Gate**: quick
**Commit**: `feat(processing): define processing domain model`

### T3: Implement conservative text cleaning ✅

**What**: Add the two-pass edge profile and pure page cleaner implementing only
the exact TXT-02 transformations.
**Where**: `lib/features/pdf_processing/domain/services/text_cleaner.dart`,
`test/features/pdf_processing/domain/services/text_cleaner_test.dart`
**Depends on**: T2
**Reuses**: `RawPage`, `CleanPage`, and no external text library.
**Requirement**: TXT-02

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Control characters, whitespace, blank separators, complete-line URLs, and isolated Arabic page numbers produce exact specified output.
- [ ] Header/footer removal requires both at least 60% of pages and at least three same-edge occurrences.
- [ ] Hyphenated lowercase continuations join exactly; nonmatching hyphens remain.
- [ ] Narrative URL/page/header lookalikes and all unmatched content remain in exact relative order.
- [ ] Raw input objects are unchanged after cleaning.
- [ ] At least 10 unit tests cover every TXT-02 criterion and cleaning edge case.

**Tests**: unit
**Gate**: quick
**Commit**: `feat(processing): add conservative text cleaner`

### T4: Implement ordered chapter detection ✅

**What**: Add the incremental chapter detector for the exact complete-line
Portuguese, English, and simplified-Chinese patterns and fallbacks.
**Where**: `lib/features/pdf_processing/domain/services/chapter_detector.dart`,
`test/features/pdf_processing/domain/services/chapter_detector_test.dart`
**Depends on**: T3
**Reuses**: Clean-page source mapping and injected ID generator.
**Requirement**: TXT-03

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Every documented heading pattern starts a chapter only as a complete trimmed line.
- [ ] Chapters have exact title/body/page range, stable unique ID, and contiguous zero-based order.
- [ ] Preamble becomes exact `Início`; no heading produces one book-titled fallback.
- [ ] Empty consecutive/final chapters remain ordered with empty bodies.
- [ ] Chapter-like narrative lines remain narrative content.
- [ ] At least 9 unit tests cover all TXT-03 criteria and chapter edge cases.

**Tests**: unit
**Gate**: quick
**Commit**: `feat(processing): detect ordered chapters`

### T5: Implement bounded narration block splitting ✅

**What**: Add paragraph-based block generation with exact sentence, whitespace,
and hard-limit fallback behavior.
**Where**: `lib/features/pdf_processing/domain/services/narration_block_splitter.dart`,
`test/features/pdf_processing/domain/services/narration_block_splitter_test.dart`
**Depends on**: T4
**Reuses**: Chapter drafts, page mapping, and injected ID generator.
**Requirement**: TXT-04

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Non-empty paragraphs at or below 3,000 Unicode characters create one exact block each.
- [ ] Long paragraphs split by last eligible sentence, then whitespace, then exact limit.
- [ ] Portuguese/English and CJK sentence boundaries are recognized exactly.
- [ ] Concatenating ordered block text reconstructs every non-whitespace source character without loss or reordering.
- [ ] Every block asserts exact ID, chapter ID, order, both text fields, character count, and page range.
- [ ] Empty chapters create zero blocks.
- [ ] At least 9 unit tests pass and the complete phase build gate passes.

**Tests**: unit
**Gate**: build
**Commit**: `feat(processing): split chapters into narration blocks`

### F0: Satisfy the Phase 1 analysis gate ✅

**What**: Correct four analyzer findings accumulated by the quick-gated T2/T4
domain tasks without changing behavior or tests.
**Where**:
`lib/features/pdf_processing/domain/entities/text_processing_models.dart`,
`lib/features/pdf_processing/domain/services/chapter_detector.dart`
**Depends on**: T4
**Requirement**: TXT-03, TXT-04

**Done when**:

- [x] All four analyzer findings are removed without changing existing tests.
- [x] `flutter analyze`, all tests, and the Android debug APK build pass.

**Tests**: existing unit suite unchanged
**Gate**: build
**Commit**: `fix(processing): satisfy domain analysis gate`

### T6: Add the version-3 processing schema and migration ✅

**What**: Add feature-owned processing tables, book processing columns, indexes,
foreign keys/cascades, migration, and regenerated Drift code.
**Where**: `lib/features/pdf_processing/data/database/processing_runs.dart`,
`lib/features/pdf_processing/data/database/raw_pages.dart`,
`lib/features/pdf_processing/data/database/chapters.dart`,
`lib/features/pdf_processing/data/database/narration_blocks.dart`,
`lib/features/library/data/database/books.dart`,
`lib/core/database/app_database.dart`, generated `.g.dart`,
`test/core/database/app_database_test.dart`,
`test/features/pdf_processing/data/database/text_processing_schema_test.dart`
**Depends on**: T5
**Reuses**: Existing converters, schema-version-2 migration style, and Drift generation.
**Requirement**: TXT-01, TXT-03, TXT-04

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Fresh schema persists every named Book/run/page/chapter/block field exactly.
- [ ] Version 2 upgrades to 3 without losing existing books and supplies exact safe processing defaults.
- [ ] Required uniqueness, order indexes, active-run reference, and foreign-key cascades are enforced.
- [ ] Empty raw pages and empty chapter text round-trip exactly.
- [ ] Generated code is current and at least 8 schema/migration tests pass.

**Tests**: integration
**Gate**: full
**Commit**: `feat(processing): add durable processing schema`

### T7: Implement staged and active Drift processing persistence ✅

**What**: Add the processing repository contract and Drift implementation for
staging, streaming, monotonic progress, activation, replacement, and discard.
**Where**: `lib/features/pdf_processing/domain/repositories/text_processing_repository.dart`,
`lib/features/pdf_processing/data/repositories/drift_text_processing_repository.dart`,
`test/features/pdf_processing/data/repositories/drift_text_processing_repository_test.dart`
**Depends on**: T6
**Reuses**: `AppDatabase`, Drift transactions, and repository mapping conventions.
**Requirement**: TXT-01, TXT-02, TXT-03, TXT-04, TXT-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Staged raw/clean/chapter/block rows are stored exactly but excluded from active read APIs.
- [ ] Raw page streams remain one-based and ordered without loading a whole dataset in one repository result.
- [ ] Progress never decreases, exceeds its stage, or emits an invalid book state.
- [ ] Activation publishes exact counts/status/stage/progress and the complete dataset in one transaction.
- [ ] Activation failure preserves the prior active run; success removes the superseded run without duplicate rows.
- [ ] Cancel/failure discard removes only the staged run and applies the exact terminal Book state.
- [ ] At least 10 repository tests cover transaction failure, retry, ordering, payloads, and cascades.

**Tests**: integration
**Gate**: full
**Commit**: `feat(processing): persist staged text processing runs`

### T8: Implement text-processing orchestration ✅

**What**: Add the domain service coordinating extraction, two-pass cleaning,
chapters, blocks, progress, typed outcomes, global serialization, and rollback.
**Where**: `lib/features/pdf_processing/domain/services/text_processing_service.dart`,
`test/features/pdf_processing/domain/services/text_processing_service_test.dart`
**Depends on**: T7
**Reuses**: Extractor, repository, cleaner, detector, splitter, clock, and ID seams.
**Requirement**: TXT-01, TXT-02, TXT-03, TXT-04, TXT-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] A selectable-text run executes exact stages/ranges and completes with exact pages, clean text, chapters, blocks, counts, and `ready`.
- [ ] Zero text produces `unsupported` and the exact no-text message with no staged data.
- [ ] Parser/persistence/algorithm failures produce `failed`, the exact standard message, and retain any prior active run.
- [ ] Cancellation at every pipeline segment stops at the next unit, removes staging, preserves PDF/metadata, and returns `importing`.
- [ ] Duplicate calls for one book join the same future; production runs are globally serialized.
- [ ] Late cancellation cannot alter an activated run; close cancels and cleans an active run.
- [ ] Progress is monotonic, stage-bounded, and page/unit incremental.
- [ ] At least 12 orchestration tests map 1:1 to all five requirements and every applicable edge case.

**Tests**: unit/integration
**Gate**: full
**Commit**: `feat(processing): orchestrate text processing pipeline`

### T9: Create the text-processing Cubit ✅

**What**: Add exact processing presentation state and guarded process/cancel/close behavior.
**Where**: `lib/features/pdf_processing/presentation/cubit/text_processing_cubit.dart`,
`lib/features/pdf_processing/presentation/cubit/text_processing_state.dart`,
`test/features/pdf_processing/presentation/cubit/text_processing_cubit_test.dart`
**Depends on**: T8
**Reuses**: Existing Cubit equality, exact-message, guard, and disposal patterns.
**Requirement**: TXT-01, TXT-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Initial state is exactly idle with no active book or message.
- [ ] Process exposes the exact active book and returns to idle with the exact completed/unsupported/failed message behavior.
- [ ] Cancel is book-specific, exposes cancel-in-flight, and ends with `Processamento cancelado`.
- [ ] Duplicate process/cancel requests do not start duplicate service operations.
- [ ] Closing the Cubit awaits service cleanup and emits no post-close state.
- [ ] At least 8 exact state-sequence tests pass and the phase build gate passes.

**Tests**: unit
**Gate**: build
**Commit**: `feat(processing): add text processing Cubit`

### T10: Add per-book processing controls to library items ✅

**What**: Extend list/grid book items with exact determinate stage/percentage
display and accessible cancellation for actively processing books.
**Where**: `lib/features/library/presentation/widgets/book_list_item.dart`,
`lib/features/library/presentation/widgets/book_grid_item.dart`,
`test/features/library/presentation/widgets/book_item_test.dart`
**Depends on**: T9
**Reuses**: Existing item parity, status labels, keys, and action semantics.
**Requirement**: TXT-01, TXT-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Both layouts show the exact stage and rounded percentage from the same Book payload.
- [ ] Processing items expose `Cancelar processamento de <título>` and identify the exact book.
- [ ] Non-processing items expose no cancel action or processing indicator.
- [ ] Every existing metadata/edit/delete/status contract remains unchanged.
- [ ] At least 8 widget tests cover every stage, parity, semantics, and cancel payload.

**Tests**: widget
**Gate**: quick
**Commit**: `feat(library): show book processing progress`

### T11: Integrate processing actions and feedback into the library page ✅

**What**: Provide the processing Cubit, route exact cancel actions, and surface
cancel/no-text/failure feedback while preserving library behavior.
**Where**: `lib/features/library/presentation/pages/library_page.dart`,
`test/features/library/presentation/pages/library_page_test.dart`
**Depends on**: T10
**Reuses**: Existing `MultiBlocProvider`, Snackbar, list/grid, and import busy state.
**Requirement**: TXT-01, TXT-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] The page routes cancel from list/grid to the exact processing book ID.
- [ ] Exact cancellation, unsupported, and failure messages appear once.
- [ ] Active import/automatic processing keeps import disabled without blocking frames.
- [ ] Completed/cancelled processing refreshes solely from durable library state.
- [ ] Existing empty/list/grid/edit/delete behavior remains unchanged.
- [ ] At least 7 page widget tests cover happy, cancel, unsupported, failure, and responsive pending paths.

**Tests**: widget
**Gate**: quick
**Commit**: `feat(library): integrate processing controls`

### T12: Start processing automatically after import ✅

**What**: Connect the committed import result to `TextProcessingCubit` and extend
the import state sequence through automatic processing.
**Where**: `lib/features/import_book/presentation/cubit/import_book_cubit.dart`,
`lib/features/import_book/presentation/cubit/import_book_state.dart`,
`test/features/import_book/presentation/cubit/import_book_cubit_test.dart`
**Depends on**: T11
**Reuses**: `ImportBookService` return value and guarded import request behavior.
**Requirement**: TXT-01, TXT-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Successful copy transitions selecting → importing → processing and starts exactly the returned book.
- [ ] Processing completion returns import state to idle; cancel/unsupported/failure expose only their specified processing message.
- [ ] Picker/import failures never start processing and retain their existing exact import message.
- [ ] A second import is ignored through the whole automatic processing lifecycle.
- [ ] Pending processing permits frame pumping and state reads.
- [ ] At least 7 Cubit tests assert exact state and returned-book conjunctions.

**Tests**: unit
**Gate**: quick
**Commit**: `feat(import): start automatic text processing`

### T13: Preserve derived content through compensated deletion ✅

**What**: Extend library deletion persistence so successful deletion cascades all
processing data and failed permanent file cleanup restores the exact active dataset.
**Where**: `lib/features/library/domain/repositories/book_repository.dart`,
`lib/features/library/data/repositories/drift_book_repository.dart`,
`lib/features/library/domain/services/library_service.dart`,
`test/features/library/data/repositories/drift_book_repository_test.dart`,
`test/features/library/domain/services/library_service_test.dart`,
`test/widget_test.dart`
**Depends on**: T12
**Reuses**: Existing quarantine-backed deletion and restart tests.
**Requirement**: TXT-01, TXT-02, TXT-03, TXT-04

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Successful deletion leaves no book, run, raw page, chapter, block, PDF, cover, or quarantine row/file after restart.
- [ ] Cancelled deletion changes no database row or file.
- [ ] Cleanup failure restores the exact Book, active run, raw pages, chapters, blocks, PDF, and cover after restart.
- [ ] External paths remain protected and existing no-derived-content deletion behavior still passes.
- [ ] At least 5 integration tests assert every restored/deleted payload field and full gate passes.

**Tests**: integration/widget
**Gate**: full
**Commit**: `fix(library): preserve processed content on deletion rollback`

### T14: Compose and verify the complete text-processing flow ✅

**What**: Register all processing dependencies, initialize `pdfrx`, inject test
seams, wire the real page/Cubits, and prove import→process→restart/delete end to end.
**Where**: `lib/main.dart`,
`lib/app/dependency_injection/configure_dependencies.dart`,
`lib/app/router/app_router.dart`,
`test/app/dependency_injection/configure_dependencies_test.dart`,
`test/app/router/app_router_test.dart`, `test/app/app_test.dart`,
`test/widget_test.dart`
**Depends on**: T13
**Reuses**: Existing GetIt lifecycle, GoRouter factory, injectable database/storage/clock/ID seams, and root fixture flow.
**Requirement**: TXT-01, TXT-02, TXT-03, TXT-04, TXT-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Production composition initializes `pdfrx` before engine access and registers exactly one extractor/repository/service/Cubit lifecycle.
- [ ] Tests inject extractor/repository/worker seams without native or global calls.
- [ ] Reset cancels workers, closes Cubits/ports/database/router, and leaves no staged run.
- [ ] A valid selectable-text PDF imports automatically and reaches exact durable `ready` pages/clean text/chapters/blocks/counts after restart.
- [ ] No-text, corrupt, cancellation, and final deletion paths produce exact statuses/messages and no partial/orphan data.
- [ ] UI remains frame-responsive during an injected pending page.
- [ ] Complete suite count does not decrease, analysis passes, and Android debug APK builds.

**Tests**: integration/widget
**Gate**: build
**Commit**: `feat(app): integrate text processing milestone`

---

## Phase Execution Map

```text
Phase 1 → Phase 2 → Phase 3

Phase 1: T1 ──→ T2 ──→ T3 ──→ T4 ──→ T5
Phase 2: T5 ──→ T6 ──→ T7 ──→ T8 ──→ T9
Phase 3: T9 ──→ T10 ──→ T11 ──→ T12 ──→ T13 ──→ T14
```

Execution is strictly sequential. With 14 tasks, the three whole phases pack
into three task-budgeted batches (5, 4, and 5 new tasks respectively); a phase is
never split across workers.

---

## Task Granularity Check

| Task | Scope | Status |
| ---- | ----- | ------ |
| T1 | One extractor adapter plus its required contract/dependency proof | ✅ Cohesive |
| T2 | One processing domain model family | ✅ Cohesive |
| T3 | One pure cleaning service | ✅ Granular |
| T4 | One pure chapter detector | ✅ Granular |
| T5 | One pure block splitter | ✅ Granular |
| T6 | One schema/migration component and generated code | ✅ Cohesive |
| T7 | One processing repository implementation and contract | ✅ Cohesive |
| T8 | One pipeline orchestration service | ✅ Granular |
| T9 | One Cubit/state component | ✅ Granular |
| T10 | One shared list/grid presentation contract | ✅ Cohesive |
| T11 | One page integration component | ✅ Granular |
| T12 | One import-to-processing integration | ✅ Granular |
| T13 | One deletion compensation behavior | ✅ Granular |
| T14 | One application composition integration | ✅ Cohesive |

---

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
| T10 | T9 | T9 → T10 | ✅ Match |
| T11 | T10 | T10 → T11 | ✅ Match |
| T12 | T11 | T11 → T12 | ✅ Match |
| T13 | T12 | T12 → T13 | ✅ Match |
| T14 | T13 | T13 → T14 | ✅ Match |

---

## Test Co-location Validation

| Task | Code Layer Created/Modified | Matrix Requires | Task Says | Status |
| ---- | --------------------------- | --------------- | --------- | ------ |
| T1 | Adapter/isolate/config | integration | integration | ✅ OK |
| T2 | Domain model | unit | unit | ✅ OK |
| T3 | Domain cleaning service | unit | unit | ✅ OK |
| T4 | Domain chapter service | unit | unit | ✅ OK |
| T5 | Domain block service | unit | unit | ✅ OK |
| T6 | Schema/migration | integration | integration | ✅ OK |
| T7 | Repository | integration | integration | ✅ OK |
| T8 | Orchestration service | unit/integration | unit/integration | ✅ OK |
| T9 | Cubit | unit | unit | ✅ OK |
| T10 | Widgets | widget | widget | ✅ OK |
| T11 | Page | widget | widget | ✅ OK |
| T12 | Import Cubit/integration | unit | unit | ✅ OK |
| T13 | Repository/service/root deletion | integration/widget | integration/widget | ✅ OK |
| T14 | Composition/root flow | integration/widget | integration/widget | ✅ OK |

All tasks co-locate the required tests. No test-bearing layer defers its tests to
a later task.

---

## Validation Fix Tasks — Iteration 1

### F1: Execute CPU-bound text transformation off the UI isolate

**What**: Move header/footer profiling, page cleaning, chapter detection, and
block splitting through an isolate-backed execution seam while preserving
page/unit progress and cancellation checks.
**Where**:
`lib/features/pdf_processing/domain/services/text_processing_service.dart`,
`test/features/pdf_processing/domain/services/text_processing_service_test.dart`
**Depends on**: T14
**Requirement**: TXT-01 (E4), RNF-002

**Done when**:

- [x] Production CPU transformation records worker isolate identities different from the caller isolate.
- [x] Exact cleaned/chapter/block payloads and all existing cancellation boundaries remain unchanged.
- [x] Focused, analysis, full-test, and Android build gates pass.

**Tests**: unit/integration
**Gate**: build
**Commit**: `fix(processing): isolate CPU text transformation`

### F2: Prove composed terminal processing paths

**What**: Exercise the production dependency graph for no-text, corrupt PDF,
and cancellation outcomes, including exact messages, durable book status, and
absence of staged/orphaned content.
**Where**:
`test/app/dependency_injection/configure_dependencies_test.dart`
**Depends on**: F1
**Requirement**: TXT-05

**Done when**:

- [x] No-text, corrupt, and cancelled runs expose their exact terminal result.
- [x] Every terminal path leaves zero processing runs, pages, chapters, and blocks.

**Tests**: composition/integration
**Gate**: full-test
**Commit**: `test(processing): cover composed terminal paths`

### F3: Prove reset cancels active processing durably

**What**: Reset the production locator during an active extraction, prove the
extractor receives cancellation, all Cubits close, and reopening the database
finds no staged run or orphaned content.
**Where**:
`test/app/dependency_injection/configure_dependencies_test.dart`
**Depends on**: F2
**Requirement**: TXT-05, RNF-002

**Done when**:

- [x] Reset waits for active extraction cancellation and closes registered Cubits.
- [x] A fresh database connection observes zero staged/orphaned processing rows.

**Tests**: lifecycle/integration
**Gate**: full-test
**Commit**: `test(processing): verify reset cancellation cleanup`
