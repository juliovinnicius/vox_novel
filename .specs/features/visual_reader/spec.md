# Visual Reader Specification

## Problem Statement

Processed books already contain durable clean text, chapters, narration blocks,
page references, and the original PDF, but users cannot open or read them.
Milestone 3 must provide an accessible offline reader that moves reliably
between reformatted text and the source PDF and restores the user's visual
reading context.

## Goals

- [ ] Open every ready book in a readable text-first experience.
- [ ] Navigate chapters and select an exact paragraph without losing source order.
- [ ] View and navigate the original PDF and switch modes at a related position.
- [ ] Customize and persist theme and typography within defined bounds.
- [ ] Restore a durable per-book visual position without conflating it with narration progress.

## Out of Scope

| Feature | Reason |
| --- | --- |
| TTS, playback queue, voice, speed, and audio controls | Milestone 4 |
| Narration progress and character-level playback position | Milestone 4 |
| Background playback and media notification | Milestone 5 |
| Bookmarks, chapter editing, keep-screen-awake, and reprocessing settings | Milestone 6 |
| OCR for image-only PDF pages | Milestone 7 |
| Text annotation, copying, search, translation, and sharing | Future reader enhancements |

---

## Assumptions & Open Questions

| Assumption / decision | Chosen default | Rationale | Confirmed? |
| --- | --- | --- | --- |
| Initial reader mode | Reformatted text; restore a saved per-book mode afterward | The processed text is the primary comfortable reading surface | delegated |
| Chapter navigation | Accessible end drawer plus previous/next actions | Keeps the reading surface focused while chapters remain one action away | delegated |
| Themes | Light, sepia, and dark | Covers daylight, low-contrast warm reading, and low-light use without premature customization | delegated |
| Typography scope | Global system sans/serif, sizes 14–32 by 2, line heights 1.2/1.5/1.8/2.0 | Deterministic bounds are testable and adequate for MVP accessibility | delegated |
| Visual position scope | Per book: mode, selected chapter/block, PDF page | Restores visual context while remaining separate from narration progress | delegated |
| Text/PDF relation | Use persisted block/chapter page ranges; choose the first matching block when returning to text | Existing processing data provides deterministic best-effort mapping | delegated |
| Paragraph meaning | One narration block is one selectable/highlightable paragraph unit | Reuses the stable unit that Milestone 4 will narrate | delegated |
| Empty chapter | Show title and an explicit `Este capítulo não possui texto` state | Empty chapters are intentionally retained by processing | delegated |
| Large chapters | Lazily build visible block widgets and scroll to the restored block after layout | Avoids eagerly rendering an entire novel and preserves UI responsiveness | delegated |
| Persistence failure | Keep the reader usable for the session and show `Não foi possível salvar sua posição` once per failed write | Reading should not be blocked by a recoverable local write error | delegated |
| Missing processed content | Refuse the reader surface and show `Conteúdo do livro indisponível` with a return action | Prevents rendering stale or partial processing data | delegated |
| Missing/corrupt original PDF | Text mode remains usable; PDF mode shows `Não foi possível abrir o PDF original` | The derived text is independently durable | delegated |
| Concurrent position writes | Serialize per book and retain the newest requested position | Prevents a delayed write from restoring an older location | delegated |
| Authentication/rate limits | N/A because all reader data and actions are device-local | No remote or privileged boundary exists in this milestone | delegated |
| Data expiry | N/A; preferences live until changed and positions until the book is deleted | Offline reader state has no meaningful TTL | delegated |
| Observability | Record book ID, mode, page/block identity, duration, and sanitized error category; never record novel text | Supports diagnosis without exposing content | delegated |

**Open questions:** none — all resolved or explicitly delegated above.

---

## User Stories

### P1: Open and read reformatted text ⭐ MVP

**User Story**: As a reader, I want to open a processed book as clean text so
that I can read comfortably without the PDF layout.

**Why P1**: This is the primary visible use of the processing completed in
Milestone 2.

**Acceptance Criteria**:

