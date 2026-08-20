# Web Source Import Validation — Iteration 2

**Date**: 2026-08-20
**Spec**: `.specs/features/web_source_import/spec.md` (including the
**Amendments** section, 2026-08-19)
**Diff range**: `69ad930..HEAD` (`f144462`) — full feature surface.
Fix delta re-verified: `9309bf7..HEAD`
**Verifier**: independent sub-agent, iteration 2 (author ≠ verifier).
Read-only over the real tree; all ten mutations ran in a throwaway
`git worktree` that was removed afterwards. Real tree confirmed clean at
`f144462`.

**Verdict**: ❌ **FAIL (narrow)** — no unmet behavioural acceptance criterion,
no failing gate, all six iteration-1 gaps closed. One **surviving mutant** in
the composition root (the exact defect class iteration 1 found can recur
undetected) and one amended-AC clause with no assertion behind it.

---

## Task Completion

| Task | Status | Notes |
| --- | --- | --- |
| T1–T16, T27 | ✅ Done | Batches 1, 2, 3, 4b marked Complete |
| T17–T24, T28 | ✅ Done | Batch 4 now marked **Complete** (`tasks.md:952`) — iteration-1 gap 6 closed |
| F1–F5 (verifier fixes) | ✅ Done | Batch 5 marked Complete (`tasks.md:953`); commits `4f560aa`, `98e2e53`, `d1c2a30`, `a818fd6`, `3406246` |
| T25, T26 | ⏭️ Deferred | P2 (WEB-13/14), explicitly out of this round (`tasks.md:954`) |

Minor staleness, not a gap: `tasks.md:12` still reads "Approved — executing
T1–T24" and does not mention F1–F5.

---

## Iteration-1 Gap Disposition

| # | Iteration-1 gap | Disposition | Evidence |
| --- | --- | --- | --- |
| 1 | No restart resume trigger — `download()` had one call site (WEB-11 AC5) | ✅ **Closed** | `lib/app/dependency_injection/configure_dependencies.dart:422` — `(resumeWebDownloads ?? () => _resumeWebDownloads(locator))().ignore();` → `:460` `await locator<WebNovelDownloadService>().resumePending();`; `lib/main.dart:37` `runApp(await createApplication())` passes no override, so production takes the default. Container-level proof: `test/app/dependency_injection/configure_dependencies_test.dart:564-600` seeds a web book left `processing` with 1/3 stored, composes the container, then `:586` `await fetcher.lastRequested.future.timeout(10s)` — the resume must fire on its own or the test times out; `:594` `expect(fetcher.requests.map(…), [chapter 2, chapter 3])`, `:598` `expect(book?.status, BookStatus.ready)`. **Mutation 2 killed it.** |
| 2 | Per-host rate limit raced under concurrency (WEB-09 AC1, edge case E8) | ✅ **Closed** | `lib/features/web_source/data/services/polite_web_fetcher.dart:177-187` — the caller claims `_nextAllowedAt[key] = slot.add(minimumHostInterval)` **before** awaiting, so a concurrent caller reserves the slot after it. `test/features/web_source/data/services/polite_web_fetcher_test.dart:112-135` — three concurrent `fetch` calls to one host, `:131` `expect(clock.now.difference(start), greaterThanOrEqualTo(Duration(seconds: 2)))` (three requests owe two intervals). **Mutation 1 (restoring the read-then-write throttle) killed exactly this test.** |
| 3 | Inert cancel button for web books (WEB-11 AC6) | ⚠️ **Closed in production code, weak at the composition seam** | Routing: `lib/features/library/presentation/pages/library_page.dart:212-223` — `_cancelProcessing` branches on `book.sourceType`; wiring: `configure_dependencies.dart:432` — `cancelWebDownload: (bookId) => locator<WebNovelDownloadService>().cancel(bookId)`. Widget proof: `test/features/library/presentation/pages/library_page_test.dart:204-219` (list **and** grid) `expect(fixture.cancelledWebBookIds, ['9'])`; PDF unchanged at `:222-237` `expect(fixture.cancelledBookIds, ['2'])` + `expect(fixture.cancelledWebBookIds, isEmpty)`. **But** the only container-level assertion is `configure_dependencies_test.dart:625` `expect(page.cancelWebDownload, isNotNull)` — see **Mutation 8, survived**. |
| 4 | WEB-06 AC1 unmet (`TextProcessingService` still PDF-coupled) | ✅ **Resolved by amendment**, honestly recorded | `spec.md` **Amendments** section quotes the original wording verbatim, names the conflicting decision (AD-009, `.specs/STATE.md:69-75`, still `active`), states **what was kept** ("adding a source does not fork the pipeline") and **what was given up** ("a single generic `ContentSource` seam at the top of `TextProcessingService`"), and records that the user chose it on 2026-08-19. The amendment **narrows** the AC — it moves the "no source-specific types" obligation from `TextProcessingService` to `ChapterIngest` — and says so plainly rather than widening it silently. Not recorded in `.specs/STATE.md` (see Observations). |
| 5 | WEB-08 AC3 covered only indirectly | ✅ **Closed** | `test/features/web_source/domain/services/web_novel_download_service_test.dart:506-535` — a chapter body containing the line `Capítulo 7`, which `ChapterDetector._isHeading` (`lib/features/pdf_processing/domain/services/chapter_detector.dart:73-77`) genuinely matches; `:526` `expect(processing.chapters.length, 1)`, `:527` `expect(…single.cleanText, contains('Capítulo 7'))`, `:533` `expect(…single.title, 'Capítulo 1 do índice')`. **Mutation 7 (actually running `ChapterDetector` over the index-segmented chapter) was killed by these two tests and nothing else** — confirming they were the missing coverage. |
| 6 | Stale `tasks.md` | ✅ **Closed** | `tasks.md:948-954` — batches 1, 2, 3, 4b, 4, 5 all **Complete**; Phase 7 **Deferred (P2)**. |

