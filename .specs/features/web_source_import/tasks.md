# Web Source Import Tasks

## Execution Protocol (MANDATORY -- do not skip)

Implement these tasks with the `tlc-spec-driven` skill: **activate it by name and follow its Execute flow and Critical Rules.** Do not search for skill files by filesystem path. The skill is the source of truth for the full flow (per-task cycle, sub-agent delegation, adequacy review, Verifier, discrimination sensor).

**If the skill cannot be activated, STOP and tell the user — do not proceed without it.**

---

**Design**: `.specs/features/web_source_import/design.md`
**Status**: Approved — executing T1–T24

---

## Test Coverage Matrix

> Generated from codebase, project guidelines, and spec — confirm before Execute. Guidelines found: none (no `AGENTS.md`, `CONTRIBUTING.md`, or coverage thresholds; `.github/workflows/ci.yml` supplies commands only) — **strong defaults applied**. Conventions sampled from `test/features/**` (hand-written fakes, no mocking package), `test/features/narration/narration_integration_test.dart` (real Drift `NativeDatabase` in a temp dir), `test/architecture/*_test.dart` (source-scanning invariants).

| Code Layer | Required Test Type | Coverage Expectation | Location Pattern | Run Command |
| --- | --- | --- | --- | --- |
| Domain services (fetcher, resolver, download service, ingest, registry) | unit | All branches; 1:1 to spec ACs; every listed edge case has a test | `test/features/**/domain/**/*_test.dart` | `flutter test` |
| Domain entities / value objects | unit | Validation and equality branches | `test/features/**/domain/entities/*_test.dart` | `flutter test` |
| Data adapters (HTTP client, HTML parser) | unit | Happy path + every failure kind, over a fake client and a stored HTML fixture — never the live site | `test/features/**/data/services/*_test.dart` | `flutter test` |
| Data repositories (Drift) | integration | Key query paths + error paths against a real `NativeDatabase` | `test/features/**/data/repositories/*_test.dart` | `flutter test` |
| Database schema / migration | integration | v5→v6 upgrade preserves seeded rows; new constraints enforced | `test/features/**/data/database/*_test.dart` | `flutter test` |
| Presentation cubits | unit | Every state transition named in the ACs | `test/features/**/presentation/cubit/*_test.dart` | `flutter test` |
| Presentation widgets | widget | Render + each interaction path in scope | `test/features/**/presentation/widgets/*_test.dart` | `flutter test` |
| Architecture invariants (AD-009, AD-010) | unit | Source-scanning assertions for the project-level constraints | `test/architecture/*_test.dart` | `flutter test` |
| Entities-only config / assets (`site_recipes.json`) | none | Build gate only (loader is covered by its registry unit tests) | — | `flutter analyze` |

## Gate Check Commands

> Generated from codebase (`.github/workflows/ci.yml`) — confirm before Execute.

| Gate Level | When to Use | Command |
| --- | --- | --- |
| Quick | After tasks with unit/widget tests only | `flutter test <task's test paths>` |
| Full | After tasks with integration tests, or any task touching shared pipeline code | `flutter test` |
| Build | After phase completion or config/asset-only tasks | `flutter analyze && flutter test && flutter build apk --debug` |

---

## Execution Plan

Phases are ordered and run sequentially — each phase completes before the next begins, and tasks within a phase execute in order.

### Phase 1: Data foundation

```
T1 → T2 → T3 → T4 → T5
```

### Phase 2: Shared ingest core

```
T6 → T7
```

### Phase 3: Network and parsing

```
T8 → T9 → T10 → T11
```

### Phase 4: Download orchestration

```
T12 → T13 → T14 → T15 → T16
```

### Phase 5: Import and library UI

```
T17 → T18 → T19 → T20
```

### Phase 6: Reader, narration boundary, wiring

```
T21 → T22 → T23 → T24
```

### Phase 7: P2 — updates and retry

```
T25 → T26
```

---

## Task Breakdown

### T1: Add source identity to the Book entity

