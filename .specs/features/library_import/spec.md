# Library and Import Specification

## Problem Statement

The application shell cannot yet import or retain a user's PDF collection. This
milestone must provide an offline library where a user can select a readable PDF,
copy it into application-controlled storage, persist its initial metadata, replace
an existing import with the same content, edit metadata, and remove the complete
local book record.

## Goals

- [ ] Import a readable PDF into private application storage without blocking the interface.
- [ ] Persist and display imported books in a library that supports list and grid layouts.
- [ ] Let the user edit initial metadata and completely delete a book.
- [ ] Make duplicate replacement and failed imports safe and deterministic.

## Out of Scope

| Feature | Reason |
| ------- | ------ |
| PDF text extraction, cleaning, chapter detection, and narration blocks | Milestone 2 |
| Processing progress beyond the file-import operation | Milestone 2 |
| PDF cover generation or metadata extraction | Milestone 2; cover editing may store a user-selected image later |
| Search, filters, sorting controls, grouping volumes, and completion state | Later library-management work |
| Opening a visual reader or original PDF viewer | Milestone 3 |
| OCR and non-PDF formats | Outside the MVP |
| Cloud backup, sync, or external telemetry | Outside the offline MVP |

---

## Assumptions & Open Questions

| Assumption / decision | Chosen default | Rationale | Confirmed? |
| --------------------- | -------------- | --------- | ---------- |
| Library layout | User can alternate between list and grid | Explicit user decision | yes |
| Duplicate policy | A successfully validated file with an existing SHA-256 hash replaces the existing book | Explicit user decision; content identity is based on hash | yes |
| Initial metadata | Title is the selected filename without its final `.pdf` extension; author and cover are empty | Explicit user decision, made precise for deterministic behavior | yes |
| Delete behavior | Delete the database record and every application-owned PDF/cover file for the book | Explicit user decision | yes |
| Duplicate replacement failure | Keep the existing book and its files unchanged unless the replacement copy and database update both succeed | Prevents data loss during partial failure | agent default |
| Duplicate replacement state | Preserve the existing book ID and user-edited title, author, and cover; replace the stored PDF, original filename, hash, import timestamp, and reset status to `importing` | Keeps the user's library identity and edits while preparing the new file for Milestone 2 | agent default |
| File picker cancellation | Return to the unchanged library without an error message | Cancellation is an intentional user action | agent default |
| Valid input | Accept one existing, readable regular file whose extension is `.pdf`, case-insensitively | Covers the MVP contract without attempting extraction | agent default |
| Import status | A copied and registered book has status `importing` until Milestone 2 processes it | Matches the documented product state model and milestone boundary | agent default |
| Concurrent imports | Only one import operation may run at a time; repeated import taps while active are ignored | Avoids file/database races and gives deterministic presentation state | agent default |
| Layout persistence | The selected list/grid layout is presentation state for this milestone and resets to list after app restart | Avoids adding a settings persistence requirement outside this milestone | agent default |
| Metadata editing | Title is required after trimming; author is optional and trimmed; empty title is rejected without changing persisted data | Provides precise input validation for the two fields in scope | agent default |
| Observability | Log import stage and sanitized error category, never PDF contents or external source path | Meets local diagnostics and privacy requirements | agent default |

**Open questions:** none — all resolved or logged above.

---

## User Stories

### P1: Import a PDF into private storage ⭐ MVP

**User Story**: As a reader, I want to select one PDF from my device so that it
becomes an offline book managed by the application.

**Why P1**: The library has no useful content without a safe import path.

**Acceptance Criteria**:

