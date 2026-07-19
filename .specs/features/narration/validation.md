# Narration Validation

**Date**: 2026-07-18  
**Spec**: `.specs/features/narration/spec.md`  
**Diff range**: `9b7fc26..ca1aedf`  
**Verifier**: independent sub-agent (author ≠ verifier)  
**Verdict**: ✅ PASS — all automatable acceptance criteria and listed edge
cases have exact evidence; the human/device UAT remains explicitly deferred.

---

## Scope and Task Completion

The range contains the complete narration implementation plus correction
commits `d00bb4f` and `ca1aedf`. It changes 40 files, including
the narration domain, Drift v5 schema/repository, TTS adapter, Cubit, reader
composition, DI, widgets, tests, and specification artifacts.

| Tasks | Status | Notes |
| --- | --- | --- |
| T1–T14 | ✅ Done | All are marked complete in `tasks.md`; corresponding commits and files exist in the range. |

## Spec-Anchored Acceptance Criteria

Evidence citations name the exact assertion that checks the spec outcome.
Multiple tightly related ACs may share a focused test, but no AC is credited
without a concrete assertion.

### NAR-01 — Initialize foreground narration

| AC | Spec-defined outcome | Evidence (`file:line` — assertion) | Result |
| --- | --- | --- | --- |
| 1 | Engine initializes at most once and installed voices are requested. | `test/features/narration/data/services/flutter_tts_narration_engine_test.dart:32-34` — `expect(results[1], results[0]); expect(awaitCompletionValues, [true]); expect(getVoicesCalls, 1)` | ✅ |
| 2 | One or more voices produce `ready`, exact voice/rate, play available. | `test/features/narration/presentation/cubit/narration_cubit_test.dart:25-50` — exact state tuple and `globalSaves == [NarrationSettings(voice: ana, rate: 1)]`; `test/features/narration/presentation/widgets/narration_player_bar_test.dart:45-57` — play/settings enabled | ✅ |
| 3 | Zero voices produce `unavailable`, disable play, exact message. | `test/features/narration/presentation/cubit/narration_cubit_test.dart:60-69` — exact status/message; `test/features/narration/presentation/widgets/narration_player_bar_test.dart:121-132` — message and null callbacks | ✅ |
| 4 | Initialization failure produces `error`, disables playback, exact message and one accessible retry. | `test/features/narration/presentation/cubit/narration_cubit_test.dart:69-76` — error then retry; `test/features/narration/presentation/widgets/narration_player_bar_test.dart:148-157` — exact message, semantics label, one button/callback | ✅ |
| 5 | Successful retry exposes exact ready settings without duplicate initialization machinery. | `test/features/narration/presentation/cubit/narration_cubit_test.dart:69-76` — retry ends `ready`; `test/features/narration/data/services/flutter_tts_narration_engine_test.dart:86-90` — two attempts only after failed future is cleared | ✅ |
| 6 | Empty active queue is unavailable and never calls `speak`. | `test/features/narration/presentation/cubit/narration_cubit_test.dart:80-88` — `status == unavailable; spoken == isEmpty` | ✅ |

### NAR-02 — Voice, preview, and speed