1. WHEN the user activates a `ready` book in the library THEN the system SHALL navigate to `/reader/:bookId`, show the exact book title, and load only that book's active processed content.
2. WHEN a book has no saved visual position THEN the reader SHALL open in text mode at the first chapter and its first block.
3. WHEN text mode loads a non-empty chapter THEN the reader SHALL display its title and every block exactly once in ascending `sortOrder`, preserving each block's exact `originalText`.
4. WHEN the selected block is visible THEN the reader SHALL expose it as selected through both a distinct visual highlight and accessibility state.
5. WHEN the user taps a block THEN the reader SHALL select exactly that block, keep all text unchanged, and request persistence of its book, chapter, and block IDs.
6. WHEN a chapter contains no blocks THEN the reader SHALL show its title and `Este capítulo não possui texto`.
7. WHEN the book is absent, not `ready`, or has no active processed content THEN the route SHALL show `Conteúdo do livro indisponível` and an accessible `Voltar à biblioteca` action.

**Independent Test**: Open a seeded ready book, assert exact ordered text, tap a
block, and observe its semantic/visual selection and persisted identity.

### P1: Navigate chapters ⭐ MVP

**User Story**: As a reader, I want to move directly between chapters so that I
can reach the section I want without scrolling through the whole novel.

**Why P1**: Chapter navigation is the primary structural navigation promised by
the processed model.

**Acceptance Criteria**:

1. WHEN the chapter control is activated THEN the reader SHALL open an accessible end drawer listing every chapter once in ascending `sortOrder`.
2. WHEN the drawer is open THEN it SHALL identify the current chapter and expose each chapter's exact title.
3. WHEN a chapter is selected THEN the drawer SHALL close, that chapter SHALL become current, and selection SHALL move to its first block or its empty-chapter state.
4. WHEN previous or next is activated within bounds THEN the adjacent source-order chapter SHALL become current and its first block SHALL be selected.
5. WHEN the first or last chapter is current THEN the unavailable previous or next action respectively SHALL be disabled.
6. WHEN chapter selection changes THEN the reader SHALL persist the resulting chapter and block position without changing the order or content.

**Independent Test**: Navigate a three-chapter fixture through drawer and
previous/next actions and assert exact current IDs, boundaries, and persisted
positions.

### P1: View and navigate the original PDF ⭐ MVP

**User Story**: As a reader, I want to inspect the original PDF so that I can
compare formatting or content with the reformatted text.

**Why P1**: The product explicitly supports both visual representations and
already retains the source file.

**Acceptance Criteria**:

1. WHEN the user switches from text to PDF THEN the reader SHALL open the stored original PDF at the selected block's `startPage`, or the current chapter's `startPage` when no block is selected.
2. WHEN PDF mode is active THEN the reader SHALL expose current page and total pages as `Página X de Y`, with one-based values.
3. WHEN the user navigates PDF pages THEN the current page SHALL remain within `1...pageCount` and SHALL be persisted for that book.
4. WHEN the user switches from PDF to text THEN the reader SHALL select the first source-order block whose page range contains the current page; if none exists, it SHALL select the first chapter whose page range contains the page; if neither exists, it SHALL retain the prior text position.
5. WHEN the original PDF cannot be opened THEN PDF mode SHALL show `Não foi possível abrir o PDF original`, while the user SHALL remain able to return to text mode.
6. WHEN the reader closes and reopens with PDF as its saved mode THEN it SHALL restore the saved valid page; an out-of-range saved page SHALL clamp to `1...pageCount`.

**Independent Test**: Switch a seeded reader between mapped text blocks and PDF
pages, verify exact page labels/mapping, then simulate an unavailable PDF and
confirm text remains usable.

### P1: Customize the reading surface ⭐ MVP

**User Story**: As a reader, I want to adjust the visual presentation so that
long reading sessions remain comfortable and accessible.

**Why P1**: Theme and font controls are explicit Milestone 3 requirements.

**Acceptance Criteria**:

1. WHEN settings are opened THEN the reader SHALL expose theme, font family, font size, and line-height controls with their current values and accessible labels.
2. WHEN no preference exists THEN the system SHALL use light theme, system sans-serif, font size `18`, and line height `1.5`.
3. WHEN the user selects a theme THEN exactly one of light, sepia, or dark SHALL apply to the reader surface and text with contrast suitable for normal text.
4. WHEN font size is decreased or increased THEN it SHALL remain within `14...32` and change only in increments of `2`; the unavailable boundary action SHALL be disabled.
5. WHEN line height changes THEN it SHALL be exactly one of `1.2`, `1.5`, `1.8`, or `2.0`.
6. WHEN font family changes THEN it SHALL be exactly system sans-serif or system serif.
7. WHEN a valid preference changes THEN the visible reader SHALL update without navigation and the complete global preference set SHALL persist atomically.
8. WHEN the app restarts THEN every reader SHALL use the last persisted global preferences.

