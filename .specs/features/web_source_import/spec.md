# Web Source Import Specification

## Problem Statement

The library can only ingest local PDF files. Readers who follow ongoing web
translations have no PDF to import, so the entire narration pipeline is
unreachable for the content they actually read. The extraction stage is the only
part of the pipeline coupled to PDF; everything downstream (cleaning, chapter
records, narration blocks, queue, TTS) is source-agnostic. This feature
generalizes the extraction boundary and adds a web content source, starting with
`centralnovel.com`.

## Goals

- [ ] Generalize the extraction boundary so `TextProcessingService` consumes a
      source-agnostic content stream instead of a PDF-specific extractor.
- [ ] Import a web novel from a series URL or any chapter URL of a supported
      domain, producing a durable book with a complete chapter index.
- [ ] Download chapters in a resumable, throttled background queue while the
      book is already readable and narratable from the first stored chapter.
- [ ] Persist every downloaded chapter locally so reading and narration work
      offline once the queue drains.
- [ ] Reuse the existing reader, narration queue, and progress persistence for
      web books without a parallel implementation.

## Out of Scope

| Feature | Reason |
| --- | --- |
| Generic readability fallback for unknown domains | User chose per-domain recipes only; unpredictable extraction quality would narrate menus and comments |
| Sites requiring JavaScript rendering or a headless WebView | `centralnovel.com` serves static HTML; WebView machinery is unjustified until a target site needs it |
| Sites behind a login, paywall, or Cloudflare interactive challenge | No credential handling in this feature |
| Redistribution, export, or sharing of downloaded chapter text | Personal offline reading only |
| Cover image download from the series page | Cosmetic; the library already renders books without a cover |
| Automatic background sync on a schedule | Update discovery is explicit and user-triggered (P2) |
| Translating source text | The source is already translated; translation belongs to a later milestone |
| The site's per-chapter `/pdf/` endpoint | Explicitly disallowed by the site's `robots.txt` |
| Changing PDF import, PDF cleaning heuristics, or PDF chapter detection behavior | This feature adds a source; it must not alter existing PDF outcomes |

---

## Assumptions & Open Questions

Every ambiguity is resolved or recorded here — nothing is left silently unclear.

| Assumption / decision | Chosen default | Rationale | Confirmed? |
| --- | --- | --- | --- |
| Download strategy | Resolve the index at import, then download all chapters in a resumable background queue; the book is readable from the first stored chapter | Combines a short import wait with a fully offline result; matches the offline-first product goal | y |
| Accepted import URL | Series URL or any chapter URL; a chapter URL is normalized up to its series before import | The user typically has a chapter URL in hand; the series page carries the full index | y |
| New-chapter discovery | Explicit "Buscar novos capítulos" action on the book (P2) | Ongoing novels gain chapters; implicit network access on open is undesirable | y |
| Domain support | Per-domain recipe configuration with exactly one shipped recipe (`centralnovel.com`) | Adding a site later becomes a config entry rather than new code | y |
| Book status vocabulary | Reuse the existing `BookStatus` enum; a web book stays `processing` while its queue drains and becomes `ready` when every indexed chapter is stored | Avoids migrating the persisted status vocabulary and the widgets that switch on it | n |
| Openability while downloading | The library allows opening a web book in `processing` status once at least one chapter is stored; PDF books keep requiring `ready` | Reading while the queue drains is the whole point of the chosen strategy, but PDF has no partial-readability semantics | n |
| Local file fields for web books | A web book has no local file; the book record carries a source type and a source reference instead, and the reader offers no original-document view | `Book.storedFilePath`/`fileHash`/`originalFileName` are PDF-specific and cannot be satisfied by a web source | n |
| Duplicate identity for web books | The canonical series URL is the web equivalent of the PDF file hash | Re-importing the same series must resolve to the existing book rather than a duplicate | n |
| Chapter segmentation | When a source supplies its own chapter index, that segmentation is authoritative and heuristic chapter detection is not run | The site's index is exact; running the PDF heuristic on top could only degrade it | n |
| Page-oriented columns for web chapters | The chapter's ordinal position in the index is stored where PDF stores page numbers | `Chapters` and `NarrationBlocks` require non-nullable page bounds; the ordinal keeps ordering and position resume working | n |
| Cleaning for web chapters | HTML extraction removes navigation, comments, and ads; `TextCleaner` still runs, and its PDF-specific repeated-header/footer profiling is expected to be inert on web input | Keeps one cleaning path; the risk is that PDF-tuned heuristics discard a legitimate short line | n |
| Request identity and politeness | Requests send a descriptive app User-Agent, never impersonate a crawler identity the site disallows, and skip `robots.txt`-disallowed paths (`/pdf/`, `/?s=`, `/search/`) | The site's `robots.txt` allows `/` for a generic agent but disallows those paths and several named AI crawlers | n |
| Chapter count bound | No artificial cap on chapters per novel | The reference novel already exceeds one thousand chapters; a cap would silently truncate a book |  n |
| Authentication | N/A because the app has no accounts and the target site serves chapters publicly without login | — | n |