---

## Spec-Anchored Acceptance Criteria

### P1: Import a web novel by URL (WEB-01, WEB-02, WEB-03)

All evidence in `test/features/web_source/domain/services/import_web_book_service_test.dart`.

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| AC1 series URL → book | title from series page; index = every listed chapter, source order | `:186` `expect(result.book.title, 'Obra sintética')`; `:201` `expect([for (final chapter in chapters) chapter.url], [4 urls])`; `:207` `expect([…sortOrder], [1, 2, 3, 4])`; `:208` `expect(result.book.pageCount, 4)` | ✅ PASS |
| AC2 chapter URL → same book | resolves the series URL, imports the same book | `:215` `expect(fromChapter.book.sourceRef, seriesUrl)`; `:217` identical URL list | ✅ PASS |
| AC3 unknown domain | reject naming the domain; no book | `:231` `expect(result.message, 'Site não suportado: outrosite.com')`; `:232` `expect(books.books, isEmpty)`; `:234` `expect(fetcher.requests, isEmpty)` | ✅ PASS |
| AC4 not an absolute http(s) URL | validation message; no book | `:242` `expect(result.message, 'Informe uma URL válida')`; `:243` no book | ✅ PASS |
| AC5 disallowed path | message stating the path is not permitted; no book | `:252` `expect(result.message, 'Este endereço não é permitido pelo site')`; `:253` no book | ✅ PASS |
| AC6 already imported | resolve to the existing book; no second book | `:263` `expect(second.book.id, first.book.id)`; `:264` `expect(books.books.length, 1)` | ✅ PASS |
| AC7 zero chapters | unsupported; "no chapters were found" | `:276` `expect(result.message, 'Nenhum capítulo encontrado')`; `:277` no book | ✅ PASS |

