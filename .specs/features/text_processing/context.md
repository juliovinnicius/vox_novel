# Text Processing Context

**Gathered:** 2026-07-17
**Spec:** `.specs/features/text_processing/spec.md`
**Status:** Approved

---

## Feature Boundary

This milestone automatically transforms an imported selectable-text PDF into
durable raw pages, conservatively cleaned text, ordered chapters, and narration
blocks of at most 3,000 characters. It exposes stage/percentage progress and
supports safe cancellation. Reading UI, TTS, OCR, and configurable reprocessing
remain outside this milestone.

---

## Implementation Decisions

### Processing lifecycle

- Processing starts automatically after a successful PDF import.
- PDF and text work executes outside the UI isolate.
- The UI receives the exact stages `Extraindo texto`, `Limpando`,
  `Detectando capítulos`, `Preparando narração`, and `Concluído`.
- Progress is monotonic and each stage owns a defined percentage interval.

### Cancellation and failure

- Cancellation retains the imported PDF and book metadata.
- A cancelled run exposes no partial raw pages, cleaned text, chapters, or blocks.
- Cancellation restores `importing`; zero extractable text uses `unsupported`;
  other failures use `failed`.
- A retry atomically replaces derived data instead of appending duplicates.

### Cleaning

- Cleaning is deliberately conservative: ambiguous content remains.
- URLs on complete lines, isolated page numbers, control characters, excessive
  whitespace, deterministic hyphenated line breaks, and statistically repeated
  headers/footers are removed or normalized.
- Raw page text is immutable and retained independently from cleaned content.

### Chapters and blocks

- Only complete-line headings match the documented Portuguese, English, and
  simplified-Chinese patterns.
- Text before a first heading becomes `Início`; no detected heading produces one
  chapter titled from the book.
- Paragraphs are the preferred block boundary.
- Long paragraphs split at sentence, then whitespace, then the exact
  3,000-character limit, without dropping or reordering characters.

### Agent's Discretion

- The exact PDF parsing package, provided it supports Android, per-page selectable
  text extraction, cancellation boundaries, and isolate-safe execution.
- Internal repository/service names and staging representation.
- Exact Material progress component and layout, while preserving required text,
  percentage, accessibility, and cancellation behavior.
- Stable ID generation mechanism, provided IDs remain unique and deterministic
  within a committed processing result.

### Declined / Undiscussed Gray Areas → Assumptions

- Repeated headers/footers require the same normalized edge line on at least 60%
  of pages and at least three pages.
- Only one processing run per book may be active.
- Empty chapters are retained but receive no narration blocks.
- User-defined cleaning and manual chapter editing are deferred.

---

## Specific References

The processing-stage names and sequence follow section 19.3 of `docs/spec.md`.
The pipeline boundary follows Milestone 2 and requirements RF-002 through RF-005.

---

## Deferred Ideas

- OCR for scanned PDFs.
- User-authored cleaning and replacement rules.
- Manual chapter rename, merge, and split.
- Reprocessing confirmation when future manual edits exist.
- Cover generation and PDF metadata enrichment.
