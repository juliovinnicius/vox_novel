# Visual Reader Design

**Spec**: `.specs/features/visual_reader/spec.md`
**Context**: `.specs/features/visual_reader/context.md`
**Status**: Approved

---

## Approach Selection

The approved approach creates an isolated `visual_reader` feature with its own
domain models, repository contract, Drift implementation, Cubit, and focused
widgets. It consumes active processing data but does not extend or couple
reader state to the text-processing orchestration.

Alternatives rejected:

- Extending `pdf_processing` would mix content production with consumption.
- Keeping persistence and navigation inside `ReaderPage` would make lifecycle,
  ordering, and failure behavior difficult to test independently.

---

## Architecture Overview

```mermaid
graph TD
    L[LibraryPage / ready book] --> R[/reader/:bookId]
    R --> P[ReaderPage]
    P --> C[VisualReaderCubit]
    C --> RR[VisualReaderRepository]
    RR --> DB[(Drift / SQLite)]
    DB --> B[Book + active run]
    DB --> CH[Ordered chapters + blocks]
    DB --> POS[Reader position]
    DB --> SET[Global reader settings]
    C --> T[TextReaderView]
    C --> PDF[OriginalPdfView]
    PDF --> A[Pdfrx viewer adapter]
```

The route receives only `bookId`. The composition root resolves a Cubit factory
for that ID, preventing route arguments from carrying stale domain objects.
The Cubit loads one immutable `ReaderBookContent` aggregate, validates/restores
position, and owns all deterministic state transitions. Presentation widgets
render state and forward intent; they do not query Drift.

---

## Code Reuse Analysis

### Existing Components to Leverage

| Component | Location | How to Use |
| --- | --- | --- |
| `Book` and `BookRepository` | `lib/features/library/domain/` | Validate that the route target exists and is `ready`; reuse exact title/path/page metadata |
| Processed chapter/block entities | `lib/features/pdf_processing/domain/entities/text_processing_models.dart` | Reuse immutable chapter and block payloads in the reader aggregate |
| Drift active-run schema | `lib/features/pdf_processing/data/database/` | Join active run, chapters, and blocks without duplicating novel content |
| Feature-first/Cubit pattern | `lib/features/*/presentation/cubit/` | Match immutable state and callback-driven Cubit conventions |
| GetIt composition | `lib/app/dependency_injection/configure_dependencies.dart` | Register repository singleton and route-scoped Cubit factory |
| `go_router` | `lib/app/router/app_router.dart` | Add `/reader/:bookId` and keep root library route |
| `pdfrx 2.4.7` | existing dependency | Use `PdfViewer.file`, `initialPageNumber`, `PdfViewerController.goToPage`, `onPageChanged`, and custom error surface |
| Existing Material/accessibility style | library pages/widgets | Preserve tooltips, semantics, header labels, and disabled controls |

### Integration Points

| System | Integration Method |
| --- | --- |
| Library list/grid | Add an `onOpen` callback; ready items expose an accessible open action while non-ready items remain disabled |
| Database | Schema version 4 adds `reader_settings` and `reader_positions`; position references `books(id) ON DELETE CASCADE` |
| Active processed content | Reader query anchors to `books.activeContentRunId` and orders chapters then blocks by their numeric `sortOrder` |
| Application router | Inject a `readerPageBuilder(bookId)` seam for tests and a production builder backed by GetIt |
| Application lifecycle | GetIt disposes each route Cubit; Cubit awaits pending ordered writes before close |
| PDF engine | Production-only widget adapter contains `pdfrx`; reader state remains package-agnostic and testable |

---

## Components

### Reader domain models

- **Purpose**: Express validated settings, visual position, mode, and complete
  active content without database or widget types.
- **Location**: `lib/features/visual_reader/domain/entities/`
- **Interfaces**:
  - `ReaderSettings.defaults()` — exact global defaults.
  - `ReaderSettings.copyWith(...)` — validates theme, family, size, line height.
  - `ReaderPosition` — one per book; validates mode/page/identity shape.
  - `ReaderBookContent` — book plus source-ordered chapters and their blocks.
  - `ReaderChapter` — chapter payload with its already ordered block list.
- **Dependencies**: `Book`, `ChapterDraft`, `NarrationBlockDraft`.
- **Reuses**: Milestone 2 immutable processed entities.

### VisualReaderRepository

- **Purpose**: Load one valid active reader aggregate and atomically persist
  global settings/per-book position.