**What**: Give `Book` a `sourceType`/`sourceRef` pair and make the three file fields nullable, with validation rejecting a book that has neither a file nor a source reference.
**Where**: `lib/features/library/domain/entities/book.dart`
**Depends on**: None
**Reuses**: Existing `copyWith`/`_unset` sentinel pattern and `TextProcessingValidationException`
**Requirement**: WEB-01, WEB-03

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] `sourceType` (`pdf` | `web`) and nullable `sourceRef` exist with storage mapping mirroring `BookStatus.fromStorage`
- [ ] `originalFileName`, `storedFilePath`, `fileHash` are nullable; `copyWith`, `==`, `hashCode` updated
- [ ] Constructor rejects a `pdf` book without a stored file and a `web` book without a `sourceRef`
- [ ] Gate check passes: `flutter test test/features/library`
- [ ] Test count: ≥6 tests pass (no silent deletions)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(library): add source identity to book entity`

---

### T2: Migrate the Books table to schema v6

**What**: Add `sourceType`/`sourceRef` columns, drop `NOT NULL` from the three file columns via `TableMigration`, add `books_source_ref_unique`, and bump `schemaVersion` to 6.
**Where**: `lib/features/library/data/database/books.dart`, `lib/core/database/app_database.dart`, `lib/features/library/data/repositories/` (row mapping)
**Depends on**: T1
**Reuses**: Existing `onUpgrade` step pattern; `UtcDateTimeConverter`
**Requirement**: WEB-03

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] `schemaVersion` is 6 with a `from < 6` upgrade step
- [ ] A v5 database seeded with PDF books upgrades with every column value preserved
- [ ] `books_file_hash_unique` still rejects duplicate non-null hashes and tolerates multiple nulls
- [ ] `books_source_ref_unique` rejects a duplicate series URL
- [ ] Gate check passes: `flutter test`
- [ ] Test count: ≥5 tests pass (no silent deletions)

**Tests**: integration
**Gate**: full
**Commit**: `feat(library): migrate books table for web sources`

---

### T3: Create the web_chapter_entries table

**What**: Add the Drift table holding the persisted chapter index/queue, with both unique indexes, wired into the v6 migration.
**Where**: `lib/features/web_source/data/database/web_chapter_entries.dart`, `lib/core/database/app_database.dart`
**Depends on**: T2
**Reuses**: `Chapters` table conventions; `UtcDateTimeConverter`; cascade-delete pattern
**Requirement**: WEB-11

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] Table created per design with `(bookId, sortOrder)` primary key and a unique `(bookId, url)` index
- [ ] Deleting a book cascades its entries away
- [ ] Inserting a duplicate `(bookId, url)` fails
- [ ] Gate check passes: `flutter test`
- [ ] Test count: ≥4 tests pass (no silent deletions)

**Tests**: integration
**Gate**: full
**Commit**: `feat(web-source): add chapter entry table`

---

### T4: Implement WebSourceRepository

**What**: Define the repository interface and its Drift implementation for index replacement, pending/failed queries, counts, and state marking.
**Where**: `lib/features/web_source/domain/repositories/web_source_repository.dart`, `lib/features/web_source/data/repositories/drift_web_source_repository.dart`
**Depends on**: T3
**Reuses**: `DriftTextProcessingRepository` transaction/batch style
**Requirement**: WEB-11, WEB-13, WEB-14

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] All eight interface methods implemented per design
- [ ] `pending` returns entries ordered by `sortOrder`, excluding `stored`
- [ ] `appendNew` adds only URLs absent from `knownUrls` and continues the `sortOrder` sequence
- [ ] `counts` reports total/stored/failed accurately after mixed marking
- [ ] Gate check passes: `flutter test`
- [ ] Test count: ≥8 tests pass (no silent deletions)

**Tests**: integration
**Gate**: full
**Commit**: `feat(web-source): add chapter queue repository`

---

### T5: Support incremental run activation

**What**: Add `activatePartialRun` and `updateRunCounts` to the processing repository and a `downloading` stage, so a run can be active while still growing.
**Where**: `lib/features/pdf_processing/domain/repositories/text_processing_repository.dart`, `.../data/repositories/drift_text_processing_repository.dart`, `.../domain/entities/text_processing_models.dart`
**Depends on**: T4
**Reuses**: Existing `activateRun` transaction body
**Requirement**: WEB-05

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] `activatePartialRun` sets the book's `activeContentRunId` and run state `active` without setting `completedAt`
- [ ] `updateRunCounts` updates chapter/block counts and progress on an already-active run
- [ ] `ProcessingStage.downloading` exists and round-trips through the converter
- [ ] Existing `activateRun` behaviour and its tests are unchanged
- [ ] Gate check passes: `flutter test`
- [ ] Test count: ≥6 tests pass (no silent deletions)

**Tests**: integration
**Gate**: full
**Commit**: `feat(processing): support incremental run activation`

---

### T6: Extract the shared ChapterIngest collaborator

**What**: Move the draft-building/splitting/persisting block out of `TextProcessingService` into `ChapterIngest` and delegate to it, with no behaviour change for PDF.
**Where**: `lib/features/content_ingestion/domain/services/chapter_ingest.dart`, `lib/features/pdf_processing/domain/services/text_processing_service.dart`
**Depends on**: T5
**Reuses**: `text_processing_service.dart:224-300` verbatim; `NarrationBlockSplitter`
**Requirement**: WEB-06, WEB-07

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] `ChapterIngest.ingest` matches the design signature and returns accurate counts
- [ ] `TextProcessingService` delegates and no longer builds drafts inline
- [ ] Every pre-existing `text_processing_service_test.dart` assertion passes **unchanged** (PDF parity)
- [ ] Calling `ingest` twice on one run appends rather than replacing
- [ ] Gate check passes: `flutter test`
- [ ] Test count: ≥6 new tests pass, existing suite green (no silent deletions)

**Tests**: unit
**Gate**: full
**Commit**: `refactor(processing): extract shared chapter ingest`

---

### T7: Add the site recipe model and registry

**What**: Define `SiteRecipe`, the JSON asset with the verified `centralnovel.com` recipe, and a registry that validates recipes at load and looks them up by host.
**Where**: `lib/features/web_source/domain/entities/site_recipe.dart`, `lib/features/web_source/domain/services/site_recipe_registry.dart`, `assets/site_recipes.json`, `pubspec.yaml` (asset entry)
**Depends on**: T6
**Reuses**: Enum storage-mapping pattern from `BookStatus`
**Requirement**: WEB-15

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] Recipe carries every field in the design, including `chapterIndexOrder` and `disallowedPathPatterns`
- [ ] A recipe missing a required field is rejected with a message naming that field
- [ ] Lookup by host returns the recipe; an unknown host returns null
- [ ] The shipped `centralnovel.com` entry matches the design's verified selectors exactly
- [ ] Gate check passes: `flutter test test/features/web_source`
- [ ] Test count: ≥6 tests pass (no silent deletions)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(web-source): add site recipe registry`

---

### T8: Implement PoliteWebFetcher