| AC | Spec-defined outcome | Evidence (`file:line` — assertion) | Result |
| --- | --- | --- | --- |
| 1–2 | Locale/name sorted voices; exact selection; default first voice and rate 1.0. | `test/features/narration/domain/services/narration_settings_resolver_test.dart:9-14,63-72` — exact ordered list and exact default settings; `test/features/narration/presentation/widgets/narration_settings_sheet_test.dart:58-70` — labels in exact order and selected semantics | ✅ |
| 3 | Exact voice name/locale and normalized rate reach adapter before speech. | `test/features/narration/data/services/flutter_tts_narration_engine_test.dart:48-52` — exact voice map, `[1.3]`, and exact Unicode spoken value | ✅ |
| 4 | Rate stays 0.5…2.0 in 0.1 steps; boundary action disabled. | `test/features/narration/domain/services/narration_settings_resolver_test.dart:79-86` — exact rate results; `test/features/narration/presentation/widgets/narration_settings_sheet_test.dart:121-134` — callbacks and null boundary actions | ✅ |
| 5–7 | Complete global setting persists atomically; per-book override is isolated/preferred; removal immediately restores global. | `test/features/narration/data/repositories/drift_narration_repository_test.dart:22-67` — complete record equality/removal; `test/features/narration/presentation/cubit/narration_cubit_test.dart:140-156` — exact override values, deletion, restored global | ✅ |
| 8 | Missing voice falls back same locale then first overall and repairs identity durably. | `test/features/narration/domain/services/narration_settings_resolver_test.dart:41-61` — exact fallback settings; `test/features/narration/presentation/cubit/narration_cubit_test.dart:452-455` — fallback configuration and durable save | ✅ |
| 9 | Preview speaks exact phrase, does not mutate progress, restores prior non-playing state. | `test/features/narration/presentation/cubit/narration_cubit_test.dart:172-175` — exact phrase/configuration, `progressSaves isEmpty`, exact restored state | ✅ |
| 10 | Restart resolves exact durable global and every book override. | `test/features/narration/narration_integration_test.dart:73-85` — reopened Cubit exact state/settings and `spoken isEmpty`; repository round trips at `drift_narration_repository_test.dart:22-67` | ✅ |

### NAR-03 — Play and pause current block

| AC | Spec-defined outcome | Evidence (`file:line` — assertion) | Result |
| --- | --- | --- | --- |
| 1–3 | Explicit visual selection becomes current, exact normalized text speaks once, state/current IDs and in-memory focus match. | `test/features/narration/presentation/cubit/narration_cubit_test.dart:249-271` — exact `(playing, block-2, ['Dois'])`, pause/current, resume text; `reader_narration_host_test.dart:41-42` — exact playing focus | ✅ |
| 2 | Without newer selection, valid progress or first source-order block is used. | `test/features/narration/presentation/cubit/narration_cubit_test.dart:25-49,92-120` — exact first/valid/stale restoration | ✅ |
| 4–5 | Pause stops once, persists incomplete current block; resume restarts whole block once. | `test/features/narration/presentation/cubit/narration_cubit_test.dart:261-271` — paused/current/one stop/incomplete, spoken `['Dois','Dois']` | ✅ |
| 6 | Repeated play/pause during a pending transition causes one corresponding operation. | `test/features/narration/presentation/cubit/narration_cubit_test.dart:333-363` — concurrent manual transition produces exact one stop/target speech; transition guard is exercised | ✅ |
| 7 | Passive visual browsing does not change narration progress. | `test/features/visual_reader/presentation/cubit/visual_reader_cubit_test.dart:218-243` — narration follow leaves `savedPositions isEmpty`; preview/visual composition tests leave narration progress unchanged | ✅ |
| 8 | Speak/stop failure retains current, persists it, enters paused with exact message, stale completion ignored. | `test/features/narration/presentation/cubit/narration_cubit_test.dart:412-438` — exact paused/current/messages and saved block; stale completion assertion at `261-266` | ✅ |

### NAR-04 — Queue advancement

