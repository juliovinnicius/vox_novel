# Text Processing Specification

## Problem Statement

Imported books currently stop at status `importing`: their PDFs are retained, but
the application has no extracted text, chapters, or narration-sized blocks. This
milestone must transform a selectable-text PDF into durable, ordered reading data
without blocking the interface, while preserving the untouched extraction for
future reprocessing.

## Goals

- [x] Extract selectable text per PDF page outside the UI isolate and persist the raw result.
- [x] Conservatively clean extracted text without removing narrative content.
- [x] Detect ordered chapters and always provide a one-chapter fallback.
- [x] Produce stable, ordered narration blocks no longer than 3,000 characters.
- [x] Expose deterministic processing stages, progress, cancellation, and failures.

## Out of Scope

| Feature | Reason |
| ------- | ------ |
| OCR for scanned or image-only PDFs | Explicitly outside the MVP |
| Password removal, decryption, or bypassing PDF protection | Security and copyright boundary |
| Manual chapter rename, merge, or split UI | Future chapter-management work |
| User-configurable cleaning rules and manual reprocessing UI | Milestone 6 |
| Visual text/PDF reader | Milestone 3 |
| TTS playback and reading-progress persistence | Milestone 4 |
| Cover generation and PDF metadata enrichment | Not required by Milestone 2 |

---

## Assumptions & Open Questions

| Assumption / decision | Chosen default | Rationale | Confirmed? |
| --------------------- | -------------- | --------- | ---------- |
| Processing trigger | Start automatically after a successful import | User-confirmed continuous import flow | yes |
| Responsiveness | Extract and process PDF content outside the UI isolate, emitting progress asynchronously | User-confirmed; satisfies RNF-002 | yes |
| Cancellation/failure durability | Preserve the imported PDF/book and commit no partial raw text, chapters, or blocks | User-confirmed rollback boundary | yes |
| Cancellation status | Restore the book to `importing` with progress `0` | Cancellation is retryable and is not a processing failure | agent default |
| Extraction failure status | Use `unsupported` for zero extractable text and `failed` for all other extraction/persistence failures | Matches the existing product status model | agent default |
| Block size | Prefer paragraph/sentence boundaries and cap every block at 3,000 Unicode characters | User-confirmed deterministic TTS-safe default | yes |
| Cleaning aggressiveness | Remove only deterministic noise and repeated page-edge lines; preserve ambiguous content | User-confirmed conservative cleaning | yes |
| Repeated page-edge threshold | Treat a normalized first/last non-empty line as repeated only when it appears on at least 60% of pages and on at least 3 pages | Precise conservative default that avoids deleting incidental prose | agent default |
| Chapter heading matching | Match a heading only when its trimmed content occupies the complete line | Prevents narrative sentences containing chapter-like words from becoming headings | agent default |
| Concurrent processing | At most one active run per book; a duplicate start request returns the existing run | Prevents competing replacements of the same derived data | agent default |
| Observability | Record book ID, stage, duration, counts, progress, and sanitized error category; never record extracted novel text | Satisfies diagnostics and privacy requirements | agent default |

**Open questions:** none — all resolved or logged above.

---

## User Stories

### P1: Extract and retain PDF text ⭐ MVP

**User Story**: As a reader, I want an imported PDF converted into locally stored
text so that later reading and narration features can use it offline.

**Why P1**: Every downstream reader and narration capability depends on durable
selectable text.

**Acceptance Criteria**:

1. WHEN a PDF import commits successfully THEN the system SHALL automatically start one processing run for that book.
2. WHEN processing starts THEN the system SHALL set the book status to `processing`, progress to `0`, and expose stage `Extraindo texto`.
3. WHEN a selectable-text PDF is processed THEN the system SHALL extract text in ascending page order and retain each page's exact extracted text and one-based page number as the immutable raw source.
4. WHEN extraction advances THEN the system SHALL report monotonic progress from `0` through `0.40` without blocking UI frame pumping or state reads.
5. WHEN the PDF has zero non-whitespace extracted characters across all pages THEN the system SHALL commit no derived text, set status `unsupported`, reset progress to `0`, and expose `Este PDF não possui texto extraível`.
6. WHEN extraction or persistence fails for any other reason THEN the system SHALL commit no partial derived data, set status `failed`, reset progress to `0`, and expose `Não foi possível processar este PDF`.
7. WHEN extraction succeeds THEN the system SHALL persist the complete raw page collection before any cleaned/chapter/block result is committed.

**Independent Test**: Process a multi-page selectable-text fixture and verify exact
raw page payloads and ordering in persistent storage while the UI remains responsive.

