# Text Processing Validation — Partial Cross-Verification Pass A

**Date**: 2026-07-18  
**Spec**: `.specs/features/text_processing/spec.md`  
**Diff range assessed**: `fd557f5..4333a6d` (F0 and T1–T13 only)  
**Verifier**: independent cross-verifier (author ≠ verifier)  
**Excluded from outcome assessment**: T14 / `87e7b10` (pending independent Pass B)

## Verdict

**Final reverification after `d58cfba`: PASS.** CPU-bound processing is protected
at the production composition boundary, composed terminal/reset paths assert
exact durable outcomes, and caller-remapped chapter/block identities are now
asserted as a conjunction. The formerly surviving mutation that persisted a
temporary worker block ID is killed by the new exact assertion.

T14 was subsequently assessed and its formerly open composition gaps were
closed; the consolidated final evidence appears below.

## Task Completion

| Scope | Status | Notes |
| --- | --- | --- |
| T1–T13 and F0 | ✅ Verified | E4/default, composed lifecycle, reset, payload IDs and cancellation verified |
| T14 | ✅ Verified | Composition, terminal paths, reset, and default isolate boundary verified |

## Spec-Anchored Acceptance Criteria

Abbreviations: E = extract, C = clean, H = chapters, B = blocks, X = cancel.