### P1: Read and narrate while chapters download (WEB-04, WEB-05)

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| AC1 enqueue all + `processing` + stored/indexed progress | every indexed chapter enqueued; status `processing`; progress = stored/indexed | `test/features/web_source/web_source_integration_test.dart:221` `expect(stored?.status, BookStatus.processing)`, `:224` counts `(total: 4, stored: 0, failed: 0)`; `web_novel_download_service_test.dart:426` `expect(processing.progressUpdates, [(downloading, 1/3), (2/3), (1.0)])` | ✅ PASS |
| AC2 open while `processing` with ≥1 stored | library allows Open | `test/features/library/presentation/widgets/book_item_test.dart:225` `expect(opened, same(book))` for `_webBook(stored: 1, indexed: 4)` (list **and** grid); `:252` a processing **PDF** book still shows no Open | ✅ PASS |
| AC3 blocks produced per stored chapter | narratable immediately | `web_novel_download_service_test.dart:410` `expect(blocksWhenStored, [1, 2, 3])`; `:401` `expect(processing.chaptersAtFirstActivation, 1)` | ✅ PASS |
| AC4 stop at the last stored chapter | stop; report next chapter not downloaded; not end-of-book | `test/features/narration/presentation/cubit/narration_cubit_test.dart:563` `expect(cubit.state.status, NarrationStatus.awaitingDownload)`; `test/features/narration/presentation/widgets/narration_player_bar_test.dart:208` renders the `awaitingDownload` bar; integration `web_source_integration_test.dart:278` same status at the boundary | ✅ PASS |
| AC5 all stored → `ready` | status transitions to ready | `web_source_integration_test.dart:314` `expect(book?.status, BookStatus.ready)`; `web_novel_download_service_test.dart:454` `expect(processing.activations, [('run-1', 3, 3, 3)])` | ✅ PASS |
| AC6 offline + fully stored → zero requests | no network request | `web_source_integration_test.dart:318-337` — read + narrate through a fetcher that throws on any call; `:328` `expect(content!.book.status, BookStatus.ready)`, `:336` `expect(cubit.state.status, NarrationStatus.completed)` | ✅ PASS |

### P1: Source-agnostic extraction pipeline (WEB-06, WEB-07, WEB-08)

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| AC1 **(amended)** one shared ingest core, no source-specific types, adding a source does not fork it | both orchestrators route clean chapter text through one `ChapterIngest`; the core names no source-specific type | *Shared core, both callers*: `lib/features/pdf_processing/domain/services/text_processing_service.dart:92` and `lib/features/web_source/domain/services/web_novel_download_service.dart:62,198` construct/consume the same `ChapterIngest`; `test/features/content_ingestion/domain/services/chapter_ingest_test.dart:124` `a second ingest on one run appends instead of replacing` covers the chaptered shape, `:38-120` the paged shape. *No-fork*: `test/architecture/web_source_architecture_test.dart:55-74` `expect(source, isNot(contains('TextProcessingService')))`. *"References no source-specific types"*: **no assertion anywhere.** By inspection `chapter_ingest.dart:1-6` imports only `text_processing_models.dart`, `text_processing_repository.dart`, `chapter_detector.dart` (for the `ProcessingIdGenerator` typedef only — the detector is never invoked) and `narration_block_splitter.dart`; no `Pdf*` type is referenced. | ⚠️ **Spec-precision / evidence gap** — behaviourally satisfied, first clause unasserted |
| AC2 PDF parity | same chapters and blocks as before, same input file | `git diff 69ad930..HEAD -- test/features/pdf_processing/domain/services/text_processing_service_test.dart` = **+24 / −0**, all fake-interface stubs (`stage` parameter, `findBySourceRef`, `activatePartialRun`, `updateRunCounts`); zero assertions changed or removed. `drift_text_processing_repository_test.dart:79` still asserts `[BookStatus.processing, ProcessingStage.extracting, 0.0]` after a default `createRun`, and `text_processing_service.dart:155` calls `createRun` without a `stage`, so the PDF path takes the unchanged default | ✅ PASS |
| AC3 index segmentation authoritative, no heuristic detection | use the index; do not run detection | `web_novel_download_service_test.dart:526` `expect(processing.chapters.length, 1)` and `:533` `expect(…title, 'Capítulo 1 do índice')` with a body containing a detector-matching heading line; also `:476` `expect(…sortOrder, [0, 1, 2])` and `:713` `[0, 2]` with a hole | ✅ PASS (iteration-1 note closed) |
| AC4 block order + per-book position persistence as for PDF | same ordering/resume behaviour | `test/architecture/web_source_architecture_test.dart:182` appended chapter narrates in `Chapters.sortOrder`; `test/features/visual_reader/domain/reader_domain_test.dart` `a position resumes onto the right chapter across a hole` → `expect([resolved.chapterId, resolved.blockId], ['c3', 'b3'])` | ✅ PASS |
| AC5 web book → text view, no original-document view | text view only | `test/features/visual_reader/presentation/pages/reader_page_test.dart:197,199` `TextReaderView` found / `OriginalPdfView` not; `:223-224` same when resumed in pdf mode; `:237` a **PDF** book still mounts `OriginalPdfView` | ✅ PASS |

