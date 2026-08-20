# Web Source Import Validation — Iteration 3 (final)

**Date**: 2026-08-20
**Spec**: `.specs/features/web_source_import/spec.md` (including the
**Amendments** section, 2026-08-19)
**Diff range**: `69ad930..HEAD` (`c58d705`) — full feature surface.
Delta re-verified this round: `f144462..c58d705`
**Verifier**: independent sub-agent, iteration 3 of a 3-iteration bound
(author ≠ verifier). Read-only over the real tree; all eight mutations ran in a
throwaway `git worktree` that was removed afterwards. Real tree confirmed clean
at `c58d705`.

**Verdict**: ✅ **PASS** — both iteration-2 gaps are genuinely closed (the
surviving mutant is now killed, and killed by a subtler variant of itself too),
no behavioural acceptance criterion is unmet, the gate is green at **613** tests,
and no regression was introduced. Two **minor, non-blocking residuals** are
recorded below: the new WEB-06 architecture scan is name-shaped rather than
import-shaped (one probe mutant survives it), and the same scan does not strip
comments, unlike its sibling in the same file.

---

## What changed since iteration 2

One commit, `c58d705`, **touching no production code** (`git diff
f144462..c58d705 -- lib/` is empty). It changes two test files plus bookkeeping:

| Change | Purpose |
| --- | --- |
| `test/app/dependency_injection/configure_dependencies_test.dart` +70 / −10 | Replaces the undiscriminating `expect(page.cancelWebDownload, isNotNull)` with a real drain through the composed router (iteration-2 Fix 1) |
| `test/architecture/web_source_architecture_test.dart` +16 / −0 | New scan: the shared ingest core names no source-specific type (iteration-2 Fix 2) |
| `.specs/STATE.md`, `spec.md`, `tasks.md` | AD-011, refreshed handoff, traceability statuses, tasks header (iteration-2 Fix 3) |

No test block was deleted: the single removed `testWidgets(` line is the rename
of `'the composed library page carries a web cancel route'` →
`'the composed library page stops a running web download'`.

---

## Iteration-2 Gap Disposition

### Gap 1 (Major) — WEB-11 AC6 composition seam had no discriminating assertion

✅ **Closed, and closed on the requirement rather than on the mutation.**

Evidence: `test/app/dependency_injection/configure_dependencies_test.dart:605-648`
— seeds a web book left `processing` with chapter 1 of 3 stored
(`:613`), composes the container with a synchronous `SiteRecipeRegistry`
(`:623`) and a gated fetcher (`:614`), opts out of the startup resume so it
cannot race (`:626`), pumps the real `GoRouter` (`:629-631`), starts a drain
(`:635`), asserts the queue is genuinely mid-chapter
(`:637` `expect(fetcher.requests.map(…), [_webChapterUrl(2)])`), invokes the
page's own callback (`:639` `page.cancelWebDownload!(_webBookId)`), releases the
gate, pumps five frames, and asserts chapter 3 is never requested
(`:647`).

Adversarial checks (both **killed**, see sensor table):

- **Mutation 1** — the exact iteration-2 survivor: `cancelWebDownload:
  (bookId) async {}`. Killed at `:647`. The five-frame pump window is
  empirically sufficient: with the route inert, chapter 3 *is* requested.
- **Mutation 2** — the subtler variant the mutation-shaping worry predicts:
  the route still calls the real service, but with a mangled id
  (`cancel('$bookId-x')`). Also killed. The test therefore asserts *identity*,
  not merely *reachability* — it is not shaped to its own mutation.
- **Mutation 6** — gutting `WebNovelDownloadService.cancel` itself (never set
  `requested`) is killed by this container test as well as by the service and
  integration suites.

Residual (observation, not a gap): the container test invokes
`page.cancelWebDownload` directly rather than tapping the widget, so removing
the `sourceType == web` branch inside `LibraryPage` (**Mutation 7**) is caught by
`library_page_test.dart`, not here. The two halves of the route are each
covered; no single test spans tap → service. That is normal layering for this
codebase.

### Gap 2 (Minor) — WEB-06 AC1 first clause had no assertion

⚠️ **Closed for the canonical violation; the scan is narrower than the clause.**

Evidence: `test/architecture/web_source_architecture_test.dart:55-69` reads
`lib/features/content_ingestion/domain/services/chapter_ingest.dart` and asserts
that `RegExp(r'\b(Pdf[A-Z]\w*|\w*Pdf\b|Web[A-Z]\w*|SiteRecipe\w*)')` matches
nothing.

