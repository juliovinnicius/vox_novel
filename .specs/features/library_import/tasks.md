# Library and Import Tasks

## Execution Protocol (MANDATORY -- do not skip)

Implement these tasks with the `spec-driven-development` skill: **activate it by
name and follow its Execute flow and Critical Rules.** Do not proceed without the
per-task gate, atomic commit, adequacy review, and final independent Verifier.

**Design**: `.specs/features/library_import/design.md`
**Status**: In Progress

---

## Test Coverage Matrix

> Generated from codebase, project guidelines, and spec — confirm before Execute.
> Guidelines found: `analysis_options.yaml` (`flutter_lints`),
> `.github/workflows/ci.yml`, and `docs/spec.md` sections 24 and 30. Existing
> Flutter tests establish `flutter_test`, `bloc_test`, in-memory Drift, widget
> semantics, architecture-contract, and composition-root patterns. Strong defaults
> apply where those files do not define behavioral depth.

| Code Layer | Required Test Type | Coverage Expectation | Location Pattern | Run Command |
| ---------- | ------------------ | -------------------- | ---------------- | ----------- |
| Domain entity/value validation | unit | Exact enum/value mapping, equality/copy behavior used by states, filename-title and metadata rules from LIB-01/LIB-04 | `test/features/**/domain/**/*_test.dart` | `flutter test test/features` |
| Drift schema and migration | integration | Fresh schema, v1→v2 migration, constraints, status conversion, exact persisted fields | `test/core/database/**/*_test.dart`, `test/features/library/data/database/**/*_test.dart` | `flutter test test/core/database test/features/library/data` |
| Repository | integration | Every query/mutation path, unique hash, stable duplicate identity, newest-first stream, rollback/error behavior | `test/features/library/data/repositories/**/*_test.dart` | `flutter test test/features/library/data/repositories` |
| Picker adapter | unit | Exact one-PDF filter, cancellation, nullable/missing path, selected metadata | `test/features/import_book/data/services/**/*_test.dart` | `flutter test test/features/import_book/data/services` |
| File-storage adapter | unit/integration | All validation branches, chunked SHA-256, staging/commit/discard, owned-root guard, missing file, cleanup and injected failures | `test/features/import_book/data/services/**/*_test.dart` | `flutter test test/features/import_book/data/services` |
| Import/library domain services | unit | All branches map 1:1 to LIB-01/LIB-02/LIB-04/LIB-05; every listed partial-failure and compensation edge case | `test/features/**/domain/services/**/*_test.dart` | `flutter test test/features` |
| Cubits | unit | Every state transition, exact message/status/payload, cancellation, single-flight guard, stream refresh and service errors | `test/features/**/presentation/cubit/**/*_test.dart` | `flutter test test/features` |
| Library widgets/dialogs | widget | Empty/content states, exact labels, semantics, list/grid identity/order, form validation, confirmations, busy/error feedback | `test/features/library/presentation/**/*_test.dart` | `flutter test test/features/library/presentation` |
| Router/composition | integration/widget | All feature registrations, injected seams, lifecycle reset, real root page and unchanged unknown-route behavior | `test/app/**/*_test.dart`, `test/widget_test.dart` | `flutter test test/app test/widget_test.dart` |
| Dependency/config/generated code | none | Package resolution, code generation, analysis, complete tests, and Android build | — | build gate only |

## Gate Check Commands

> Generated from `pubspec.yaml`, `analysis_options.yaml`, and
> `.github/workflows/ci.yml`.

| Gate Level | When to Use | Command |
| ---------- | ----------- | ------- |
| Quick | After unit or widget-test tasks | `flutter test` |
| Full | After repository, filesystem, migration, or composition integration tasks | `flutter test` |
| Build | After phase completion or config/schema-only tasks | `dart run build_runner build && flutter analyze && flutter test && flutter build apk --debug` |

---

## Execution Plan

Phases are ordered and run sequentially. Tasks within each phase execute in order.

### Phase 1: Domain and persistence

```text
T1 → T2 → T3 → T4
```

### Phase 2: Platform boundaries and domain operations

```text
T4 → T5 → T6 → T7 → T8
```

### Phase 3: Presentation

```text
T8 → T9 → T10 → T11 → T12 → T13
```

### Phase 4: Application integration

```text
T13 → T14
```

---

## Task Breakdown

### T1: Add library-import dependencies ✅

