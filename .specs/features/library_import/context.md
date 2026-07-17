# Library and Import Context

**Gathered:** 2026-07-17
**Spec:** `.specs/features/library_import/spec.md`
**Status:** Ready for design

---

## Feature Boundary

This milestone selects and validates one PDF, copies it to private storage,
registers or safely replaces a local book, displays the persisted collection,
edits title and author, and completely deletes a book. Text extraction,
processing, chapters, reading, and narration remain outside this milestone.

---

## Implementation Decisions

### Library presentation

- The user can alternate between list and grid layouts.
- The library defaults to list after restart in this milestone.
- Phone grid layout uses two columns and preserves the same newest-first order as the list.

### Duplicate behavior

- Identical content is detected by SHA-256.
- Reimporting identical content replaces the existing item rather than creating a duplicate or asking for confirmation.
- Replacement preserves the stable book identity and user-edited title, author, and cover.
- The old PDF remains intact until both the replacement file and database update are durable.

### Initial metadata

- Initial title is the source filename without its final `.pdf` extension.
- Author and cover start empty.
- A filename that yields no title uses `Livro sem título`.

### Deletion

- Deletion requires confirmation naming the book.
- Confirmed deletion removes the database record, private PDF, and application-owned cover.
- Cancellation changes nothing.
- A file-removal failure cannot be presented as successful deletion.

### Agent's Discretion

- Exact Material components, spacing, icons, and responsive breakpoints.
- Internal error types and sanitized logging implementation.
- Exact private filenames and staging-directory organization.
- Repository and service interface names, provided the feature-first architecture and constructor injection decisions remain intact.

### Declined / Undiscussed Gray Areas → Assumptions

- Picker cancellation silently returns to the unchanged library.
- Only one import runs at a time.
- Layout choice is not persisted until a settings milestone requires it.
- Metadata editing covers title and optional author; cover selection is deferred.
- A copied book remains `importing` until Milestone 2 processes it.

---

## Specific References

No external product reference was requested. Interaction follows standard Material
library, modal confirmation, and form-validation patterns.

---

## Deferred Ideas

- Persisting the preferred library layout.
- Search, filter, sorting selection, volume grouping, and cover editing.
- Extraction progress, text processing, and recovery of interrupted processing.