- **Mutation 3** — the violation the fix task named: import
  `pdf_text_extractor.dart` and add a `PdfTextExtractor? extractor` field.
  Compiles, `flutter analyze` clean, and the scan **kills** it. ✅
- **Mutation 4** — a realistic web-side fork the clause also forbids: import
  `html_recipe_parser.dart` (a `web_source` **data**-layer file) and hold
  `HtmlRecipeParser? parser; ChapterParseResult? lastParse;`. Compiles, analyze
  clean, and **the full 613-test suite stays green**. ❌ **Survived.**

Why it slips through: the pattern is keyed on type *names*. `\bWeb[A-Z]` needs a
word boundary before `Web`, so `PoliteWebFetcher` does not match; nothing in the
pattern matches `HtmlRecipeParser`, `ChapterParseResult`, `ChapterParsed`, or
`PdfrxPdfTextExtractor` (whose `Pdf` is followed by lowercase `r`, and whose
second `Pdf` is followed by `T`). The sibling AD-010 test at `:34-53` in the same
file already demonstrates the stronger, import-path-shaped form.

Scope note, in the scan's favour: `lib/features/content_ingestion/` contains
exactly one file today, so pinning the scan to `chapter_ingest.dart` is currently
equivalent to scanning the feature — and if the file is moved the scan throws
rather than silently passing. It does become blind to any *second* file added to
the feature.

- **Mutation 8** (false-positive probe) — a doc comment reading "Callers such as
  the paged orchestrator own their own PdfTextExtractor" fails the scan. The
  sibling AD-009 test strips `//` lines precisely because "prose may name the
  constraint; only executable references count" (`:73`). The new scan does not.

### Gap 3 (Cosmetic) — bookkeeping

✅ **Closed, and the claims check out as true, not merely present.**

| Claim | Verified |
| --- | --- |
| AD-011 recorded in `.specs/STATE.md:85-91` | ✅ Present, numbering does not collide, `active` |
| AD-011 honestly states what was given up | ✅ Its trade-off line — "`TextProcessingService` keeps `PdfTextExtractor`, so 'the processing service references no PDF-specific types' is knowingly not true" — is literally true: `text_processing_service.dart:47,84`. It also correctly scopes the compensating test as "that narrower promise" rather than claiming the original AC |
| Handoff refreshed | ✅ `.specs/STATE.md:94-103` now names `web_source_import`, branch `feat/web-source-import`, and carries the cancelled-book-resume decision forward as the next step. Previously it still described the *narration* feature |
| `spec.md` traceability matches reality | ✅ WEB-01…WEB-12 and WEB-15 moved `Design/Pending` → `Execute/Implementing`; WEB-13/WEB-14 correctly left `Pending`. Conservative and accurate — they were not marked `Verified` while validation was still failing. The coverage line replaces the stale "0 mapped to tasks, 15 unmapped ⚠️" with a true statement. This report's traceability section moves them to `Verified` |
| `tasks.md` header matches the branch | ✅ "T1–T24, T27–T28 and fixes F1–F5 complete. T25–T26 (P2) unstarted." F1–F5 map 1:1 to commits `4f560aa`, `98e2e53`, `d1c2a30`, `a818fd6`, `3406246`; T25/T26 have no service or UI consumer |

One inconsistency, cosmetic: the iteration-2 fixes delivered by `c58d705` were
**not** written into `tasks.md` as tasks, although the iteration-1 fixes were
(`### F1`…`### F5`, plus batch row 5 in the Phase Execution Map at `:953`). The
Phase Execution Map has no row for this round's work.

---

## Regression Check (`f144462..c58d705`)

| Risk | Finding |
| --- | --- |
| Production behaviour | **No risk** — zero `lib/` changes in the commit |
| `siteRecipeRegistry` / `resumeWebDownloads` newly used by the test | Both parameters pre-existed (`configure_dependencies.dart:167,173,345-346,422`); the commit only *uses* seams already shipped |
| Shared DI test file disturbed | No. Fresh `GetIt.asNewInstance()` per test with `resetDependencies` in `tearDown` (`:55-61`); the rewritten test registers its own `AppDatabase` through the guarded-registration pattern the project mandates. **Mutation 5** (drop the default startup resume) still kills `startup resumes a partially downloaded web book with no explicit download call`, so the neighbouring container test lost none of its discrimination |
| Flakiness of the new timing-shaped test | Ran `configure_dependencies_test.dart` three consecutive times: `+19 All tests passed!` each time |
| Test count | 612 → **613** (+1, the new architecture scan). No test deleted, no assertion weakened |