**What**: Build the single network adapter enforcing per-host throttling, `Retry-After`, bounded backoff, app User-Agent, and off-host redirect refusal.
**Where**: `lib/features/web_source/domain/services/web_fetcher.dart` (interface), `lib/features/web_source/data/services/polite_web_fetcher.dart`, `pubspec.yaml` (`http: ^1.6.0`)
**Depends on**: T7
**Reuses**: Injected-clock pattern from `TextProcessingService`
**Requirement**: WEB-09, WEB-10

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] Consecutive requests to one host are spaced ≥1s using an injected clock/delay (tests do not sleep in real time)
- [ ] `429` and `503` with `Retry-After` wait at least the stated duration
- [ ] Transient failures retry with exponential backoff to a bounded attempt count, then surface a failure
- [ ] A redirect to another host is abandoned and reported as `offDomain`
- [ ] Requests carry a descriptive app User-Agent
- [ ] Gate check passes: `flutter test test/features/web_source`
- [ ] Test count: ≥8 tests pass (no silent deletions)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(web-source): add polite web fetcher`

---

### T9: Parse chapter content from HTML

**What**: Implement recipe-driven chapter extraction (title + paragraph text) with the minimum-length rule, over a synthetic HTML fixture.
**Where**: `lib/features/web_source/data/services/html_recipe_parser.dart`, `test/fixtures/web_chapter.html`, `pubspec.yaml` (`html: ^0.15.6`)
**Depends on**: T8
**Reuses**: `SiteRecipe` selectors
**Requirement**: WEB-12

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] Extracts the chapter title and joins paragraph text in document order
- [ ] Content outside the recipe's container (nav, comments, ads) is excluded
- [ ] Text below `minimumChapterCharacters` yields an extraction failure, never a stored stub
- [ ] Missing content container yields an extraction failure naming the selector
- [ ] The fixture is a synthetic tag skeleton mirroring the site's structure, not copied prose
- [ ] Gate check passes: `flutter test test/features/web_source`
- [ ] Test count: ≥6 tests pass (no silent deletions)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(web-source): parse chapter content from html`

---

### T10: Parse the chapter index from HTML

