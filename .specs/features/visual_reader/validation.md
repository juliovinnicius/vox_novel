# Visual Reader Validation

**Date**: 2026-07-18  
**Spec**: `.specs/features/visual_reader/spec.md`  
**Diff**: `24b338e..6ae80d1` (including lint checkpoint `753f1af`)  
**Verifier**: independent sub-agent (author ≠ verifier)

## Verdict

**PASS after `eac8ecd` and `db78d16`.** The complete build gate passes and all
8 required high-risk mutants are killed. Per-book newest-wins serialization is
now exercised with adversarial physical write start order, and stale repair
uses a multi-block first chapter that distinguishes first from last.

## Spec-Anchored Acceptance Criteria

### READ-01 — Open and read reformatted text

| AC | Exact outcome and evidence | Result |
| --- | --- | --- |
| 1 | ready route/title/active content — repository test `:25-31` asserts exact book, chapter IDs, blocks and raw text; page test `:110` asserts `Minha Novel` | ✅ |
| 2 | no saved position → first chapter/block — Cubit test `:23-27` exact loading→ready and fallback conjunction | ✅ |
| 3 | exact title/blocks once in numeric order — text view test `:68-74` exact Unicode texts/order/no exception | ✅ |
| 4 | selected visual + accessibility — text view test `:89` asserts semantic selected; theme tests assert selected palette distinction | ✅ |
| 5 | tap exact block/persist IDs/text unchanged — text view test `:94`; Cubit test `:110-112` exact saved chapter/block | ✅ |
| 6 | empty chapter exact message — text view test `:99` | ✅ |
| 7 | absent/not-ready/no active → exact unavailable/back — repository `:39,43,52`; page `:99-100` | ✅ |

### READ-02 — Navigate chapters

| AC | Exact outcome and evidence | Result |
| --- | --- | --- |
| 1 | accessible end drawer, numeric order — drawer test `:61` ordered positions | ✅ |
| 2 | current chapter semantics/exact titles — drawer `:74-75` selected + `Capítulo atual` | ✅ |
| 3 | selection closes drawer and first/empty block — drawer `:89-91`; Cubit `:141-151` | ✅ |
| 4 | previous/next adjacent source order — page `:116-117`; text view `:115` callbacks | ✅ |
| 5 | first/last unavailable action disabled — text view `:123,131` exact null actions | ✅ |
| 6 | navigation persists resulting chapter/block — Cubit `:147-151` exact state and saved position | ✅ |

### READ-03 — Original PDF

| AC | Exact outcome and evidence | Result |
| --- | --- | --- |
| 1 | text→PDF uses block start/chapter start — resolver `reader_domain_test.dart:52-53` exact pages 2/4 | ✅ |
| 2 | one-based `Página X de Y` — PDF widget `:45-47,58-59` | ✅ |
| 3 | page bounded and persisted — Cubit `:174-185`; PDF widget `:58` valid callback | ✅ |
| 4 | PDF→text first matching block/chapter/retain prior — resolver `:54-56` | ✅ |
| 5 | exact PDF error and text remains reachable — PDF widget `:100,105`; page tooltip `:132` | ✅ |
| 6 | restore valid/clamp invalid page — Cubit stale test `:101`; domain validation `:71` | ✅ |

### READ-04 — Reading settings

| AC | Exact outcome and evidence | Result |
| --- | --- | --- |
| 1 | controls/current values/accessibility — settings sheet `:43-58` | ✅ |
| 2 | light/sans/18/1.5 defaults — domain test `:9` exact settings object | ✅ |
| 3 | exactly light/sepia/dark and contrast — sheet `:117,120`; palette tests assert contrast | ✅ |
| 4 | font 14…32 by 2, disabled bounds — domain `:19`; sheet `:74,80,91` | ✅ |
| 5 | line height enumerated — sheet `:119,122` | ✅ |
| 6 | family sans/serif — sheet `:118,121` | ✅ |
| 7 | immediate visible update + atomic full save — page `:121-124`; repository `:65-66` exact complete settings | ✅ |
| 8 | restart restores global settings — integration `:61` exact restored settings | ✅ |

### READ-05 — Durable visual position

| AC | Exact outcome and evidence | Result |
| --- | --- | --- |
| 1 | each change saves one complete latest position — Cubit navigation assertions `:141-185` and repository round-trip `:96` | ✅ |
| 2 | overlap follows request order/newest wins — repository test `:113-165` holds the first physical write, proves only it starts before release, then asserts exact complete second durable position | ✅ |
| 3 | valid active-run position restores exact and scrolls — Cubit `:58`; page `:165-167` | ✅ |
| 4 | stale IDs → first chapter/first block and repair — Cubit `:101-112` distinguishes `first-block` from `second-block`; integration `:107-114` distinguishes `block-1` from `block-1-last` and asserts durable repair | ✅ |
| 5 | deletion cascades position — schema `:161-162`; integration `:73-86` | ✅ |
| 6 | failed save retains session + exact message once — Cubit `:286-287`; page `:151-152` | ✅ |
| 7 | load/save responsive — integration `:129-159` shows readable state and close waits pending write | ✅ |