Iteration-2 criteria not plausibly disturbed by a test-only commit were
**spot-checked, not re-derived**, as instructed. Mutations 5, 6 and 7 re-confirm
the startup-resume seam, the cancel semantics, and the library routing branch.

---

## Spec-Anchored Acceptance Criteria

Iteration 2 established 26 of 26 in-scope P1 criteria as behaviourally
satisfied, with full `file:line` evidence; that table is not re-derived here.
Only the two criteria whose evidence changed this round are restated.

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| **WEB-06 AC1** (amended) — one shared ingest core, referencing no source-specific type; adding a source does not fork it | both orchestrators route clean chapter text through one `ChapterIngest`; the core names no source-specific type | *Shared core*: `text_processing_service.dart:92` and `web_novel_download_service.dart:62,198` construct/consume the same `ChapterIngest`; `test/features/content_ingestion/domain/services/chapter_ingest_test.dart:38-124`. *No fork*: `test/architecture/web_source_architecture_test.dart:55-74`. *First clause*: **now asserted** at `web_source_architecture_test.dart:66-68` `expect(sourceSpecific, isEmpty)` — kills `PdfTextExtractor` (Mutation 3), misses `HtmlRecipeParser` (Mutation 4) | ✅ PASS with a narrowed guard |
| **WEB-11 AC6** — cancel stops requests and retains stored chapters | stop issuing requests; keep every stored chapter | Service: `web_novel_download_service_test.dart:838` `expect(outcome, WebDownloadOutcome.cancelled)`, `:839` only chapter 1 requested, `:840` states `[stored, pending, pending]`, `:845` no discard. UI route: `library_page_test.dart:218` `expect(fixture.cancelledWebBookIds, ['9'])` (list + grid). **Composition (new)**: `configure_dependencies_test.dart:647` `expect(fetcher.requests.map(…), [_webChapterUrl(2)])` after the page's own cancel callback ran mid-drain | ✅ PASS — seam now discriminating |

All other criteria: unchanged from iteration 2 — **26 of 26** in-scope P1
criteria behaviourally satisfied, **9 of 9** listed edge cases covered.

### Out of scope this round

| Requirement | State |
| --- | --- |
| WEB-13, WEB-14 (P2) | Not implemented — T25/T26 deliberately deferred; repository affordances exist and are covered, with no consumer yet |
| WEB-15 (P3) | Delivered at registry scope; a new domain needs only a recipe entry |

---

## Discrimination Sensor

Depth: **P0-full** — eight behaviour-level mutations, weighted to the code and
tests `c58d705` changed. Every mutation was applied in a temporary `git worktree`
at `c58d705`, tested, reverted; the worktree was removed and the real tree
confirmed clean. Each mutation was checked to compile (`flutter analyze` clean)
where the change was non-trivial, so no kill is a compile-error false positive.

| # | File:line | Mutation | Tests run | Killed? |
| --- | --- | --- | --- | --- |
| 1 | `lib/app/dependency_injection/configure_dependencies.dart:431-432` | **The iteration-2 survivor**: web cancel route → inert `(bookId) async {}` | `configure_dependencies_test.dart` | ✅ Killed — `the composed library page stops a running web download` (17 passed, 1 failed) |
| 2 | same:432 | Route reaches the real service with a mangled id — `cancel('$bookId-x')` | `configure_dependencies_test.dart` | ✅ Killed — same test (17 passed, 1 failed). Proves identity, not just reachability |
| 3 | `lib/features/content_ingestion/domain/services/chapter_ingest.dart:6,67` | Import `pdf_text_extractor.dart`, add `PdfTextExtractor? extractor` (analyze clean) | `test/architecture` | ✅ Killed — `the shared ingest core names no source-specific type (WEB-06)` (8 passed, 1 failed) |
| 4 | same | Import `html_recipe_parser.dart`, add `HtmlRecipeParser? parser; ChapterParseResult? lastParse` (analyze clean) | `test/architecture`, then **full suite** | ❌ **Survived — 613/613 passed** |
| 5 | `configure_dependencies.dart:422` | Drop the default startup resume, keeping only the injected seam | `configure_dependencies_test.dart` | ✅ Killed — `startup resumes a partially downloaded web book with no explicit download call` |
| 6 | `lib/features/web_source/domain/services/web_novel_download_service.dart:137` | `cancel` never sets `requested` | `test/features/web_source`, `test/app/dependency_injection` | ✅ Killed — 4 failures, including the new container test |
| 7 | `lib/features/library/presentation/pages/library_page.dart:216-220` | Remove the web branch so every cancel routes to the PDF cubit | `test/features/library`, `test/app/dependency_injection` | ✅ Killed — `list/grid cancelling a web book stops its download` (124 passed, 2 failed) |
| 8 | `chapter_ingest.dart:42` (false-positive probe) | Doc comment naming `PdfTextExtractor`, no code change | `test/architecture` | ⚠️ Failed the scan — the guard trips on prose, unlike its AD-009 sibling |