1. WHEN the user activates the accessible import action THEN the system SHALL open a picker restricted to PDF files.
2. WHEN the user cancels selection THEN the system SHALL return to the unchanged library without showing an error.
3. WHEN the selected path does not identify an existing, readable regular file with a case-insensitive `.pdf` extension THEN the system SHALL leave the library and internal storage unchanged and show `Não foi possível importar este PDF`.
4. WHEN a valid PDF is selected THEN the system SHALL calculate its SHA-256 hash and copy it to a unique application-private path without executing file work on the UI isolate.
5. WHEN the private copy succeeds THEN the system SHALL persist exactly one book with a stable unique ID, title derived from the filename without `.pdf`, empty author and cover, original filename, private stored path, hash, status `importing`, zero processing progress, and import timestamps.
6. WHEN copying or persistence fails THEN the system SHALL remove any partial new copy, leave the prior library unchanged, and show `Não foi possível importar este PDF`.
7. WHEN an import is active THEN the library SHALL show an indeterminate import indicator, disable the import action, and remain responsive.

**Independent Test**: Select a fixture PDF through an injected picker, observe the
busy state, then verify one exact database record and one application-private copy.

### P1: Replace duplicate content safely ⭐ MVP

**User Story**: As a reader, I want reimporting identical PDF content to replace
the existing library item so that duplicate entries do not accumulate.

**Why P1**: Content identity and retry behavior must be deterministic from the first import.

**Acceptance Criteria**:

1. WHEN a valid selected PDF has a SHA-256 hash not present in the library THEN the system SHALL create one new book.
2. WHEN a valid selected PDF has a SHA-256 hash already present THEN the system SHALL keep the existing book ID, title, author, and cover while atomically replacing its private PDF and updating original filename, stored path, import/update timestamps, status to `importing`, and processing progress to zero.
3. WHEN duplicate replacement commits successfully THEN the system SHALL delete the superseded application-owned PDF only after the new file and updated record are durable.
4. WHEN duplicate replacement fails before commit THEN the system SHALL retain the existing record and existing PDF unchanged and remove any partial replacement file.
5. WHEN two import requests are attempted concurrently THEN the system SHALL execute only the first request and SHALL NOT create or replace a second record.

**Independent Test**: Import two fixture paths with identical bytes and verify one
stable book ID, preserved edited metadata, one active private PDF, and no orphan copy.

### P1: Browse the local library ⭐ MVP

**User Story**: As a reader, I want to see my imported books and alternate between
list and grid layouts so that I can browse the collection in my preferred density.

**Why P1**: Imported content must be discoverable and visibly persistent.

**Acceptance Criteria**:

1. WHEN the library contains no books THEN it SHALL show `Sua biblioteca está vazia` and an accessible `Importar PDF` action.
2. WHEN persisted books exist THEN the library SHALL render each book exactly once with its title, optional author when non-empty, and exact processing-status label.
3. WHEN the user selects grid layout THEN the same books SHALL be displayed in a two-column grid on phones without changing their order or persisted data.
4. WHEN the user selects list layout THEN the same books SHALL be displayed as a one-column list without changing their order or persisted data.
5. WHEN the application restarts THEN the library SHALL load persisted books ordered by most recently imported or updated first and default to list layout.
6. WHEN the library contains persisted data under normal local conditions THEN its first query and visible result SHALL complete within two seconds.

**Independent Test**: Seed multiple records, render the library in both layouts,
and verify the same ordered IDs and exact visible metadata.

### P1: Edit book metadata ⭐ MVP

**User Story**: As a reader, I want to edit a book's title and author so that the
library uses meaningful metadata instead of only filenames.

**Why P1**: Manual title and author editing is part of the MVP library contract.

**Acceptance Criteria**:

1. WHEN the user opens edit metadata THEN the form SHALL contain the book's current title and author.
2. WHEN the user saves a non-empty trimmed title and an optional author THEN the system SHALL persist the trimmed values, update `updatedAt`, and show them in the library.
3. WHEN the user saves a title that is empty after trimming THEN the system SHALL show `Informe o título` and leave persisted metadata unchanged.
4. WHEN metadata persistence fails THEN the system SHALL keep the previous visible and persisted values and show `Não foi possível salvar as alterações`.
5. WHEN the user cancels editing THEN the system SHALL return without changing persisted metadata.

**Independent Test**: Edit a seeded book, verify exact trimmed values after a fresh
repository query, then verify invalid and cancelled edits do not change the record.

### P1: Delete a complete local book ⭐ MVP