**What**: Add the approved picker, application-directory, SHA-256, path, and UUID packages.
**Where**: `pubspec.yaml`, `pubspec.lock`, generated platform plugin registrants
**Depends on**: None
**Reuses**: Existing Flutter package manifest and platform projects.
**Requirement**: LIB-01, LIB-02

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`
- CLI: `flutter pub add`

**Done when**:

- [x] `file_picker`, `path_provider`, `crypto`, `path`, and `uuid` are runtime dependencies.
- [x] Dependency resolution completes without overrides.
- [x] Existing generated plugin registrants contain only tool-generated changes.
- [x] Build gate passes before feature behavior is introduced.

**Tests**: none
**Gate**: build
**Commit**: `build(library): add import dependencies`

### T2: Define the Book domain model ✅

**What**: Add the immutable `Book`, `BookStatus`, metadata normalization, and filename-title rules.
**Where**: `lib/features/library/domain/entities/book.dart`,
`test/features/library/domain/entities/book_test.dart`
**Depends on**: T1
**Reuses**: Product `Book` model and status vocabulary from `docs/spec.md`.
**Requirement**: LIB-01, LIB-03, LIB-04

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [x] `Book` exposes exactly the Milestone 1 fields from the approved design.
- [x] Status strings round-trip exactly for all five documented statuses.
- [x] `Novel.PDF` produces title `Novel`; `.pdf` produces `Livro sem título`.
- [x] Valid metadata is trimmed and empty author becomes null.
- [x] Empty trimmed title returns the exact validation outcome `Informe o título`.
- [x] Spec-derived unit tests cover every listed rule and quick gate passes.

**Tests**: unit
**Gate**: quick
**Commit**: `feat(library): add book domain model`

### T3: Add the Books schema and migration ✅

**What**: Add the feature-owned Drift table, status converter, indexes, and schema v1→v2 migration.
**Where**: `lib/features/library/data/database/books.dart`,
`lib/core/database/app_database.dart`, generated Drift part,
`test/core/database/app_database_test.dart`,
`test/features/library/data/database/books_test.dart`
**Depends on**: T2
**Reuses**: Existing `AppDatabase`, injected executor, and in-memory tests.
**Requirement**: LIB-01, LIB-02, LIB-03

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`
- CLI: `dart run build_runner build`

**Done when**:

- [x] Fresh databases create every designed column and unique hash constraint.
- [x] A version-1 database upgrades to version 2 without losing pre-existing schema state.
- [x] Every `BookStatus` persists and reads back exactly.
- [x] Duplicate hashes are rejected by the database constraint.
- [x] Generated code is current and contains no hand edits.
- [x] Integration tests satisfy the matrix and build gate passes.

**Tests**: integration
**Gate**: build
**Commit**: `feat(database): add books schema`

### T4: Implement the Drift book repository ✅

**What**: Implement the `BookRepository` contract and Drift mapper/query/mutation behavior.
**Where**: `lib/features/library/domain/repositories/book_repository.dart`,
`lib/features/library/data/repositories/drift_book_repository.dart`,
`test/features/library/data/repositories/drift_book_repository_test.dart`
**Depends on**: T3
**Reuses**: `AppDatabase`, `Books`, and the domain model.
**Requirement**: LIB-01, LIB-02, LIB-03, LIB-04, LIB-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [x] `watchAll()` emits every book exactly once ordered by `updatedAt` descending with deterministic ID tie-break.
- [x] Find-by-ID and find-by-hash return exact domain values or null.
- [x] Insert persists every named field.
- [x] Replacement preserves ID, created timestamp, title, author, and cover while updating the approved import fields.
- [x] Metadata update trims valid values and changes only title, author, and `updatedAt`.
- [x] Delete removes exactly the requested record.
- [x] Transaction failure rolls back without an intermediate stream emission.
- [x] Integration tests satisfy every repository matrix path and build gate passes.

**Tests**: integration
**Gate**: build
**Commit**: `feat(library): add Drift book repository`

### T5: Implement the PDF picker adapter ✅

**What**: Add the platform-neutral picker contract and `file_picker` adapter.
**Where**: `lib/features/import_book/domain/services/pdf_picker.dart`,
`lib/features/import_book/data/services/file_picker_pdf_picker.dart`,
`test/features/import_book/data/services/file_picker_pdf_picker_test.dart`
**Depends on**: T4
**Reuses**: `file_picker` documented custom-extension API.
**Requirement**: LIB-01

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [x] The adapter requests one file with custom type and exact allowed extension `pdf`.
- [x] Native cancellation returns null without an error.
- [x] A result with a usable path maps exact source path and original filename.
- [x] A selected result without a usable path returns a typed invalid-selection failure.
- [x] Unit tests cover exact adapter arguments and all result branches.
- [x] Quick gate passes.