### P1: Clean text conservatively ⭐ MVP

**User Story**: As a reader, I want deterministic PDF noise removed so that the
content is comfortable to read and narrate without losing story text.

**Why P1**: Raw PDF layout artifacts produce broken paragraphs and unwanted speech.

**Acceptance Criteria**:

1. WHEN raw text enters cleaning THEN the system SHALL expose stage `Limpando` and monotonic overall progress from `0.40` through `0.60`.
2. WHEN text contains C0 control characters other than line feed or tab THEN the system SHALL remove those characters.
3. WHEN a line contains leading/trailing whitespace, repeated internal horizontal whitespace, or more than two consecutive blank lines THEN the system SHALL trim line edges, collapse internal horizontal whitespace to one space, and retain at most one blank separator.
4. WHEN a complete trimmed line is an HTTP or HTTPS URL or an isolated Arabic page number THEN the system SHALL remove that line.
5. WHEN the normalized first or last non-empty line appears in the same edge position on at least 60% of pages and at least three pages THEN the system SHALL remove those repeated occurrences as headers or footers.
6. WHEN a line ends in a letter followed by a hyphen and the next non-empty line begins with a lowercase letter THEN the system SHALL join both fragments without the hyphen.
7. WHEN content does not meet an explicit removal or joining rule THEN the system SHALL preserve its characters and relative order.
8. WHEN cleaning completes THEN the system SHALL retain both the immutable raw pages and the cleaned text so future processing can restart from raw content.

**Independent Test**: Apply the cleaner to raw-page fixtures containing each
defined artifact and narrative lookalikes, verifying exact cleaned output and
unchanged raw pages.

### P1: Detect ordered chapters ⭐ MVP

**User Story**: As a reader, I want chapter boundaries detected automatically so
that the book can be navigated and narrated in meaningful sections.

**Why P1**: Chapters are the primary structural unit for both the visual reader and player.

**Acceptance Criteria**:

1. WHEN chapter detection starts THEN the system SHALL expose stage `Detectando capítulos` and monotonic overall progress from `0.60` through `0.75`.
2. WHEN a complete trimmed line case-insensitively matches `Capítulo N`, `Capitulo N`, `Chapter N`, `Volume N`, `Prólogo`, `Prologo`, `Epílogo`, `Epilogo`, or `Extra`, or matches `第N章`, THEN the system SHALL start a chapter at that line.
3. WHEN headings are detected THEN the system SHALL create chapters in source order with stable unique IDs, zero-based contiguous `sortOrder`, exact heading text as title, cleaned body text, and available start/end page references.
4. WHEN text precedes the first detected heading THEN the system SHALL create an initial chapter titled `Início` containing that text before the detected chapters.
5. WHEN no heading is detected THEN the system SHALL create exactly one chapter titled from the book title with all cleaned text and `sortOrder` zero.
6. WHEN a heading has no body before the next heading or end of book THEN the system SHALL retain that empty chapter in source order.

**Independent Test**: Run mixed Portuguese, English, and simplified-Chinese
heading fixtures plus a no-heading fixture and verify exact titles, bodies, and order.

### P1: Generate narration blocks ⭐ MVP

**User Story**: As a reader, I want each chapter divided into small ordered units
so that later TTS playback can move forward and backward reliably.

**Why P1**: Stable bounded blocks are the persistence and navigation unit for narration.

**Acceptance Criteria**:

1. WHEN block generation starts THEN the system SHALL expose stage `Preparando narração` and monotonic overall progress from `0.75` through `0.95`.
2. WHEN a chapter contains non-empty paragraphs THEN the system SHALL create blocks in paragraph order, omitting whitespace-only paragraphs.
3. WHEN a paragraph is at most 3,000 Unicode characters THEN the system SHALL create one block containing its exact trimmed text.
4. WHEN a paragraph exceeds 3,000 characters THEN the system SHALL split it at the last sentence-ending boundary at or before 3,000 characters, otherwise at the last whitespace, otherwise exactly at 3,000 characters, and SHALL repeat until all characters are retained in order.
5. WHEN blocks are created THEN every block SHALL have a stable unique ID, chapter ID, zero-based contiguous `sortOrder`, identical `originalText` and `normalizedText`, exact character count, and available page references.
6. WHEN a chapter has no non-whitespace body THEN the system SHALL create zero blocks for that chapter.
7. WHEN all chapters and blocks are ready THEN the system SHALL atomically replace prior derived data, set the book chapter count, block count, status `ready`, progress `1`, and expose stage `Concluído`.