| AC | Spec-defined outcome | `file:line` + exact assertion | Result |
| --- | --- | --- | --- |
| E1 | successful import automatically starts the returned book | `test/features/import_book/presentation/cubit/import_book_cubit_test.dart:38` — `expect(processing.processedBookIds, ['id'])` | ✅ |
| E2 | processing / 0 / extracting | `test/features/pdf_processing/data/repositories/drift_text_processing_repository_test.dart:77` — `expect([book.status, book.processingProgress, book.processingStage], [BookStatus.processing, 0.0, ProcessingStage.extracting])` | ✅ |
| E3 | exact ordered one-based raw pages | `test/features/pdf_processing/data/services/pdfrx_pdf_text_extractor_test.dart:42` — `expect(pages.map((e) => e.pageNumber), [1, 2, 3])`; `:44` — exact page texts | ✅ |
| E4 | monotonic 0–.40 without blocking UI frames/state | `test/app/dependency_injection/configure_dependencies_test.dart:160-166` — production composition completes, observes workers, and asserts every identity differs from caller; `lib/app/dependency_injection/configure_dependencies.dart:40,121` — default/injection are isolate-backed | ✅ |
| E5 | whitespace-only → unsupported / 0 / exact message / no derived | `test/features/pdf_processing/domain/services/text_processing_service_test.dart:92` — `ProcessingResult.unsupported('Este PDF não possui texto extraível')`; `:98-99` — unsupported discard and no activation | ✅ |
| E6 | other failure → failed / 0 / exact message / no partial | `test/features/pdf_processing/domain/services/text_processing_service_test.dart:111` — exact failed message; `:115` — failed discard | ✅ |
| E7 | complete raw collection retained before derived activation | `test/features/pdf_processing/data/repositories/drift_text_processing_repository_test.dart:94-99` — exact staged raw/clean and active read is null; `:195-198` — complete activated payload | ✅ |
| C1 | cleaning stage .40–.60 monotonic | `test/features/pdf_processing/domain/services/text_processing_service_test.dart:68` — exact `.40, .50, .60` cleaning progress | ✅ |
| C2 | remove C0 except LF/tab | `test/features/pdf_processing/domain/services/text_cleaner_test.dart:13` — `expect(clean('a\\u0000b\\t c\\nx').text, 'ab c\\nx')` | ✅ |
| C3 | trim/collapse horizontal whitespace and blank runs | `test/features/pdf_processing/domain/services/text_cleaner_test.dart:16` — `'um dois'`; `:19` — `'A\\n\\nB'` | ✅ |
| C4 | remove complete-line URL/page number | `test/features/pdf_processing/domain/services/text_cleaner_test.dart:22` — `'A\\nB'`; `:25` — `'A\\nB'` | ✅ |
| C5 | same-edge ≥60% and ≥3 removal | `test/features/pdf_processing/domain/services/text_cleaner_test.dart:39-41` — exact header/footer sets and cleaned page; `:48,55` — below-threshold empty profile | ✅ |
| C6 | lowercase hyphen continuation joins | `test/features/pdf_processing/domain/services/text_cleaner_test.dart:58` — `expect(clean('pala-\\nvra').text, 'palavra')` | ✅ |
| C7 | unmatched content/order preserved | `test/features/pdf_processing/domain/services/text_cleaner_test.dart:61` — exact nonmatching hyphens preserved | ✅ |
| C8 | raw remains immutable and clean retained | `test/features/pdf_processing/domain/services/text_cleaner_test.dart:66` — raw object unchanged; repository test `:94` — `['Raw', 'Texto.']` | ✅ |
| H1 | detecting stage .60–.75 monotonic | `test/features/pdf_processing/domain/services/text_processing_service_test.dart:68` — exact `.675, .75` values | ✅ |
| H2 | exact complete-line PT/EN/Volume/prologue/epilogue/extra/CJK patterns | `test/features/pdf_processing/domain/services/chapter_detector_test.dart:19,34,45` — exact title collections and `第12章` | ✅ |
| H3 | IDs/order/title/body/pages exact | `test/features/pdf_processing/domain/services/chapter_detector_test.dart:86-99` — exact IDs, sort orders, body and page ranges | ✅ |
| H4 | preamble → `Início` | `test/features/pdf_processing/domain/services/chapter_detector_test.dart:54-55` — `['Início', 'Capítulo 1']` and exact preamble | ✅ |
| H5 | no heading → one book-title fallback | `test/features/pdf_processing/domain/services/chapter_detector_test.dart:62-64` — title/body/pages exact | ✅ |
| H6 | empty chapters retained | `test/features/pdf_processing/domain/services/chapter_detector_test.dart:70` — `expect(...cleanText, ['', ''])` | ✅ |
| B1 | building stage .75–.95 monotonic | `test/features/pdf_processing/domain/services/text_processing_service_test.dart:68` — exact `.95` block stage | ✅ |
| B2 | paragraph order; whitespace-only omitted | `test/features/pdf_processing/domain/services/narration_block_splitter_test.dart:30-31` — `['Primeiro','Segundo']`, `[0,1]`; `:107` — empty | ✅ |
| B3 | ≤3000 exact trimmed block | `test/features/pdf_processing/domain/services/narration_block_splitter_test.dart:24-26` — exact text/normalized/count | ✅ |
| B4 | >3000 sentence, whitespace, hard-limit fallback | `test/features/pdf_processing/domain/services/narration_block_splitter_test.dart:34,42,50,58,67-68` — exact split sequences and bounds | ✅ |
| B5 | exact block payload fields | `test/features/pdf_processing/domain/services/narration_block_splitter_test.dart:87-90` — IDs/chapter/order/text/count/page conjunction | ✅ |
| B6 | empty body → zero blocks | `test/features/pdf_processing/domain/services/narration_block_splitter_test.dart:107` — `isEmpty` | ✅ |
| B7 | atomic ready/counts/progress/completed replacement | `test/features/pdf_processing/data/repositories/drift_text_processing_repository_test.dart:183-198` — exact book tuple and complete content | ✅ |
| X1 | stage/percent and accessible cancel action | `test/features/library/presentation/widgets/book_item_test.dart:118-132` — exact semantics, indicator value and book payload | ✅ |
| X2 | cancel boundary/discard/importing/0 and worker cancel | `test/features/pdf_processing/domain/services/text_processing_service_test.dart:167-170`; repository test `:340` — exact outcome, run ID, status and progress | ✅ |
| X3 | exact cancellation message and no staged visibility | `test/features/pdf_processing/presentation/cubit/text_processing_cubit_test.dart:80-81`; repository test `:323-328` — exact message/state and empty staged tables | ✅ |
| X4 | late cancel leaves ready result | `test/features/pdf_processing/domain/services/text_processing_service_test.dart:270-273` — completed before/after cancel and no discard | ✅ |
| X5 | duplicate request joins same future/no competing worker | `test/features/pdf_processing/domain/services/text_processing_service_test.dart:233-236` — identical future and one extraction; `:260-264` — global serialization | ✅ |