**Tests**: unit
**Gate**: quick
**Commit**: `feat(import): add PDF picker adapter`

### T6: Implement private book file storage ✅

**What**: Add chunked validation, SHA-256, staging, commit, rollback, quarantine, and owned-path protection.
**Where**: `lib/features/import_book/domain/services/book_file_storage.dart`,
`lib/features/import_book/data/services/local_book_file_storage.dart`,
`test/features/import_book/data/services/local_book_file_storage_test.dart`
**Depends on**: T5
**Reuses**: `path_provider`, `crypto`, `path`, and application-support storage guidance.
**Requirement**: LIB-01, LIB-02, LIB-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [x] Validation accepts an existing readable regular file with case-insensitive `.pdf`.
- [x] Missing, directory, unreadable, and non-PDF inputs return typed validation failures.
- [x] Empty readable PDFs are valid in this milestone.
- [x] SHA-256 is calculated from a chunked stream and matches a known fixture digest.
- [x] Stage, commit, discard, backup/restore, and quarantine operations have exact filesystem outcomes.
- [x] Deletion rejects every path outside the canonical owned books root.
- [x] Missing owned files count as deleted.
- [x] Injected copy/move/delete failures leave the expected pre-operation filesystem state.
- [x] Tests use temporary directories and satisfy every file-storage matrix branch.
- [x] Build gate passes.

**Tests**: unit/integration
**Gate**: build
**Commit**: `feat(import): add private PDF storage`

### T7: Implement PDF import orchestration ✅

**What**: Add `ImportBookService` for new imports, duplicate replacement, and reverse-order compensation.
**Where**: `lib/features/import_book/domain/services/import_book_service.dart`,
`test/features/import_book/domain/services/import_book_service_test.dart`
**Depends on**: T6
**Reuses**: `BookRepository`, `BookFileStorage`, injected clock, and injected UUID generator.
**Requirement**: LIB-01, LIB-02

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [x] A new PDF produces one exact `importing` book, zero progress, derived title, empty author/cover, timestamps, hash, and owned path.
- [x] A duplicate preserves stable ID, created timestamp, title, author, and cover while replacing only approved fields.
- [x] Old duplicate files are removed only after the replacement and row are durable.
- [x] Every validation, hash, stage, commit, repository, and cleanup failure executes exact compensation and returns the standard typed failure.
- [x] No failed path leaves a new record or active partial copy.
- [x] Domain tests map 1:1 to every LIB-01/LIB-02 criterion and listed import edge case.
- [x] Build gate passes.

**Tests**: unit
**Gate**: build
**Commit**: `feat(import): orchestrate PDF imports`

### T8: Implement library metadata and deletion service

**What**: Add one domain service coordinating validated edits and quarantine-backed complete deletion.
**Where**: `lib/features/library/domain/services/library_service.dart`,
`test/features/library/domain/services/library_service_test.dart`
**Depends on**: T7
**Reuses**: `BookRepository`, `BookFileStorage`, and metadata rules from `Book`.
**Requirement**: LIB-04, LIB-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Valid metadata persists exact trimmed title/author and injected update timestamp.
- [ ] Empty title fails with `Informe o título` before any repository mutation.
- [ ] Repository failure returns the exact save error and preserves old values.
- [ ] Deletion quarantines every existing owned file before deleting the record.
- [ ] Pre-commit file or repository failure restores files and retains/restores the exact record.
- [ ] Successful deletion removes the row and schedules/removes quarantined files.
- [ ] External paths are never removed.
- [ ] Unit tests cover every LIB-04/LIB-05 criterion and edge case.
- [ ] Build gate passes.

**Tests**: unit
**Gate**: build
**Commit**: `feat(library): add metadata and deletion service`

### T9: Create the import Cubit

**What**: Add exact import presentation states and guarded picker/import transitions.
**Where**: `lib/features/import_book/presentation/cubit/import_book_cubit.dart`,
`lib/features/import_book/presentation/cubit/import_book_state.dart`,
`test/features/import_book/presentation/cubit/import_book_cubit_test.dart`
**Depends on**: T8
**Reuses**: `PdfPicker`, `ImportBookService`, and Cubit conventions.
**Requirement**: LIB-01, LIB-02

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Initial state is exactly idle with no message.
- [ ] A request emits selecting, then importing, then idle on success.
- [ ] Cancellation emits selecting then idle without an error.
- [ ] Picker/import failure returns to idle with `Não foi possível importar este PDF`.
- [ ] A second call during selecting or importing is ignored and invokes no dependency.
- [ ] A pending import does not block state reads or widget frame pumping.
- [ ] Cubit tests assert every exact state sequence and quick gate passes.