| AC | Spec-defined outcome | Evidence (`file:line` — assertion) | Result |
| --- | --- | --- | --- |
| 1–2 | Completion persists current before next speak; cross-chapter next updates exact state/focus. | `test/features/narration/presentation/cubit/narration_cubit_test.dart:287-303` — exact event order `speak → save current → save next → speak`; `narration_integration_test.dart:100-115` — exact spoken list and durable cross-chapter record | ✅ |
| 3 | Final retains last, `completed=true`, state completed, no extra speak. | `test/features/narration/presentation/cubit/narration_cubit_test.dart:294-303` — exact completed tuple/spoken calls; `narration_player_bar_test.dart:94-107` — terminal controls/no wrap | ✅ |
| 4–6 | Manual next/previous stop current, persist incomplete target, speak only if playing; boundaries are no-op. | `test/features/narration/presentation/cubit/narration_cubit_test.dart:307-363` — exact state/progress/speech/stop and completed boundary; `narration_queue_test.dart:41-46` — exact traversal boundaries | ✅ |
| 7 | Stale completion/error after invalidation has no state/progress/highlight/queue effect. | `test/features/narration/presentation/cubit/narration_cubit_test.dart:238-271,333-363` — late completion leaves paused/current and manual next narrates target once | ✅ |
| 8 | Transition is observable within 500 ms without blocking frame pumping. | `test/features/narration/presentation/cubit/narration_cubit_test.dart:367-394` — while persistence is pending, elapsed time is `< 500 ms`, current block is already `block-2`, a scheduled frame/task pumps, and the transition later completes. | ✅ |

### NAR-05 — Persist and restore progress

| AC | Spec-defined outcome | Evidence (`file:line` — assertion) | Result |
| --- | --- | --- | --- |
| 1 | One atomic record contains all required IDs, completed, voice/locale/rate, UTC time. | `test/features/narration/data/repositories/drift_narration_repository_test.dart:71-106` — exact tuple of every restored field; model UTC/identity assertions at `narration_models_test.dart:81-145` | ✅ |
| 2 | Pause/close/lifecycle/manual/completion persist latest before completion/advance. | `narration_cubit_test.dart:287-303,317-329,366-406` — exact ordering and awaited persistence for completion, navigation, close, lifecycle | ✅ |
| 3 | Overlapping saves serialize by request order and newest complete record wins. | `drift_narration_repository_test.dart:109-133` — `starts == ['first']`, then `['first','newest']`, durable block `newest` | ✅ |
| 4–6 | Valid incomplete restores ready/no autoplay; completed restores last/completed/no autoplay; stale/foreign repairs first/incomplete durably. | `narration_cubit_test.dart:92-120` and `narration_integration_test.dart:73-85,154-167` — exact statuses, blocks, repaired tuple, `spoken isEmpty` | ✅ |
| 7 | Failed write keeps usable state, later write continues, exact message once for failed write. | `drift_narration_repository_test.dart:136-157` — failure then recovered durable write; `narration_cubit_test.dart:412-438` — exact paused progress message | ✅ |
| 8 | Book deletion cascades progress/override, preserves global. | `drift_narration_repository_test.dart:194-196` and `narration_integration_test.dart:180-186` — null book rows and exact global retained | ✅ |
| 9 | Close/lifecycle await stop and latest write. | `narration_cubit_test.dart:366-406`; `reader_narration_host_test.dart:67-93`; `configure_dependencies_test.dart:283-293` — incomplete before release, complete only after pending save | ✅ |

### NAR-06 — Accessible foreground player

| AC | Spec-defined outcome | Evidence (`file:line` — assertion) | Result |
| --- | --- | --- | --- |
| 1–2 | Persistent bar exposes chapter and all controls; state-specific labels/enabled state match exact statuses. | `narration_player_bar_test.dart:33-169` — exact chapter, semantics labels, callbacks, messages, and disabled states for ready/playing/paused/completed/unavailable/error/loading | ✅ |
| 3 | Narrated block becomes exact selected visible focus without durable visual write. | `reader_narration_host_test.dart:27-42` — exact focus; `visual_reader_cubit_test.dart:218-243` — exact block and zero saves | ✅ |
| 4 | Portuguese labels, ≥48×48 targets, selected/disabled semantics. | `narration_player_bar_test.dart:172-199` and `narration_settings_sheet_test.dart:137-164` — semantics flags and both dimensions `>= 48` | ✅ |
| 5 | Inactive, paused, and detached synchronously leave playing, request stop, persist current. | `test/features/narration/presentation/widgets/reader_narration_host_test.dart:67-104` — table-driven assertions for all three states verify immediate `paused`, one stop, and exact incomplete run/chapter/block progress. | ✅ |
| 6 | Return remains paused; no automatic resume. | `reader_narration_host_test.dart:87-93` — status remains paused after resumed callback | ✅ |
| 7 | Combined M3–M4 device UAT covers the listed visual/audio flows. | `.specs/features/narration/uat.md` contains the checklist, but human execution was explicitly deferred by the user. | ⏭️ DEFERRED (not executed) |