**Spec-anchored total after final correction**: 33/33 applicable outcomes match;
the previously open E4 and B5 discrimination gaps are closed.

## Edge Cases

| Edge | Evidence | Result |
| --- | --- | --- |
| zero pages/whitespace → unsupported | service test `:92-99` exact unsupported result/discard/no activation | ✅ |
| corrupt/protected → failed without bypass | extractor test `:66-71` and `:93-98` exact sanitized failure and zero pages | ✅ |
| empty page retained among text pages | extractor test `:42-49` exact three pages including empty text | ✅ |
| delayed/repeated progress cannot decrease/exceed stage | repository test `:147-164` exact monotonic/clamped values | ✅ |
| `. ! ? 。 ！ ？` split candidates | block splitter test `:80` exact multilingual reconstruction/splits | ✅ |
| chapter-like narrative line stays narrative | chapter detector test `:77` exact narrative content | ✅ |
| final replacement failure preserves prior dataset | repository test `:213-225` exact prior run/content | ✅ |
| retry replaces rather than duplicates | repository test `:258-261` exact new raw pages and one surviving run | ✅ |

## Discrimination Sensor

All mutations ran in `/tmp/vox_novel_verify`; the real tree was untouched.

| Mutation | Target | Observed kill |
| --- | --- | --- |
| page number `n → n+1` | extractor event mapping | ✅ killed at extractor test line 42 (`[2,3,4]` vs `[1,2,3]`) |
| activation `ready → failed` | Drift atomic activation | ✅ killed at repository test line 183 |
| cancellation terminal `importing → failed` | service rollback | ✅ killed at service tests lines 170 and 287 |

**Sensor**: 3/3 killed.

## Whole-HEAD Gate (T14 not outcome-assessed)

- `flutter analyze`: PASS, no issues.
- `flutter test --reporter compact`: PASS, **227 passed**, 0 failed, 0 skipped.
- `flutter build apk --debug`: PASS; APK produced.
- Test declarations: baseline `fd557f5` = 87; HEAD = 188; delta +101.
- `git diff --check fd557f5..4333a6d`: only expected PDF xref trailing
  spaces in the binary-like selectable fixture; no source whitespace errors.

## Code Quality

| Check | Result |
| --- | --- |
| Surgical feature-first structure / existing patterns | ✅ |
| Exact-value, non-shallow tests | ✅ strong across domain/repository/UI |
| Payload conjunctions | ✅ |
| No skip/disabled tests or `SPEC_DEVIATION` markers | ✅ |
| Guidelines (`analysis_options.yaml`, `.github/workflows/ci.yml`, `docs/spec.md`) | ✅ |
| CPU-bound cleaner/chapter/block work off caller isolate | ✅ `_cpu` wraps cleaner profile/page transforms and chapter/block generation at service lines 201, 207, and 227; production default is isolate-backed |

## Ranked Gaps

None after `d58cfba`.

## Pass-B Handoff

Pass B must independently assess only T14 (`87e7b10`), including composition,
reset/disposal, root import→ready→restart/delete, failure/cancel seams, and frame
responsiveness. It must not treat the whole-HEAD gate above as T14 outcome
evidence.

## Reverification after `30835ef`

### Required focus evidence

1. **CPU-bound work and production default**
   - `lib/features/pdf_processing/domain/services/text_processing_service.dart:201`
     executes header/footer profiling through `_cpu`.
   - Line 207 executes per-page cleaning through `_cpu`.
   - Lines 227–238 execute chapter detection and narration block splitting in
     one `_cpu` computation.
   - Lines 342–352 record worker identity and implement the production
     `Isolate.run` executor.
   - `lib/app/dependency_injection/configure_dependencies.dart:42,122` defaults
     composition to and injects `isolateProcessingExecutor`.
   - `test/features/pdf_processing/domain/services/text_processing_service_test.dart:83-86`
     asserts completion, nonempty worker observations, every identity different
     from the caller, and exact activation `[2,1,1]`.

2. **Composed no-text/corrupt/cancel**
   - `test/app/dependency_injection/configure_dependencies_test.dart:186-192`
     asserts exact outcome, exact message, exact durable status, and calls the
     zero-row conjunction.
   - Lines 211–224 assert exact cancelled result, exact run cancellation,
     `importing`, progress `0`, zero rows, and completed processing future.
   - Lines 280–284 assert all four staging/derived tables are empty.