**What**: Implement index extraction with direct-child anchor selection, descending-order reversal, deduplication, and the no-gap invariant.
**Where**: `lib/features/web_source/data/services/html_recipe_parser.dart` (extend), `test/fixtures/web_series_index.html`
**Depends on**: T9
**Reuses**: `SiteRecipe.chapterIndexSelector` / `chapterIndexOrder`
**Requirement**: WEB-01, WEB-15

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] `li > a` selection excludes the sibling `div.epl-pdf > a.dlpdf` links entirely (no `/pdf/` URL ever enters the index)
- [ ] A list item carrying the variant class (`li.tseplsfrst`) is included — the fixture contains one as its oldest entry
- [ ] A descending index is reversed so `sortOrder` 1 is the oldest chapter
- [ ] Repeated URLs collapse to one entry preserving first occurrence
- [ ] An index whose parsed count disagrees with its `/pdf/`-sibling count fails loudly rather than returning a short list
- [ ] Gate check passes: `flutter test test/features/web_source`
- [ ] Test count: ≥8 tests pass (no silent deletions)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(web-source): parse chapter index from html`

---

### T11: Implement WebNovelIndexResolver

**What**: Normalize any supported URL to its series URL and produce the ordered, validated index.
**Where**: `lib/features/web_source/domain/services/web_novel_index_resolver.dart`
**Depends on**: T10
**Reuses**: `WebFetcher`, `HtmlRecipeParser`, `SiteRecipeRegistry`
**Requirement**: WEB-01, WEB-02

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] A series URL resolves directly; a chapter URL resolves via the breadcrumb series link
- [ ] A chapter URL and its series URL produce identical indexes
- [ ] Host matching ignores a leading `www.` and is case-insensitive, so `https://WWW.centralnovel.com/...` resolves to the same recipe and the same canonical `sourceRef` as the bare host
- [ ] A non-absolute or non-`http(s)` URL is rejected before any request is issued
- [ ] An unknown host is rejected naming the domain, before any request
- [ ] A disallowed path is rejected naming the restriction, before any request
- [ ] An empty index surfaces the unsupported outcome
- [ ] Gate check passes: `flutter test test/features/web_source`
- [ ] Test count: ≥8 tests pass (no silent deletions)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(web-source): resolve novel index from url`

---

### T12: Drain the download queue into ChapterIngest

**What**: Implement the happy path of `WebNovelDownloadService.download` — fetch each pending entry in order, ingest it, and update progress and status.
**Where**: `lib/features/web_source/domain/services/web_novel_download_service.dart`
**Depends on**: T11
**Reuses**: `ChapterIngest`, `WebSourceRepository`, `activatePartialRun`/`updateRunCounts`, per-book run-map pattern
**Requirement**: WEB-04, WEB-05

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] The first stored chapter activates the run, making the book openable
- [ ] Each stored chapter's narration blocks exist immediately after that chapter is ingested
- [ ] Progress reports stored-over-total with stage `downloading`
- [ ] The book becomes `ready` only when every indexed chapter is stored
- [ ] Chapters are persisted in index order regardless of ingest timing
- [ ] Gate check passes: `flutter test`
- [ ] Test count: ≥8 tests pass (no silent deletions)

**Tests**: unit
**Gate**: full
**Commit**: `feat(web-source): drain chapter queue into ingest`

---

### T13: Handle chapter failures and retries

**What**: Add bounded retry with backoff, `failed` marking with a reason, and continuation past failures.
**Where**: `lib/features/web_source/domain/services/web_novel_download_service.dart` (extend)
**Depends on**: T12
**Reuses**: `PoliteWebFetcher` backoff; `markFailed`
**Requirement**: WEB-10

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] A transient failure retries to the bounded attempt count before being marked failed
- [ ] A `404` marks the entry failed without exhausting retries
- [ ] A failed chapter does not stop the queue; later chapters still download
- [ ] The book stays readable with the chapters already stored
- [ ] `attemptCount` and `lastError` are persisted per entry
- [ ] Gate check passes: `flutter test`
- [ ] Test count: ≥7 tests pass (no silent deletions)

**Tests**: unit
**Gate**: full
**Commit**: `feat(web-source): retry and record chapter failures`

---

### T14: Resume and cancel the queue

**What**: Make `download` resume from the first non-stored entry and make `cancel` stop requests while retaining stored chapters.
**Where**: `lib/features/web_source/domain/services/web_novel_download_service.dart` (extend)
**Depends on**: T13
**Reuses**: `_Cancellation` token pattern from `TextProcessingService`
**Requirement**: WEB-11

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] Restarting a partially downloaded book issues zero requests for already-stored chapters
- [ ] Resume begins at the lowest non-stored `sortOrder`
- [ ] Cancel stops further requests and retains every stored chapter
- [ ] A cancelled book can be resumed later and completes
- [ ] Gate check passes: `flutter test`
- [ ] Test count: ≥6 tests pass (no silent deletions)

**Tests**: unit
**Gate**: full
**Commit**: `feat(web-source): resume and cancel chapter downloads`

---

### T15: Mark an unrecognized layout unsupported

**What**: Terminate a book as `unsupported` when every chapter fails extraction, with the layout message.
**Where**: `lib/features/web_source/domain/services/web_novel_download_service.dart` (extend)
**Depends on**: T14
**Reuses**: `discardRun` terminal-status pattern
**Requirement**: WEB-12

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] All-chapters-fail-extraction marks the book `unsupported` with the layout message
- [ ] A mix of failures and successes never marks the book unsupported
- [ ] Network-only failures pause rather than mark unsupported
- [ ] Gate check passes: `flutter test`
- [ ] Test count: ≥4 tests pass (no silent deletions)

**Tests**: unit
**Gate**: full
**Commit**: `feat(web-source): flag unrecognized site layouts`

---

### T16: Assert the architectural invariants

**What**: Add source-scanning tests for AD-009 and AD-010 and for the global-lock and block-ordering risks.
**Where**: `test/architecture/web_source_architecture_test.dart`
**Depends on**: T15
**Reuses**: `test/architecture/foundation_architecture_test.dart` scanning style
**Requirement**: WEB-06 (design risk mitigations)

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] No file outside `polite_web_fetcher.dart` imports `package:http` (AD-010)
- [ ] `WebNovelDownloadService` does not reference the static processing tail (AD-009 / global-lock risk)
- [ ] A behavioural test asserts a PDF import proceeds while a web download is mid-queue
- [ ] A behavioural test appends a chapter after activation and asserts narration order follows `Chapters.sortOrder`, not chapter id
- [ ] Gate check passes: `flutter test`
- [ ] Test count: ≥4 tests pass (no silent deletions)

**Tests**: unit
**Gate**: full
**Commit**: `test(web-source): assert source architecture invariants`

---

### T17: Implement ImportWebBookService

**What**: Validate the URL, resolve the index, create or resolve the book, persist the index, and hand off to the download service.
**Where**: `lib/features/web_source/domain/services/import_web_book_service.dart`
**Depends on**: T16
**Reuses**: `ImportBookService` structure; `BookRepository`; `WebNovelIndexResolver`
**Requirement**: WEB-01, WEB-02, WEB-03

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] Validation runs in the design's order: URL form → known domain → allowed path → resolvable index → non-empty index
- [ ] A successful import creates a book carrying the series title, `sourceType: web`, and the canonical `sourceRef`
- [ ] Re-importing the same series resolves to the existing book and creates no second row
- [ ] A network failure during import leaves no partially created book
- [ ] Gate check passes: `flutter test`
- [ ] Test count: ≥9 tests pass (no silent deletions)

**Tests**: unit
**Gate**: full
**Commit**: `feat(web-source): import novels from a url`

---

### T18: Add ImportWebBookCubit

**What**: Presentation state for the web import flow.
**Where**: `lib/features/web_source/presentation/cubit/import_web_book_cubit.dart`, `.../import_web_book_state.dart`
**Depends on**: T17
**Reuses**: `ImportBookCubit`/`ImportBookState` shape; `bloc_test`
**Requirement**: WEB-01

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] States cover idle → submitting → success and each rejection reason as a distinct failure message
- [ ] Submitting twice does not start two imports
- [ ] Gate check passes: `flutter test test/features/web_source`
- [ ] Test count: ≥6 tests pass (no silent deletions)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(web-source): add web import cubit`

---

### T19: Add the URL import dialog