- **Location**:
  `lib/features/visual_reader/domain/repositories/visual_reader_repository.dart`
- **Interfaces**:
  - `Future<ReaderBookContent?> loadBook(String bookId)`
  - `Future<ReaderSettings> loadSettings()`
  - `Future<void> saveSettings(ReaderSettings settings)`
  - `Future<ReaderPosition?> loadPosition(String bookId)`
  - `Future<void> savePosition(ReaderPosition position)`
- **Dependencies**: none at contract level.
- **Reuses**: established repository abstraction style.

### DriftVisualReaderRepository

- **Purpose**: Implement active-run validation, source-order queries, atomic
  settings upsert, per-book serialized position upsert, and stale-position
  repair support.
- **Location**:
  `lib/features/visual_reader/data/repositories/drift_visual_reader_repository.dart`
- **Interfaces**: implements `VisualReaderRepository`.
- **Dependencies**: `AppDatabase`.
- **Reuses**: Drift converters, transactions, foreign-key cascades.
- **Ordering rule**: query chapters by `chapters.sortOrder`; for each ordered
  chapter query/associate blocks by `narrationBlocks.sortOrder`. No lexical ID
  ordering is used.

### VisualReaderCubit

- **Purpose**: Own loading, validation, mode switching, text/PDF mapping,
  chapter/block selection, bounded settings changes, ordered persistence, and
  sanitized transient errors.
- **Location**:
  `lib/features/visual_reader/presentation/cubit/visual_reader_cubit.dart`
- **Interfaces**:
  - `load(bookId)`
  - `selectBlock(chapterId, blockId)`
  - `selectChapter(chapterId)`
  - `previousChapter()` / `nextChapter()`
  - `showText()` / `showPdf()`
  - `pageChanged(page)`
  - `setTheme(theme)` / `setFontFamily(family)`
  - `increaseFont()` / `decreaseFont()` / `setLineHeight(value)`
  - `clearMessage()`
- **Dependencies**: `VisualReaderRepository`, clock.
- **Reuses**: Cubit immutable-state/error-message conventions.

State shape:

```text
VisualReaderState
  status: initial | loading | ready | unavailable
  content: ReaderBookContent?
  settings: ReaderSettings
  mode: text | pdf
  chapterId: String?
  blockId: String?
  pdfPage: int
  message: String?
```

Selection validation is centralized:

1. Match position against the loaded active aggregate.
2. For valid text mode, retain exact chapter/block.
3. For stale identities, choose first chapter and first block (nullable for an
   empty chapter), then request a repair write.
4. Clamp PDF page to `1...book.pageCount`; zero pages makes PDF unavailable.

Position writes use a per-Cubit future tail. Every request captures a complete
immutable position, chains after the preceding write, and handles its own
failure. `close()` awaits the tail. Thus request order, not completion timing,
defines the durable winner.

### ReaderPage

- **Purpose**: Provide the route-level scaffold, app bar controls, end drawer,
  settings sheet, loading/unavailable states, and Cubit lifecycle.
- **Location**:
  `lib/features/visual_reader/presentation/pages/reader_page.dart`
- **Interfaces**: `ReaderPage(bookId, cubit, pdfViewBuilder?)`.
- **Dependencies**: `VisualReaderCubit`, `TextReaderView`, `OriginalPdfView`.
- **Reuses**: Material scaffold, BlocProvider/BlocListener patterns.

### TextReaderView

- **Purpose**: Render one current chapter's title and lazily built ordered
  blocks, highlight/semantics, empty state, and chapter boundary controls.
- **Location**:
  `lib/features/visual_reader/presentation/widgets/text_reader_view.dart`
- **Interfaces**: immutable view model plus selection/navigation callbacks.
- **Dependencies**: Flutter scroll/semantics APIs.
- **Reuses**: exact `NarrationBlockDraft.originalText`.

Each block has a stable key by block ID. A controller/key registry scrolls only
the restored or newly selected target into view after layout. `ListView.builder`
prevents eager widget creation for large chapters.

### ChapterDrawer

- **Purpose**: Render exact source-ordered chapter titles and current selection.
- **Location**:
  `lib/features/visual_reader/presentation/widgets/chapter_drawer.dart`
- **Interfaces**: chapters, current ID, `onSelect`.
- **Dependencies**: Material navigation widgets.
- **Reuses**: chapter domain payloads.

### ReaderSettingsSheet