3. **Reset during active extraction**
   - `test/app/dependency_injection/configure_dependencies_test.dart:249-260`
     starts active extraction, awaits the worker seam, resets dependencies,
     asserts exact cancelled run ID and all Cubits closed, reopens the file
     database, and asserts zero processing rows.

### Focused gate

- `flutter analyze`: PASS after rerunning sequentially (initial parallel run
  hit a Flutter Swift-package symlink race, not a source failure).
- `flutter test test/features/pdf_processing/domain/services/text_processing_service_test.dart test/app/dependency_injection/configure_dependencies_test.dart`:
  PASS, 22 tests.

### Targeted mutation sensor (`/tmp/vox_novel_reverify`)

| Mutation | Outcome |
| --- | --- |
| DI default `isolateProcessingExecutor → inlineProcessingExecutor` | ❌ **Survived** 22 relevant tests |
| no-text message → `Sem texto` | ✅ Killed at composed test line 187 |
| remove `TextProcessingCubit.close()` service cleanup | ✅ Killed at reset test line 254 |

**Sensor result**: 2/3 killed, 1 survived → FAIL under the mandatory
discrimination rule. The real working tree was not mutated.

## Follow-up reverification after `24e49a8`

### Evidence-or-zero

- **Production default executor**:
  `test/app/dependency_injection/configure_dependencies_test.dart:149-166`
  configures dependencies without passing `processingExecutor`, processes
  selectable text, asserts completion, asserts a nonempty worker collection,
  and asserts every worker identity differs from the caller.
- **Caller-side ID generation/remapping**:
  `lib/features/pdf_processing/domain/services/text_processing_service.dart:223-260`
  creates temporary chapter/block IDs inside workers, then invokes `_chapterId`
  and `_blockId` on the caller and remaps `block.chapterId`.
- **Payload evidence**:
  `test/features/pdf_processing/domain/services/text_processing_service_test.dart:48-59`
  asserts outcome/counts/raw/clean/title/block text, but has **no assertion** for
  final chapter ID, final block ID, or the remapped block→chapter conjunction.
- **Cancellation evidence**:
  service tests lines 187–189 assert exact cancelled results and extractor run
  ID; lines 203–242 retain cancellation coverage at cleaning, chapter, and
  block boundaries. Composed cancellation remains asserted at dependency test
  lines 230–247.

### Gate

- `flutter analyze`: PASS, no issues.
- Focused service + dependency tests: PASS, **23 tests**, 0 failed.

### Follow-up mutations (`/tmp/vox_novel_followup`)

| Mutation | Outcome |
| --- | --- |
| DI default `isolateProcessingExecutor → inlineProcessingExecutor` | ✅ Killed by composition test line 166 |
| final block ID `_blockId() → block.id` (temporary worker ID persisted) | ❌ Survived selectable-content service test |

**Follow-up sensor**: 1/2 killed, 1 survived → **FAIL**. Real implementation was
not changed.

## Final reverification after `d58cfba`

### Consolidated focus matrix

| Required outcome | Implementation evidence | Exact test evidence | Result |
| --- | --- | --- | --- |
| CPU-bound cleaner/chapter/block work outside caller; production default isolate-backed | `lib/features/pdf_processing/domain/services/text_processing_service.dart:201,207,223-246,360-370`; `lib/app/dependency_injection/configure_dependencies.dart:40,121` | `test/app/dependency_injection/configure_dependencies_test.dart:149-166` — default composition observes nonempty workers and `expect(workers.every((identity) => identity != caller), isTrue)` | ✅ |
| no-text/corrupt/cancel exact messages/status and zero staging/orphans | service lines 185–194 and 316–337; repository discard transaction | dependency test `:186-192` — exact outcome/message/status + zero-row helper; `:234-247` — exact cancel/run/importing/0/zero rows | ✅ |
| reset during active extraction cancels and reopens without staging | processing Cubit close awaits service close; service close cancels active runs | dependency test `:272-284` — exact cancelled run, all Cubits closed, reopened database and all four processing tables empty | ✅ |
| caller-generated IDs replace temporary worker IDs and preserve relationship | service lines 223–260 generate worker drafts then remap chapter/block IDs on caller | service test `:60` — `expect(...chapter.id, 'chapter-2')`; `:61` — `expect(...block.id, 'block-3')`; `:62` — `expect(block.chapterId, chapter.id)` | ✅ |
| cancellation remains exact at every pipeline boundary | service cancellation checks before page/unit staging and before activation | service tests `:187-189,203-242,292-306`; composed test `:230-247` | ✅ |