**What**: The dialog with a URL field, submit action, and inline error display, reachable from the library.
**Where**: `lib/features/web_source/presentation/widgets/import_web_book_dialog.dart`, `lib/features/library/presentation/pages/library_page.dart`
**Depends on**: T18
**Reuses**: `edit_book_dialog.dart` / `delete_book_dialog.dart` structure
**Requirement**: WEB-01

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] The dialog submits a URL and shows each failure message inline
- [ ] The library exposes an "Importar da web" affordance that opens it
- [ ] Submit is disabled while an import is in flight
- [ ] Gate check passes: `flutter test test/features/web_source test/features/library`
- [ ] Test count: ≥5 tests pass (no silent deletions)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(web-source): add url import dialog`

---

### T20: Show web books correctly in the library

**What**: Allow opening a web book while `processing` once a chapter exists, and hide PDF-only affordances for web books.
**Where**: `lib/features/library/presentation/widgets/book_list_item.dart`, `.../book_grid_item.dart`
**Depends on**: T19
**Reuses**: Existing status-switch rendering
**Requirement**: WEB-04

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] A web book with ≥1 stored chapter offers Open while `processing`
- [ ] A web book with zero stored chapters does not offer Open
- [ ] A PDF book still requires `ready` to offer Open
- [ ] Download progress renders as stored/total chapters
- [ ] Gate check passes: `flutter test test/features/library`
- [ ] Test count: ≥6 tests pass (no silent deletions)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(library): surface web book download state`

---

### T21: Hide the original-document view for web books

**What**: The reader offers only the text view when the book has no local file.
**Where**: `lib/features/visual_reader/presentation/pages/reader_page.dart`
**Depends on**: T20
**Reuses**: Existing view-toggle logic
**Requirement**: WEB-06

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] A web book renders `TextReaderView` and never mounts `OriginalPdfView`
- [ ] A PDF book still offers both views
- [ ] Gate check passes: `flutter test test/features/visual_reader`
- [ ] Test count: ≥4 tests pass (no silent deletions)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(reader): hide pdf view for web books`

---

### T22: Handle the narration download boundary

**What**: When narration reaches the last loaded block with entries still pending, reload content once; if nothing new exists, report awaiting-download instead of end-of-book.
**Where**: `lib/features/narration/domain/services/narration_queue.dart`, `lib/features/narration/presentation/cubit/narration_cubit.dart`
**Depends on**: T21
**Reuses**: `NarrationQueue.next`; existing cubit completion path
**Requirement**: WEB-04

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] Reaching the last block with pending entries triggers exactly one content reload
- [ ] If the reload yields new chapters, narration continues into them without user action
- [ ] If it yields nothing, the state reports awaiting-download, distinct from end-of-book
- [ ] A fully downloaded book still reports end-of-book at its last block
- [ ] Gate check passes: `flutter test test/features/narration`
- [ ] Test count: ≥6 tests pass (no silent deletions)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(narration): stop at the download boundary`

---

### T23: Wire the web source into dependency injection

**What**: Register every web-source collaborator in the composition root and declare the new dependencies and asset.
**Where**: `lib/app/dependency_injection/configure_dependencies.dart`, `pubspec.yaml`
**Depends on**: T22
**Reuses**: Existing `get_it` registration style (AD-003)
**Requirement**: WEB-01

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] All web-source services resolve from the container
- [ ] `http`, `html`, and the recipes asset are declared in `pubspec.yaml`
- [ ] The existing DI test still passes and covers the new registrations
- [ ] Gate check passes: `flutter analyze && flutter test && flutter build apk --debug`
- [ ] Test count: ≥4 tests pass (no silent deletions)

**Tests**: unit
**Gate**: build
**Commit**: `feat(app): register web source dependencies`

---

### T24: End-to-end web source integration test

**What**: One integration test over a real database driving import → partial download → narrate → restart/resume → complete → offline read.
**Where**: `test/features/web_source/web_source_integration_test.dart`
**Depends on**: T23
**Reuses**: `narration_integration_test.dart` database setup; fake fetcher over fixtures
**Requirement**: WEB-04, WEB-05, WEB-11

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] Import from a chapter URL produces the full index against the fixture
- [ ] Narration plays a chapter while the queue still has pending entries
- [ ] A simulated restart resumes without re-fetching stored chapters
- [ ] After completion, a fetcher that throws on any call proves reading and narration issue zero requests
- [ ] Gate check passes: `flutter test`
- [ ] Test count: ≥5 tests pass (no silent deletions)

**Tests**: integration
**Gate**: full
**Commit**: `test(web-source): cover the end-to-end web flow`

---

### T25: Fetch new chapters for an ongoing novel

**What**: Implement `fetchNewChapters` plus its library affordance.
**Where**: `lib/features/web_source/domain/services/web_novel_download_service.dart`, `lib/features/library/presentation/widgets/book_list_item.dart`
**Depends on**: T24
**Reuses**: `appendNew`, `knownUrls`, `WebNovelIndexResolver`
**Requirement**: WEB-13

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] Only chapters absent from the local index are appended, after the existing ones
- [ ] An unchanged index reports up-to-date and modifies nothing
- [ ] Reader and narration positions are unchanged by an append
- [ ] A failed update leaves stored chapters untouched
- [ ] The library affordance appears for web books and is absent for PDF books
- [ ] Gate check passes: `flutter test`
- [ ] Test count: ≥6 tests pass (no silent deletions)

**Tests**: widget
**Gate**: full
**Commit**: `feat(web-source): fetch newly published chapters`

---

### T26: Retry failed chapters

**What**: Implement `retryFailed` plus the failed-count display and retry action.
**Where**: `lib/features/web_source/domain/services/web_novel_download_service.dart`, `lib/features/library/presentation/widgets/book_list_item.dart`
**Depends on**: T25
**Reuses**: `failed`, `counts`, existing retry path from T13
**Requirement**: WEB-14

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] Retry re-enqueues only `failed` entries under the same throttle and backoff
- [ ] A succeeding retry updates progress and can complete the book to `ready`
- [ ] The failed count is displayed when non-zero and hidden at zero
- [ ] Gate check passes: `flutter test`
- [ ] Test count: ≥6 tests pass (no silent deletions)