### P1: Resumable, throttled, fault-tolerant download queue (WEB-09 … WEB-12)

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| AC1 ≤ 1 request/second per domain | per-host rate limit holds, sequential **and** concurrent | Sequential: `polite_web_fetcher_test.dart:81,85` each gap `greaterThanOrEqualTo(Duration(seconds: 1))`; per host not global at `:98` `Duration.zero` across hosts. Concurrent: `:131` `expect(clock.now.difference(start), greaterThanOrEqualTo(Duration(seconds: 2)))` for 3 concurrent same-host fetches; `:147` `expect(gapsBetween(transport), [Duration.zero])` for two different hosts; `:164` each concurrent caller gets its own response | ✅ PASS (iteration-1 gap closed) |
| AC2 429/503 + `Retry-After` | wait at least that duration | `:207` `≥ 5s` after 429; `:224` `≥ 7s` after 503; `:188` `≥ 5s` even with a second caller queued behind the host slot | ✅ PASS |
| AC3 transient → bounded exponential backoff → failed | retry to a bound, then mark failed | `:236` `expect(transport.requests.length, PoliteWebFetcher.maximumAttempts)`; `:242` `expect(gaps, const [1s, 2s, 4s])`; `web_novel_download_service_test.dart:679` `expect(source.entries[1].state, WebChapterState.failed)` | ✅ PASS |
| AC4 failed chapter → continue, stay readable | queue continues; stored chapters retained | `web_novel_download_service_test.dart:708` states `[stored, failed, stored]`; `:721` `expect(outcome, WebDownloadOutcome.paused)`; `:722` partial activation kept, `:724` `expect(processing.discards, isEmpty)` | ✅ PASS |
| AC5 restart resumes from the first non-stored chapter | no re-download of stored chapters | Service: `:786` `expect(fetcher.requests.map(…), [chapterUrl(3)])`; `:819` `expect(processing.createdRuns, isEmpty)` on a resumed run. Startup trigger: `:985-1010` `resumePending` re-enqueues, `:1013` skips a fully stored book, `:1028` never hands a PDF book to the web queue, `:1035` only web books still `processing`. Container: `configure_dependencies_test.dart:564-600` (see gap 1) | ✅ PASS (iteration-1 gap closed) |
| AC6 cancel stops requests, retains stored | stop issuing; keep stored chapters | Service: `:838` `expect(outcome, WebDownloadOutcome.cancelled)`, `:839` `expect(fetcher.requests.map(…), [chapterUrl(1)])`, `:840` states `[stored, pending, pending]`, `:845` no discard. UI route: `library_page_test.dart:218` `expect(fixture.cancelledWebBookIds, ['9'])` (list + grid). Composition: `configure_dependencies.dart:432`, asserted only as non-null (`configure_dependencies_test.dart:625`) | ⚠️ **PASS with a weak seam** (Mutation 8 survived) |
| AC7 fetched but no text | failed with an extraction reason; no empty chapter | `:753` state `failed`; `:754` `expect(…lastError, contains('abaixo do mínimo'))`; `:755` stored `[0, 2]`, no stub | ✅ PASS |
| AC8 every chapter fails extraction | book `unsupported` + layout message | `:923` `expect(processing.discards, [('run-1', BookStatus.unsupported)])`; `:924` message `'O layout do site não foi reconhecido'`; `:928` `expect(processing.chapters, isEmpty)`; negative cases at `:931`, `:948`, `:959` all `paused` with `messageFor(bookId)` null | ✅ PASS |

### Out of scope this round

| Requirement | State |
| --- | --- |
| WEB-13, WEB-14 (P2) | Not implemented — T25/T26 deliberately deferred. Repository affordances (`appendNew`, `knownUrls`, `failed`) exist and are covered by `test/features/web_source/data/repositories/drift_web_source_repository_test.dart`, with no service or UI consumer yet. As planned. |
| WEB-15 (P3) | ✅ `SiteRecipeRegistry` + `assets/site_recipes.json`; `test/features/web_source/domain/services/site_recipe_registry_test.dart:70` names each missing required field, `:101` rejects a bad `chapterIndexOrder` |