**Independent Test**: Change every bounded setting, verify the rendered style
and disabled boundaries, restart with the same database, and assert exact
restored values.

### P1: Restore visual reading position ⭐ MVP

**User Story**: As a reader, I want each book to reopen where I left it so that
I can continue reading without searching for my place.

**Why P1**: Durable local continuity is a core offline-reader behavior.

**Acceptance Criteria**:

1. WHEN a text block, chapter, mode, or PDF page changes THEN the system SHALL persist one latest visual position for that book.
2. WHEN multiple saves for one book overlap THEN their durable order SHALL follow request order and the newest request SHALL win.
3. WHEN the reader reopens a text-mode position whose chapter and block still belong to the active run THEN it SHALL restore that exact chapter/block and bring it into view.
4. WHEN a saved chapter or block no longer belongs to active content THEN the reader SHALL fall back to the first chapter and first block and replace the stale position.
5. WHEN a book is deleted THEN its visual position SHALL be deleted in the same database cascade.
6. WHEN saving fails THEN the current session SHALL retain the requested position and show `Não foi possível salvar sua posição` once for that failed write.
7. WHEN loading or saving position occurs THEN the UI SHALL remain responsive to frame pumping and state reads.

**Independent Test**: Save positions, overlap two writes, restart, replace active
content, and delete the book while asserting exact restore, fallback, error, and
cascade outcomes.

---

## Edge Cases

- WHEN a ready book has one chapter and zero blocks THEN text mode SHALL render the exact empty-chapter state without crashing or inventing text.
- WHEN chapter or block rows arrive out of storage order THEN the reader repository SHALL return them in ascending `sortOrder`.
- WHEN a saved block belongs to another chapter or book THEN it SHALL be treated as stale and replaced by the first valid position.
- WHEN page mapping spans multiple blocks THEN returning from PDF SHALL choose the first block by chapter order then block order.
- WHEN the device rotates or the viewport changes THEN current mode, chapter, block, page, and settings SHALL remain unchanged.
- WHEN the system back action is used from the reader THEN it SHALL return to the library without losing the latest requested visual position.
- WHEN a paragraph is very long or multilingual THEN it SHALL wrap without horizontal scrolling and preserve every Unicode character.
- WHEN the original PDF has zero reported pages THEN PDF mode SHALL use the standard PDF-unavailable state.

---

## Implicit-Requirement Dimensions

| Dimension | Resolution |
| --- | --- |
| Input validation & bounds | Theme/family enums, size 14–32 by 2, enumerated line heights, valid page/chapter/block membership |
| Failure / partial failure | Explicit unavailable-content, unavailable-PDF, and save-failure states; session reading remains usable |
| Idempotency / retry / duplicates | One upserted settings row and one upserted position per book; repeated selection is harmless |
| Auth boundaries & rate limits | N/A because all operations are device-local |
| Concurrency / ordering | Position writes serialize per book and newest requested position wins |
| Data lifecycle / expiry | Preferences persist globally; position cascades with its book; no TTL |
| Observability | IDs/mode/timing/sanitized categories only; no novel text |
| External-dependency failure | PDF renderer failure is isolated from text mode |
| State-transition integrity | Only ready active content opens; stale positions validate against the active run; bounded mode/settings transitions |

---

## Requirement Traceability

| Requirement ID | Story | Phase | Status |
| --- | --- | --- | --- |
| READ-01 | Open and read reformatted text | Execute | Implementing |
| READ-02 | Navigate chapters | Execute | Implementing |
| READ-03 | View and navigate original PDF | Execute | Implementing |
| READ-04 | Customize the reading surface | Execute | Implementing |
| READ-05 | Restore visual reading position | Execute | Implementing |

**Coverage:** 5 total, 5 mapped to tasks, 0 unmapped.

---

## Success Criteria

- [ ] A ready book opens in text mode and exposes exact ordered chapter/block content.
- [ ] Text↔PDF switching lands on deterministic related positions.
- [ ] Theme and typography survive a full application/database restart.
- [ ] Each book restores its latest valid visual position and safely repairs stale state.
- [ ] Reader loading, navigation, settings, and persistence pass accessibility, full-test, analysis, and Android build gates.