**User Story**: As a reader, I want to delete a book and its application-owned
files so that I control local storage usage.

**Why P1**: Local content ownership requires a complete deletion path.

**Acceptance Criteria**:

1. WHEN the user requests deletion THEN the system SHALL ask for confirmation naming the book.
2. WHEN the user cancels confirmation THEN the system SHALL keep the record and all files unchanged.
3. WHEN the user confirms deletion THEN the system SHALL remove the book record, its private PDF, and its application-owned cover before removing the item from the visible library.
4. WHEN any owned-file deletion fails THEN the system SHALL keep or restore the database record, report `Não foi possível excluir o livro`, and SHALL NOT present the deletion as successful.
5. WHEN deletion succeeds THEN the book SHALL remain absent after application restart and no application-owned file referenced by it SHALL remain.

**Independent Test**: Delete a seeded book with PDF and cover fixtures, then verify
the database, filesystem, refreshed UI, and cancellation/failure paths.

---

## Edge Cases

- WHEN a filename is exactly `.pdf` after removing its extension THEN the system SHALL use `Livro sem título` as the initial title.
- WHEN a selected PDF is empty but readable THEN this milestone SHALL import it; Milestone 2 is responsible for reporting no extractable text.
- WHEN the source file disappears before or during copying THEN the system SHALL roll back the import and show the standard import error.
- WHEN private storage has insufficient space THEN the system SHALL roll back the import and show the standard import error.
- WHEN the library observes a book changed by import, edit, replacement, or deletion THEN it SHALL emit one refreshed ordered collection without duplicate IDs.
- WHEN an application-owned cover path is empty THEN deletion SHALL skip cover removal and still delete the book.
- WHEN a book record references an already-missing owned file during deletion THEN the missing file SHALL count as already deleted.

---

## Implicit-Requirement Dimensions

| Dimension | Resolution |
| --------- | ---------- |
| Input validation & bounds | One readable `.pdf` regular file per import; trimmed non-empty title; optional trimmed author. |
| Failure / partial-failure states | Partial copies are removed; existing duplicate records/files survive failed replacement; deletion is not reported successful on owned-file failure. |
| Idempotency / retry / duplicate handling | SHA-256 identifies duplicate content; retry replaces the stable record instead of creating a duplicate. |
| Auth boundaries & rate limits | N/A because the MVP is entirely local and has no accounts or remote API. |
| Concurrency / ordering | One import runs at a time; transactional writes and stable newest-first library ordering prevent races and duplicate emissions. |
| Data lifecycle / expiry | Files persist until explicit deletion or successful duplicate replacement; no automatic expiry. |
| Observability | Sanitized local stage/error logging only; novel contents and external source paths are excluded. |
| External-dependency failure | Picker cancellation is benign; picker, filesystem, hashing, and database failures produce deterministic rollback and user errors. |
| State-transition integrity | Import presentation moves idle → selecting → importing → success/error → idle; persisted books enter or re-enter `importing` and cannot become `ready` in this milestone. |

## Requirement Traceability

| Requirement ID | Story | Phase | Status |
| -------------- | ----- | ----- | ------ |
| LIB-01 | Import a PDF into private storage | Tasks | Implementing |
| LIB-02 | Replace duplicate content safely | Tasks | Implementing |
| LIB-03 | Browse the local library | Tasks | Implementing |
| LIB-04 | Edit book metadata | Tasks | Implementing |
| LIB-05 | Delete a complete local book | Tasks | Implementing |

**Coverage:** 5 total, 5 mapped to tasks, 0 unmapped.

---

## Success Criteria

- [ ] A user can import one valid PDF and see exactly one durable library item without restarting.
- [ ] Reimporting identical bytes leaves exactly one book and one active private PDF.
- [ ] Every failed import or replacement leaves no partial file and no incorrect database mutation.
- [ ] The same persisted books appear in list and two-column grid layouts.
- [ ] Valid metadata edits survive restart; invalid or cancelled edits change nothing.
- [ ] Confirmed deletion removes the record and all application-owned files; cancelled deletion changes nothing.