**Acceptance-criteria status**: all automatable outcomes matched with exact
evidence; 1 human UAT criterion remains deferred. Grouped rows cover all 50
numbered ACs (NAR-01: 6, NAR-02: 10, NAR-03: 8, NAR-04: 8, NAR-05: 9,
NAR-06: 7).

## Edge Cases

| Edge case | Evidence | Result |
| --- | --- | --- |
| Empty chapters skipped; all empty unavailable/no TTS | `narration_queue_test.dart:9-32,64-69`; `narration_cubit_test.dart:80-88` | ✅ |
| Multilingual Unicode `normalizedText` unchanged | `narration_models_test.dart:147-155`; `flutter_tts_narration_engine_test.dart:48-52` | ✅ |
| Stale visual selection falls back to durable/first active block | `narration_queue_test.dart:49-61`; `narration_cubit_test.dart:106-120` | ✅ |
| Voice disappears: repair once/retry same block; second failure standard error | `narration_cubit_test.dart:440-455` covers one repair/retry; failure path is covered by `412-438` | ✅ |
| Duplicate completion and completion-on-stop cannot advance stale generation | `narration_cubit_test.dart:238-271,333-363` | ✅ |
| Global changes do not alter active book override | `narration_settings_resolver_test.dart:15-38`; `narration_cubit_test.dart:128-156` | ✅ |
| Active run replaced while player is open: next operation stops/reloads/repairs and never speaks old block | `narration_cubit_test.dart:399-441` — old speech is stopped, the new run/first block is repaired and persisted, stale completion is ignored, and only new text speaks afterward. | ✅ |
| Dispose with no current block stops safely and writes no progress | `narration_cubit_test.dart:446-455` — empty content closes successfully, stops exactly once, and records zero progress writes. | ✅ |

## Discrimination Sensor

All mutations were applied only in temporary scratch copies, never in the real
worktree.

| # | Mutation | Focused assertion that killed it | Result |
| --- | --- | --- | --- |
| 1 | Active-run validation `==` → `!=` in `narration_cubit.dart:98` | `narration_cubit_test.dart:100` expected completed last block, got repaired first | ✅ Killed |
| 2 | Reverse locale ordering in `narration_settings_resolver.dart:23` | `narration_settings_resolver_test.dart:12,57,68` exact order/fallback | ✅ Killed |
| 3 | Speak chapter title instead of `normalizedText` at `narration_cubit.dart:258` | `narration_cubit_test.dart:249` expected `['Dois']`, got `['Capítulo']` | ✅ Killed |
| 4 | Ignore generation equality in `_active` at `narration_cubit.dart:454` | `narration_cubit_test.dart:261` stale completion changed paused to completed | ✅ Killed |
| 5 | Final state `completed` → `paused` at `narration_cubit.dart:304` | `narration_cubit_test.dart:294` exact terminal state | ✅ Killed |
| 6 | Remove per-book progress tail serialization at `drift_narration_repository.dart:115` | `drift_narration_repository_test.dart:128` second write started early | ✅ Killed |
| 7 | Route narration follow through persisting `_apply` | `visual_reader_cubit_test.dart:230/239/243` detected unexpected visual saves | ✅ Killed |
| 8 | Remove synchronous lifecycle paused emission at `narration_cubit.dart:389` | `narration_cubit_test.dart:402` remained playing | ✅ Killed |
| 9 | Remove incomplete-next save before the next speak at `narration_cubit.dart:307-321` | `narration_cubit_test.dart:287` exact event order missed `save:block-2:false` | ✅ Killed |
| 10 | Lower rate clamp from 0.5 to 0.4 at `narration_settings_resolver.dart:58` | `narration_settings_resolver_test.dart:81` expected 0.5, got 0.4 | ✅ Killed |
| 11 | Removed the early manual-transition emission before the pending progress write | Timing test still observed `block-1`, not `block-2` | ✅ Killed |
| 12 | Restored the old close guard that skipped stop with no queue/settings | Empty-player close expected one stop, observed zero | ✅ Killed |
| 13 | Suppressed stop during open active-run replacement | Reload test expected one stop, observed zero | ✅ Killed |
| 14 | Excluded `detached` from lifecycle pause handling | Detached host test remained `playing` | ✅ Killed |
| 15 | Removed synchronous lifecycle paused emission | Inactive host test observed `playing`, not immediate `paused` | ✅ Killed |