**Open questions:** none — all resolved or logged above.

---

## User Stories

### P1: Import a web novel by URL ⭐ MVP

**User Story**: As a reader, I want to paste the URL of a translated novel so
that it enters my library as a book without me producing a PDF.

**Why P1**: Nothing else in the feature is reachable without an imported book.

**Acceptance Criteria**:

1. WHEN the user submits a series URL of a supported domain THEN the system
   SHALL create a book whose title comes from the series page and whose chapter
   index contains every chapter listed on that page, in source order.
2. WHEN the user submits a chapter URL of a supported domain THEN the system
   SHALL resolve its series URL from the page and import the same book it would
   have imported from the series URL directly.
3. WHEN the submitted URL's domain has no configured recipe THEN the system
   SHALL reject the import with a message naming the unsupported domain and
   SHALL NOT create a book.
4. WHEN the submitted text is not a valid absolute `http`/`https` URL THEN the
   system SHALL reject the import with a validation message and SHALL NOT create
   a book.
5. WHEN the submitted URL matches a path the domain's recipe marks disallowed
   THEN the system SHALL reject the import with a message stating the path is
   not permitted and SHALL NOT create a book.
6. WHEN the user imports a series that is already in the library THEN the system
   SHALL resolve to the existing book and SHALL NOT create a second book for the
   same canonical series URL.
7. WHEN the series page yields zero chapters THEN the system SHALL mark the
   import unsupported with a message stating no chapters were found.

**Independent Test**: Paste a chapter URL, observe one book appear in the
library carrying the series title and a chapter count matching the site index.

---

### P1: Read and narrate while chapters download ⭐ MVP

**User Story**: As a reader, I want to start listening as soon as the first
chapter arrives so that a long novel does not force me to wait for a full
download.

**Why P1**: This is the download strategy the product chose; without it the
import is a multi-minute block before any value is delivered.

**Acceptance Criteria**:

1. WHEN a web import completes its index resolution THEN the system SHALL enqueue
   every indexed chapter for download and SHALL report the book as `processing`
   with progress derived from stored chapters over indexed chapters.
2. WHEN at least one chapter of a web book is stored THEN the library SHALL
   allow opening that book even while its status is `processing`.
3. WHEN a chapter's text is stored THEN the system SHALL produce its narration
   blocks so that the chapter is immediately narratable without waiting for the
   remaining chapters.
4. WHEN narration reaches the end of the last stored chapter while later chapters
   are still queued THEN the system SHALL stop at that boundary and report that
   the next chapter is not downloaded yet, rather than ending the book.
5. WHEN every indexed chapter is stored THEN the system SHALL transition the book
   to `ready`.
6. WHEN a book is opened with no network available and all its chapters are
   stored THEN reading and narration SHALL work without any network request.

**Independent Test**: Import a long series, open the book while progress is below
100%, and narrate the first chapter while the counter keeps rising.

---

### P1: Source-agnostic extraction pipeline ⭐ MVP

**User Story**: As a maintainer, I want the processing pipeline to consume a
generic content source so that adding a source does not fork the pipeline.

**Why P1**: Both P1 stories above depend on web content reaching the existing
cleaning, chapter, and narration-block stages.

**Acceptance Criteria**:

1. WHEN a content source produces clean chapter text THEN it SHALL reach
   persistence through one shared ingest core that references no source-specific
   types, and adding a source SHALL NOT fork that core.
   *(Amended 2026-08-19 — see the Amendments section below.)*
2. WHEN a book's source is a PDF THEN processing SHALL produce the same chapters
   and narration blocks it produced before this feature, for the same input file.
3. WHEN a source supplies its own chapter index THEN the system SHALL use that
   segmentation and SHALL NOT run heuristic chapter detection over it.
4. WHEN narration blocks are produced from a web chapter THEN their ordering and
   per-book position persistence SHALL behave as they do for PDF blocks.
5. WHEN a web book is opened in the reader THEN the reader SHALL present the text
   view and SHALL NOT offer an original-document view.

**Independent Test**: Existing PDF processing tests pass unchanged while a web
book produces chapters and narration blocks through the same service.

---

### P1: Resumable, throttled, fault-tolerant download queue ⭐ MVP

**User Story**: As a reader, I want an interrupted download to pick up where it
stopped so that a long novel survives a dropped connection or an app restart.