**Status**: 26 of 26 in-scope P1 criteria behaviourally satisfied. 1 spec-precision /
evidence gap (WEB-06 AC1, first clause). 1 criterion (WEB-11 AC6) correct in
production but with an undiscriminating assertion at the composition seam.

---

## Edge Cases

| Edge case | `file:line` + assertion | Result |
| --- | --- | --- |
| Same chapter URL twice in the index → stored once, one position | `test/features/web_source/data/services/html_recipe_parser_test.dart:202` `expect(urls, [capitulo-a, capitulo-b])`; `:206` `expect(sortOrders, [1, 2])` | ✅ |
| Chapter page `404` → mark failed, continue | `web_novel_download_service_test.dart:691` one request only, `:697` state `failed`; integration `web_source_integration_test.dart:346` counts `(total: 4, stored: 3, failed: 1)`, `:353` reader opens `[0, 2, 3]` | ✅ |
| No network at import → network message, no partial book | `import_web_book_service_test.dart:292-295` reason `network`, message `'Sem conexão com a internet'`, `books.books` empty, `source.replacements` empty | ✅ |
| Network drops mid-queue → pause, retain, resume later | Pause + retain: `web_novel_download_service_test.dart:721,724`. Resume now reaches the user: `configure_dependencies.dart:422` + `configure_dependencies_test.dart:564` | ✅ (iteration-1 ⚠️ closed) |
| Deleting a web book removes chapters, blocks, queue state | `test/features/web_source/data/database/web_chapter_entries_test.dart:152` `expect(await select(webChapterEntries).get(), isEmpty)` after the book is deleted | ✅ |
| Index resolved, nothing stored → no Open | `book_item_test.dart:237` `expect(find.byTooltip('Abrir Title'), findsNothing)` for `_webBook(stored: 0, indexed: 4)` (list + grid) | ✅ |
| Text below a meaningful minimum → failure, no stub | `html_recipe_parser_test.dart:89` (below), `:98` (exactly at the minimum passes); `web_novel_download_service_test.dart:753-755` | ✅ (spec leaves the minimum undefined; the recipe fixes it at 200) |
| Two downloads for different books → no interleaving beyond the per-domain limit | `polite_web_fetcher_test.dart:112-135` — three concurrent `fetch` calls through **one** `PoliteWebFetcher`, which is the DI singleton two draining books share (`configure_dependencies.dart` registers one). Mechanism-equivalent to two books; a two-book-shaped test was drafted during F2 and dropped (see Observations) | ✅ (mechanism-level) |
| Redirect chain leaves the recipe's domain → abandon | `polite_web_fetcher_test.dart:276` `expect(kind, WebFetchFailureKind.offDomain)`; `:278` `expect(transport.requests.length, 1, reason: 'the off-host URL is never requested')` | ✅ |

**9 of 9 covered** (iteration 1: 8 of 9, with E8 empirically violated).

---

## Discrimination Sensor

Depth: **P0-full** — 10 behaviour-level mutations, weighted toward the five fix
commits. Every mutation was applied in a temporary `git worktree` at `f144462`,
tested, and reverted; the worktree was removed and the real tree confirmed clean.