### Final gate

- `flutter analyze`: PASS, no issues.
- Focused service + dependency tests: PASS, **23 tests**, 0 failed.

### Final discrimination sensor

Scratch copy: `/tmp/vox_novel_final_verify`; real tree untouched.

| Mutation | Expected detector | Outcome |
| --- | --- | --- |
| `id: _blockId()` → `id: block.id` | service test exact final block ID | ✅ Killed at `text_processing_service_test.dart:61`: expected `block-3`, actual `worker-1` |

The prior production-default mutation was already killed after `24e49a8` by the
direct composition assertion at dependency test line 166. Across the final
follow-up chain, all originally required high-risk mutations are killed.

## Final Summary

**Overall: PASS ✅**

- Spec-anchored outcomes: 33/33 applicable outcomes matched.
- Final focused gate: 23 passed, 0 failed.
- Analyzer: clean.
- Required mutation regressions: all killed.
- Remaining ranked gaps: none.

---

## Historical Pass B Baseline — T14 Composition and Root Integration (Superseded)

**Scope assessed**: T14 commit `87e7b10` only  
**Verifier**: independent cross-verifier (author ≠ T14 author)  
**Focused command**:
`flutter test test/app/dependency_injection/configure_dependencies_test.dart test/widget_test.dart --reporter compact`

### Pass-B Verdict

**T14: FAIL (verification gaps).** Production composition, injectable seams,
automatic import→processing wiring, the durable happy path through restart, and
final deletion are covered with exact assertions. The T14 test surface does not
exercise the composed no-text, corrupt, or cancellation paths, and reset
coverage does not prove worker/port cancellation or absence of a staged run.
The feature remains **overall FAIL** because Pass A's E4 responsiveness failure
also remains unchanged.

### T14 Done-When Evidence

| T14 criterion | Spec/task-defined outcome | `file:line` + exact assertion | Result |
| --- | --- | --- | --- |
| Production initializes `pdfrx` before engine access and registers one processing lifecycle | initializer runs once before extractor registration; extractor/repository/service/Cubit are registered once | `test/app/dependency_injection/configure_dependencies_test.dart:64` — `expect(locator.isRegistered<PdfTextExtractor>(), isFalse)`; `:73` — `expect(initializationCalls, 1)`; `:48-51` — exact four processing registrations; `:95-99` — existing singleton instances are reused | ✅ |
| Tests inject extractor/repository/worker seams without native/global calls | application configuration accepts injected extractor/repository/initializer and awaits configuration | `test/widget_test.dart:57` — `pdfTextExtractor: _TextExtractor()`; `:66-80` — injected processing seams forwarded; `:89-100` — application remains uncreated until configuration completes and uses the registered router | ✅ |
| Reset cancels workers, closes Cubits/ports/database/router, and leaves no staged run | all active processing resources close and no staged rows remain | `test/app/dependency_injection/configure_dependencies_test.dart:119-125` — application/library/import/processing Cubits are closed and DB rejects queries; no assertion locates worker/port cancellation, router disposal behavior, or empty staged rows | ❌ GAP |
| Valid selectable-text PDF automatically reaches exact durable ready data after restart | ready/1/completed/run ID/counts and exact raw/clean/chapter/block payload survive restart | `test/widget_test.dart:145` — `expect(locator<ImportBookCubit>().state.status, ImportBookStatus.idle)`; `:152-158` — exact ready state/count conjunction; `:160-186` — exact durable raw, clean, chapter and block values; `:202-221` — exact book/run and row counts after restart | ✅ |
| No-text, corrupt, cancellation, and final deletion produce exact outcomes with no partial/orphan data | each composed terminal path has its specified status/message and no staged/orphan data | final deletion only: `test/widget_test.dart:282-284` — empty library and PDF/cover absent. Searches of T14 tests find no no-text, corrupt, cancellation-message/status, or staged/orphan assertions | ❌ GAP |
| UI remains frame-responsive during an injected pending page | frames and state remain observable while a page is pending | no T14 assertion; the root extractor at `test/widget_test.dart:527-530` emits synchronously and never suspends | ❌ GAP; also consistent with Pass A E4 |
| Suite count does not decrease; analysis and Android build pass | full build gate passes with nondecreasing suite | Pass A whole-HEAD gate: analysis PASS, 227 tests PASS, APK build PASS, declaration delta +101 | ✅ gate evidence |