**Sensor depth**: P0-full
**Result**: **7 of 8 behaved as intended; 1 probe mutant survived (#4)** and one
probe (#8) exposes a false-positive edge. Mutation 4 is a *widening* probe of a
guard that did not exist before this commit, not a regression: WEB-06 AC1's first
clause went from **no** assertion to a partial one.

---

## Gate Check

- **Gate command**: `flutter analyze && flutter test && flutter build apk --debug`
- `flutter analyze`: ✅ **No issues found** (exit 0)
- `flutter test`: ✅ **613 passed, 0 failed, 0 skipped** (exit 0) — matches the expected 613
- `flutter build apk --debug`: ✅ **Built `build/app/outputs/flutter-apk/app-debug.apk`** (exit 0)
- **Test count before the feature** (`69ad930`): **377**
- **After iteration 1** (`9309bf7`): **593** → **after fixes** (`f144462`): **612** → **now** (`c58d705`): **613**
- **Delta**: **+236** for the feature; **+1** this round
- **Skipped**: none
- **Test integrity**: `git diff f144462..c58d705 -- test/` is **+86 / −10**. The
  only removed `testWidgets(` line is the rename of the cancel test. No
  assertion was weakened; the rewritten test is strictly stronger (an
  existence check became a behavioural one)

---

## Code Quality

| Principle | Status |
| --- | --- |
| Minimum code | ✅ Test-only commit; no production code added to satisfy a verifier |
| Surgical changes | ✅ Two test files plus spec bookkeeping |
| No scope creep | ✅ P2 (T25/T26) still unimplemented |
| Matches patterns | ✅ Hand-written fakes, `final class`, guarded registrations, real `NativeDatabase`, pt-BR UI strings, Conventional Commit scope (CLAUDE.md) |
| Spec-anchored outcome check | ✅ Both previously unasserted clauses now have assertions targeting the spec-defined outcome |
| Per-layer Coverage Expectation met | ✅ The composition layer now asserts behaviour, not existence |
| Every test maps to a spec requirement — no unclaimed tests | ✅ Both new/changed tests name their requirement (WEB-11 AC6, WEB-06) |
| Documented guidelines followed | ✅ `CLAUDE.md` (AD-002…AD-011, test conventions, commit format) |
| Documented deviation | `web_novel_index_resolver.dart:36` `// SPEC_DEVIATION` — sealed result instead of the design's throwing signature; unchanged this round |

Two style nits in `c58d705`, cosmetic only:

1. `configure_dependencies_test.dart:719-723` — the doc comment "Serves
   synthetic chapter pages and records every URL it was asked for…" belonged to
   `_ChapterFetcher` and now dangles above `const SiteRecipe _centralNovelRecipe`,
   which was inserted between them. Two doc comments are now stacked on the
   recipe constant.
2. `.specs/STATE.md:92-93` — a stray double blank line before `## Handoff`.

---

## Product Decision Carried Forward (not a defect)

A cancelled web book stays `processing` with pending entries
(`web_novel_download_service.dart:176`), so `resumePending` re-enqueues it at the
next launch (`:114-129`). WEB-11 AC5 and AC6 are both silent on which wins. This
is now an open product decision with the user and is recorded as the next step in
`.specs/STATE.md`'s handoff. It is **not** ranked as a gap.

---

## Fix Plans (non-blocking — recommended, not required for PASS)

### Residual 1: the WEB-06 ingest-core scan is name-shaped, not import-shaped — Minor

- **Root cause**: `web_source_architecture_test.dart:65-67` keys on type-name
  patterns. Mutation 4 shows a `web_source` data-layer type
  (`HtmlRecipeParser`, `ChapterParseResult`) reaching the shared ingest core
  while all 613 tests stay green. `PoliteWebFetcher` and `PdfrxPdfTextExtractor`
  are equally invisible to the pattern.
- **Suggested fix**: assert on imports instead of names, mirroring the AD-010
  scan at `:34-53` — no file under `lib/features/content_ingestion/` may import
  `features/web_source/` or a PDF-specific service (`pdf_text_extractor.dart`,
  `pdfrx_pdf_text_extractor.dart`); keep the name pattern as a second belt.
  Iterate `dartSourcesIn('lib/features/content_ingestion')` rather than pinning
  one filename, so a second file in the feature cannot slip past.
- **Verify**: the test fails for both Mutation 3 and Mutation 4.
- **Priority**: Minor (widens a guard that did not exist before this commit).

### Residual 2: the same scan trips on prose — Cosmetic

- **Root cause**: it reads the raw file. Mutation 8 shows a doc comment naming
  `PdfTextExtractor` fails the build, while the sibling AD-009 scan at `:70-88`
  deliberately strips `//` lines for exactly this reason.
- **Suggested fix**: strip comment lines the way `:75-79` already does.
- **Priority**: Cosmetic.

### Residual 3: `c58d705`'s work is untracked in `tasks.md` — Cosmetic

- Iteration-1 fixes became `### F1`…`### F5` with a Phase Execution Map row;
  iteration-2 fixes got neither. Add `F6`/`F7` (or a "Verifier fixes — round 2"
  row) so the tasks file continues to account for every commit on the branch.

---

## Requirement Traceability Update

| Requirement | Previous | New |
| --- | --- | --- |
| WEB-01 | ✅ Verified | ✅ Verified |
| WEB-02 | ✅ Verified | ✅ Verified |
| WEB-03 | ✅ Verified | ✅ Verified |
| WEB-04 | ✅ Verified | ✅ Verified |
| WEB-05 | ✅ Verified | ✅ Verified |
| WEB-06 | ⚠️ First clause unasserted | ✅ Verified against the amended AC (AD-011) — guard present and killing the canonical violation; widening recommended (Residual 1) |
| WEB-07 | ✅ Verified | ✅ Verified |
| WEB-08 | ✅ Verified | ✅ Verified |
| WEB-09 | ✅ Verified | ✅ Verified |
| WEB-10 | ✅ Verified | ✅ Verified |
| WEB-11 | ⚠️ AC6 seam untested | ✅ Verified — composition seam now kills both the inert route and the mangled-id route |
| WEB-12 | ✅ Verified | ✅ Verified |
| WEB-13 | ⏭️ Deferred | ⏭️ Deferred (P2) |
| WEB-14 | ⏭️ Deferred | ⏭️ Deferred (P2) |
| WEB-15 | ✅ Verified | ✅ Verified (registry scope) |

`spec.md`'s table still reads `Implementing` for WEB-01…WEB-12 and WEB-15; with
this PASS they may be advanced to `Verified`.

---

## Summary

**Overall**: ✅ **Ready**

**Spec-anchored check**: 26 of 26 in-scope P1 criteria satisfied; 9 of 9 edge
cases covered; both iteration-2 evidence gaps closed.
**Sensor**: 8 mutations — the iteration-2 survivor and a subtler variant of it
are both killed; the canonical WEB-06 violation is killed; 1 widening probe
survived (Residual 1), 1 false-positive probe noted (Residual 2).
**Gate**: analyze clean, **613** tests passed, debug APK built.

**What this round genuinely closed**: the composition root's web-cancel route is
no longer asserted by existence. It is driven through the real `GoRouter`-built
`LibraryPage` against a live drain, and it fails both when the route is inert and
when it reaches the right service with the wrong id — so it tests the
requirement, not the mutation that motivated it. WEB-06 AC1's first clause has
gone from zero assertions to a guard that kills the violation the amendment was
written about. AD-011 records the trade-off truthfully, including the part that
is knowingly not true, and the handoff, traceability table, and tasks header now
describe this feature rather than the previous one.

**Issues found**: three residuals, all Minor/Cosmetic, none blocking: a
name-shaped ingest-core scan with demonstrated blind spots, its prose
false-positive, and untracked fix tasks in `tasks.md`.

**Next steps**: advance `spec.md`'s traceability statuses to `Verified`;
optionally apply Residual 1 (import-shaped scan) before merge; and settle the
open product decision on whether a cancelled web book should stay cancelled
across a restart.