| # | File:line | Mutation | Tests run | Killed? |
| --- | --- | --- | --- | --- |
| 1 | `lib/features/web_source/data/services/polite_web_fetcher.dart:177-187` | Restored the pre-fix throttle (read `last`, await, **then** write) — the original iteration-1 defect | `test/features/web_source/data/services/polite_web_fetcher_test.dart` | ✅ Killed — `concurrent drains charges a full host interval to every concurrent request but the first` (14 passed, 1 failed) |
| 2 | `lib/app/dependency_injection/configure_dependencies.dart:422` | Removed the default startup resume (kept only the injected seam) | `test/app/dependency_injection/configure_dependencies_test.dart` | ✅ Killed — `startup resumes a partially downloaded web book with no explicit download call` (17 passed, 1 failed) |
| 3 | `lib/features/web_source/domain/services/web_novel_download_service.dart:118-121` | Dropped the `status != processing` guard in `resumePending` | `test/features/web_source` | ✅ Killed — `startup resume re-enqueues only the web books still processing` (149 passed, 1 failed) |
| 4 | `lib/features/library/presentation/pages/library_page.dart:216-222` | Removed the web branch — every cancel routes to the PDF cubit (the iteration-1 defect) | `test/features/library` | ✅ Killed — `list/grid cancelling a web book stops its download` (104 passed, 2 failed) |
| 5 | `lib/features/web_source/domain/services/web_novel_download_service.dart:164` | Dropped `stage: ProcessingStage.downloading` from `createRun` | `test/features/web_source`, `test/features/pdf_processing` | ✅ Killed — `leaves the book carrying the downloading stage while its queue drains` (249 passed, 1 failed) |
| 6 | `lib/features/pdf_processing/data/repositories/drift_text_processing_repository.dart:36` | Ignored the `stage` argument, hard-coding `extracting` again | `test/features/pdf_processing` | ✅ Killed — 4 failures incl. `create run records the stage a chaptered source starts in` |
| 7 | `web_novel_download_service.dart:198-223` | Ran `ChapterDetector` over the index-segmented chapter before ingest (the wrong implementation WEB-08 AC3 forbids) | `test/features/web_source` | ✅ Killed — **only** by `index-authoritative segmentation` ×2 (149 passed, 2 failed) |
| 8 | `lib/app/dependency_injection/configure_dependencies.dart:432` | Replaced the web cancel route with an inert `(bookId) async {}` — the route exists but reaches nothing | **full suite** | ❌ **SURVIVED — 612/612 passed** |
| 9 | `lib/features/visual_reader/domain/entities/reader_models.dart:120-123` | `bookIsReadable` made source-blind, so a **PDF** book becomes readable while `processing` | `test/features/visual_reader`, `test/features/library` | ✅ Killed — `a processing pdf book is never readable content` + `missing not-ready and stale active content return null` (175 passed, 2 failed) |
| 10 | `reader_models.dart:135` | Relaxed the ordering invariant `sortOrder <= previous` → `< previous` (duplicates allowed) | `test/features/visual_reader`, `test/features/narration` | ✅ Killed — `content rejects duplicate and out-of-order chapter sort orders` (153 passed, 1 failed) |

**Sensor depth**: P0-full
**Result**: **9/10 killed, 1 survived** — ❌ FAIL. No compile-error false kills:
every run reported assertion failures with a large passing majority.

---

## Gate Check

- **Gate command**: `flutter analyze && flutter test && flutter build apk --debug`
- `flutter analyze`: ✅ **No issues found** (exit 0)
- `flutter test`: ✅ **612 passed, 0 failed, 0 skipped** (exit 0)
- `flutter build apk --debug`: ✅ **Built `build/app/outputs/flutter-apk/app-debug.apk`** (exit 0)
- **Test count before the feature** (`69ad930`): **377**
- **After iteration 1** (`9309bf7`): **593**
- **After the fixes** (`f144462`): **612** — **+19** from the five fix commits, **+235** for the feature
- **Skipped**: none
- **Test integrity**: `git diff 9309bf7..HEAD -- test/` is **+489 / −7**. Every one of
  the seven deleted lines is a fake-signature or fixture-builder change
  (`FakeBookRepository` constructor and `findById`/`watchAll`, the `createRun`
  and `updateProgress` signatures, the `webBook` builder). **No test was deleted
  and no assertion was weakened.** Over the full range, `69ad930..HEAD`, the only
  deletions inside pre-existing suites are the `schemaVersion` 5 → 6 bump and
  PDF-file fixture fields that became nullable.

---

## Code Quality