### T14-Applicable Acceptance and Edge Coverage

| Outcome | Evidence | Result |
| --- | --- | --- |
| E1 automatic processing from committed import | `test/widget_test.dart:135-158` — UI import finishes in idle and exact persisted state is `ready`, progress `1`, stage `completed`, run/counts exact | ✅ |
| E3/E7/C8/H3/B5/B7 durable payload conjunction | `test/widget_test.dart:160-186` — exact raw/clean/chapter/block fields; `:202-221` — active result persists through restart | ✅ |
| X2/X3 composed cancellation and no staged visibility | no T14 cancellation fixture or exact cancellation/staging assertion | ❌ GAP |
| unsupported and corrupt composed failure edges | no T14 no-text/corrupt extractor fixture or exact status/message/orphan assertion | ❌ GAP |
| final deletion removes active content | `test/widget_test.dart:279-284` proves UI/book files disappear; Pass A/T13 repository tests prove cascaded processing rows, but T14 root test does not itself assert processing tables after final deletion | ⚠️ partial composition evidence |
| retry/restart does not duplicate active content | `test/widget_test.dart:202-221` — one raw page, chapter, and block after restart | ✅ |

### Pass-B Discrimination Sensor

Mutation ran only in `/tmp/vox_novel_t14_mutation`; the real tree was untouched.

| Mutation | Target | Observed kill |
| --- | --- | --- |
| Removed automatic DI wiring by changing `ImportBookCubit(textProcessingCubit: locator())` to `textProcessingCubit: null` | `lib/app/dependency_injection/configure_dependencies.dart:136-140` | ✅ killed by `test/widget_test.dart:152`: expected `BookStatus.ready`, actual `BookStatus.importing` |

**Sensor**: 1/1 killed.

### Pass-B Focused Gate

- **Result**: 10 passed, 0 failed, 0 skipped.
- **Real tree after sensor**: unchanged by mutation; only this validation report
  is updated by Pass B.

### Pass-B Code Quality

| Check | Result |
| --- | --- |
| Composition changes are surgical and use existing GetIt/injection patterns | ✅ |
| Exact happy-path payload assertions are non-shallow | ✅ |
| All T14 done-when criteria have evidence-or-zero accounting | ✅ |
| Per-layer failure/cancellation/reset coverage expectation met | ❌ |
| Guidelines (`analysis_options.yaml`, `.github/workflows/ci.yml`, `docs/spec.md`) followed | ✅ |

### Consolidated Ranked Gaps

1. **Major — E4 / responsiveness (Pass A)**: CPU-bound cleaning, chapter
   detection, and block splitting remain on the caller isolate; no CPU-bound
   frame-responsiveness test exists.
2. **Major — T14 terminal-path integration coverage**: add composed root tests
   for no-text, corrupt input, and cancellation that assert exact
   statuses/messages and zero partial/orphan/staged rows.
3. **Major — T14 reset lifecycle coverage**: add an injected pending worker/run,
   reset dependencies, and assert worker cancellation/port closure, closed
   router/Cubits/database, and no staged run.

## Final Cross-Verification Summary

**Historical outcome before validation fixes**: ❌ Not ready (superseded by the final PASS above)  
**Spec-anchored result**: Pass A matched 32 ACs and failed E4; Pass B confirms
the T14 happy path but finds two additional integration-coverage gaps.  
**Gate**: whole-HEAD build gate PASS; Pass-B focused tests 10/10 PASS.  
**Sensor**: 4/4 mutations killed across Pass A and Pass B.