**Why P1**: At over a thousand chapters, a queue that cannot resume will not
finish, and an unthrottled queue risks being blocked by the site.

**Acceptance Criteria**:

1. WHEN the queue downloads chapters THEN it SHALL issue at most one request per
   second to a given domain.
2. WHEN a chapter response is `429` or `503` with a `Retry-After` value THEN the
   queue SHALL wait at least that duration before its next request to that
   domain.
3. WHEN a chapter request fails with a transient error THEN the queue SHALL retry
   it with exponential backoff up to a bounded attempt count before marking that
   chapter failed.
4. WHEN a chapter is marked failed THEN the queue SHALL continue with the
   remaining chapters and SHALL keep the book readable with the chapters it
   already stored.
5. WHEN the app restarts with a partially downloaded web book THEN the queue
   SHALL resume from the first chapter that has no stored text and SHALL NOT
   re-download chapters already stored.
6. WHEN the user cancels a running web download THEN the system SHALL stop
   issuing requests and SHALL retain every chapter already stored.
7. WHEN a chapter page is fetched but the recipe extracts no text THEN the system
   SHALL mark that chapter failed with an extraction-failure reason and SHALL NOT
   store an empty chapter.
8. WHEN every chapter of a book fails extraction THEN the system SHALL mark the
   book unsupported with a message stating the site's layout was not recognized.

**Independent Test**: Kill the app mid-download, reopen it, and confirm the
counter resumes from its previous value rather than from zero.

---

### P2: Fetch new chapters for an ongoing novel

**User Story**: As a reader of an ongoing translation, I want to pull newly
published chapters into a book I already imported.

**Why P2**: The MVP delivers value with the chapters that exist at import time;
this extends it without changing the import path.

**Acceptance Criteria**:

1. WHEN the user triggers "Buscar novos capítulos" on a web book THEN the system
   SHALL re-resolve the series index and enqueue only chapters absent from the
   local index.
2. WHEN the re-resolved index contains no new chapters THEN the system SHALL
   report that the book is up to date and SHALL NOT modify stored chapters.
3. WHEN new chapters are appended THEN they SHALL keep source order after the
   existing chapters and SHALL NOT alter the reader or narration position stored
   for the book.
4. WHEN the update request fails THEN the system SHALL report the failure and
   SHALL leave the book's stored chapters unchanged.

**Independent Test**: Import a book, remove its last chapter locally, trigger the
action, and observe only that chapter re-download.

---

### P2: Retry failed chapters

**User Story**: As a reader, I want to retry chapters that failed so that a
transient site problem does not leave a permanent gap in the book.

**Why P2**: The MVP already keeps the book usable with gaps; retry improves it.

**Acceptance Criteria**:

1. WHEN a web book has failed chapters THEN the system SHALL show how many
   chapters failed and SHALL offer a retry action.
2. WHEN the user retries THEN the system SHALL re-enqueue only the failed
   chapters, under the same throttle and backoff rules.
3. WHEN a retried chapter succeeds THEN the book's progress and status SHALL
   update as if it had succeeded on the first attempt.

**Independent Test**: Force a chapter failure, retry, and confirm the gap closes.

---

### P3: Add a domain without code changes

**User Story**: As a maintainer, I want a new site's selectors to be a
configuration entry so that supporting another translation site is not a code
change.

**Acceptance Criteria**:

1. WHEN a recipe entry is added for a new domain THEN import from that domain
   SHALL work through the same code path as the shipped recipe.
2. WHEN a recipe is missing a required field THEN the system SHALL reject that
   recipe at load time with a message naming the field.

---

## Edge Cases

- WHEN the same chapter URL appears twice in the series index THEN the system
  SHALL store it once and keep a single index position for it.
- WHEN a chapter page returns `404` THEN the system SHALL mark that chapter
  failed and continue with the remaining chapters.
- WHEN the network is unavailable at import time THEN the system SHALL fail the
  import with a network message and SHALL NOT leave a partially created book.
- WHEN the network drops mid-queue THEN the system SHALL pause the queue, retain
  stored chapters, and resume when the user reopens or retries.
- WHEN the user deletes a web book THEN the system SHALL remove its chapters,
  narration blocks, and queue state.
- WHEN a web book's index is resolved but no chapter has been stored yet THEN the
  library SHALL NOT offer to open the book.
- WHEN a chapter's extracted text is shorter than a meaningful minimum THEN the
  system SHALL treat it as an extraction failure rather than storing a stub.
- WHEN two web downloads are pending for different books THEN the system SHALL
  process them without interleaving requests beyond the per-domain rate limit.
- WHEN a redirect chain leads outside the recipe's domain THEN the system SHALL
  abandon that request rather than fetching an unconfigured host.