- **Purpose**: Render the three themes and bounded typography controls.
- **Location**:
  `lib/features/visual_reader/presentation/widgets/reader_settings_sheet.dart`
- **Interfaces**: settings plus change callbacks.
- **Dependencies**: reader domain enums.
- **Reuses**: Cubit-driven immediate state updates.

### OriginalPdfView / Pdfrx adapter

- **Purpose**: Isolate the native PDF widget, controller, callbacks, page label,
  and standard unavailable state.
- **Location**:
  `lib/features/visual_reader/presentation/widgets/original_pdf_view.dart`
- **Interfaces**:
  - `OriginalPdfView(path, initialPage, expectedPages, onPageChanged)`
  - injectable `PdfSurfaceBuilder` used by widget/root tests.
- **Dependencies**: production adapter uses `pdfrx 2.4.7`.
- **Reuses**: the already initialized PDF engine from the composition root.

The production surface constructs `PdfViewer.file` with one-based
`initialPageNumber`, listens through `PdfViewerParams.onPageChanged`, reports
document page count, uses `PdfViewerController.goToPage` for state-driven
changes, and replaces package errors with the exact product message.

---

## Data Models

### ReaderSettings table/domain

```text
reader_settings
  id: INTEGER PRIMARY KEY CHECK(id = 1)
  theme: TEXT NOT NULL          // light | sepia | dark
  font_family: TEXT NOT NULL    // sans | serif
  font_size: INTEGER NOT NULL   // 14..32, even
  line_height: REAL NOT NULL    // 1.2 | 1.5 | 1.8 | 2.0
  updated_at: INTEGER NOT NULL UTC
```

No row means exact defaults. Saving performs one transaction/upsert of the
complete preference set, preventing mixed old/new fields.

### ReaderPosition table/domain

```text
reader_positions
  book_id: TEXT PRIMARY KEY REFERENCES books(id) ON DELETE CASCADE
  mode: TEXT NOT NULL           // text | pdf
  chapter_id: TEXT NULL
  block_id: TEXT NULL
  pdf_page: INTEGER NOT NULL DEFAULT 1
  updated_at: INTEGER NOT NULL UTC
```

Chapter/block references are deliberately not foreign keys: reprocessing
replaces the active run and cascades old derived rows. Retaining the stored IDs
allows the reader to detect and repair a stale position deterministically.
Book deletion still cascades the entire position.

### ReaderBookContent

```text
ReaderBookContent
  book: Book
  chapters: List<ReaderChapter>

ReaderChapter
  chapter: ChapterDraft
  blocks: List<NarrationBlockDraft>
```

Construction copies lists as unmodifiable and asserts:

- book status is `ready` with a non-null active run;
- chapter orders are contiguous/source ordered;
- each block belongs to its containing chapter;
- block orders are contiguous inside each chapter.

---

## Database Migration

`AppDatabase.schemaVersion` advances from 3 to 4.

- Fresh databases create all seven tables.
- Upgrade `from < 4` creates `reader_settings` and `reader_positions`.
- Foreign keys remain enabled before open.
- Migration tests seed a schema-v3 database, upgrade it, assert old book and
  processed rows remain exact, then round-trip new reader state.
- Generated Drift output is updated through the existing build-runner command.

---

## Text/PDF Mapping

All page numbers are one-based.

```text
text → PDF
  selected block.startPage
  else current chapter.startPage
  else 1

PDF → text
  first chapter by sortOrder containing page
    → first block by sortOrder in that chapter containing page
    → otherwise chapter with null block
  no matching chapter
    → retain prior valid text selection
```

The mapping is pure and lives in a domain service
`ReaderPositionResolver`, enabling exhaustive tests without widgets or PDF
engine access.

---

## Error Handling Strategy

| Error Scenario | Handling | User Impact |
| --- | --- | --- |
| Book absent/not ready/no active content | Repository returns null; Cubit enters unavailable | `Conteúdo do livro indisponível` and return action |
| Content query/validation failure | Sanitize to unavailable; do not expose SQL/content | Same unavailable state |
| Missing/corrupt PDF or zero pages | PDF adapter reports unavailable only for PDF surface | `Não foi possível abrir o PDF original`; text control remains |
| Settings load failure | Use exact defaults and expose one transient save/load message only when actionable | Reader still opens with defaults |
| Settings save failure | Retain requested in-memory values; one transient message | `Não foi possível salvar suas configurações` |
| Position save failure | Retain current state and continue later writes in order | `Não foi possível salvar sua posição` once for failed write |
| Stale position | Resolve first valid content, persist repair | No blocking error |
| Cubit closes during pending write | Await ordered tail before close | Latest requested position is not abandoned |