**Tests**: widget
**Gate**: full
**Commit**: `feat(web-source): retry failed chapters`

---

### T27: Clean web chapter text before ingest

**What**: Run `TextCleaner` over each extracted web chapter with a neutral profile, so web and PDF share one cleaning path.
**Where**: `lib/features/web_source/domain/services/web_novel_download_service.dart`
**Depends on**: T16
**Reuses**: `TextCleaner`, `HeaderFooterProfile`
**Requirement**: WEB-06, WEB-07

**Tools**: MCP: NONE · Skill: NONE

**Origin**: Gap found after Phase 4. `spec.md` (Assumptions: "Cleaning for web
chapters") states `TextCleaner` still runs on web input and `design.md` lists it
as a reused component with a neutral profile, but no task T1-T26 assigned it, so
the download service passed raw extracted text to `ChapterIngest`.

**Done when**:
- [ ] Extracted chapter text passes through `TextCleaner` before reaching `ChapterIngest`
- [ ] The profile carries no PDF-derived repeated header/footer entries
- [ ] A short standalone line in a web chapter survives cleaning (design.md risk row)
- [ ] Cleaning removes what it removes for PDF input given the same text
- [ ] Existing Phase 4 download tests pass unchanged
- [ ] Gate check passes: `flutter test test/features/web_source`
- [ ] Test count: >=4 new tests pass (no silent deletions)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(web-source): clean chapter text before ingest`

---

### T28: Let the reader load a growing web book

**What**: Allow reader content to load while a web book is still `processing`, and tolerate the holes a failed chapter leaves in the chapter sequence.
**Where**: `lib/features/visual_reader/domain/entities/reader_models.dart`, `lib/features/visual_reader/data/repositories/drift_visual_reader_repository.dart`
**Depends on**: T20
**Reuses**: Existing `ReaderBookContent` validation and `loadContent` query
**Requirement**: WEB-04

**Tools**: MCP: NONE · Skill: NONE

**Origin**: Gap found after Phase 4. T20 makes the library offer Open for a web
book with >=1 stored chapter (WEB-04 AC2), but `loadContent` requires
`status == ready` and `ReaderBookContent` requires `chapters[i].sortOrder == i`,
so opening such a book throws. The spec's 404 edge case makes holes an expected
state, not an error.

**Done when**:
- [ ] A web book with status `processing` and >=1 stored chapter loads its reader content
- [ ] A web book whose chapter 2 failed (stored orders 0 and 2) loads without throwing
- [ ] `ReaderBookContent` rejects out-of-order or duplicate chapter sort orders
- [ ] A PDF book still requires `ready` — its existing reader tests pass unchanged
- [ ] Reader position resume still resolves to the correct chapter across a hole
- [ ] Gate check passes: `flutter test`
- [ ] Test count: >=6 new tests pass (no silent deletions)

**Tests**: unit, integration
**Gate**: full
**Commit**: `feat(reader): load web books while chapters download`

---

### F1: Resume pending web downloads when the app starts

**What**: Re-enqueue every web book left `processing` with unstored chapters, so an interrupted download continues after a restart.
**Where**: `lib/app/dependency_injection/configure_dependencies.dart`, `lib/features/web_source/domain/services/web_novel_download_service.dart`
**Depends on**: T23
**Reuses**: `WebNovelDownloadService.download` (already resumes from the first unstored chapter), `BookRepository`
**Requirement**: WEB-11

**Tools**: MCP: NONE · Skill: NONE

**Origin**: Verifier gap 1 (blocker). `download` had exactly one call site — the
import flow — so the tested resume logic was never triggered on restart. The
feature's own integration test supplied the trigger itself.

**Done when**:
- [ ] Starting the app re-enqueues each web book with status `processing` and at least one unstored chapter
- [ ] A web book with every chapter stored is not re-enqueued
- [ ] A PDF book is never handed to the web download service
- [ ] Resume issues no request for a chapter already stored
- [ ] Startup does not await the download — composition returns before the queue drains (awaiting real I/O during composition deadlocks `testWidgets`)
- [ ] Gate check passes: `flutter test`
- [ ] Test count: >=5 new tests pass (no silent deletions)

**Tests**: unit, integration
**Gate**: full
**Commit**: `fix(web-source): resume pending downloads on startup`

---

### F2: Hold the per-host rate limit under concurrent drains

**What**: Reserve a host's next slot synchronously, before awaiting, so two concurrent downloads cannot read the same stale timestamp and fire together.
**Where**: `lib/features/web_source/data/services/polite_web_fetcher.dart`
**Depends on**: None
**Reuses**: Existing `_throttle` and injected clock/delay seams
**Requirement**: WEB-09

**Tools**: MCP: NONE · Skill: NONE

**Origin**: Verifier gap 2. `_throttle` read `_lastRequestAt`, awaited, then
wrote — so concurrent callers to one host both fired immediately. Reproduced as
request gaps of `[1s, 0s]`. The fetcher is a DI singleton, so two web books
draining at once race. Spec edge case E8 had no test.

**Done when**:
- [ ] Two concurrent fetches to one host are spaced by at least `minimumHostInterval`
- [ ] Two concurrent fetches to different hosts are not serialized against each other
- [ ] Sequential fetches keep their existing spacing — the current throttle tests pass unchanged
- [ ] `Retry-After` handling still wins over the base interval
- [ ] Tests drive concurrency with the injected clock/delay, never real sleeps
- [ ] Gate check passes: `flutter test test/features/web_source`
- [ ] Test count: >=4 new tests pass (no silent deletions)

**Tests**: unit
**Gate**: quick
**Commit**: `fix(web-source): hold the host rate limit under concurrency`

---

### F3: Make the library cancel action stop a web download

**What**: Route the existing cancel affordance to `WebNovelDownloadService.cancel` when the book's source is web.
**Where**: `lib/features/library/presentation/pages/library_page.dart`, `lib/app/dependency_injection/configure_dependencies.dart`
**Depends on**: F1
**Reuses**: `WebNovelDownloadService.cancel`, existing cancel wiring for PDF
**Requirement**: WEB-11

**Tools**: MCP: NONE · Skill: NONE

**Origin**: Verifier gap 3. A downloading web book is `processing`, so the
library renders "Cancelar processamento", which routed to
`TextProcessingService.cancel` — it finds no run for a web book and returns, so
the button was visible and inert.

**Done when**:
- [ ] Cancelling a web book calls the web download service and stops the queue
- [ ] Cancelling a PDF book still routes to `TextProcessingCubit.cancel`
- [ ] Chapters already stored survive the cancel
- [ ] Gate check passes: `flutter test test/features/library && flutter test test/app`
- [ ] Test count: >=4 new tests pass (no silent deletions)

**Tests**: widget, unit
**Gate**: full
**Commit**: `fix(library): cancel web downloads from the library`

---

### F4: Persist the downloading stage for a web book

**What**: Let a web run actually reach `ProcessingStage.downloading`, and make the download tests able to catch it if it does not.
**Where**: `lib/features/pdf_processing/data/repositories/drift_text_processing_repository.dart`, `lib/features/pdf_processing/domain/repositories/text_processing_repository.dart`
**Depends on**: None
**Reuses**: Existing `createRun` / `updateProgress` monotonic-stage rule
**Requirement**: WEB-04

**Tools**: MCP: NONE · Skill: NONE

**Origin**: Found by the Phase 5 worker, confirmed by the orchestrator, missed by
the Verifier. `createRun` hardcodes `ProcessingStage.extracting` (index 1) and
`updateProgress` drops any stage whose index is lower, while `downloading` is
index 0 — so every `updateProgress(stage: downloading)` is silently discarded and
a web book's persisted stage stays `extracting` for the whole download. The
download service's fake repository has no stage guard, so no unit test saw it.

**Done when**:
- [ ] A web book's persisted `processingStage` is `downloading` while its queue drains
- [ ] The PDF path still starts at `extracting` and its stage sequence is unchanged
- [ ] The monotonic-stage rule still rejects a genuine backwards transition
- [ ] The download service's fake processing repository enforces the same stage rule the Drift repository does, so this class of defect fails a unit test
- [ ] Gate check passes: `flutter test`
- [ ] Test count: >=4 new tests pass (no silent deletions)

**Tests**: unit, integration
**Gate**: full
**Commit**: `fix(processing): persist the downloading stage`

---

### F5: Assert heuristic chapter detection never runs on a web source

**What**: Make WEB-08 AC3 directly observable instead of inferring it from matching counts.
**Where**: `test/features/web_source/domain/services/web_novel_download_service_test.dart`
**Depends on**: None
**Reuses**: Existing download-service test harness
**Requirement**: WEB-08

**Tools**: MCP: NONE · Skill: NONE

**Origin**: Verifier gap 5. Coverage was indirect — chapter counts matching index
entries 1:1 — with no assertion that `ChapterDetector` is never invoked.

**Done when**:
- [ ] A test asserts `ChapterDetector` is not invoked for a web chapter ingest
- [ ] The assertion fails if the web path is changed to run detection
- [ ] Index segmentation is still asserted 1:1 against the stored entries
- [ ] Gate check passes: `flutter test test/features/web_source`
- [ ] Test count: >=2 new tests pass (no silent deletions)

**Tests**: unit
**Gate**: quick
**Commit**: `test(web-source): assert index segmentation skips detection`

---

## Phase Execution Map

```
Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7

Phase 1:  T1 ──→ T2 ──→ T3 ──→ T4 ──→ T5
Phase 2:  T6 ──→ T7
Phase 3:  T8 ──→ T9 ──→ T10 ──→ T11
Phase 4:  T12 ──→ T13 ──→ T14 ──→ T15 ──→ T16
Phase 4b: T27
Phase 5:  T17 ──→ T18 ──→ T19 ──→ T20
Phase 6:  T28 ──→ T21 ──→ T22 ──→ T23 ──→ T24
Phase 7:  T25 ──→ T26
```

Execution is strictly sequential — there is no intra-phase parallelism.

**Batch packing** (~7 tasks per worker, whole phases only):

Approved delivery scope for this round is **T1–T24 plus T27–T28 (all P1)**.
T27 and T28 were added after Phase 4 to close two spec behaviours that no
original task claimed; the user approved both. Phase 7 (T25–T26, both P2) is
specified and stays unstarted until the MVP has been used.

| Batch | Phases | Tasks | Count | Status |
| --- | --- | --- | --- | --- |
| 1 | Phase 1 + Phase 2 | T1–T7 | 7 | Complete |
| 2 | Phase 3 | T8–T11 | 4 | Complete |
| 3 | Phase 4 | T12–T16 | 5 | Complete |
| 4b | Phase 4b | T27 | 1 | Complete |
| 4 | Phase 5 + Phase 6 | T17–T20, T28, T21–T24 | 9 | Complete |
| 5 | Verifier fixes | F1–F5 | 5 | Complete |
| — | Phase 7 | T25–T26 | 2 | Deferred (P2, out of this round) |

The Verifier runs automatically after T24 — the last task of the P1 group being
delivered on its own.

---

## Task Granularity Check

| Task | Scope | Status |
| --- | --- | --- |
| T1 | 1 entity | ✅ Granular |
| T2 | 1 table + migration step | ✅ Granular |
| T3 | 1 table | ✅ Granular |
| T4 | 1 interface + 1 implementation (cohesive) | ✅ Granular |
| T5 | 2 repository methods + 1 enum value (cohesive) | ✅ Granular |
| T6 | 1 extraction refactor | ✅ Granular |
| T7 | 1 registry + its asset | ✅ Granular |
| T8 | 1 adapter | ✅ Granular |
| T9 | 1 parser method | ✅ Granular |
| T10 | 1 parser method | ✅ Granular |
| T11 | 1 service | ✅ Granular |
| T12 | 1 service method (happy path) | ✅ Granular |
| T13 | 1 concern on 1 service | ✅ Granular |
| T14 | 1 concern on 1 service | ✅ Granular |
| T15 | 1 terminal state | ✅ Granular |
| T16 | 1 test file | ✅ Granular |
| T17 | 1 service | ✅ Granular |
| T18 | 1 cubit + state | ✅ Granular |
| T19 | 1 dialog + entry point | ✅ Granular |
| T20 | 2 sibling widgets, same change | ✅ Granular |
| T21 | 1 page condition | ✅ Granular |
| T22 | 1 boundary behaviour | ✅ Granular |
| T23 | 1 composition root | ✅ Granular |
| T24 | 1 test file | ✅ Granular |
| T25 | 1 method + 1 affordance | ✅ Granular |
| T26 | 1 method + 1 affordance | ✅ Granular |

---

## Diagram-Definition Cross-Check

| Task | Depends On (body) | Diagram Shows | Status |
| --- | --- | --- | --- |
| T1 | None | (phase start) | ✅ Match |
| T2 | T1 | T1 → T2 | ✅ Match |
| T3 | T2 | T2 → T3 | ✅ Match |
| T4 | T3 | T3 → T4 | ✅ Match |
| T5 | T4 | T4 → T5 | ✅ Match |
| T6 | T5 | T5 → T6 (phase 1 → 2) | ✅ Match |
| T7 | T6 | T6 → T7 | ✅ Match |
| T8 | T7 | T7 → T8 (phase 2 → 3) | ✅ Match |
| T9 | T8 | T8 → T9 | ✅ Match |
| T10 | T9 | T9 → T10 | ✅ Match |
| T11 | T10 | T10 → T11 | ✅ Match |
| T12 | T11 | T11 → T12 (phase 3 → 4) | ✅ Match |
| T13 | T12 | T12 → T13 | ✅ Match |
| T14 | T13 | T13 → T14 | ✅ Match |
| T15 | T14 | T14 → T15 | ✅ Match |
| T16 | T15 | T15 → T16 | ✅ Match |
| T17 | T16 | T16 → T17 (phase 4 → 5) | ✅ Match |
| T18 | T17 | T17 → T18 | ✅ Match |
| T19 | T18 | T18 → T19 | ✅ Match |
| T20 | T19 | T19 → T20 | ✅ Match |
| T21 | T20 | T20 → T21 (phase 5 → 6) | ✅ Match |
| T22 | T21 | T21 → T22 | ✅ Match |
| T23 | T22 | T22 → T23 | ✅ Match |
| T24 | T23 | T23 → T24 | ✅ Match |
| T25 | T24 | T24 → T25 (phase 6 → 7) | ✅ Match |
| T26 | T25 | T25 → T26 | ✅ Match |

No task depends on a later phase.

---

## Test Co-location Validation

| Task | Code Layer Created/Modified | Matrix Requires | Task Says | Status |
| --- | --- | --- | --- | --- |
| T1 | Domain entity | unit | unit | ✅ OK |
| T2 | Database schema / migration | integration | integration | ✅ OK |
| T3 | Database schema | integration | integration | ✅ OK |
| T4 | Data repository (Drift) | integration | integration | ✅ OK |
| T5 | Data repository + entity enum | integration | integration | ✅ OK |
| T6 | Domain service | unit | unit | ✅ OK |
| T7 | Domain service + config asset | unit (highest) | unit | ✅ OK |
| T8 | Data adapter | unit | unit | ✅ OK |
| T9 | Data adapter | unit | unit | ✅ OK |
| T10 | Data adapter | unit | unit | ✅ OK |
| T11 | Domain service | unit | unit | ✅ OK |
| T12 | Domain service | unit | unit | ✅ OK |
| T13 | Domain service | unit | unit | ✅ OK |
| T14 | Domain service | unit | unit | ✅ OK |
| T15 | Domain service | unit | unit | ✅ OK |
| T16 | Architecture invariants | unit | unit | ✅ OK |
| T17 | Domain service | unit | unit | ✅ OK |
| T18 | Presentation cubit | unit | unit | ✅ OK |
| T19 | Presentation widget | widget | widget | ✅ OK |
| T20 | Presentation widget | widget | widget | ✅ OK |
| T21 | Presentation widget | widget | widget | ✅ OK |
| T22 | Domain service + cubit | unit | unit | ✅ OK |
| T23 | Composition root | unit | unit | ✅ OK |
| T24 | Integration | integration | integration | ✅ OK |
| T25 | Domain service + widget | widget (highest) | widget | ✅ OK |
| T26 | Domain service + widget | widget (highest) | widget | ✅ OK |

All 26 tasks pass. No task defers its tests to a later task.