---


## Amendments

### 2026-08-26 — WEB-11 AC6 scoped to the session (clarification)

**Question**: AC5 requires an interrupted download to resume after a restart and
AC6 requires a user cancel to stop the queue. Neither says which wins when the
user cancels and then relaunches the app.

**Decision**: cancel is **session-scoped**. A cancelled web book keeps status
`processing` with its remaining chapters pending, so the startup resume
re-enqueues it on the next launch. Cancel means "stop fetching now", not "stop
fetching this novel".

**Why**: AC5's success criterion — a novel of over a thousand chapters completing
across app restarts — depends on the resume being unconditional. A durable
"paused by the user" state would need a new book or queue state, a resume
affordance in the library, and a schema migration; it was judged not worth that
before the MVP has been used.

**Consequence a user sees**: a deliberate cancel is undone by relaunching the
app. If that proves wrong in use, the durable-pause design is the follow-up.


### 2026-08-19 — WEB-06 AC1 re-anchored on AD-009

**Original wording**: "WHEN the processing service runs THEN it SHALL depend on a
source-agnostic content-source abstraction and SHALL NOT reference PDF-specific
types."

**Why amended**: This AC was written before AD-009. AD-009 chose a different
boundary for the same goal — paged sources stay batch-processed, chaptered
sources are ingested incrementally, and both route through one shared
`ChapterIngest` that owns clean-text-to-blocks persistence. Its recorded
trade-off is explicit: "Two orchestrators exist over one ingest core." Under that
decision the paged orchestrator legitimately keeps `PdfTextExtractor`, so the
original wording and the active architectural decision cannot both hold.

**What was kept**: the user story's actual goal — "adding a source does not fork
the pipeline" — which the shared ingest core delivers and which
`test/features/content_ingestion/domain/services/chapter_ingest_test.dart` and
`test/architecture/web_source_architecture_test.dart` cover.

**What was given up**: a single generic `ContentSource` seam at the top of
`TextProcessingService`. Building it would mean refactoring the settled PDF path
and revoking AD-009; the user chose the amendment on 2026-08-19 after the
Verifier surfaced the conflict.

**Status**: AD-009 remains active and governs. No `ContentSource` abstraction is
planned.

---

## Requirement Traceability

| Requirement ID | Story | Phase | Status |
| --- | --- | --- | --- |
| WEB-01 | P1: Import a web novel by URL | Execute | Implementing |
| WEB-02 | P1: Import a web novel by URL (URL validation and disallowed paths) | Execute | Implementing |
| WEB-03 | P1: Import a web novel by URL (duplicate series identity) | Execute | Implementing |
| WEB-04 | P1: Read and narrate while chapters download | Execute | Implementing |
| WEB-05 | P1: Read and narrate while chapters download (status transitions) | Execute | Implementing |
| WEB-06 | P1: Source-agnostic extraction pipeline | Execute | Implementing |
| WEB-07 | P1: Source-agnostic extraction pipeline (PDF parity) | Execute | Implementing |
| WEB-08 | P1: Source-agnostic extraction pipeline (index-authoritative chapters) | Execute | Implementing |
| WEB-09 | P1: Resumable queue (throttle and Retry-After) | Execute | Implementing |
| WEB-10 | P1: Resumable queue (retry, backoff, failed chapters) | Execute | Implementing |
| WEB-11 | P1: Resumable queue (resume after restart, cancel) | Execute | Implementing |
| WEB-12 | P1: Resumable queue (extraction failure and unsupported layout) | Execute | Implementing |
| WEB-13 | P2: Fetch new chapters for an ongoing novel | - | Pending |
| WEB-14 | P2: Retry failed chapters | - | Pending |
| WEB-15 | P3: Add a domain without code changes | Execute | Implementing (recipe registry only) |

**ID format:** `WEB-[NUMBER]`

**Status values:** Pending → In Design → In Tasks → Implementing → Verified

**Coverage:** 15 total. WEB-01 to WEB-12 are mapped to T1-T28 plus fixes F1-F5
and carry test evidence in `validation.md`. WEB-15 is partly delivered (a new
domain needs only a recipe entry). WEB-13 and WEB-14 are P2 and unstarted
(T25-T26).

---

## Success Criteria

- [ ] A reader pastes a chapter URL and reaches audible narration of chapter 1 in
      under one minute, without waiting for the full novel to download.
- [ ] A novel with over one thousand chapters completes its download across app
      restarts, with zero chapters re-downloaded after a resume.
- [ ] With the network disabled and the queue drained, reading and narration make
      zero network requests.
- [ ] Existing PDF import, processing, and narration tests pass unchanged.
- [ ] Supporting a second site requires only a new recipe entry.