| Principle | Status |
| --- | --- |
| Minimum code | ✅ |
| Surgical changes | ✅ The five fixes touch only the seams they name |
| No scope creep | ✅ P2 (T25/T26) still unimplemented |
| Matches patterns | ✅ Injectable seam mirroring `initializePdfEngine`; guarded registrations; hand-written fakes; `final class`; pt-BR UI strings; real `NativeDatabase` for repository tests (CLAUDE.md) |
| Spec-anchored outcome check | ⚠️ One amended-AC clause has no assertion (WEB-06 AC1) |
| Per-layer Coverage Expectation met | ⚠️ Domain and widget layers are 1:1 with the ACs; the composition layer asserts existence, not identity, for the cancel route |
| Every test maps to a spec requirement — no unclaimed tests | ✅ Spot-checked `web_novel_download_service_test.dart` and `polite_web_fetcher_test.dart`; every test traces to an AC, a listed edge case, or a Done-when criterion |
| Documented guidelines followed | ✅ `CLAUDE.md` (AD-002…AD-010, Drift migration procedure, test conventions, Conventional Commits) |
| Documented deviation | `web_novel_index_resolver.dart:36` `// SPEC_DEVIATION` — sealed result instead of the design's throwing signature; unchanged this round |

---

## Observations (checked, reported honestly)

1. **No test was deleted during the fixes.** The brief for this iteration stated
   that a library cancel assertion had been removed because it passed under the
   bug. `git diff 9309bf7..HEAD -- test/` shows **zero** removed `test(` blocks
   and only seven deleted lines, all signature/fixture edits enumerated above.
   `library_page_test.dart` is **+52 / −0**. Nothing was removed; the claim does
   not hold against the diff.
2. **The fetcher concurrency assertion was reworked before it was ever
   committed, and the rework was the right call — with one avoidable loss.**
   `polite_web_fetcher_test.dart` is **+91 / −0**, so nothing in the tree was
   rewritten; the earlier draft survives only in a scratch file. It asserted
   per-send gaps (`gapsFor(...) everyElement >= 1s`). That assertion is
   unsound with this harness: `FakeClock.delay` advances a single shared virtual
   instant synchronously, so three concurrent callers all record the *same*
   send timestamp and every gap is zero regardless of correctness. Replacing it
   with the total host interval charged (`clock.now - start >= 2s`) is the right
   response, and **Mutation 1 proves it discriminates the real defect**. What
   was avoidable: the draft also contained a *two books draining one host at
   once* test — the literal shape of spec edge case E8 — and that scenario was
   dropped rather than re-expressed under the new assertion, which it easily
   could have been. E8 is still covered by the same mechanism (one shared
   fetcher singleton), so this is a naming/traceability loss, not a coverage
   hole.
3. **A cancelled web download is re-enqueued at the next app launch.** Cancel
   leaves the book `processing` with pending entries
   (`web_novel_download_service.dart:176`), and `resumePending`
   (`:114-129`) re-enqueues exactly that shape. WEB-11 AC5 and AC6 are silent on
   which wins; the implementation chose AC5. Worth a product decision, not a
   spec violation as written.
4. **`.specs/STATE.md` was not updated.** The WEB-06 AC1 amendment lives only in
   `spec.md`; iteration 1's Fix 1 option (b) asked for it to be recorded in
   `STATE.md` as well. `STATE.md`'s Handoff block (`:85-94`) still describes the
   *narration* feature. Bookkeeping only.
5. **`spec.md`'s Requirement Traceability table is stale** — all 15 requirements
   still read `Pending`, and it still says "0 mapped to tasks, 15 unmapped ⚠️".
   See the traceability update below.

---

## Fix Plans

### Fix 1: The composition root's web-cancel route is not asserted to reach the download service (WEB-11 AC6) — Major

- **Root cause**: `configure_dependencies.dart:432` builds
  `cancelWebDownload: (bookId) => locator<WebNovelDownloadService>().cancel(bookId)`,
  but the only container-level assertion is
  `configure_dependencies_test.dart:625` `expect(page.cancelWebDownload, isNotNull)`.
  Replacing the lambda with `(bookId) async {}` leaves all **612** tests green
  (Mutation 8). The production wiring is correct today; the suite cannot tell if
  it stops being correct — and an inert cancel route is precisely the defect
  iteration 1 raised.
- **Fix task**: In `configure_dependencies_test.dart`, register a fake
  `WebNovelDownloadService` (or a recording `WebFetcher` plus a real in-flight
  download) before composing, then invoke
  `tester.widget<LibraryPage>(…).cancelWebDownload!('book-id')` and assert the
  call reaches the service. The test comment at `:626-627` says resolving the
  callback "pulls the asset-backed recipe registry"; pre-registering a fake
  service in the guarded locator avoids that entirely.