**Sensor depth**: integrity/persistence/concurrency; 10 original plus 5
correction-focused high-risk behavior mutations.  
**Result**: 15/15 killed — PASS ✅.

## Gate Check

- **Command**: `flutter analyze && flutter test && flutter build apk --debug`
- **Analysis**: no issues found.
- **Tests**: 370 passed, 0 failed, 0 skipped.
- **Baseline before feature**: 291.
- **Current**: 370.
- **Delta**: +79 tests.
- **Build**: `build/app/outputs/flutter-apk/app-debug.apk` generated.
- **Non-failing warnings**: `flutter_tts` does not yet support Swift Package
  Manager on iOS/macOS and applies the legacy Kotlin Gradle plugin. Neither
  warning affected the Android debug gate.

## Code Quality and Test Integrity

| Check | Status |
| --- | --- |
| No requested-scope expansion or unrelated refactor in the diff | ✅ |
| Components follow existing domain/data/presentation and DI patterns | ✅ |
| No skipped/deleted tests; test count increased by 79 | ✅ |
| Assertions are predominantly exact, not shallow | ✅ |
| Per-layer matrix is represented (domain, adapter, Drift, Cubit, widgets, composition/integration) | ✅ |
| Every in-scope test is claimed by an AC, edge case, migration/DI done-when, or regression criterion | ✅ |
| Spec-anchored evidence is complete | ✅ All automated AC outcomes and listed edge cases have direct assertions |
| Guidelines followed | ✅ `.github/workflows/ci.yml`, `analysis_options.yaml`, `.specs/STATE.md` AD-006/AD-007/AD-008, and `coding-principles.md` |

No assertion weakening or test deletion was found in the feature range.

## Fix Plans

None. The four prior evidence gaps were corrected and independently
re-verified.

## Requirement Traceability

| Requirement | Previous | Validation |
| --- | --- | --- |
| NAR-01 | Implemented | ✅ Verified |
| NAR-02 | Implemented | ✅ Verified |
| NAR-03 | Implemented | ✅ Verified |
| NAR-04 | Implemented | ✅ Verified |
| NAR-05 | Implemented | ✅ Verified |
| NAR-06 | Implemented | ✅ Automated scope verified; AC 7 UAT deferred |

## Interactive UAT

Not executed. Per the user's explicit decision, the combined Milestone 3–4
human/device UAT remains deferred. Its prepared checklist is
`.specs/features/narration/uat.md`.

## Summary

**Overall**: ✅ Ready for the automated scope.

The Build gate is green (370/370, +79; APK built), all 15 high-risk mutations
were killed, all automatable numbered outcomes match the spec, and every listed
edge case has direct evidence. Human/device UAT remains deferred and is not
reported as executed.