**Independent Test**: Generate blocks from short, long, whitespace-free, and
multilingual paragraphs and verify exact reconstruction, limits, payloads, and order.

### P1: Cancel processing without partial results ⭐ MVP

**User Story**: As a reader, I want to cancel lengthy processing so that I remain
in control without corrupting my imported book.

**Why P1**: Large PDFs must not trap the user in an irreversible background task.

**Acceptance Criteria**:

1. WHEN a book is actively processing THEN the library SHALL show its exact current stage, percentage, and an accessible cancel action.
2. WHEN cancellation is requested THEN the active worker SHALL stop at the next page or pipeline-unit boundary, discard the run's staged derived data, retain the imported PDF and book metadata, and restore status `importing` with progress `0`.
3. WHEN cancellation completes THEN the system SHALL show `Processamento cancelado` and no raw page, cleaned text, chapter, or block from the cancelled run SHALL be visible.
4. WHEN cancellation is requested after the final atomic commit THEN the completed `ready` result SHALL remain unchanged and cancellation SHALL have no effect.
5. WHEN a second processing request targets a book with an active run THEN the system SHALL reuse or report that run and SHALL NOT start a competing worker.

**Independent Test**: Pause an injected worker mid-extraction, cancel it, and verify
the exact persisted book/PDF survives with no visible derived records.

---

## Edge Cases

- WHEN a PDF contains zero pages or only whitespace THEN the system SHALL follow the `unsupported` no-extractable-text result.
- WHEN a PDF is corrupt or password-protected THEN the system SHALL follow the standard `failed` result without attempting to bypass protection.
- WHEN a page has no text but other pages do THEN the system SHALL retain that raw page with empty text and continue processing.
- WHEN progress updates arrive out of order or repeat THEN the persisted and visible percentage SHALL never decrease or exceed the current stage's upper bound.
- WHEN sentence boundaries include `.`, `!`, `?`, `。`, `！`, or `？` THEN they SHALL be eligible split points.
- WHEN a chapter heading appears inside a narrative line THEN it SHALL remain narrative text.
- WHEN persistence fails during final replacement THEN the previous complete derived dataset SHALL remain intact, or no derived dataset SHALL remain if none existed.
- WHEN processing is retried after failure or cancellation THEN it SHALL replace, not duplicate, raw pages, chapters, or blocks.

---

## Implicit-Requirement Dimensions

| Dimension | Resolution |
| --------- | ---------- |
| Input validation & bounds | Only application-owned imported PDFs are processed; exact heading patterns and 3,000-character block limit are defined. |
| Failure / partial-failure states | Derived data is staged and committed atomically; unsupported, failed, and cancelled outcomes have exact statuses/messages. |
| Idempotency / retry / duplicate handling | One active run per book; successful retry replaces all derived data without duplicates. |
| Auth boundaries & rate limits | N/A because processing is entirely local and has no account or remote endpoint. |
| Concurrency / ordering | One run per book; pages, chapters, and blocks use preserved source order and contiguous sort order. |
| Data lifecycle / expiry | Raw and derived text persist until replacement or book deletion; cancelled staged data is discarded. |
| Observability | Sanitized local stages, durations, counts, progress, and error categories; no novel content in logs. |
| External-dependency failure | PDF parser, isolate, and database failures produce deterministic rollback; protected PDFs are not bypassed. |
| State-transition integrity | `importing → processing → ready`, `processing → importing` on cancel, `processing → unsupported` for no text, and `processing → failed` otherwise. |

## Requirement Traceability

| Requirement ID | Story | Phase | Status |
| -------------- | ----- | ----- | ------ |
| TXT-01 | Extract and retain PDF text | Tasks | In Tasks |
| TXT-02 | Clean text conservatively | Tasks | In Tasks |
| TXT-03 | Detect ordered chapters | Tasks | In Tasks |
| TXT-04 | Generate narration blocks | Tasks | In Tasks |
| TXT-05 | Cancel processing without partial results | Tasks | In Tasks |

**Coverage:** 5 total, 0 mapped to tasks, 5 unmapped.

---

## Success Criteria

- [ ] A selectable-text fixture becomes one durable raw dataset, cleaned text, ordered chapter set, and bounded block set.
- [ ] Every successful book reaches `ready` only after chapters and blocks commit atomically.
- [ ] Unsupported, failed, and cancelled runs expose their exact result without partial derived data.
- [ ] Concatenating a chapter's blocks in order reconstructs all non-whitespace chapter content without loss or reordering.
- [ ] Processing progress is monotonic, stage-bounded, cancellable, and does not block UI frame pumping.