- **Verify**: the new test fails when `cancelWebDownload` is replaced by a
  no-op lambda.
- **Priority**: Major (test strength — no user-visible defect present today).

### Fix 2: WEB-06 AC1's "references no source-specific types" clause has no assertion — Minor

- **Root cause**: The amendment moved the obligation from `TextProcessingService`
  to `ChapterIngest`, but no test enforces it there. Inspection confirms
  `chapter_ingest.dart` names no `Pdf*` type today; nothing stops one appearing.
- **Fix task**: Add one source-scanning invariant to `test/architecture/` that
  fails if `lib/features/content_ingestion/**` references a `Pdf`-prefixed
  identifier or imports a source-specific extractor — mirroring the existing
  AD-010 scan at `web_source_architecture_test.dart:34`.
- **Verify**: the test fails when `PdfTextExtractor` is imported into
  `chapter_ingest.dart`.
- **Priority**: Minor.

### Fix 3: Bookkeeping — Cosmetic

- Record the WEB-06 AC1 amendment in `.specs/STATE.md` and refresh its Handoff
  block, which still names the narration feature.
- Update `spec.md`'s Requirement Traceability statuses and coverage line.
- `tasks.md:12` still reads "Approved — executing T1–T24".

---

## Requirement Traceability Update

| Requirement | Previous | New |
| --- | --- | --- |
| WEB-01 | ✅ Verified | ✅ Verified |
| WEB-02 | ✅ Verified | ✅ Verified |
| WEB-03 | ✅ Verified | ✅ Verified |
| WEB-04 | ✅ Verified | ✅ Verified |
| WEB-05 | ✅ Verified | ✅ Verified |
| WEB-06 | ❌ Needs Fix | ⚠️ Verified against the amended AC — first clause unasserted (Fix 2) |
| WEB-07 | ✅ Verified | ✅ Verified — PDF parity re-confirmed after the `createRun` and `ReaderBookContent` changes |
| WEB-08 | ⚠️ Indirect | ✅ Verified — AC3 now directly asserted |
| WEB-09 | ❌ Needs Fix | ✅ Verified — concurrency race fixed and covered; E8 closed |
| WEB-10 | ✅ Verified | ✅ Verified |
| WEB-11 | ❌ Needs Fix | ⚠️ Verified — AC5 fully closed; AC6 correct but its composition seam is untested (Fix 1) |
| WEB-12 | ✅ Verified | ✅ Verified |
| WEB-13 | ⏭️ Deferred | ⏭️ Deferred (P2) |
| WEB-14 | ⏭️ Deferred | ⏭️ Deferred (P2) |
| WEB-15 | ✅ Verified | ✅ Verified (registry scope) |

---

## Summary

**Overall**: ⚠️ Nearly ready — one surviving mutant and one unasserted AC clause
stand between this and PASS.

**Spec-anchored check**: 26 of 26 in-scope P1 criteria behaviourally satisfied;
1 spec-precision / evidence gap (WEB-06 AC1); 1 criterion correct in production
with an undiscriminating composition-seam assertion (WEB-11 AC6).
Edge cases: **9 of 9** covered (iteration 1: 8 of 9).

**Sensor**: 9/10 killed, 1 survived.

**Gate**: analyze clean, **612** tests passed (593 → 612), debug APK built.

**What the fixes genuinely closed**: the startup resume is wired into the real
composition path and proven by a container test that cannot pass without it; the
per-host rate limit now reserves its slot before awaiting and the concurrency
regression is killed by a test that discriminates the original defect; the
library cancel button routes web books to the download service in both list and
grid while the PDF path is unchanged; the discarded `downloading` stage is
persisted and the fake now mirrors the repository's monotonic rule so the class
of defect stays catchable; WEB-08 AC3 has a direct assertion that no other test
covers; `tasks.md` is current. The WEB-06 AC1 amendment is honestly recorded —
it narrows the criterion and says so.

**Issues found**: Fix 1 (Major), Fix 2 (Minor), Fix 3 (Cosmetic).

**Next steps**: route Fix 1 to an implementer, add Fix 2's architecture scan,
then re-verify. Neither blocks a build or a user path; both are about the suite's
ability to keep the fixes fixed.