**Tests**: unit
**Gate**: quick
**Commit**: `feat(import): add import Cubit`

### T10: Create the library Cubit

**What**: Add stream-backed library state, list/grid transitions, and edit/delete result handling.
**Where**: `lib/features/library/presentation/cubit/library_cubit.dart`,
`lib/features/library/presentation/cubit/library_state.dart`,
`test/features/library/presentation/cubit/library_cubit_test.dart`
**Depends on**: T9
**Reuses**: `BookRepository`, `LibraryService`, and Cubit conventions.
**Requirement**: LIB-03, LIB-04, LIB-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Initial state defaults to list with no books.
- [ ] `start()` emits loading then exact ordered repository books.
- [ ] Stream changes emit one refreshed immutable collection without duplicate IDs.
- [ ] List/grid methods change layout only and preserve book identity/order/data.
- [ ] Restarting a new Cubit defaults to list.
- [ ] Edit/delete errors preserve the last book collection and expose exact required messages.
- [ ] Stream failure preserves the last successful collection and exposes failure.
- [ ] Subscription is cancelled when the Cubit closes.
- [ ] Cubit tests cover every exact transition and build gate passes.

**Tests**: unit
**Gate**: build
**Commit**: `feat(library): add library Cubit`

### T11: Create reusable library book tiles

**What**: Add list and two-column-grid item widgets with exact metadata/status rendering and actions.
**Where**: `lib/features/library/presentation/widgets/book_list_item.dart`,
`lib/features/library/presentation/widgets/book_grid_item.dart`,
`test/features/library/presentation/widgets/book_item_test.dart`
**Depends on**: T10
**Reuses**: `Book`, Material cards/list tiles, and accessibility requirements.
**Requirement**: LIB-03, LIB-04, LIB-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Both variants render the exact title and exact localized processing-status label.
- [ ] Non-empty author is visible; empty author is omitted.
- [ ] Edit and delete actions identify the exact book.
- [ ] Interactive controls have accessible labels and adequate Material tap targets.
- [ ] Widget tests cover list/grid parity and semantics.
- [ ] Quick gate passes.

**Tests**: widget
**Gate**: quick
**Commit**: `feat(library): add book item widgets`

### T12: Create metadata and deletion dialogs

**What**: Add the edit form and named deletion confirmation dialogs.
**Where**: `lib/features/library/presentation/widgets/edit_book_dialog.dart`,
`lib/features/library/presentation/widgets/delete_book_dialog.dart`,
`test/features/library/presentation/widgets/book_dialogs_test.dart`
**Depends on**: T11
**Reuses**: Material dialogs and metadata validation rules.
**Requirement**: LIB-04, LIB-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Edit fields start with exact current title and author.
- [ ] Save returns exact trimmed valid values.
- [ ] Empty title shows `Informe o título` and does not close the dialog.
- [ ] Cancel returns no mutation.
- [ ] Delete confirmation names the exact title and has accessible cancel/delete actions.
- [ ] Confirmation and cancellation return exact typed results.
- [ ] Widget tests cover every form and confirmation branch.
- [ ] Quick gate passes.

**Tests**: widget
**Gate**: quick
**Commit**: `feat(library): add book management dialogs`

### T13: Replace the library placeholder with the complete page

**What**: Build the library page integrating both Cubits, layouts, empty state, import feedback, editing, and deletion.
**Where**: `lib/features/library/presentation/pages/library_page.dart`,
remove `lib/features/library/presentation/pages/library_placeholder_page.dart`,
`test/features/library/presentation/pages/library_page_test.dart`,
update placeholder test references
**Depends on**: T12
**Reuses**: Existing exact `Biblioteca` title, tiles, dialogs, and Cubits.
**Requirement**: LIB-01, LIB-03, LIB-04, LIB-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Empty state shows `Sua biblioteca está vazia` and accessible `Importar PDF`.
- [ ] Non-empty list and grid render the same exact ordered book IDs once each.
- [ ] Grid uses exactly two columns at phone width.
- [ ] Layout controls expose selected semantics and mutate no book data.
- [ ] Import busy state shows an indeterminate indicator and disables import.
- [ ] Import, edit, delete, and library failures show exact specified messages.
- [ ] Edit and deletion dialogs invoke the exact selected book and refresh only from repository state.
- [ ] The existing `Biblioteca` title and semantics contract remains.
- [ ] Widget tests cover happy, empty, busy, cancellation, validation, and failure paths.
- [ ] Build gate passes.