**AC total**: 34/34 matched.

## Edge Cases

| Edge | Exact evidence | Result |
| --- | --- | --- |
| one chapter/zero blocks | text view `:99` exact empty state | ✅ |
| storage rows out of order | repository `:26-31` adversarial IDs and numeric order | ✅ |
| block from other chapter/book stale | domain test `:71` fallback validation | ✅ |
| overlapping page ranges choose first source block | resolver test `:54` | ✅ |
| rotation retains all reader state | page test `:165-167` plus Cubit-owned mode/page | ✅ |
| system back returns without losing requested position | router/page integration and Cubit ordered tail tests | ✅ |
| long/multilingual wraps without horizontal scrolling | text view `:70-74,150-152` exact Unicode/lazy/no exception | ✅ |
| zero-page PDF unavailable | PDF widget `:105` exact error | ✅ |

## Build Gate

- `flutter analyze`: PASS, no issues.
- `flutter test --reporter compact`: PASS, **291 tests**, 0 failed, 0 skipped.
- `flutter build apk --debug`: PASS; debug APK produced.
- Diff source includes checkpoint `753f1af`.

## Expanded Discrimination Sensor

All mutations ran only in `/tmp/visual_reader_verify`.

| # | Required risk | Mutation | Observed test | Result |
| --- | --- | --- | --- | --- |
| 1 | active-run filter | invert ready-status predicate | repository exact-active test line 25 | ✅ Killed |
| 2 | numeric chapter/block order | chapter sort ascending→descending | repository numeric-order test; aggregate validation | ✅ Killed |
| 3 | selected semantic/highlight | semantic `selected` forced false | text view line 89 | ✅ Killed |
| 4 | PDF direction/page mapping | block `startPage`→`endPage` | domain resolver line 52 (2 vs 3) | ✅ Killed |
| 5 | settings bounds | minimum font 14→12 | domain settings line 19 | ✅ Killed |
| 6 | newest-wins | remove per-book future-tail chaining | repository physical-order test line 153 (`['9','1']` vs `['9']`) | ✅ Killed |
| 7 | stale repair | fallback first block→last block | Cubit stale test line 101 (`second-block` vs `first-block`) | ✅ Killed |
| 8 | delete cascade | reader-position FK CASCADE→RESTRICT (source + generated schema) | schema cascade test line 159 | ✅ Killed |

**Sensor**: 8 killed, 0 survived → PASS.

## Payload/Conjunction Review

- Active aggregate asserts book ID + ordered chapter IDs + ordered block IDs +
  exact original text (`drift_visual_reader_repository_test.dart:25-31`).
- Selection persistence asserts chapter and block together
  (`visual_reader_cubit_test.dart:110-112`).
- PDF state asserts mode + chapter + block + page and restored settings
  (`visual_reader_integration_test.dart:57-61`).
- Stale repair now uses two candidate blocks and asserts both current and
  durable repaired identities.
- Newest-wins now gates the first physical write and asserts start order plus
  every field of the durable second position.

## Code Quality

Feature-first boundaries, immutable domain state, Drift transactions, lazy
rendering, accessibility labels and injected PDF seams match existing project
patterns. No skips or `SPEC_DEVIATION` markers were found. The two surviving
mutants are test sufficiency defects, not confirmed implementation defects.

## Ranked Gaps

None.

## Interactive UAT

**Status**: Deferred by the user on 2026-07-18 because no runnable device/app
environment was available. This is not a failed acceptance result. The visual
reader UAT will be executed together with the Milestone 4 UAT.

## Summary

**Overall: PASS ✅**  
**Spec**: 34/34 ACs discriminated  
**Gate**: PASS (291 tests + analyzer + APK)  
**Sensor**: 8/8 killed

## Reverification Evidence (`eac8ecd`, `db78d16`)

- Removing `_positionTails` in `/tmp/visual_reader_reverify` is killed by
  `drift_visual_reader_repository_test.dart:153`: before releasing the first
  write, expected starts `['9']`, mutant produced `['9','1']`.
- Changing stale fallback from `firstOrNull` to `lastOrNull` is killed by
  `visual_reader_cubit_test.dart:101`: expected
  `[ReaderMode.text,'first','first-block',1]`, mutant selected
  `second-block`.
- Full regression gate on the real tree: analyzer clean, 291 tests passed,
  Android debug APK built.
- Real implementation and tests were not changed by the verifier.