---

## Test Strategy

| Layer | Required evidence |
| --- | --- |
| Domain models/resolver | Exact defaults/bounds; text↔PDF mapping; stale/cross-chapter identity; empty content; Unicode preservation |
| Drift schema/repository | Fresh v4; v3 upgrade retention; exact settings/position round trips; active-run filtering; chapter+block numeric order; cascade; overlapping saves |
| Cubit | Every state transition and exact message; selection; boundaries; settings; stale repair; write ordering; close awaiting |
| Widgets | Exact text once/order; semantic highlight; empty chapter; drawer current state; disabled boundaries; themes/font/line height; PDF label/error/switch |
| Router/library | Ready-only open affordance; exact `/reader/:bookId`; unavailable route; back navigation |
| Root integration | Seed → open → select/settings → PDF mapping → reset/restart → exact restore → delete cascade |
| Accessibility | Tooltips/labels, selected semantics, header semantics, contrast checks for three fixed palettes, no horizontal overflow |
| Performance | Large fixture proves lazy block building and frame/state responsiveness during load/save |

The final verifier must mutate at minimum: active-run filter, chapter/block
ordering, selected semantic/highlight, PDF mapping direction, settings bounds,
position newest-wins, stale repair, and delete cascade.

---

## Risks & Concerns

| Concern | Location | Impact | Mitigation |
| --- | --- | --- | --- |
| Existing active-content block query orders by lexical `chapterId` before block order | `lib/features/pdf_processing/data/repositories/drift_text_processing_repository.dart:277` | Reader could display chapters/blocks out of source order when IDs are non-lexical | Reader repository anchors block association to numerically ordered chapters and tests adversarial IDs |
| Router currently supports only `/` and accepts only a library builder | `lib/app/router/app_router.dart:4` | Adding reader directly could couple GetIt into router tests | Add a `readerPageBuilder(bookId)` injection seam |
| Library items have edit/delete but no primary open intent | `lib/features/library/presentation/widgets/book_list_item.dart`, `book_grid_item.dart` | Ambiguous taps and inaccessible non-ready behavior | Add explicit semantic open callbacks and tests for ready/non-ready |
| `pdfrx` is native/widget state with asynchronous document errors | package `pdfrx 2.4.7` | Widget tests may hang or require native assets | Keep package behind `OriginalPdfView` builder seam; test adapter contract separately and root flow with a fake surface |
| Existing root integration test is already long | `test/widget_test.dart` | Reader additions could make one brittle monolithic test | Add a dedicated visual-reader root integration test file and retain existing library flow unchanged |
| Reprocessing replaces chapter/block IDs | processing run cascade design | Saved visual IDs become stale | Avoid derived-row FKs and validate/repair against the active aggregate on every load |
| Unbounded novel content | processed blocks may be numerous | Eager rendering can stall frames/memory | Render one chapter with `ListView.builder`; repository returns immutable lists and performance test measures lazy build |

---

## Tech Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Feature ownership | New `visual_reader` feature | Reading consumes but does not produce processed content |
| State coordinator | One route-scoped `VisualReaderCubit` | Mode/mapping/selection/settings/position are one coherent state machine |
| Persistence | Drift tables for global settings and per-book position | Required offline durability and transactional/cascade behavior |
| Visual vs narration progress | Separate reader position model | Prevents visual browsing from corrupting future playback progress |
| PDF integration | Thin production widget adapter with injected test surface | Uses verified `pdfrx` APIs while keeping tests deterministic |
| Rendering unit | One current chapter, lazy block list | Bounds widget creation and aligns with chapter navigation |
| Derived identity lifecycle | Store chapter/block IDs without derived-row FKs, validate on load | Allows deterministic stale repair after reprocessing |

The separation between visual position and narration progress is a cross-feature
constraint and is recorded as project decision AD-007.

---

## Requirement Mapping

| Requirement | Components |
| --- | --- |
| READ-01 | repository aggregate, Cubit, ReaderPage, TextReaderView |
| READ-02 | resolver, Cubit, ChapterDrawer, TextReaderView |
| READ-03 | resolver, Cubit, OriginalPdfView/pdfrx adapter |
| READ-04 | settings model/table/repository, Cubit, settings sheet/theme surface |
| READ-05 | position model/table/repository, resolver, Cubit close lifecycle |