**Tests**: widget
**Gate**: build
**Commit**: `feat(library): build library page`

### T14: Integrate library and import into application composition

**What**: Register all feature dependencies and route the application root to the real library page.
**Where**: `lib/app/dependency_injection/configure_dependencies.dart`,
`lib/app/router/app_router.dart`, `lib/main.dart`,
`test/app/dependency_injection/configure_dependencies_test.dart`,
`test/app/router/app_router_test.dart`, `test/app/app_test.dart`,
`test/widget_test.dart`
**Depends on**: T13
**Reuses**: Existing GetIt lifecycle, GoRouter factory, app factory, and unknown-route tests.
**Requirement**: LIB-01, LIB-03, LIB-04, LIB-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Composition registers one repository, picker, storage, domain service, `LibraryCubit`, and `ImportBookCubit`.
- [ ] Tests can inject database, picker, storage root, clock, and ID seams without global platform calls.
- [ ] Repeated configuration reuses instances and reset closes Cubits, streams, router, and database.
- [ ] `/` renders the real empty library and exact `Biblioteca` title.
- [ ] Unknown routes retain the exact visible navigation error contract.
- [ ] A root integration test imports a fixture, observes one visible durable book, edits it, and deletes its record/files.
- [ ] The complete suite count does not decrease and no placeholder references remain.
- [ ] Build gate passes.

**Tests**: integration/widget
**Gate**: build
**Commit**: `feat(app): integrate library import flow`

---

## Phase Execution Map

```text
Phase 1 → Phase 2 → Phase 3 → Phase 4

Phase 1: T1 ──→ T2 ──→ T3 ──→ T4
Phase 2: T4 ──→ T5 ──→ T6 ──→ T7 ──→ T8
Phase 3: T8 ──→ T9 ──→ T10 ──→ T11 ──→ T12 ──→ T13
Phase 4: T13 ──→ T14
```

Execution is sequential. Phase boundaries are semantic; execution batches may
contain consecutive whole phases but never split a phase.

## Task Granularity Check

| Task | Scope | Status |
| ---- | ----- | ------ |
| T1 | One dependency-manifest change | ✅ Granular |
| T2 | One domain model and its co-located tests | ✅ Granular |
| T3 | One database schema/migration component and generated part | ✅ Granular |
| T4 | One repository implementation and contract | ✅ Granular |
| T5 | One picker adapter and contract | ✅ Granular |
| T6 | One cohesive filesystem adapter and contract | ✅ Granular |
| T7 | One import orchestration service | ✅ Granular |
| T8 | One library mutation service | ✅ Granular |
| T9 | One import Cubit/state component | ✅ Granular |
| T10 | One library Cubit/state component | ✅ Granular |
| T11 | One book-item widget family sharing one rendering contract | ✅ Granular |
| T12 | One book-management dialog family sharing one mutation boundary | ✅ Granular |
| T13 | One library page integration component | ✅ Granular |
| T14 | One application composition integration | ✅ Granular |

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

## Test Co-location Validation

| Task | Code Layer Created/Modified | Matrix Requires | Task Says | Status |
| ---- | --------------------------- | --------------- | --------- | ------ |
| T1 | Dependency/config/generated | none | none | ✅ OK |
| T2 | Domain entity/value validation | unit | unit | ✅ OK |
| T3 | Drift schema and migration | integration | integration | ✅ OK |
| T4 | Repository | integration | integration | ✅ OK |
| T5 | Picker adapter | unit | unit | ✅ OK |
| T6 | File-storage adapter | unit/integration | unit/integration | ✅ OK |
| T7 | Import domain service | unit | unit | ✅ OK |
| T8 | Library domain service | unit | unit | ✅ OK |
| T9 | Import Cubit | unit | unit | ✅ OK |
| T10 | Library Cubit | unit | unit | ✅ OK |
| T11 | Library widgets | widget | widget | ✅ OK |
| T12 | Library dialogs | widget | widget | ✅ OK |
| T13 | Library page | widget | widget | ✅ OK |
| T14 | Router/composition | integration/widget | integration/widget | ✅ OK |
